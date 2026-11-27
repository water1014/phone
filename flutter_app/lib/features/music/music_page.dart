import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
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
        _accountName = nickname;
        _playlists = playlists;
        _message = '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loggedIn = false;
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
    var dialogActive = true;

    try {
      final keyResponse = await _api.qrKey(_worker);
      qrKey = MusicApiClient.qrKeyValue(keyResponse);
      if (qrKey == null || qrKey.isEmpty) throw Exception('无法获取登录二维码');
      final imageResponse = await _api.qrCreate(_worker, qrKey);
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
            if (!dialogActive || checking || finished || qrKey == null) return;
            checking = true;
            try {
              final response = await _api.qrCheck(_worker, qrKey);
              if (!dialogActive || !dialogContext.mounted) return;
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
                  dialogActive = false;
                  timer?.cancel();
                  await _secure.write(key: _cookieKey, value: cookie);
                  if (mounted) setState(() => _cookie = cookie);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  await _loadAccount();
                  _toast('网易云已登录');
                }
              }
              if (dialogActive && dialogContext.mounted) refresh(() {});
            } catch (e) {
              if (!dialogActive || !dialogContext.mounted) return;
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
                        base64Decode(qrImage.replaceFirst(RegExp(r'^data:image/[^;]+;base64,'), '')),
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
              TextButton(onPressed: () { dialogActive = false; timer?.cancel(); Navigator.of(dialogContext).pop(); }, child: const Text('取消', style: TextStyle(color: _muted))),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: _ink, foregroundColor: Colors.white),
                onPressed: () async {
                  final cookie = MusicApiClient.extractMusicCookie(manualController.text);
                  if (cookie == null) {
                    refresh(() => status = '没有识别到 MUSIC_U，请粘贴完整 Cookie');
                    return;
                  }
                  finished = true;
                  dialogActive = false;
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
    dialogActive = false;
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
    if (!mounted) return;
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
      await _audio.setAudioSource(
        AudioSource.uri(
          Uri.parse(url),
          tag: MediaItem(
            id: song.id.toString(),
            title: song.name,
            artist: song.artist,
            artUri: song.cover.isEmpty ? null : Uri.tryParse(song.cover),
          ),
        ),
      );
      await _audio.play();
    } catch (e) {
      _toast(MusicApiClient.prettyError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<Map<String, dynamic>> _parseLyrics(String raw) {
    final lines = <Map<String, dynamic>>[];
    final pattern = RegExp(r'^\[(\d+):(\d+(?:\.\d+)?)\](.*)$');
    for (final line in raw.split(RegExp(r'\r?\n'))) {
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

  Widget _songTile(MusicSong song, int index, {VoidCallback? onTap}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap ?? () => _play(song, source: _results),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(children: [
          SizedBox(
            width: 22,
            child: Center(child: Text(index.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 9, color: Color(0xFF999999)))),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: song.cover.isEmpty
                ? Container(width: 46, height: 46, color: const Color(0xFFF0F0F0), child: const Icon(Icons.music_note_rounded, color: Color(0xFF666666), size: 20))
                : Image.network(song.cover, width: 46, height: 46, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 46, height: 46, color: const Color(0xFFF0F0F0), child: const Icon(Icons.music_note_rounded, color: Color(0xFF666666), size: 20))),
          ),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: _current?.id == song.id ? const Color(0xFF202020) : const Color(0xFF414141), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
          ])),
          const SizedBox(width: 8),
          Icon(_current?.id == song.id ? Icons.equalizer_rounded : Icons.play_circle_outline_rounded,
              color: const Color(0xFF666666), size: 21),
        ]),
      ),
    ),
  );

  Widget _homeContent() {
    final featured = _current ?? (_queue.isNotEmpty ? _queue.first : null);
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_loggedIn ? '欢迎回来' : '听歌时间',
                    style: const TextStyle(fontSize: 9, letterSpacing: 2.2, color: Color(0xFF666666), fontWeight: FontWeight.w700)),
                const SizedBox(height: 7),
                Text(_loggedIn && _accountName.isNotEmpty ? _accountName : '音乐',
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 25, color: Color(0xFF202020), fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_loggedIn ? '网易云音乐已连接' : '让喜欢的音乐，随时陪着你',
                    style: const TextStyle(fontSize: 11, color: Color(0xFF777777))),
              ]),
            ),
            GestureDetector(
              onTap: _loggedIn ? _logout : _showLogin,
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: .82), shape: BoxShape.circle, border: Border.all(color: Colors.white)),
                child: Icon(_loggedIn ? Icons.check_rounded : Icons.person_outline_rounded, color: const Color(0xFF303030)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 27),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('正在播放', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0xFF666666), fontWeight: FontWeight.w700)),
          Text(_queue.isEmpty ? '我的音乐' : '${_queue.length.toString().padLeft(2, '0')} 首歌曲',
              style: const TextStyle(fontSize: 9, letterSpacing: 1.2, color: Color(0xFF999999))),
        ]),
        const SizedBox(height: 12),
        if (featured != null)
          GestureDetector(
            onTap: _showPlayer,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .84),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 1.2),
                boxShadow: [BoxShadow(color: const Color(0xFF666666).withValues(alpha: .08), blurRadius: 24, offset: const Offset(0, 10))],
              ),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: featured.cover.isEmpty
                      ? Container(width: 92, height: 92, color: const Color(0xFFF2F2F2), child: const Icon(Icons.music_note_rounded, size: 35, color: Color(0xFF666666)))
                      : Image.network(featured.cover, width: 92, height: 92, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(width: 92, height: 92, color: const Color(0xFFF2F2F2), child: const Icon(Icons.music_note_rounded, color: Color(0xFF666666)))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('继续聆听', style: TextStyle(fontSize: 8, letterSpacing: 1.5, color: Color(0xFF666666))),
                  const SizedBox(height: 8),
                  Text(featured.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16, height: 1.3, fontWeight: FontWeight.w700, color: Color(0xFF202020))),
                  const SizedBox(height: 4),
                  Text(featured.artist, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: Color(0xFF777777))),
                  const SizedBox(height: 9),
                  const Row(children: [
                    Icon(Icons.graphic_eq_rounded, size: 14, color: Color(0xFF202020)),
                    SizedBox(width: 5),
                    Text('打开播放器', style: TextStyle(fontSize: 8, letterSpacing: 1.2, color: Color(0xFF202020), fontWeight: FontWeight.w700)),
                  ]),
                ])),
              ]),
            ),
          )
        else
          GestureDetector(
            onTap: _showLogin,
            child: Container(
              height: 154,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .78),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white),
              ),
              child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.headphones_rounded, size: 34, color: Color(0xFF202020)),
                SizedBox(height: 12),
                Text('让喜欢的音乐住进来', style: TextStyle(fontSize: 14, color: Color(0xFF414141), fontWeight: FontWeight.w600)),
                SizedBox(height: 5),
                Text('登录网易云音乐，读取你的歌单', style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
              ]),
            ),
          ),
        const SizedBox(height: 27),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('我的歌单', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0xFF666666), fontWeight: FontWeight.w700)),
          TextButton(onPressed: () => setState(() => _tab = 1),
              child: const Text('查看全部  ›', style: TextStyle(fontSize: 9, letterSpacing: 1, color: Color(0xFF202020)))),
        ]),
        if (_playlists.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 22),
            alignment: Alignment.centerLeft,
            child: Text(_loggedIn ? '还没有读取到歌单' : '登录后，这里会出现你的网易云歌单',
                style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
          )
        else
          SizedBox(
            height: 158,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _playlists.length > 8 ? 8 : _playlists.length,
              separatorBuilder: (_, __) => const SizedBox(width: 13),
              itemBuilder: (_, i) {
                final p = _playlists[i];
                return GestureDetector(
                  onTap: () => _openPlaylist(p),
                  child: SizedBox(width: 112, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: p.cover.isEmpty
                          ? Container(width: 112, height: 112, color: const Color(0xFFF0F0F0), child: const Icon(Icons.album_rounded, color: Color(0xFF666666), size: 30))
                          : Image.network(p.cover, width: 112, height: 112, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(width: 112, height: 112, color: const Color(0xFFF0F0F0), child: const Icon(Icons.album_rounded, color: Color(0xFF666666)))),
                    ),
                    const SizedBox(height: 7),
                    Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF414141), fontWeight: FontWeight.w600)),
                    Text('${p.count} 首歌曲', style: const TextStyle(fontSize: 9, color: Color(0xFF888888))),
                  ])),
                );
              },
            ),
          ),
        const SizedBox(height: 20),
        if (_queue.isNotEmpty) ...[
          const Text('接下来播放', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0xFF666666), fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ..._queue.take(4).toList().asMap().entries.map((entry) => _songTile(entry.value, entry.key + 1)),
        ],
      ],
    );
  }

  Widget _playlistContent() {
    if (!_loggedIn) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.library_music_outlined, size: 42, color: Color(0xFF666666)),
          const SizedBox(height: 14),
          const Text('登录后查看你的歌单', style: TextStyle(fontSize: 14, color: Color(0xFF414141), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('用网易云音乐扫码即可同步', style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
          const SizedBox(height: 16),
          FilledButton(onPressed: _showLogin, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF202020)), child: const Text('连接网易云')),
        ]),
      ));
    }
    if (_playlists.isEmpty) return _empty('暂时没有读取到歌单', Icons.queue_music_rounded);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
      itemCount: _playlists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final p = _playlists[i];
        return InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _openPlaylist(p),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: .82), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white)),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: p.cover.isEmpty
                    ? Container(width: 66, height: 66, color: const Color(0xFFF0F0F0), child: const Icon(Icons.music_note_rounded, color: Color(0xFF666666)))
                    : Image.network(p.cover, width: 66, height: 66, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 66, height: 66, color: const Color(0xFFF0F0F0), child: const Icon(Icons.music_note_rounded, color: Color(0xFF666666)))),
              ),
              const SizedBox(width: 13),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Color(0xFF414141), fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text('${p.count} 首歌曲', style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
              ])),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF666666)),
            ]),
          ),
        );
      },
    );
  }

  Widget _discoverContent() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
        child: Row(children: [
          Expanded(child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white), boxShadow: [
              BoxShadow(color: const Color(0xFF666666).withValues(alpha: .07), blurRadius: 18, offset: const Offset(0, 6)),
            ]),
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: const InputDecoration(
                hintText: '搜索歌曲或歌手…',
                hintStyle: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF777777), size: 19),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          )),
          const SizedBox(width: 9),
          SizedBox(height: 47, child: FilledButton(
            onPressed: _busy ? null : _search,
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF202020), shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 20)),
            child: _busy ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('搜索'),
          )),
        ]),
      ),
      const Padding(
        padding: EdgeInsets.fromLTRB(22, 2, 22, 8),
        child: Row(children: [
          Text('发现音乐', style: TextStyle(fontSize: 10, letterSpacing: 2.3, color: Color(0xFF666666), fontWeight: FontWeight.w700)),
          SizedBox(width: 10),
          Expanded(child: Divider(color: Color(0xFFE7E7E7))),
        ]),
      ),
      Expanded(child: _results.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 18),
              itemCount: _results.length,
              itemBuilder: (_, i) => _songTile(_results[i], i + 1, onTap: () => _play(_results[i], source: _results)),
            )
          : _message.isNotEmpty
              ? _empty(_message, Icons.info_outline_rounded)
              : _queue.isNotEmpty
                  ? ListView(children: [
                      const Padding(padding: EdgeInsets.fromLTRB(22, 16, 22, 8), child: Text('最近播放', style: TextStyle(fontSize: 10, letterSpacing: 1.8, color: Color(0xFF888888)))),
                      ..._queue.asMap().entries.map((entry) => _songTile(entry.value, entry.key + 1)),
                    ])
                  : _empty('搜索一首想听的歌，发现下一首喜欢的音乐', Icons.headphones_rounded)),
    ]);
  }

  Widget _empty(String text, IconData icon) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 34, color: const Color(0xFF999999)),
        const SizedBox(height: 13),
        Text(text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.7, color: Color(0xFF777777))),
      ]),
    ),
  );

  Widget _miniPlayer() {
    final song = _current!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Material(
        color: const Color(0xFF252428),
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _showPlayer,
          child: Container(
            padding: const EdgeInsets.fromLTRB(11, 9, 12, 9),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: .08)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: song.cover.isEmpty
                    ? Container(width: 43, height: 43, color: const Color(0xFF414047), child: const Icon(Icons.music_note_rounded, color: Colors.white70))
                    : Image.network(song.cover, width: 43, height: 43, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 43, height: 43, color: const Color(0xFF414047), child: const Icon(Icons.music_note_rounded, color: Colors.white70))),
              ),
              const SizedBox(width: 11),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFFB9B7BC))),
              ])),
              IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () async {
                  if (_audio.playing) { await _audio.pause(); } else { await _audio.play(); }
                  if (mounted) setState(() {});
                },
                icon: StreamBuilder<PlayerState>(
                  stream: _audio.playerStateStream,
                  builder: (_, snapshot) => Icon(snapshot.data?.playing == true ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 26),
                ),
              ),
              IconButton(visualDensity: VisualDensity.compact, onPressed: _next, icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 24)),
            ]),
          ),
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
      useSafeArea: true,
      backgroundColor: const Color(0xFF101116),
      barrierColor: Colors.black54,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => StatefulBuilder(builder: (context, refresh) {
        final song = _current!;
        final size = MediaQuery.of(context).size;
        return SizedBox(
          height: size.height,
          child: Stack(children: [
            Positioned.fill(
              child: song.cover.isEmpty
                  ? Container(color: const Color(0xFF191A20))
                  : Image.network(song.cover, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF191A20))),
            ),
            Positioned.fill(child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
                  const Color(0xFF101116).withValues(alpha: .68),
                  const Color(0xFF101116).withValues(alpha: .78),
                  const Color(0xFF101116),
                ], stops: const [0, .42, 1]),
              ),
            )),
            SafeArea(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  IconButton(onPressed: () => Navigator.pop(sheetContext), icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 30)),
                  const Text('正在播放', style: TextStyle(fontSize: 9, letterSpacing: 2.2, color: Color(0xFFB9B7BC))),
                  IconButton(onPressed: () { Navigator.pop(sheetContext); _showSettings(); }, icon: const Icon(Icons.more_horiz_rounded, color: Colors.white, size: 25)),
                ]),
                const SizedBox(height: 22),
                Row(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: song.cover.isEmpty
                        ? Container(width: 58, height: 58, color: const Color(0xFF30313A), child: const Icon(Icons.music_note_rounded, color: Colors.white70))
                        : Image.network(song.cover, width: 58, height: 58, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 58, height: 58, color: const Color(0xFF30313A), child: const Icon(Icons.music_note_rounded, color: Colors.white70))),
                  ),
                  const SizedBox(width: 13),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(song.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFFB9B7BC))),
                  ])),
                ]),
                const SizedBox(height: 26),
                Expanded(child: StreamBuilder<int>(
                  // 只在歌词行变化时重建，避免 positionStream 高频刷新整份歌词列表。
                  stream: _audio.positionStream.map((position) {
                    final seconds = position.inMilliseconds / 1000;
                    return _lyrics.lastIndexWhere((line) => (line['time'] as double) <= seconds);
                  }).distinct(),
                  builder: (_, snapshot) {
                    var active = snapshot.data ?? 0;
                    if (active < 0) active = 0;
                    if (_lyrics.isEmpty) {
                      return const Center(child: Text('让音乐慢慢流淌', style: TextStyle(fontSize: 13, color: Color(0xFF777982))));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 26),
                      itemCount: _lyrics.length,
                      itemBuilder: (_, index) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          _lyrics[index]['text'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: index == active ? 21 : 15,
                            height: 1.4,
                            color: index == active ? Colors.white : const Color(0xFF777982),
                            fontWeight: index == active ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  },
                )),
                const SizedBox(height: 10),
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
                        activeColor: Colors.white,
                        inactiveColor: const Color(0xFF4A4B52),
                        onChanged: (v) => _audio.seek(Duration(milliseconds: v.toInt())),
                      ),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(_time(position), style: const TextStyle(fontSize: 10, color: Color(0xFF9B9CA3))),
                        Text(_time(duration), style: const TextStyle(fontSize: 10, color: Color(0xFF9B9CA3))),
                      ]),
                    ]);
                  },
                ),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  IconButton(onPressed: _previous, icon: const Icon(Icons.shuffle_rounded, color: Color(0xFFB9B7BC), size: 21)),
                  IconButton(onPressed: _previous, icon: const Icon(Icons.skip_previous_rounded, color: Colors.white, size: 35)),
                  StreamBuilder<PlayerState>(
                    stream: _audio.playerStateStream,
                    builder: (_, snap) => IconButton(
                      onPressed: () async {
                        if (snap.data?.playing == true) { await _audio.pause(); } else { await _audio.play(); }
                        if (sheetContext.mounted) refresh(() {});
                      },
                      icon: Icon(snap.data?.playing == true ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded, color: Colors.white, size: 68),
                    ),
                  ),
                  IconButton(onPressed: _next, icon: const Icon(Icons.skip_next_rounded, color: Colors.white, size: 35)),
                  IconButton(onPressed: () { Navigator.pop(sheetContext); setState(() => _tab = 1); }, icon: const Icon(Icons.queue_music_rounded, color: Color(0xFFB9B7BC), size: 22)),
                ]),
              ]),
            )),
          ]),
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
    backgroundColor: const Color(0xFFF7F7F7),
    body: SafeArea(child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(17, 8, 17, 8),
        child: SizedBox(height: 48, child: Stack(alignment: Alignment.center, children: [
          const Text('音乐', style: TextStyle(fontSize: 22, color: Color(0xFF202020), fontWeight: FontWeight.w700, letterSpacing: 1)),
          Align(alignment: Alignment.centerLeft, child: _roundHeaderButton(Icons.chevron_left_rounded, () => Navigator.of(context).maybePop())),
          Align(alignment: Alignment.centerRight, child: _roundHeaderButton(Icons.tune_rounded, _showSettings)),
        ])),
      ),
      Expanded(child: _tab == 0 ? _homeContent() : _tab == 1 ? _playlistContent() : _discoverContent()),
      if (_current != null) _miniPlayer(),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 2, 18, 10),
        child: Container(
          height: 66,
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .88), borderRadius: BorderRadius.circular(35), border: Border.all(color: Colors.white, width: 1.2),
            boxShadow: [BoxShadow(color: const Color(0xFF666666).withValues(alpha: .08), blurRadius: 20, offset: const Offset(0, 7))]),
          child: Row(children: [
            _bottomTab(Icons.home_outlined, '首页', 0),
            _bottomTab(Icons.library_music_outlined, '歌单', 1),
            _bottomTab(Icons.search_rounded, '发现', 2),
          ]),
        ),
      ),
    ])),
  );

  Widget _roundHeaderButton(IconData icon, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(30),
    child: Container(width: 42, height: 42, decoration: BoxDecoration(color: Colors.white.withValues(alpha: .9), shape: BoxShape.circle, border: Border.all(color: Colors.white)),
      child: Icon(icon, color: const Color(0xFF303030), size: 22)),
  );

  Widget _bottomTab(IconData icon, String label, int value) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _tab = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: _tab == value ? const Color(0xFFEAEAEA) : Colors.transparent, borderRadius: BorderRadius.circular(28)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 21, color: _tab == value ? const Color(0xFF202020) : const Color(0xFF999999)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 9, color: _tab == value ? const Color(0xFF202020) : const Color(0xFF999999), fontWeight: _tab == value ? FontWeight.w700 : FontWeight.w400)),
        ]),
      ),
    ),
  );

}
