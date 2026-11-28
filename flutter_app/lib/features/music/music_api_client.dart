import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:encrypt/encrypt.dart' as encryption;

class MusicSong {
  const MusicSong({required this.id, required this.name, required this.artist, required this.album, required this.cover, required this.durationMs, this.fee = 0});
  final int id;
  final String name;
  final String artist;
  final String album;
  final String cover;
  final int durationMs;
  final int fee;

  factory MusicSong.fromJson(Map<String, dynamic> j) {
    final ar = j['ar'] ?? j['artists'] ?? [];
    final artist = ar is List ? ar.map((e) => e is Map ? e['name'] ?? '' : e).join(' / ') : '';
    final al = j['al'] ?? j['album'] ?? {};
    final cover = al is Map ? (al['picUrl'] ?? '').toString() : '';
    final duration = j['dt'] ?? j['duration'] ?? 0;
    return MusicSong(
      id: (j['id'] as num?)?.toInt() ?? 0,
      name: (j['name'] ?? '未知歌曲').toString(),
      artist: artist.isEmpty ? '未知歌手' : artist,
      album: al is Map ? (al['name'] ?? '').toString() : '',
      cover: cover.replaceFirst(RegExp(r'^http:'), 'https:'),
      durationMs: (duration as num?)?.toInt() ?? 0,
      fee: (j['fee'] as num?)?.toInt() ?? 0,
    );
  }
}

class MusicPlaylist {
  const MusicPlaylist({required this.id, required this.name, required this.cover, required this.count});
  final int id;
  final String name;
  final String cover;
  final int count;
  factory MusicPlaylist.fromJson(Map<String, dynamic> j) => MusicPlaylist(
    id: (j['id'] as num?)?.toInt() ?? 0,
    name: (j['name'] ?? '未命名歌单').toString(),
    cover: (j['coverImgUrl'] ?? '').toString().replaceFirst(RegExp(r'^http:'), 'https:'),
    count: (j['trackCount'] as num?)?.toInt() ?? 0,
  );
}

class MusicApiClient {
  static final Map<String, Map<String, dynamic>> _songUrlCache = {};
  static final Map<String, Map<String, dynamic>> _lyricCache = {};

  MusicApiClient({Dio? dio}) : _dio = dio ?? Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 25),
  ));
  final Dio _dio;
  static const defaultWorker = 'https://proxy.friedsully.com';

  String worker(String value) => value.trim().replaceAll(RegExp(r'/+$'), '').isEmpty
      ? defaultWorker
      : value.trim().replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, dynamic>> call(String base, String action, {String cookie = '', Map<String, dynamic> body = const {}}) async {
    final headers = <String, dynamic>{'Content-Type': 'application/json'};
    if (cookie.trim().isNotEmpty) headers['X-Netease-Cookie'] = cookie.trim();
    final response = await _dio.post<dynamic>(
      '${worker(base)}/netease/$action',
      data: body,
      options: Options(headers: headers, validateStatus: (s) => s != null && s < 500),
    );
    final raw = response.data;
    if ((response.statusCode ?? 0) < 200 || (response.statusCode ?? 0) >= 300) {
      final message = raw is Map ? raw['error'] ?? raw['message'] ?? raw['hint'] : null;
      throw Exception(message ?? 'HTTP ${response.statusCode}');
    }
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw Exception('音乐服务返回了无法识别的数据');
  }

  Future<List<MusicSong>> search(String base, String keyword, {String cookie = ''}) async {
    final r = await _eapiPost(
      path: '/api/cloudsearch/pc',
      endpoint: 'https://interface.music.163.com/eapi/cloudsearch/pc',
      payload: {
        's': keyword,
        'type': 1,
        'limit': 30,
        'offset': 0,
        'total': true,
      },
      cookie: cookie,
    );
    final result = r['result'] ?? r['data'] ?? {};
    final rows = result is Map ? result['songs'] : null;
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((e) => MusicSong.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id > 0)
        .toList();
  }

  static const _eapiKey = 'e82ckenh8dichen8';
  static const _songUrlEndpoint =
      'https://interface.music.163.com/eapi/song/enhance/player/url/v1';
  static const _songUrlPath = '/api/song/enhance/player/url/v1';

  String _encryptEapi(String path, Map<String, dynamic> payload) {
    final json = jsonEncode(payload);
    final digest = md5.convert(utf8.encode('nobody$path' + 'use$json' + 'md5forencrypt')).toString();
    final plain = '$path-36cd479b6b5-$digest-$json';
    final encrypter = encryption.Encrypter(encryption.AES(
      encryption.Key.fromUtf8(_eapiKey),
      mode: encryption.AESMode.ecb,
      padding: 'PKCS7',
    ));
    return encrypter.encrypt(plain).base16.toLowerCase();
  }

  Future<Map<String, dynamic>> _eapiPost({
    required String path,
    required String endpoint,
    required Map<String, dynamic> payload,
    String cookie = '',
  }) async {
    final params = _encryptEapi(path, payload);
    final headers = <String, dynamic>{
      'User-Agent': 'NeteaseMusic/8.10.05 (Linux; Android 14)',
      'Referer': 'https://music.163.com/',
      'Cookie': 'os=android; appver=8.10.05${cookie.trim().isEmpty ? '' : '; ${cookie.trim()}'}',
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final response = await _dio.post<dynamic>(
      endpoint,
      data: {'params': params},
      options: Options(
        headers: headers,
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 500,
      ),
    );
    final raw = response.data;
    if ((response.statusCode ?? 0) < 200 || (response.statusCode ?? 0) >= 300) {
      final message = raw is Map ? raw['message'] ?? raw['msg'] : null;
      throw Exception(message ?? '网易云接口 HTTP ${response.statusCode}');
    }
    if (raw is Map<String, dynamic>) {
      final cookies = response.headers.map['set-cookie'];
      if (cookies != null && cookies.isNotEmpty) {
        raw['cookie'] = cookies.map((value) => value.split(';').first).where((value) => value.contains('=')).join('; ');
      }
      return raw;
    }
    if (raw is Map) {
      final result = Map<String, dynamic>.from(raw);
      final cookies = response.headers.map['set-cookie'];
      if (cookies != null && cookies.isNotEmpty) {
        result['cookie'] = cookies.map((value) => value.split(';').first).where((value) => value.contains('=')).join('; ');
      }
      return result;
    }
    throw Exception('网易云接口返回了无法识别的数据');
  }

  Future<String> songUrl(String base, int id, {String cookie = '', String quality = 'exhigh'}) async {
    // Direct NetEase request: no user-hosted server and no third-party proxy.
    final session = cookie.trim().hashCode;
    final key = 'netease-direct|$id|$quality|$session';
    final cached = _songUrlCache[key];
    if (cached != null && DateTime.now().difference(cached['time'] as DateTime) < const Duration(minutes: 2)) {
      return cached['url'] as String;
    }

    final levels = <String>[quality, 'higher', 'standard'].toSet().toList();
    Object? lastError;
    for (final level in levels) {
      try {
        final params = _encryptEapi(_songUrlPath, {
          'ids': jsonEncode([id]),
          'level': level,
          'encodeType': 'flac',
          'immerseType': 'c51',
        });
        final headers = <String, dynamic>{
          'User-Agent': 'NeteaseMusic/8.10.05 (Linux; Android 14)',
          'Referer': 'https://music.163.com/',
          'Cookie': 'os=android; appver=8.10.05${cookie.trim().isEmpty ? '' : '; ${cookie.trim()}'}',
          'Content-Type': 'application/x-www-form-urlencoded',
        };
        final response = await _dio.post<dynamic>(
          _songUrlEndpoint,
          data: {'params': params},
          options: Options(
            headers: headers,
            contentType: Headers.formUrlEncodedContentType,
            responseType: ResponseType.json,
            validateStatus: (status) => status != null && status < 500,
          ),
        );
        final raw = response.data;
        if ((response.statusCode ?? 0) < 200 || (response.statusCode ?? 0) >= 300) {
          throw Exception('网易云直连接口 HTTP ${response.statusCode}');
        }
        final data = raw is Map ? raw['data'] : null;
        if (data is List && data.isNotEmpty && data.first is Map) {
          final row = data.first as Map;
          final url = (row['url'] ?? '').toString().trim();
          final parsed = Uri.tryParse(url);
          if (parsed != null && (parsed.scheme == 'https' || parsed.scheme == 'http') && parsed.host.isNotEmpty) {
            final normalized = url.replaceFirst(RegExp(r'^http:'), 'https:');
            _songUrlCache[key] = {'url': normalized, 'time': DateTime.now()};
            return normalized;
          }
          lastError = Exception((row['message'] ?? row['msg'] ?? '网易云没有返回可播放地址').toString());
          final code = raw is Map ? raw['code'] : null;
          if (code != null && code != 200) lastError = Exception('网易云返回状态码 $code');
        } else {
          lastError = Exception('网易云直连接口没有返回歌曲地址');
        }
      } catch (error) {
        lastError = error;
        if (error is DioException &&
            error.type != DioExceptionType.connectionTimeout &&
            error.type != DioExceptionType.receiveTimeout &&
            error.type != DioExceptionType.sendTimeout &&
            error.type != DioExceptionType.connectionError) {
          rethrow;
        }
      }
    }
    throw Exception('网易云直连获取音源失败：${lastError == null ? '没有可用音源' : prettyError(lastError)}。可能是版权、会员权限或接口风控限制。');
  }

  Future<Map<String, dynamic>> lyric(String base, int id, {String cookie = ''}) async {
    final key = 'netease-direct|$id|${cookie.trim().hashCode}';
    final cached = _lyricCache[key];
    if (cached != null && DateTime.now().difference(cached['time'] as DateTime) < const Duration(hours: 12)) {
      return Map<String, dynamic>.from(cached['value'] as Map);
    }
    final value = await _eapiPost(
      path: '/api/song/lyric/v1',
      endpoint: 'https://interface3.music.163.com/eapi/song/lyric/v1',
      payload: {
        'id': id,
        'cp': false,
        'tv': '0',
        'lv': '0',
        'rv': '0',
        'kv': '0',
        'yv': '0',
        'ytv': '0',
        'yrv': '0',
      },
      cookie: cookie,
    );
    _lyricCache[key] = {'value': value, 'time': DateTime.now()};
    return value;
  }

  Future<Map<String, dynamic>> qrKey(String base) => _eapiPost(
    path: '/api/login/qrcode/unikey',
    endpoint: 'https://interface.music.163.com/eapi/login/qrcode/unikey',
    payload: {'type': 3},
  );

  Future<Map<String, dynamic>> qrCheck(String base, String key) => _eapiPost(
    path: '/api/login/qrcode/client/login',
    endpoint: 'https://interface.music.163.com/eapi/login/qrcode/client/login',
    payload: {'key': key, 'type': 3},
  );
  Future<Map<String, dynamic>> loginStatus(String base, String cookie) => _eapiPost(
    path: '/api/nuser/account/get',
    endpoint: 'https://interface.music.163.com/eapi/nuser/account/get',
    payload: const {},
    cookie: cookie,
  );

  Future<List<MusicPlaylist>> playlists(String base, String cookie, int uid) async {
    final r = await _eapiPost(
      path: '/api/user/playlist',
      endpoint: 'https://interface.music.163.com/eapi/user/playlist',
      payload: {
        'uid': uid,
        'limit': 60,
        'offset': 0,
        'includeVideo': true,
      },
      cookie: cookie,
    );
    final rows = r['playlist'] ?? (r['data'] is Map ? r['data']['playlist'] : null);
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((e) => MusicPlaylist.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<MusicSong>> playlistSongs(String base, String cookie, int id) async {
    final r = await _eapiPost(
      path: '/api/v6/playlist/detail',
      endpoint: 'https://interface.music.163.com/eapi/v6/playlist/detail',
      payload: {
        'id': id,
        'n': 100,
        's': 8,
      },
      cookie: cookie,
    );
    final playlist = r['playlist'] ?? (r['data'] is Map ? r['data']['playlist'] : null);
    final rows = playlist is Map ? playlist['tracks'] : (r['songs'] ?? r['tracks']);
    if (rows is! List) return [];
    return rows
        .whereType<Map>()
        .map((e) => MusicSong.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.id > 0)
        .toList();
  }

  static String? extractMusicCookie(String raw) {
    final match = RegExp(r'(?:^|;\s*)MUSIC_U=([^;]+)', caseSensitive: false).firstMatch(raw.trim());
    if (match != null) return 'MUSIC_U=${match.group(1)}';
    final value = raw.trim();
    if (value.isNotEmpty && !value.contains('=') && value.length > 20) return 'MUSIC_U=$value';
    return null;
  }

  static String? qrKeyValue(Map<String, dynamic> r) {
    final d = r['data'];
    return (d is Map ? d['unikey'] : r['unikey'])?.toString();
  }
  static String? qrImage(Map<String, dynamic> r) {
    final d = r['data'];
    final value = (d is Map ? d['qrimg'] : r['qrimg'])?.toString();
    if (value == null || value.isEmpty) return null;
    return value.contains(',') ? value.substring(value.indexOf(',') + 1) : value;
  }
  static int? qrCode(Map<String, dynamic> r) => (r['code'] as num?)?.toInt();
  static int? userId(Map<String, dynamic> r) {
    final d = r['data'];
    final account = d is Map ? d['account'] : null;
    final profile = d is Map ? d['profile'] : null;
    final id = account is Map ? account['id'] : (profile is Map ? profile['userId'] : null);
    return (id as num?)?.toInt();
  }
  static String prettyError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final message = data['message'] ?? data['msg'] ?? data['error'];
        if (message != null && message.toString().trim().isNotEmpty) {
          return message.toString();
        }
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return '音乐服务连接超时，请稍后重试';
      }
      if (error.type == DioExceptionType.connectionError) {
        return '无法连接音乐服务，请检查网络或代理地址';
      }
      return error.message ?? '音乐服务请求失败';
    }
    return error.toString().replaceFirst(RegExp(r'^Exception: ?'), '');
  }

  static String? lyricText(Map<String, dynamic> r) => (r['lrc'] is Map ? r['lrc']['lyric'] : null)?.toString();
}
