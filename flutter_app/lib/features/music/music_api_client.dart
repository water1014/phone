import 'package:dio/dio.dart';

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
    final r = await call(base, 'search', cookie: cookie, body: {'keyword': keyword, 'limit': 30, 'offset': 0, 'type': 1});
    final result = r['result'] ?? r['data'] ?? {};
    final rows = result is Map ? result['songs'] : null;
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => MusicSong.fromJson(Map<String, dynamic>.from(e))).where((e) => e.id > 0).toList();
  }

  Future<String> songUrl(String base, int id, {String cookie = '', String quality = 'exhigh'}) async {
    final r = await call(base, 'song/url', cookie: cookie, body: {'ids': [id], 'level': quality});
    final rows = r['data'];
    if (rows is List && rows.isNotEmpty && rows.first is Map) {
      final url = (rows.first['url'] ?? '').toString();
      if (url.isNotEmpty) return url.replaceFirst(RegExp(r'^http:'), 'https:');
    }
    throw Exception('暂无可用播放地址，可能受版权或会员权限限制');
  }

  Future<Map<String, dynamic>> lyric(String base, int id, {String cookie = ''}) =>
      call(base, 'lyric', cookie: cookie, body: {'id': id});

  Future<Map<String, dynamic>> qrKey(String base) => call(base, 'login/qr/key');
  Future<Map<String, dynamic>> qrCreate(String base, String key) => call(base, 'login/qr/create', body: {'key': key, 'qrimg': true});
  Future<Map<String, dynamic>> qrCheck(String base, String key) => call(base, 'login/qr/check', body: {'key': key});
  Future<Map<String, dynamic>> loginStatus(String base, String cookie) => call(base, 'login/status', cookie: cookie);

  Future<List<MusicPlaylist>> playlists(String base, String cookie, int uid) async {
    final r = await call(base, 'user/playlist', cookie: cookie, body: {'uid': uid, 'limit': 60});
    final rows = r['playlist'] ?? (r['data'] is Map ? r['data']['playlist'] : null);
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => MusicPlaylist.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  Future<List<MusicSong>> playlistSongs(String base, String cookie, int id) async {
    final r = await call(base, 'playlist/track/all', cookie: cookie, body: {'id': id, 'limit': 100, 'offset': 0});
    final rows = r['songs'] ?? (r['data'] is Map ? r['data']['songs'] : null);
    if (rows is! List) return [];
    return rows.whereType<Map>().map((e) => MusicSong.fromJson(Map<String, dynamic>.from(e))).where((e) => e.id > 0).toList();
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
