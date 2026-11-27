import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _ink = Color(0xFF202020);
const _muted = Color(0xFF888888);
const _line = Color(0xFFE7E7E7);
const _soft = Color(0xFFF3F3F3);
const _serverUrlKey = 'music_player_server_url';

class MusicPage extends StatefulWidget {
  const MusicPage({super.key});

  @override
  State<MusicPage> createState() => _MusicPageState();
}

class _MusicPageState extends State<MusicPage> {
  static const _storage = FlutterSecureStorage();
  final _urlController = TextEditingController();
  late final WebViewController _webView;
  bool _ready = false;
  bool _loading = false;
  bool _canGoBack = false;
  bool _showSettings = false;
  String? _serverUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _webView = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFFAFAFA))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() {
            _loading = true;
            _error = null;
          });
        },
        onPageFinished: (_) async {
          final canGoBack = await _webView.canGoBack();
          if (mounted) setState(() {
            _loading = false;
            _ready = true;
            _canGoBack = canGoBack;
          });
        },
        onWebResourceError: (error) {
          if (!mounted || error.errorType == WebResourceErrorType.cancelled) return;
          setState(() {
            _loading = false;
            _error = '播放器暂时无法连接。请检查服务器地址、网络和 HTTPS 配置。';
          });
        },
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null) return NavigationDecision.prevent;
          if (uri.scheme == 'https' ||
              (uri.scheme == 'http' &&
                  (uri.host == 'localhost' || uri.host == '127.0.0.1'))) {
            return NavigationDecision.navigate;
          }
          return NavigationDecision.prevent;
        },
      ));
    _restoreServer();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _restoreServer() async {
    final saved = await _storage.read(key: _serverUrlKey);
    if (!mounted) return;
    if (saved == null || saved.trim().isEmpty) {
      setState(() => _ready = true);
      return;
    }
    _urlController.text = saved;
    await _connect(saved, persist: false);
  }

  String? _normalizeUrl(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return null;
    if (!value.contains('://')) value = 'https://$value';
    final uri = Uri.tryParse(value);
    if (uri == null || uri.host.isEmpty) return null;
    final localHttp = uri.scheme == 'http' &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1');
    if (uri.scheme != 'https' && !localHttp) return null;
    if (uri.hasQuery || uri.hasFragment || uri.userInfo.isNotEmpty) return null;
    return uri.toString().endsWith('/') ? uri.toString() : '${uri.toString()}/';
  }

  Future<void> _connect(String raw, {bool persist = true}) async {
    final normalized = _normalizeUrl(raw);
    if (normalized == null) {
      if (mounted) setState(() => _error = '请输入有效的 HTTPS 播放器地址，例如 https://music.example.com/music/');
      return;
    }
    if (persist) await _storage.write(key: _serverUrlKey, value: normalized);
    if (!mounted) return;
    setState(() {
      _serverUrl = normalized;
      _urlController.text = normalized;
      _showSettings = false;
      _loading = true;
      _error = null;
      _canGoBack = false;
    });
    try {
      await _webView.loadRequest(Uri.parse(normalized));
    } catch (_) {
      if (mounted) setState(() {
        _loading = false;
        _error = '播放器地址无法打开，请确认服务器已经启动。';
      });
    }
  }

  Future<void> _openSettings() async {
    _urlController.text = _serverUrl ?? '';
    setState(() => _showSettings = true);
  }

  Future<void> _forgetServer() async {
    await _storage.delete(key: _serverUrlKey);
    if (!mounted) return;
    setState(() {
      _serverUrl = null;
      _showSettings = false;
      _error = null;
      _canGoBack = false;
      _ready = true;
    });
  }

  Future<void> _handleBack(bool didPop) async {
    if (didPop || !_canGoBack) return;
    await _webView.goBack();
    final canGoBack = await _webView.canGoBack();
    if (mounted) setState(() => _canGoBack = canGoBack);
  }

  @override
  Widget build(BuildContext context) => PopScope<Object?>(
    canPop: !_canGoBack,
    onPopInvokedWithResult: (didPop, result) => _handleBack(didPop),
    child: Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: '返回',
          onPressed: () async {
            if (_canGoBack) {
              await _webView.goBack();
              final canGoBack = await _webView.canGoBack();
              if (mounted) setState(() => _canGoBack = canGoBack);
            } else {
              Navigator.of(context).maybePop();
            }
          },
          icon: const Icon(Icons.chevron_left_rounded, size: 29, color: _ink),
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TOGETHER LISTENING', style: TextStyle(fontSize: 9, letterSpacing: 1.25, color: _muted, fontWeight: FontWeight.w600)),
            SizedBox(height: 3),
            Text('一起听', style: TextStyle(fontSize: 18, color: _ink, fontWeight: FontWeight.w600)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '刷新播放器',
            onPressed: _serverUrl == null ? null : () => _webView.reload(),
            icon: const Icon(Icons.refresh_rounded, color: _ink, size: 20),
          ),
          IconButton(
            tooltip: '服务器设置',
            onPressed: _openSettings,
            icon: const Icon(Icons.tune_rounded, color: _ink, size: 20),
          ),
          const SizedBox(width: 5),
        ],
        bottom: _loading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2, color: _ink, backgroundColor: _line),
              )
            : null,
      ),
      body: Stack(
        children: [
          if (_serverUrl != null)
            WebViewWidget(controller: _webView)
          else
            _emptyState(),
          if (_error != null)
            Positioned(
              left: 16,
              right: 16,
              top: 14,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.info_outline_rounded, size: 17, color: _muted),
                    const SizedBox(width: 9),
                    Expanded(child: Text(_error!, style: const TextStyle(fontSize: 11, height: 1.55, color: _muted))),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() => _error = null),
                      icon: const Icon(Icons.close_rounded, size: 16, color: _muted),
                    ),
                  ]),
                ),
              ),
            ),
          if (_showSettings) _settingsPanel(),
        ],
      ),
    ),
  );

  Widget _emptyState() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25), border: Border.all(color: _line)),
            child: const Icon(Icons.headphones_rounded, size: 34, color: _ink),
          ),
          const SizedBox(height: 21),
          const Text('把喜欢的歌放在一起', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink)),
          const SizedBox(height: 8),
          const Text(
            '连接自己的音乐服务器后，就能使用完整的网易云播放器、歌词、批注本和双人点歌功能。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, height: 1.8, color: _muted),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _openSettings,
            style: FilledButton.styleFrom(backgroundColor: _ink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12)),
            icon: const Icon(Icons.link_rounded, size: 16),
            label: const Text('连接音乐服务器'),
          ),
          const SizedBox(height: 14),
          const Text('网易云登录凭据由你的服务器保管，不会进入聊天记录。', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: _muted)),
        ],
      ),
    ),
  );

  Widget _settingsPanel() => Positioned.fill(
    child: Material(
      color: const Color(0x66000000),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _showSettings = false),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 22),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(23)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Expanded(child: Text('音乐服务器', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink))),
                    IconButton(onPressed: () => setState(() => _showSettings = false), icon: const Icon(Icons.close_rounded, color: _muted)),
                  ]),
                  const SizedBox(height: 7),
                  const Text('填写部署好 Music-Mcp-Netease 的 HTTPS 地址。地址只保存在本机安全存储中。', style: TextStyle(fontSize: 11, height: 1.65, color: _muted)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    enableSuggestions: false,
                    decoration: InputDecoration(
                      hintText: 'https://你的域名/music/',
                      hintStyle: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _line)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _line)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _ink)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    if (_serverUrl != null)
                      Expanded(child: OutlinedButton(
                        onPressed: _forgetServer,
                        style: OutlinedButton.styleFrom(foregroundColor: _muted, side: const BorderSide(color: _line), padding: const EdgeInsets.symmetric(vertical: 13)),
                        child: const Text('断开连接'),
                      )),
                    if (_serverUrl != null) const SizedBox(width: 9),
                    Expanded(child: FilledButton(
                      onPressed: () => _connect(_urlController.text),
                      style: FilledButton.styleFrom(backgroundColor: _ink, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
                      child: const Text('保存并连接'),
                    )),
                  ]),
                  const SizedBox(height: 10),
                  const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.lock_outline_rounded, size: 14, color: _muted),
                    SizedBox(width: 7),
                    Expanded(child: Text('仅允许 HTTPS 地址；本机 localhost 可使用 HTTP 测试。请勿把网易云 Cookie 或服务器访问密钥发到聊天里。', style: TextStyle(fontSize: 10, height: 1.55, color: _muted))),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
