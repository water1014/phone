import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'music_api_client.dart';

const _ink = Color(0xFF202020);
const _muted = Color(0xFF888888);
const _line = Color(0xFFE7E7E7);
const _paper = Color(0xFFFAFAFA);

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});
  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  static const _secure = FlutterSecureStorage();
  static final AudioPlayer _audio = AudioPlayer();
  static const _cookieKey = 'phone.music.netease.cookie';
  static const _workerKey = 'phone.music.worker';
  final _api = MusicApiClient();
  final _searchController = TextEditingController();
  final _workerController = TextEditingController();

  String _worker = MusicApiClient.defaultWorker;
  String _cookie = '';
  String _accountName = '';
  String _message = '';
  bool _busy = false;
  bool _loggedIn = false;
  int? _uid;
  int _tab = 0;
  List<MusicSong> _results = [];
  List<MusicSong> _queue = [];
  List<MusicPlaylist> _playlists = [];
  MusicSong? _current;
  List<Map<String, dynamic>> _lyrics = [];
  StreamSubscription<PlayerState>? _playerSubscription;

  @override
  void initState() {
    super.initState();
    _playerSubscription = _audio.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed && mounted) _next();
    });
    _restore();
  }

  @override
  void dispose() {
    _playerSubscription?.cancel();
    _searchController.dispose();
    _workerController.dispose();
    super.dispose();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final worker = prefs.getString(_workerKey) ?? MusicApiClient.defaultWorker;
    final cookie = await _secure.read(key: _cookieKey) ?? '';
    if (!mounted) return;
    setState(() {
      _worker = _api.worker(worker);
      _workerController.text = _worker;
      _cookie = cookie;
    });
    if (cookie.isNotEmpty) await _loadAccount(showError: false);
  }

  Future<void> _saveWorker(String value) async {
    final normalized = _api.worker(value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_workerKey, normalized);
    if (!mounted) return;
    setState(() {
      _worker = normalized;
      _workerController.text = normalized;
    });
    if (_cookie.isNotEmpty) await _loadAccount(showError: false);
    _toast('音乐服务地址已保存');
  }

  Future<void> _loadAccount({bool showError = true}) async {
    if (_cookie.isEmpty) return;
    try {
      final status = await _api.loginStatus(_worker, _cookie);
      final uid = MusicApiClient.userId(status);
      final data = status['data'];
      final profile = data is Map ? data['profile'] : null;
      final nickname = profile is Map ? (profile['nickname'] ?? '').toString() : '';
      if (uid == null) throw Exception('登录状态未通过验证，请重新扫码');
      final playlists = await _api.playlists(_worker, _cookie, uid);
      if (!mounted) return;
      setState(() {
        _loggedIn = true;
        _uid = uid;
        _accountName = nickname;
        _playlists = playlists;
        _message = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loggedIn = false;
        _uid = null;
        _playlists = [];
        _message = showError ? MusicApiClient.prettyError(e) : '';
      });
    }
  }

  Future<void> _showLogin() async {
    final manualController = TextEditingController();
    String? qrImage;
    String? qrKey;
    String status = '正在生成二维码…';
    bool checking = false;
    Timer? timer;
    var finished = false;

    try {
      final keyResponse = await _api.qrKey(_worker);
      qrKey = MusicApiClient.qrKeyValue(keyResponse);
      if (qrKey == null || qrKey!.isEmpty) throw Exception('无法获取登录二维码');
      final imageResponse = await _api.qrCreate(_worker, qrKey!);
      final image = MusicApiClient.qrImage(imageResponse);
      if (image == null) throw Exception('二维码生成失败');
      qrImage = image;
    } catch (e) {
      status = MusicApiClient.prettyError(e);
    }

    if (!mounted) {
      manualController.dispose();
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, refresh) {
          Future<void> poll() async {
            if (checking || finished || qrKey == null) return;
            checking = true;
            try {
              final response = await _api.qrCheck(_worker, qrKey!);
              final code = MusicApiClient.qrCode(response);
              if (code == 800) {
                status = '二维码已过期，请关闭后重新打开';
              } else if (code == 801) {
                status = '请使用网易云音乐 App 扫描二维码';
              } else if (code == 802) {
                status = '已扫描，请在网易云音乐 App 中确认登录';
              } else if (code == 803) {
                final cookie = MusicApiClient.extractMusicCookie((response['cookie'] ?? '').toString());
                if (cookie == null) {
                  status = '登录完成，但没有取得登录凭据，请改用 Cookie 登录';
                } else {
                  finished = true;
                  timer?.cancel();
                  await _secure.write(key: _cookieKey, value: cookie);
                  if (mounted) setState(() => _cookie = cookie);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  await _loadAccount();
                  _toast('网易云已登录');
                }
              }
              refresh(() {});
            } catch (e) {
              status = MusicApiClient.prettyError(e);
              refresh(() {});
            } finally {
              checking = false;
            }
          }

          timer ??= Timer.periodic(const Duration(milliseconds: 2500), (_) => poll());
          return AlertDialog(
            backgroundColor: _paper,
            surfaceTintColor: Colors.transparent,
            title: const Text('连接网易云音乐', style: TextStyle(color: _ink, fontSize: 17, fontWeight: FontWeight.w600)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (qrImage != null)
                    Container(
                      width: 190,
                      height: 190,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(16)),
                      child: Image.memory(
                        base64Decode(qrImage!.replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), '')),
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Center(child: Text('二维码无法显示')),
                      ),
                    )
                  else
                    const Icon(Icons.qr_code_2_rounded, size: 90, color: _muted),
                  const SizedBox(height: 10),
                  Text(status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.5, color: _muted)),
                  const SizedBox(height: 18),
                  const Divider(color: _line),
                  const Align(alignment: Alignment.centerLeft, child: Text('也可以粘贴 MUSIC_U Cookie', style: TextStyle(fontSize: 12, color: _ink, fontWeight: FontWeight.w600))),
                  const SizedBox(height: 8),
                  TextField(
                    controller: manualController,
                    minLines: 1,
                    maxLines: 3,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'MUSIC_U=…',
                      hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _line)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('取消', style: TextStyle(color: _muted))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _ink, foregroundColor: Colors.white),
                onPressed: () async {
                  final cookie = MusicApiClient.extractMusicCookie(manualController.text);
                  if (cookie == null) {
                    refresh(() => status = '没有识别到 MUSIC_U，请粘贴完整 Cookie');
                    return;
                  }
                  finished = true;
                  timer?.cancel();
                  await _secure.write(key: _cookieKey, value: cookie);
                  if (mounted) setState(() => _cookie = cookie);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  await _loadAccount();
                  _toast('网易云登录凭据已安全保存');
                },
                child: const Text('保存并验证'),
              ),
            ],
          );
        },
      ),
    );
    timer?.cancel();
    manualController.dispose();
  }

  Future<void> _search() async {
    final keyword = _searchController.text.trim();
    if (keyword.isEmpty) return;
    setState(() {
      _busy = true;
      _message = '';
      _tab = 0;
    });
    try {
      final songs = await _api.search(_worker, keyword, cookie: _cookie);
      if (!mounted) return;
      setState(() {
        _results = songs;
        _message = songs.isEmpty ? '没有找到相关歌曲' : '';
      });
    } catch (e) {
      if (mounted) setState(() => _message = MusicApiClient.prettyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _play(MusicSong song, {List<MusicSong>? source}) async {
    setState(() {
      _busy = true;
      _current = song;
      if (source != null) _queue = source;
      if (!_queue.any((item) => item.id == song.id)) _queue = [..._queue, song];
    });
    try {
      final url = await _api.songUrl(_worker, song.id, cookie: _cookie);
      final lyricResponse = await _api.lyric(_worker, song.id, cookie: _cookie).catchError((_) => <String, dynamic>{});
      final lyricRaw = MusicApiClient.lyricText(lyricResponse) ?? '';
      if (mounted) setState(() => _lyrics = _parseLyrics(lyricRaw));
      await _audio.setUrl(url);
      await _audio.play();
    } catch (e) {
      _toast(MusicApiClient.prettyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Map<String, dynamic>> _parseLyrics(String raw) {
    final lines = <Map<String, dynamic>>[];
    final pattern = RegExp(r'^\\[(\\d+):(\\d+(?:\\.\\d+)?)\\](.*)
    setState(() => _busy = true);
    try {
      final songs = await _api.playlistSongs(_worker, _cookie, playlist.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: _paper,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (context) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .76,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  child: Row(children: [
                    Expanded(child: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink))),
                    Text('${songs.length} 首', style: const TextStyle(fontSize: 11, color: _muted)),
                  ]),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (_, index) => _songTile(songs[index], index + 1, onTap: () => _play(songs[index], source: songs)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _toast(MusicApiClient.prettyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _songTile(MusicSong song, int index, {VoidCallback? onTap}) => ListTile(
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
    leading: SizedBox(
      width: 26,
      child: Center(child: Text(index.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 10, color: _muted, fontFeatures: []))),
    ),
    title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: _current?.id == song.id ? _ink : const Color(0xFF333333), fontWeight: _current?.id == song.id ? FontWeight.w600 : FontWeight.w400)),
    subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _muted)),
    trailing: Icon(_current?.id == song.id ? Icons.equalizer_rounded : Icons.play_arrow_rounded, color: _current?.id == song.id ? _ink : _muted, size: 19),
    onTap: onTap ?? () => _play(song, source: _results),
  );

  Widget _content() {
    if (_tab == 1) {
      if (!_loggedIn) return _empty('登录后查看自己的网易云歌单', Icons.library_music_outlined);
      if (_playlists.isEmpty) return _empty('暂时没有读取到歌单', Icons.queue_music_rounded);
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        itemCount: _playlists.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: _line, indent: 66),
        itemBuilder: (_, i) {
          final p = _playlists[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: p.cover.isEmpty
                  ? Container(width: 48, height: 48, color: const Color(0xFFEDEDED), child: const Icon(Icons.music_note_rounded, color: _muted))
                  : Image.network(p.cover, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: const Color(0xFFEDEDED), child: const Icon(Icons.music_note_rounded, color: _muted))),
            ),
            title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _ink, fontWeight: FontWeight.w500)),
            subtitle: Text('${p.trackCount} 首', style: const TextStyle(fontSize: 10, color: _muted)),
            trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
            onTap: () => _openPlaylist(p),
          );
        },
      );
    }
    if (_tab == 2) {
      if (_queue.isEmpty) return _empty('搜索歌曲或打开歌单，把喜欢的歌加入播放队列', Icons.queue_music_rounded);
      return ListView.builder(
        padding: const EdgeInsets.only(top: 6, bottom: 12),
        itemCount: _queue.length,
        itemBuilder: (_, i) => _songTile(_queue[i], i + 1, onTap: () => _play(_queue[i], source: _queue)),
      );
    }
    if (_results.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 6, bottom: 12),
        itemCount: _results.length,
        itemBuilder: (_, i) => _songTile(_results[i], i + 1, onTap: () => _play(_results[i], source: _results)),
      );
    }
    if (_message.isNotEmpty) return _empty(_message, Icons.info_outline_rounded);
    return _empty('搜索一首想听的歌，或者登录网易云读取你的歌单', Icons.headphones_rounded);
  }

  Widget _empty(String text, IconData icon) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 34, color: const Color(0xFFB5B5B5)),
        const SizedBox(height: 13),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.7, color: _muted)),
      ]),
    ),
  );

  Widget _miniPlayer() {
    final song = _current!;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: _showPlayer,
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 9, 12, 9),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: _line))),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.cover.isEmpty
                  ? Container(width: 39, height: 39, color: const Color(0xFFEDEDED), child: const Icon(Icons.music_note_rounded, color: _muted))
                  : Image.network(song.cover, width: 39, height: 39, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 39, height: 39, color: const Color(0xFFEDEDED), child: const Icon(Icons.music_note_rounded, color: _muted))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _ink, fontWeight: FontWeight.w600)),
              Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _muted)),
            ])),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                if (_audio.playing) {
                  await _audio.pause();
                } else {
                  await _audio.play();
                }
                if (mounted) setState(() {});
              },
              icon: StreamBuilder<PlayerState>(
                stream: _audio.playerStateStream,
                builder: (_, snapshot) => Icon(snapshot.data?.playing == true ? Icons.pause_rounded : Icons.play_arrow_rounded, color: _ink, size: 25),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: _next,
              icon: const Icon(Icons.skip_next_rounded, color: _ink, size: 24),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _next() async {
    if (_queue.isEmpty || _current == null) return;
    final index = _queue.indexWhere((s) => s.id == _current!.id);
    final next = _queue[(index + 1) % _queue.length];
    await _play(next, source: _queue);
  }

  Future<void> _showPlayer() async {
    if (_current == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (context, refresh) {
        final song = _current!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 34, height: 4, decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(9))),
              const SizedBox(height: 25),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: song.cover.isEmpty
                    ? Container(width: 210, height: 210, color: const Color(0xFFEDEDED), child: const Icon(Icons.album_rounded, size: 80, color: _muted))
                    : Image.network(song.cover, width: 210, height: 210, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 210, height: 210, color: const Color(0xFFEDEDED), child: const Icon(Icons.album_rounded, size: 80, color: _muted))),
              ),
              const SizedBox(height: 22),
              Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink)),
              const SizedBox(height: 5),
              Text(song.artist, style: const TextStyle(fontSize: 12, color: _muted)),
              const SizedBox(height: 25),
              StreamBuilder<Duration>(
                stream: _audio.positionStream,
                builder: (_, snap) {
                  final position = snap.data ?? Duration.zero;
                  final duration = _audio.duration ?? Duration.zero;
                  final max = duration.inMilliseconds.toDouble().clamp(1.0, double.infinity).toDouble();
                  return Column(children: [
                    Slider(
                      value: position.inMilliseconds.toDouble().clamp(0.0, max).toDouble(),
                      max: max,
                      activeColor: _ink,
                      inactiveColor: _line,
                      onChanged: (v) => _audio.seek(Duration(milliseconds: v.toInt())),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(_time(position), style: const TextStyle(fontSize: 10, color: _muted)),
                      Text(_time(duration), style: const TextStyle(fontSize: 10, color: _muted)),
                    ]),
                  ]);
                },
              ),
              const SizedBox(height: 14),
              Container(
                height: 150,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: _line)),
                child: _lyrics.isEmpty
                    ? const Center(child: Text('暂无歌词', style: TextStyle(fontSize: 11, color: _muted)))
                    : StreamBuilder<Duration>(
                        stream: _audio.positionStream,
                        builder: (_, snapshot) {
                          final now = (snapshot.data ?? Duration.zero).inMilliseconds / 1000;
                          var active = _lyrics.lastIndexWhere((line) => (line['time'] as double) <= now);
                          if (active < 0) active = 0;
                          return ListView.builder(
                            itemCount: _lyrics.length,
                            itemBuilder: (_, index) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Text(
                                _lyrics[index]['text'] as String,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: index == active ? 12 : 10, height: 1.35, color: index == active ? _ink : const Color(0xFFAAAAAA), fontWeight: index == active ? FontWeight.w600 : FontWeight.w400),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 15),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(onPressed: _previous, icon: const Icon(Icons.skip_previous_rounded, size: 34, color: _ink)),
                const SizedBox(width: 18),
                StreamBuilder<PlayerState>(
                  stream: _audio.playerStateStream,
                  builder: (_, snap) => IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: _ink, foregroundColor: Colors.white, fixedSize: const Size(58, 58)),
                    onPressed: () async {
                      if (snap.data?.playing == true) {
                        await _audio.pause();
                      } else {
                        await _audio.play();
                      }
                      refresh(() {});
                    },
                    icon: Icon(snap.data?.playing == true ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
                  ),
                ),
                const SizedBox(width: 18),
                IconButton(onPressed: _next, icon: const Icon(Icons.skip_next_rounded, size: 34, color: _ink)),
              ]),
            ]),
          ),
        );
      }),
    );
  }

  Future<void> _previous() async {
    if (_queue.isEmpty || _current == null) return;
    final index = _queue.indexWhere((s) => s.id == _current!.id);
    final previous = _queue[(index - 1 + _queue.length) % _queue.length];
    await _play(previous, source: _queue);
  }

  String _time(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _showSettings() async {
    _workerController.text = _worker;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('音乐连接设置', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink)),
            const SizedBox(height: 7),
            const Text('默认使用糯米机音乐模块的公共代理，无需你部署服务器。也可以填写自己的兼容 Worker 地址。', style: TextStyle(fontSize: 11, height: 1.6, color: _muted)),
            const SizedBox(height: 14),
            TextField(
              controller: _workerController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: MusicApiClient.defaultWorker,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _line)),
              ),
            ),
            const SizedBox(height: 13),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('取消'))),
              const SizedBox(width: 9),
              Expanded(child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _ink, foregroundColor: Colors.white),
                onPressed: () async {
                  await _saveWorker(_workerController.text);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('保存地址'),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await _secure.delete(key: _cookieKey);
    if (!mounted) return;
    setState(() {
      _cookie = '';
      _loggedIn = false;
      _uid = null;
      _accountName = '';
      _playlists = [];
    });
    _toast('已退出网易云账号');
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(
      backgroundColor: _paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.chevron_left_rounded, color: _ink, size: 28)),
      titleSpacing: 0,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('TOGETHER LISTENING', style: TextStyle(fontSize: 9, letterSpacing: 1.3, color: _muted, fontWeight: FontWeight.w600)),
        SizedBox(height: 3),
        Text('一起听', style: TextStyle(fontSize: 18, color: _ink, fontWeight: FontWeight.w600)),
      ]),
      actions: [
        if (_loggedIn)
          IconButton(tooltip: '退出网易云', onPressed: _logout, icon: const Icon(Icons.logout_rounded, color: _muted, size: 19)),
        IconButton(tooltip: '连接设置', onPressed: _showSettings, icon: const Icon(Icons.tune_rounded, color: _ink, size: 20)),
      ],
    ),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(15, 7, 15, 10),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: '搜索歌曲、歌手或专辑',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 19),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _ink)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 46,
            child: FilledButton(
              onPressed: _busy ? null : _search,
              style: FilledButton.styleFrom(backgroundColor: _ink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
              child: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('搜索', style: TextStyle(fontSize: 12)),
            ),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 9),
        child: Row(children: [
          _tabChip('搜索', 0),
          const SizedBox(width: 7),
          _tabChip('我的歌单', 1),
          const SizedBox(width: 7),
          _tabChip('播放队列', 2),
          const Spacer(),
          if (_loggedIn)
            Text(_accountName.isEmpty ? '已登录' : _accountName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _muted)),
          if (!_loggedIn)
            TextButton(onPressed: _showLogin, style: TextButton.styleFrom(foregroundColor: _ink, visualDensity: VisualDensity.compact), child: const Text('登录', style: TextStyle(fontSize: 11))),
        ]),
      ),
      if (_message.isNotEmpty && _tab != 0)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text(_message, style: const TextStyle(fontSize: 10, color: _muted))),
      Expanded(child: _content()),
      if (_current != null) _miniPlayer(),
    ]),
  );

  Widget _tabChip(String label, int value) => ChoiceChip(
    label: Text(label, style: TextStyle(fontSize: 10, color: _tab == value ? Colors.white : _muted)),
    selected: _tab == value,
    onSelected: (_) => setState(() => _tab = value),
    selectedColor: _ink,
    backgroundColor: Colors.white,
    side: BorderSide(color: _tab == value ? _ink : _line),
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 4),
  );
}
);
    for (final line in raw.split(RegExp(r'\\r?\\n'))) {
      final match = pattern.firstMatch(line.trim());
      if (match == null) continue;
      final text = match.group(3)?.trim() ?? '';
      if (text.isEmpty) continue;
      final seconds = int.parse(match.group(1)!) * 60 + double.parse(match.group(2)!);
      lines.add({'time': seconds, 'text': text});
    }
    lines.sort((a, b) => (a['time'] as double).compareTo(b['time'] as double));
    return lines;
  }

  Future<void> _openPlaylist(MusicPlaylist playlist) async {
    setState(() => _busy = true);
    try {
      final songs = await _api.playlistSongs(_worker, _cookie, playlist.id);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: _paper,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
        builder: (context) => SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .76,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                  child: Row(children: [
                    Expanded(child: Text(playlist.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink))),
                    Text('${songs.length} 首', style: const TextStyle(fontSize: 11, color: _muted)),
                  ]),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (_, index) => _songTile(songs[index], index + 1, onTap: () => _play(songs[index], source: songs)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _toast(MusicApiClient.prettyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _songTile(MusicSong song, int index, {VoidCallback? onTap}) => ListTile(
    dense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
    leading: SizedBox(
      width: 26,
      child: Center(child: Text(index.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 10, color: _muted, fontFeatures: []))),
    ),
    title: Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: _current?.id == song.id ? _ink : const Color(0xFF333333), fontWeight: _current?.id == song.id ? FontWeight.w600 : FontWeight.w400)),
    subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _muted)),
    trailing: Icon(_current?.id == song.id ? Icons.equalizer_rounded : Icons.play_arrow_rounded, color: _current?.id == song.id ? _ink : _muted, size: 19),
    onTap: onTap ?? () => _play(song, source: _results),
  );

  Widget _content() {
    if (_tab == 1) {
      if (!_loggedIn) return _empty('登录后查看自己的网易云歌单', Icons.library_music_outlined);
      if (_playlists.isEmpty) return _empty('暂时没有读取到歌单', Icons.queue_music_rounded);
      return ListView.separated(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
        itemCount: _playlists.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: _line, indent: 66),
        itemBuilder: (_, i) {
          final p = _playlists[i];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: p.cover.isEmpty
                  ? Container(width: 48, height: 48, color: const Color(0xFFEDEDED), child: const Icon(Icons.music_note_rounded, color: _muted))
                  : Image.network(p.cover, width: 48, height: 48, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 48, height: 48, color: const Color(0xFFEDEDED), child: const Icon(Icons.music_note_rounded, color: _muted))),
            ),
            title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _ink, fontWeight: FontWeight.w500)),
            subtitle: Text('${p.trackCount} 首', style: const TextStyle(fontSize: 10, color: _muted)),
            trailing: const Icon(Icons.chevron_right_rounded, color: _muted),
            onTap: () => _openPlaylist(p),
          );
        },
      );
    }
    if (_tab == 2) {
      if (_queue.isEmpty) return _empty('搜索歌曲或打开歌单，把喜欢的歌加入播放队列', Icons.queue_music_rounded);
      return ListView.builder(
        padding: const EdgeInsets.only(top: 6, bottom: 12),
        itemCount: _queue.length,
        itemBuilder: (_, i) => _songTile(_queue[i], i + 1, onTap: () => _play(_queue[i], source: _queue)),
      );
    }
    if (_results.isNotEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 6, bottom: 12),
        itemCount: _results.length,
        itemBuilder: (_, i) => _songTile(_results[i], i + 1, onTap: () => _play(_results[i], source: _results)),
      );
    }
    if (_message.isNotEmpty) return _empty(_message, Icons.info_outline_rounded);
    return _empty('搜索一首想听的歌，或者登录网易云读取你的歌单', Icons.headphones_rounded);
  }

  Widget _empty(String text, IconData icon) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 34, color: const Color(0xFFB5B5B5)),
        const SizedBox(height: 13),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.7, color: _muted)),
      ]),
    ),
  );

  Widget _miniPlayer() {
    final song = _current!;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: _showPlayer,
        child: Container(
          padding: const EdgeInsets.fromLTRB(13, 9, 12, 9),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: _line))),
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.cover.isEmpty
                  ? Container(width: 39, height: 39, color: const Color(0xFFEDEDED), child: const Icon(Icons.music_note_rounded, color: _muted))
                  : Image.network(song.cover, width: 39, height: 39, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 39, height: 39, color: const Color(0xFFEDEDED), child: const Icon(Icons.music_note_rounded, color: _muted))),
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: _ink, fontWeight: FontWeight.w600)),
              Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _muted)),
            ])),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: () async {
                if (_audio.playing) {
                  await _audio.pause();
                } else {
                  await _audio.play();
                }
                if (mounted) setState(() {});
              },
              icon: StreamBuilder<PlayerState>(
                stream: _audio.playerStateStream,
                builder: (_, snapshot) => Icon(snapshot.data?.playing == true ? Icons.pause_rounded : Icons.play_arrow_rounded, color: _ink, size: 25),
              ),
            ),
            IconButton(
              visualDensity: VisualDensity.compact,
              onPressed: _next,
              icon: const Icon(Icons.skip_next_rounded, color: _ink, size: 24),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _next() async {
    if (_queue.isEmpty || _current == null) return;
    final index = _queue.indexWhere((s) => s.id == _current!.id);
    final next = _queue[(index + 1) % _queue.length];
    await _play(next, source: _queue);
  }

  Future<void> _showPlayer() async {
    if (_current == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(builder: (context, refresh) {
        final song = _current!;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 34, height: 4, decoration: BoxDecoration(color: _line, borderRadius: BorderRadius.circular(9))),
              const SizedBox(height: 25),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: song.cover.isEmpty
                    ? Container(width: 210, height: 210, color: const Color(0xFFEDEDED), child: const Icon(Icons.album_rounded, size: 80, color: _muted))
                    : Image.network(song.cover, width: 210, height: 210, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 210, height: 210, color: const Color(0xFFEDEDED), child: const Icon(Icons.album_rounded, size: 80, color: _muted))),
              ),
              const SizedBox(height: 22),
              Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink)),
              const SizedBox(height: 5),
              Text(song.artist, style: const TextStyle(fontSize: 12, color: _muted)),
              const SizedBox(height: 25),
              StreamBuilder<Duration>(
                stream: _audio.positionStream,
                builder: (_, snap) {
                  final position = snap.data ?? Duration.zero;
                  final duration = _audio.duration ?? Duration.zero;
                  final max = duration.inMilliseconds.toDouble().clamp(1.0, double.infinity).toDouble();
                  return Column(children: [
                    Slider(
                      value: position.inMilliseconds.toDouble().clamp(0.0, max).toDouble(),
                      max: max,
                      activeColor: _ink,
                      inactiveColor: _line,
                      onChanged: (v) => _audio.seek(Duration(milliseconds: v.toInt())),
                    ),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(_time(position), style: const TextStyle(fontSize: 10, color: _muted)),
                      Text(_time(duration), style: const TextStyle(fontSize: 10, color: _muted)),
                    ]),
                  ]);
                },
              ),
              const SizedBox(height: 15),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                IconButton(onPressed: _previous, icon: const Icon(Icons.skip_previous_rounded, size: 34, color: _ink)),
                const SizedBox(width: 18),
                StreamBuilder<PlayerState>(
                  stream: _audio.playerStateStream,
                  builder: (_, snap) => IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: _ink, foregroundColor: Colors.white, fixedSize: const Size(58, 58)),
                    onPressed: () async {
                      if (snap.data?.playing == true) {
                        await _audio.pause();
                      } else {
                        await _audio.play();
                      }
                      refresh(() {});
                    },
                    icon: Icon(snap.data?.playing == true ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 30),
                  ),
                ),
                const SizedBox(width: 18),
                IconButton(onPressed: _next, icon: const Icon(Icons.skip_next_rounded, size: 34, color: _ink)),
              ]),
            ]),
          ),
        );
      }),
    );
  }

  Future<void> _previous() async {
    if (_queue.isEmpty || _current == null) return;
    final index = _queue.indexWhere((s) => s.id == _current!.id);
    final previous = _queue[(index - 1 + _queue.length) % _queue.length];
    await _play(previous, source: _queue);
  }

  String _time(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _showSettings() async {
    _workerController.text = _worker;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('音乐连接设置', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink)),
            const SizedBox(height: 7),
            const Text('默认使用糯米机音乐模块的公共代理，无需你部署服务器。也可以填写自己的兼容 Worker 地址。', style: TextStyle(fontSize: 11, height: 1.6, color: _muted)),
            const SizedBox(height: 14),
            TextField(
              controller: _workerController,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                hintText: MusicApiClient.defaultWorker,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _line)),
              ),
            ),
            const SizedBox(height: 13),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('取消'))),
              const SizedBox(width: 9),
              Expanded(child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _ink, foregroundColor: Colors.white),
                onPressed: () async {
                  await _saveWorker(_workerController.text);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('保存地址'),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await _secure.delete(key: _cookieKey);
    if (!mounted) return;
    setState(() {
      _cookie = '';
      _loggedIn = false;
      _uid = null;
      _accountName = '';
      _playlists = [];
    });
    _toast('已退出网易云账号');
  }

  void _toast(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text), behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 2)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _paper,
    appBar: AppBar(
      backgroundColor: _paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.chevron_left_rounded, color: _ink, size: 28)),
      titleSpacing: 0,
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text('TOGETHER LISTENING', style: TextStyle(fontSize: 9, letterSpacing: 1.3, color: _muted, fontWeight: FontWeight.w600)),
        SizedBox(height: 3),
        Text('一起听', style: TextStyle(fontSize: 18, color: _ink, fontWeight: FontWeight.w600)),
      ]),
      actions: [
        if (_loggedIn)
          IconButton(tooltip: '退出网易云', onPressed: _logout, icon: const Icon(Icons.logout_rounded, color: _muted, size: 19)),
        IconButton(tooltip: '连接设置', onPressed: _showSettings, icon: const Icon(Icons.tune_rounded, color: _ink, size: 20)),
      ],
    ),
    body: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(15, 7, 15, 10),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                hintText: '搜索歌曲、歌手或专辑',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
                prefixIcon: const Icon(Icons.search_rounded, color: _muted, size: 19),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _line)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _ink)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 46,
            child: FilledButton(
              onPressed: _busy ? null : _search,
              style: FilledButton.styleFrom(backgroundColor: _ink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
              child: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('搜索', style: TextStyle(fontSize: 12)),
            ),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(15, 0, 15, 9),
        child: Row(children: [
          _tabChip('搜索', 0),
          const SizedBox(width: 7),
          _tabChip('我的歌单', 1),
          const SizedBox(width: 7),
          _tabChip('播放队列', 2),
          const Spacer(),
          if (_loggedIn)
            Text(_accountName.isEmpty ? '已登录' : _accountName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: _muted)),
          if (!_loggedIn)
            TextButton(onPressed: _showLogin, style: TextButton.styleFrom(foregroundColor: _ink, visualDensity: VisualDensity.compact), child: const Text('登录', style: TextStyle(fontSize: 11))),
        ]),
      ),
      if (_message.isNotEmpty && _tab != 0)
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), child: Text(_message, style: const TextStyle(fontSize: 10, color: _muted))),
      Expanded(child: _content()),
      if (_current != null) _miniPlayer(),
    ]),
  );

  Widget _tabChip(String label, int value) => ChoiceChip(
    label: Text(label, style: TextStyle(fontSize: 10, color: _tab == value ? Colors.white : _muted)),
    selected: _tab == value,
    onSelected: (_) => setState(() => _tab = value),
    selectedColor: _ink,
    backgroundColor: Colors.white,
    side: BorderSide(color: _tab == value ? _ink : _line),
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 4),
  );
}
