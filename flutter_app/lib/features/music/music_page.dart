import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:just_audio/just_audio.dart';

const _ink = Color(0xFF202020);
const _muted = Color(0xFF888888);
const _line = Color(0xFFE7E7E7);
const _soft = Color(0xFFF3F3F3);
const _cookieKey = 'netease_music_cookie';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  static const _storage = FlutterSecureStorage();
  final _cookieController = TextEditingController();
  final _searchController = TextEditingController();
  final _player = AudioPlayer();
  Dio? _api;
  bool _busy = false;
  bool _loadingPlaylists = false;
  bool _searching = false;
  bool _showCookie = false;
  bool _hasCookie = false;
  bool _verified = false;
  String? _accountName;
  String? _message;
  String? _musicMessage;
  int? _userId;
  List<_Playlist> _playlists = [];
  List<_Song> _songs = [];
  _Song? _currentSong;
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _restoreLogin();
  }

  @override
  void dispose() {
    _cookieController.dispose();
    _searchController.dispose();
    _player.dispose();
    super.dispose();
  }

  Dio _client(String cookie) => Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    sendTimeout: const Duration(seconds: 15),
    headers: {
      'Cookie': cookie,
      'Referer': 'https://music.163.com/',
      'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36',
    },
    responseType: ResponseType.json,
    validateStatus: (status) => status != null && status < 500,
  ));

  Future<dynamic> _get(String path, [Map<String, dynamic>? query]) async {
    final api = _api;
    if (api == null) throw StateError('请先连接网易云账号');
    final response = await api.get<dynamic>(path, queryParameters: query);
    final data = response.data;
    if (data is! Map || (data['code'] != 200 && data['code'] != 0)) {
      throw FormatException(data is Map ? '网易云接口返回：${data['message'] ?? data['msg'] ?? data['code']}' : '网易云返回了无法识别的数据');
    }
    return data;
  }

  Future<void> _restoreLogin() async {
    try {
      final cookie = await _storage.read(key: _cookieKey);
      if (!mounted || cookie == null || cookie.trim().isEmpty) return;
      setState(() {
        _hasCookie = true;
        _message = '已保存登录凭据，正在检查登录状态…';
      });
      await _verifyCookie(cookie, save: false);
    } catch (_) {
      if (mounted) setState(() => _message = '读取本地登录状态失败');
    }
  }

  Future<void> _pasteCookie() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final value = data?.text?.trim();
    if (value == null || value.isEmpty) {
      if (mounted) setState(() => _message = '剪贴板里没有 Cookie');
      return;
    }
    _cookieController.text = value;
    if (mounted) setState(() => _message = '已粘贴，请确认内容后验证登录');
  }

  Future<void> _login() async {
    final cookie = _cookieController.text.trim();
    if (cookie.isEmpty) {
      setState(() => _message = '请先粘贴网易云音乐 Cookie');
      return;
    }
    await _verifyCookie(cookie, save: true);
  }

  Future<void> _verifyCookie(String cookie, {required bool save}) async {
    setState(() {
      _busy = true;
      _message = '正在安全验证网易云账号…';
      _verified = false;
      _accountName = null;
    });
    try {
      final client = _client(cookie);
      final response = await client.get<dynamic>('https://music.163.com/api/nuser/account/get');
      final body = response.data;
      if (body is! Map) throw const FormatException('网易云返回了无法识别的数据');
      final profile = body['profile'];
      final account = body['account'];
      final nickname = profile is Map ? profile['nickname'] : null;
      final userId = account is Map ? int.tryParse('${account['id']}') : null;
      if (body['code'] != 200 || (nickname == null && userId == null)) {
        throw const FormatException('登录验证未通过，Cookie 可能已过期或权限不足');
      }
      if (save) await _storage.write(key: _cookieKey, value: cookie);
      _api = client;
      if (!mounted) return;
      setState(() {
        _hasCookie = true;
        _verified = true;
        _userId = userId;
        _accountName = nickname?.toString() ?? '网易云音乐用户';
        _message = save ? '登录成功，Cookie 已加密保存在本机' : '登录状态有效';
        _cookieController.clear();
      });
      await _loadPlaylists();
    } on DioException catch (error) {
      if (!mounted) return;
      final status = error.response?.statusCode;
      setState(() => _message = status == null
          ? '连接网易云失败，请检查网络后重试'
          : '网易云暂时无法验证（HTTP $status），可以稍后再试');
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error is FormatException ? error.message : '验证失败，请检查 Cookie 是否完整');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loadPlaylists() async {
    final uid = _userId;
    if (uid == null) {
      if (mounted) setState(() => _musicMessage = '账号未返回用户编号，暂时无法读取歌单');
      return;
    }
    setState(() {
      _loadingPlaylists = true;
      _musicMessage = null;
    });
    try {
      final data = await _get('/api/user/playlist', {'uid': uid, 'limit': 30, 'offset': 0});
      final raw = data['playlist'];
      final items = raw is List ? raw : const [];
      final playlists = items.whereType<Map>().map(_Playlist.fromJson).toList();
      if (!mounted) return;
      setState(() {
        _playlists = playlists;
        _musicMessage = playlists.isEmpty ? '暂时没有读取到歌单' : null;
      });
    } catch (error) {
      if (mounted) setState(() => _musicMessage = '歌单读取失败：${_friendlyError(error)}');
    } finally {
      if (mounted) setState(() => _loadingPlaylists = false);
    }
  }

  Future<void> _openPlaylist(_Playlist playlist) async {
    setState(() {
      _loadingPlaylists = true;
      _musicMessage = '正在读取「${playlist.name}」…';
      _songs = [];
    });
    try {
      final data = await _get('/api/playlist/track/all', {'id': playlist.id, 'limit': 100, 'offset': 0});
      final raw = data['songs'];
      final songs = raw is List ? raw.whereType<Map>().map(_Song.fromJson).toList() : <_Song>[];
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _musicMessage = songs.isEmpty ? '这个歌单暂时没有可显示的歌曲' : null;
      });
    } catch (error) {
      if (mounted) setState(() => _musicMessage = '歌单打开失败：${_friendlyError(error)}');
    } finally {
      if (mounted) setState(() => _loadingPlaylists = false);
    }
  }

  Future<void> _search() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;
    setState(() {
      _searching = true;
      _showSearch = true;
      _musicMessage = null;
      _songs = [];
    });
    try {
      final data = await _get('/api/search/get', {'s': keyword, 'type': 1, 'limit': 30, 'offset': 0});
      final result = data['result'];
      final raw = result is Map ? result['songs'] : null;
      final songs = raw is List ? raw.whereType<Map>().map(_Song.fromJson).toList() : <_Song>[];
      if (!mounted) return;
      setState(() {
        _songs = songs;
        _musicMessage = songs.isEmpty ? '没有找到相关歌曲' : null;
      });
    } catch (error) {
      if (mounted) setState(() => _musicMessage = '搜索失败：${_friendlyError(error)}');
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _play(_Song song) async {
    setState(() {
      _currentSong = song;
      _musicMessage = '正在获取播放地址…';
    });
    try {
      final data = await _get('/api/song/enhance/player/url/v1', {'id': song.id, 'level': 'standard'});
      final raw = data['data'];
      final item = raw is List && raw.isNotEmpty ? raw.first : null;
      final url = item is Map ? item['url']?.toString() : null;
      if (url == null || url.isEmpty) throw const FormatException('歌曲暂时没有可用播放地址');
      await _player.setUrl(url);
      await _player.play();
      if (mounted) setState(() => _musicMessage = null);
    } catch (error) {
      if (mounted) setState(() => _musicMessage = '播放失败：${_friendlyError(error)}');
    }
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      return status == null ? '网络连接失败' : '接口暂不可用（HTTP $status）';
    }
    return error is FormatException ? error.message : '接口异常，请稍后重试';
  }

  Future<void> _logout() async {
    await _storage.delete(key: _cookieKey);
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _api = null;
      _hasCookie = false;
      _verified = false;
      _accountName = null;
      _userId = null;
      _playlists = [];
      _songs = [];
      _currentSong = null;
      _message = '已退出网易云音乐登录';
      _musicMessage = null;
      _cookieController.clear();
    });
  }

  Widget _sectionTitle(String title, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.fromLTRB(2, 22, 2, 11),
    child: Row(children: [
      Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink))),
      if (trailing != null) trailing,
    ]),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAFAFA),
    body: SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(13, 8, 20, 17),
          child: Row(children: [
            IconButton(
              tooltip: '返回',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.chevron_left_rounded, size: 29, color: _ink),
            ),
            const SizedBox(width: 5),
            const Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('MUSIC SPACE', style: TextStyle(fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w600, color: _muted)),
                SizedBox(height: 4),
                Text('一起听', style: TextStyle(fontSize: 22, height: 1.1, fontWeight: FontWeight.w600, color: _ink)),
                SizedBox(height: 4),
                Text('把喜欢的歌放在一起', style: TextStyle(fontSize: 11, color: _muted)),
              ],
            )),
          ]),
        ),
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 26),
          children: [
            _accountCard(),
            if (_verified) ...[
              _sectionTitle('搜索歌曲'),
              Row(children: [
                Expanded(child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                  decoration: InputDecoration(
                    hintText: '歌名、歌手或专辑',
                    prefixIcon: const Icon(Icons.search_rounded, size: 19, color: _muted),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
                  ),
                )),
                const SizedBox(width: 8),
                SizedBox(height: 48, child: FilledButton(
                  onPressed: _searching ? null : _search,
                  style: FilledButton.styleFrom(backgroundColor: _ink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                  child: _searching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('搜索'),
                )),
              ]),
              _sectionTitle(_showSearch ? '搜索结果' : '我的歌单', trailing: TextButton.icon(
                onPressed: _showSearch ? () => setState(() { _showSearch = false; _songs = []; }) : _loadPlaylists,
                icon: Icon(_showSearch ? Icons.arrow_back_rounded : Icons.refresh_rounded, size: 14),
                label: Text(_showSearch ? '返回歌单' : '刷新'),
                style: TextButton.styleFrom(foregroundColor: _muted, textStyle: const TextStyle(fontSize: 10)),
              )),
              if (_showSearch) ..._songList() else ..._playlistList(),
              if (_songs.isNotEmpty && !_showSearch) ...[
                _sectionTitle('歌单歌曲'),
                ..._songList(),
              ],
              if (_musicMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Text(_musicMessage!, style: const TextStyle(fontSize: 11, color: _muted)),
                ),
              if (_playlists.isEmpty && !_loadingPlaylists && !_showSearch)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text('连接成功后，你的歌单会显示在这里。', style: TextStyle(fontSize: 11, color: _muted)),
                ),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(16)),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.shield_outlined, size: 16, color: _muted),
                SizedBox(width: 9),
                Expanded(child: Text(
                  '安全提醒：Cookie 等同于登录凭据，仅保存在本机安全存储中，不会发送给宋祁的聊天模型。网易云接口可能调整或触发风控，部分歌曲也可能受版权和地区限制。',
                  style: TextStyle(fontSize: 10, height: 1.6, color: _muted),
                )),
              ]),
            ),
          ],
        )),
        if (_currentSong != null) _miniPlayer(),
      ]),
    ),
  );

  Widget _accountCard() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: _line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          width: 43, height: 43,
          decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.music_note_rounded, color: _ink, size: 23),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('网易云音乐', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _ink)),
          SizedBox(height: 3),
          Text('Cookie 安全连接', style: TextStyle(fontSize: 10, color: _muted)),
        ])),
        if (_verified) const _StatusPill(label: '已连接', good: true)
        else if (_hasCookie) const _StatusPill(label: '待验证', good: false),
      ]),
      const SizedBox(height: 17),
      if (_verified) ...[
        Text(_accountName ?? '网易云音乐用户', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
        const SizedBox(height: 5),
        const Text('账号已连接，可以读取歌单并搜索歌曲。', style: TextStyle(fontSize: 11, height: 1.6, color: _muted)),
        const SizedBox(height: 13),
        OutlinedButton(
          onPressed: _busy ? null : _logout,
          style: OutlinedButton.styleFrom(foregroundColor: _muted, side: const BorderSide(color: _line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
          child: const Text('退出登录'),
        ),
      ] else ...[
        const Text('粘贴从网易云音乐登录后获取的 Cookie。验证成功后会加密保存在本机，不会进入聊天记录。', style: TextStyle(fontSize: 11, height: 1.65, color: _muted)),
        const SizedBox(height: 13),
        TextField(
          controller: _cookieController,
          obscureText: !_showCookie,
          maxLines: _showCookie ? 3 : 1,
          minLines: 1,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(
            hintText: 'MUSIC_U=…; __csrf=…',
            hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _ink)),
            suffixIcon: IconButton(
              tooltip: _showCookie ? '隐藏 Cookie' : '显示 Cookie',
              onPressed: () => setState(() => _showCookie = !_showCookie),
              icon: Icon(_showCookie ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: _muted),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: OutlinedButton.icon(
            onPressed: _busy ? null : _pasteCookie,
            icon: const Icon(Icons.content_paste_rounded, size: 15),
            label: const Text('粘贴 Cookie'),
            style: OutlinedButton.styleFrom(foregroundColor: _ink, side: const BorderSide(color: _line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
          )),
          const SizedBox(width: 9),
          Expanded(child: FilledButton(
            onPressed: _busy ? null : _login,
            style: FilledButton.styleFrom(backgroundColor: _ink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
            child: _busy
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('验证并登录'),
          )),
        ]),
      ],
      if (_message != null) ...[
        const SizedBox(height: 13),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(12)),
          child: Text(_message!, style: const TextStyle(fontSize: 10, height: 1.5, color: _muted)),
        ),
      ],
    ]),
  );

  List<Widget> _playlistList() => _playlists.map((playlist) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: InkWell(
      onTap: _loadingPlaylists ? null : () => _openPlaylist(playlist),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: _line)),
        child: Row(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: playlist.cover.isEmpty
                ? Container(width: 48, height: 48, color: _soft, child: const Icon(Icons.album_outlined, color: _muted))
                : Image.network(playlist.cover, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: _soft, child: const Icon(Icons.album_outlined, color: _muted))),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink)),
            const SizedBox(height: 4),
            Text('${playlist.trackCount} 首歌曲', style: const TextStyle(fontSize: 10, color: _muted)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: _muted, size: 20),
        ]),
      ),
    ),
  )).toList();

  List<Widget> _songList() => _songs.map((song) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 5),
      leading: Container(
        width: 38, height: 38,
        decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.music_note_rounded, size: 18, color: _muted),
      ),
      title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _ink, fontWeight: FontWeight.w500)),
      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _muted)),
      trailing: IconButton(
        tooltip: '播放',
        onPressed: () => _play(song),
        icon: Icon(_currentSong?.id == song.id ? Icons.equalizer_rounded : Icons.play_circle_outline_rounded, color: _ink),
      ),
      onTap: () => _play(song),
    ),
  )).toList();

  Widget _miniPlayer() => StreamBuilder<PlayerState>(
    stream: _player.playerStateStream,
    builder: (context, snapshot) {
      final playing = snapshot.data?.playing ?? false;
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 9, 16, 10),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: _line))),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.album_rounded, color: _ink)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_currentSong!.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _ink)),
            Text(_currentSong!.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 9, color: _muted)),
          ])),
          IconButton(
            onPressed: () => playing ? _player.pause() : _player.play(),
            icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: _ink, size: 27),
          ),
          IconButton(onPressed: () => _player.stop(), icon: const Icon(Icons.stop_rounded, color: _muted, size: 22)),
        ]),
      );
    },
  );
}

class _Playlist {
  const _Playlist({required this.id, required this.name, required this.cover, required this.trackCount});
  final int id;
  final String name;
  final String cover;
  final int trackCount;

  factory _Playlist.fromJson(Map json) => _Playlist(
    id: int.tryParse('${json['id']}') ?? 0,
    name: json['name']?.toString() ?? '未命名歌单',
    cover: json['coverImgUrl']?.toString() ?? '',
    trackCount: int.tryParse('${json['trackCount']}') ?? 0,
  );
}

class _Song {
  const _Song({required this.id, required this.name, required this.artist});
  final int id;
  final String name;
  final String artist;

  factory _Song.fromJson(Map json) {
    final artists = json['ar'] ?? json['artists'];
    final artist = artists is List
        ? artists.whereType<Map>().map((item) => item['name']?.toString() ?? '').where((name) => name.isNotEmpty).join(' / ')
        : '';
    return _Song(
      id: int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '未知歌曲',
      artist: artist.isEmpty ? '未知歌手' : artist,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.good});
  final String label;
  final bool good;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
    decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 10, color: good ? _ink : _muted, fontWeight: FontWeight.w600)),
  );
}
