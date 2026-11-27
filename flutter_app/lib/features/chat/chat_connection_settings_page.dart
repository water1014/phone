import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import 'chat_api_client.dart';

class ChatConnectionSettingsPage extends StatefulWidget {
  const ChatConnectionSettingsPage({super.key});

  @override
  State<ChatConnectionSettingsPage> createState() => _ChatConnectionSettingsPageState();
}

class _ChatConnectionSettingsPageState extends State<ChatConnectionSettingsPage> {
  final _url = TextEditingController();
  final _model = TextEditingController();
  final _key = TextEditingController();
  final _headers = TextEditingController();
  String _provider = 'deepseek';
  bool _loading = true;
  bool _saving = false;
  bool _hideKey = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final config = await ChatApiConfigStore.load();
    if (!mounted) return;
    setState(() {
      _provider = config.provider;
      _url.text = config.baseUrl;
      _model.text = config.model;
      _key.text = config.apiKey;
      _headers.text = config.customHeaders;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _url.dispose();
    _model.dispose();
    _key.dispose();
    _headers.dispose();
    super.dispose();
  }

  void _selectProvider(String? value) {
    if (value == null) return;
    final oldDefaults = ChatApiConfig.defaultsFor(_provider);
    final nextDefaults = ChatApiConfig.defaultsFor(value);
    setState(() {
      if (_url.text.trim().isEmpty || _url.text == oldDefaults.baseUrl) {
        _url.text = nextDefaults.baseUrl;
      }
      if (_model.text.trim().isEmpty || _model.text == oldDefaults.model) {
        _model.text = nextDefaults.model;
      }
      _provider = value;
    });
  }

  Future<void> _save() async {
    setState(() {
      _error = null;
      _saving = true;
    });
    try {
      if (_key.text.trim().isEmpty) throw Exception('请填写 API Key');
      if (_url.text.trim().isEmpty) throw Exception('请填写接口地址');
      if (_model.text.trim().isEmpty) throw Exception('请填写模型名称');
      if (_headers.text.trim().isNotEmpty) {
        final parsed = ChatApiClient.validateHeaders(_headers.text);
        if (!parsed) throw const FormatException('自定义请求头必须是 JSON 对象');
      }
      await ChatApiConfigStore.save(ChatApiConfig(
        provider: _provider,
        baseUrl: _url.text.trim(),
        model: _model.text.trim(),
        apiKey: _key.text.trim(),
        customHeaders: _headers.text.trim(),
      ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('聊天接口配置已安全保存')),
      );
    } catch (error) {
      if (mounted) setState(() => _error = error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF7F8F7),
    body: SafeArea(
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 18, 13),
                child: Row(children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.secondary),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('聊天接口', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
                    SizedBox(height: 3),
                    Text('连接模型服务，密钥仅保存在本机', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                  ])),
                ]),
              ),
              Expanded(child: ListView(
                padding: const EdgeInsets.fromLTRB(15, 3, 15, 28),
                children: [
                  _card('服务商', [
                    DropdownButtonFormField<String>(
                      value: _provider,
                      decoration: _decoration('选择服务商'),
                      items: const [
                        DropdownMenuItem(value: 'deepseek', child: Text('DeepSeek 官方')),
                        DropdownMenuItem(value: 'opencode', child: Text('OpenCode Go')),
                        DropdownMenuItem(value: 'openai', child: Text('OpenAI 兼容接口')),
                      ],
                      onChanged: _selectProvider,
                    ),
                    const SizedBox(height: 15),
                    _field('接口地址', _url, hint: 'https://…'),
                    const SizedBox(height: 13),
                    _field('模型名称', _model, hint: '例如 deepseek-chat'),
                    const SizedBox(height: 13),
                    TextField(
                      controller: _key,
                      obscureText: _hideKey,
                      decoration: _decoration('API Key').copyWith(
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _hideKey = !_hideKey),
                          icon: Icon(_hideKey ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 19),
                        ),
                      ),
                    ),
                    const SizedBox(height: 13),
                    TextField(
                      controller: _headers,
                      minLines: 3,
                      maxLines: 6,
                      autocorrect: false,
                      style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                      decoration: _decoration('自定义请求头（JSON，可留空）').copyWith(
                        hintText: '{"X-Custom-Header":"value"}',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 13),
                  _card('连接说明', [
                    Text(
                      _provider == 'opencode'
                        ? 'OpenCode Go 默认使用官方 Go 推理入口，并自动附带稳定的 x-opencode-session。若你使用中转站，可自行修改接口地址和请求头。'
                        : _provider == 'deepseek'
                          ? '默认地址为 DeepSeek 官方兼容接口。请填写你自己的 API Key，模型名可按账户权限调整。'
                          : '可填写任何兼容 /v1/chat/completions 的服务地址，并通过自定义请求头适配第三方服务。',
                      style: const TextStyle(fontSize: 12, height: 1.65, color: AppColors.secondary),
                    ),
                    const SizedBox(height: 9),
                    const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.lock_outline_rounded, size: 15, color: AppColors.muted),
                      SizedBox(width: 7),
                      Expanded(child: Text(
                        'API Key 和自定义请求头使用 Android 安全存储保存，不会写入普通聊天记录。',
                        style: TextStyle(fontSize: 10, height: 1.5, color: AppColors.muted),
                      )),
                    ]),
                  ]),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(fontSize: 12, color: Color(0xFFB65B5B))),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 49,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _saving
                        ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('保存接口配置', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              )),
            ]),
    ),
  );

  Widget _card(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.fromLTRB(15, 15, 15, 16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .93),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xFFE9E9E8)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.secondary)),
      ),
      ...children,
    ]),
  );

  Widget _field(String label, TextEditingController controller, {String? hint}) =>
      TextField(controller: controller, autocorrect: false, decoration: _decoration(label).copyWith(hintText: hint));

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(fontSize: 12, color: AppColors.muted),
    filled: true,
    fillColor: const Color(0xFFF7F7F6),
    contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFEAE9E8))),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: Color(0xFFEAE9E8))),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.accent)),
  );
}
