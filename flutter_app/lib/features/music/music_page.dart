import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  bool _busy = false;
  bool _showCookie = false;
  bool _hasCookie = false;
  String? _accountName;
  String? _message;
  bool _verified = false;

  @override
  void initState() {
    super.initState();
    _restoreLogin();
  }

  @override
  void dispose() {
    _cookieController.dispose();
    super.dispose();
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
    setState(() => _message = '已粘贴，请确认内容后验证登录');
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
      final response = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
        headers: {
          'Cookie': cookie,
          'Referer': 'https://music.163.com/',
          'User-Agent': 'Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120.0 Mobile Safari/537.36',
        },
        responseType: ResponseType.json,
        validateStatus: (status) => status != null && status < 500,
      )).get<dynamic>('https://music.163.com/api/nuser/account/get');

      final body = response.data;
      if (body is! Map) {
        throw const FormatException('网易云返回了无法识别的数据');
      }
      final code = body['code'];
      final profile = body['profile'];
      final account = body['account'];
      final nickname = profile is Map ? profile['nickname'] : null;
      final userId = account is Map ? account['id'] : null;
      if (code != 200 || (nickname == null && userId == null)) {
        throw const FormatException('登录验证未通过，Cookie 可能已过期或权限不足');
      }
      if (save) {
        await _storage.write(key: _cookieKey, value: cookie);
      }
      if (!mounted) return;
      setState(() {
        _hasCookie = true;
        _verified = true;
        _accountName = nickname?.toString() ?? '网易云音乐用户';
        _message = save ? '登录成功，Cookie 已加密保存在本机' : '登录状态有效';
        _cookieController.clear();
      });
    } on DioException catch (error) {
      if (!mounted) return;
      final status = error.response?.statusCode;
      setState(() => _message = status == null
          ? '连接网易云失败，请检查网络后重试'
          : '网易云暂时无法验证（HTTP $status），可以稍后再试');
    } catch (error) {
      if (!mounted) return;
      setState(() => _message = error is FormatException
          ? error.message
          : '验证失败，请检查 Cookie 是否完整');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _logout() async {
    await _storage.delete(key: _cookieKey);
    if (!mounted) return;
    setState(() {
      _hasCookie = false;
      _verified = false;
      _accountName = null;
      _message = '已退出网易云音乐登录';
      _cookieController.clear();
    });
  }

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
                Text('一起听歌', style: TextStyle(fontSize: 22, height: 1.1, fontWeight: FontWeight.w600, color: _ink)),
                SizedBox(height: 4),
                Text('连接你的网易云音乐', style: TextStyle(fontSize: 11, color: _muted)),
              ],
            )),
          ]),
        ),
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: _line),
              ),
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
                    Text('Cookie 登录', style: TextStyle(fontSize: 10, color: _muted)),
                  ])),
                  if (_verified)
                    const _StatusPill(label: '已连接', good: true)
                  else if (_hasCookie)
                    const _StatusPill(label: '待验证', good: false),
                ]),
                const SizedBox(height: 18),
                if (_verified) ...[
                  Text(_accountName ?? '网易云音乐用户', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                  const SizedBox(height: 5),
                  const Text('账号已连接。Cookie 仅保存在当前设备的安全存储中。', style: TextStyle(fontSize: 11, height: 1.6, color: _muted)),
                  const SizedBox(height: 15),
                  Row(children: [
                    Expanded(child: OutlinedButton(
                      onPressed: _busy ? null : () => setState(() {
                        _verified = false;
                        _message = '粘贴新的 Cookie 后重新验证';
                      }),
                      style: OutlinedButton.styleFrom(foregroundColor: _ink, side: const BorderSide(color: _line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                      child: const Text('更换 Cookie'),
                    )),
                    const SizedBox(width: 9),
                    Expanded(child: OutlinedButton(
                      onPressed: _busy ? null : _logout,
                      style: OutlinedButton.styleFrom(foregroundColor: _muted, side: const BorderSide(color: _line), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13))),
                      child: const Text('退出登录'),
                    )),
                  ]),
                ] else ...[
                  const Text('粘贴从网易云音乐登录后获取的 Cookie。验证成功后会加密保存在本机，不会进入聊天记录。', style: TextStyle(fontSize: 11, height: 1.65, color: _muted)),
                  const SizedBox(height: 13),
                  TextField(
                    controller: _cookieController,
                    obscureText: !_showCookie,
                    maxLines: 2,
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
            ),
            const SizedBox(height: 13),
            Container(
              padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: _line)),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('登录方式说明', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink)),
                SizedBox(height: 9),
                _InfoLine(text: '在网易云音乐网页端或客户端登录后，复制自己的 Cookie。'),
                _InfoLine(text: 'Cookie 有效期可能变化，失效后需要重新粘贴。'),
                _InfoLine(text: '当前先完成账号安全连接，歌单同步和播放入口会在后续接入。'),
              ]),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(16)),
              child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.shield_outlined, size: 16, color: _muted),
                SizedBox(width: 9),
                Expanded(child: Text(
                  '安全提醒：Cookie 等同于登录凭据。不要发给任何人，也不要粘贴到聊天窗口。此功能不会把 Cookie 发送给宋祁的模型接口。网易云接口可能调整或触发风控，验证失败不一定代表 Cookie 本身错误。',
                  style: TextStyle(fontSize: 10, height: 1.6, color: _muted),
                )),
              ]),
            ),
          ],
        )),
      ]),
    ),
  );
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(padding: EdgeInsets.only(top: 5), child: Icon(Icons.circle, size: 5, color: _muted)),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 10, height: 1.55, color: _muted))),
    ]),
  );
}
