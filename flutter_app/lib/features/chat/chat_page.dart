import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_side_drawer.dart';
import 'chat_preferences.dart';
import 'chat_api_client.dart';
import 'chat_message.dart';
import 'chat_message_store.dart';

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.mine,
    required this.time,
    this.reasoning,
    this.isSystem = false,
    this.isTyping = false,
    this.inputTokens,
    this.outputTokens,
    this.imagePath,
  });
  final String text;
  final bool mine;
  final DateTime time;
  final String? reasoning;
  final bool isSystem;
  final bool isTyping;
  final int? inputTokens;
  final int? outputTokens;
  final String? imagePath;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _search = TextEditingController();
  final _messagesScroll = ScrollController();
  final _api = ChatApiClient();
  final _imagePicker = ImagePicker();
  String? _pendingImagePath;
  final List<_ChatMessage> _messages = [];
  bool _searching = false;
  bool _loadingHistory = true;
  bool _sending = false;
  bool _showJumpLatest = false;
  CancelToken? _activeCancelToken;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _messagesScroll.addListener(_handleScroll);
    unawaited(ChatPreferenceStore.load());
    unawaited(_loadChat());
    unawaited(_restoreDraft());
  }

  Future<void> _restoreDraft() async {
    final prefs = await SharedPreferences.getInstance();
    final draft = prefs.getString('chat.draft.v1') ?? '';
    if (!mounted || _input.text.isNotEmpty || draft.isEmpty) return;
    _input.value = TextEditingValue(
      text: draft,
      selection: TextSelection.collapsed(offset: draft.length),
    );
  }

  Future<void> _saveDraft(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('chat.draft.v1', value);
  }

  Future<void> _loadChat() async {
    final saved = await ChatMessageStore.load();
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(saved.map((message) => _ChatMessage(
          text: message.text,
          mine: message.mine,
          time: message.createdAt,
          reasoning: message.reasoning,
          isSystem: message.isSystem,
          inputTokens: message.inputTokens,
          outputTokens: message.outputTokens,
          imagePath: message.imagePath,
        )));
      _loadingHistory = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
  }

  Future<void> _persistChat() => ChatMessageStore.save(
    _messages.where((message) => !message.isTyping).map((message) => ChatMessageRecord(
      text: message.text,
      mine: message.mine,
      createdAt: message.time,
      reasoning: message.reasoning,
      isSystem: message.isSystem,
      inputTokens: message.inputTokens,
      outputTokens: message.outputTokens,
      imagePath: message.imagePath,
    )).toList(),
  );

  void _handleScroll() {
    if (!_messagesScroll.hasClients) return;
    final shouldShow = _messagesScroll.position.pixels < _messagesScroll.position.maxScrollExtent - 180;
    if (shouldShow != _showJumpLatest && mounted) setState(() => _showJumpLatest = shouldShow);
  }

  @override
  void dispose() {
    _messagesScroll.removeListener(_handleScroll);
    _input.dispose();
    _search.dispose();
    _messagesScroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? quickText]) async {
    if (_sending) return;
    final value = (quickText ?? _input.text).trim();
    final imagePath = quickText == null ? _pendingImagePath : null;
    if (value.isEmpty && imagePath == null) return;
    setState(() {
      _messages.add(_ChatMessage(text: value, mine: true, time: DateTime.now(), imagePath: imagePath));
      _input.clear();
      _pendingImagePath = null;
      _query = '';
      _search.clear();
      _sending = true;
    });
    FocusScope.of(context).unfocus();
    unawaited(_saveDraft(''));
    await _persistChat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());

    final cancelToken = CancelToken();
    _activeCancelToken = cancelToken;
    try {
      final config = await ChatApiConfigStore.load();
      if (!mounted) return;
      if (config.apiKey.trim().isEmpty || config.baseUrl.trim().isEmpty || config.model.trim().isEmpty) {
        setState(() {
          _messages.add(_ChatMessage(
            text: '还没有配置聊天接口。打开「更多 → 聊天设置 → 聊天接口配置」，填入服务商和 API Key 后就可以开始聊天啦。',
            mine: false,
            isSystem: true,
            time: DateTime.now(),
          ));
          _sending = false;
        });
        await _persistChat();
        return;
      }

      final historyMessages = _messages
          .where((message) => !message.isSystem && !message.isTyping &&
              (message.text.trim().isNotEmpty || message.imagePath != null))
          .toList()
          .reversed
          .take(20)
          .toList()
          .reversed;
      final history = <Map<String, dynamic>>[];
      for (final message in historyMessages) {
        final imagePath = message.imagePath;
        if (imagePath != null && await File(imagePath).exists()) {
          final file = File(imagePath);
          final bytes = await file.readAsBytes();
          final extension = file.path.toLowerCase().split('.').last;
          final mime = extension == 'png' ? 'image/png' :
              extension == 'webp' ? 'image/webp' : 'image/jpeg';
          history.add({
            'role': message.mine ? 'user' : 'assistant',
            'content': [
              if (message.text.trim().isNotEmpty)
                {'type': 'text', 'text': message.text},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:$mime;base64,${base64Encode(bytes)}'},
              },
            ],
          });
        } else {
          history.add({
            'role': message.mine ? 'user' : 'assistant',
            'content': message.text,
          });
        }
      }

      const systemPrompt = '你在「小窝」这个私人空间里。你就是你自己，不是客服。说话自然、有体温，偶尔走神、偶尔说重一点。可以用（括号）写神情和动作当旁白，也可以直接说话，不要列条目。';
      final requestMessages = <Map<String, dynamic>>[
        {'role': 'system', 'content': systemPrompt},
        ...history,
      ];

      final replyIndex = _messages.length;
      setState(() {
        _messages.add(_ChatMessage(text: '', mine: false, time: DateTime.now(), isTyping: true));
      });

      await for (final event in _api.streamReply(
        config: config,
        messages: requestMessages,
        cancelToken: cancelToken,
      )) {
        if (!mounted) return;
        if (event.textDelta.isNotEmpty || event.reasoningDelta.isNotEmpty ||
            event.inputTokens != null || event.outputTokens != null) {
          setState(() {
            final current = _messages[replyIndex];
            _messages[replyIndex] = _ChatMessage(
              text: current.text + event.textDelta,
              mine: false,
              time: current.time,
              reasoning: (current.reasoning ?? '') + event.reasoningDelta,
              isTyping: !event.finished,
              inputTokens: event.inputTokens ?? current.inputTokens,
              outputTokens: event.outputTokens ?? current.outputTokens,
            );
          });
        }
        if (event.finished) {
          setState(() {
            final current = _messages[replyIndex];
            _messages[replyIndex] = _ChatMessage(
              text: current.text,
              mine: false,
              time: current.time,
              reasoning: current.reasoning,
              inputTokens: current.inputTokens,
              outputTokens: current.outputTokens,
              imagePath: current.imagePath,
            );
          });
        }
      }
      await _persistChat();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    } catch (error) {
      if (!mounted) return;
      final cancelled = (error is DioException && CancelToken.isCancel(error)) || cancelToken.isCancelled;
      setState(() {
        final typingIndex = _messages.lastIndexWhere((message) => message.isTyping);
        if (typingIndex >= 0) {
          final current = _messages[typingIndex];
          if (current.text.trim().isEmpty && (current.reasoning ?? '').trim().isEmpty) {
            _messages.removeAt(typingIndex);
          } else {
            _messages[typingIndex] = _ChatMessage(
              text: current.text,
              mine: current.mine,
              time: current.time,
              reasoning: current.reasoning,
              inputTokens: current.inputTokens,
              outputTokens: current.outputTokens,
            );
          }
        }
        if (!cancelled) {
          _messages.add(_ChatMessage(
            text: '连接没有成功：${error.toString().replaceFirst('Exception: ', '')}',
            mine: false,
            isSystem: true,
            time: DateTime.now(),
          ));
        }
      });
      await _persistChat();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    } finally {
      _activeCancelToken = null;
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _retryLastUserMessage() async {
    if (_sending) return;
    final userIndex = _messages.lastIndexWhere((message) => message.mine && !message.isSystem);
    if (userIndex < 0) return;
    final failedMessage = _messages[userIndex];
    final text = failedMessage.text;
    setState(() {
      _messages.removeWhere((message) => message.isSystem && message.text.startsWith('连接没有成功：'));
      _messages.removeAt(userIndex);
      _input.text = text;
      _pendingImagePath = failedMessage.imagePath;
    });
    await _saveDraft(text);
    await _send();
  }

  void _stopGeneration() {
    _activeCancelToken?.cancel('用户停止生成');
  }

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return '今天 · ${['周一', '周二', '周三', '周四', '周五', '周六', '周日'][date.weekday - 1]}';
    }
    return '${date.month}月${date.day}日';
  }

  String _clock(DateTime date) =>
      '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ChatPreferences>(
      valueListenable: ChatPreferenceStore.value,
      builder: (context, prefs, _) => Scaffold(
        drawer: const AppSideDrawer(active: 'chat'),
        drawerEnableOpenDragGesture: false,
        backgroundColor: const Color(0xFFF7F8F7),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              if (_searching) _buildSearchBar(),
              Expanded(child: _buildMessages(prefs)),
              _buildComposer(prefs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => Builder(builder: (scaffoldContext) => Padding(
    padding: const EdgeInsets.fromLTRB(13, 8, 13, 9),
    child: Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .88),
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE9E9E8)),
        boxShadow: [BoxShadow(color: const Color(0xFF333333).withValues(alpha: .035), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        IconButton(
          tooltip: '打开侧栏',
          onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
          icon: const Icon(Icons.menu_rounded, size: 20, color: AppColors.secondary),
        ),
        IconButton(
          tooltip: '返回',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.secondary),
        ),
        const Spacer(),
        const CircleAvatar(
          radius: 17,
          backgroundColor: Color(0xFFE9E3EA),
          child: Text('祁', style: TextStyle(color: Color(0xFF665A67), fontSize: 13)),
        ),
        const SizedBox(width: 9),
        const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('宋祁', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
            SizedBox(height: 3),
            Row(children: [
              Icon(Icons.circle, size: 6, color: Color(0xFF8DAA91)),
              SizedBox(width: 4),
              Text('在线', style: TextStyle(fontSize: 10, color: AppColors.muted)),
            ]),
          ],
        ),
        const Spacer(),
        IconButton(
          tooltip: '搜索聊天',
          onPressed: () => setState(() {
            _searching = !_searching;
            _query = '';
            _search.clear();
          }),
          icon: Icon(_searching ? Icons.close_rounded : Icons.search_rounded, size: 20, color: AppColors.secondary),
        ),
        PopupMenuButton<String>(
          tooltip: '更多',
          icon: const Icon(Icons.more_horiz_rounded, color: AppColors.secondary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) {
            if (value == 'settings') context.push('/chat/settings');
            if (value == 'latest') FocusScope.of(context).unfocus();
            if (value == 'clear') {
              _confirmClear();
            }
            if (value == 'search') setState(() => _searching = true);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'search', child: Text('搜索聊天记录')),
            PopupMenuItem(value: 'settings', child: Text('聊天设置')),
            PopupMenuItem(value: 'latest', child: Text('回到最新消息')),
            PopupMenuItem(value: 'clear', child: Text('清空对话')),
          ],
        ),
      ]),
    ),
  ));

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
    child: TextField(
      controller: _search,
      onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
      decoration: InputDecoration(
        hintText: '搜索聊天记录…',
        prefixIcon: const Icon(Icons.search_rounded, size: 19),
        suffixIcon: IconButton(onPressed: () { _search.clear(); setState(() => _query = ''); }, icon: const Icon(Icons.close_rounded, size: 18)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: Color(0xFFE9E9E8))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: Color(0xFFE9E9E8))),
      ),
    ),
  );

  Widget _buildMessages(ChatPreferences prefs) {
    if (_loadingHistory) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final visible = _messages.asMap().entries.where((entry) =>
      _query.isEmpty || entry.value.text.toLowerCase().contains(_query)).toList();
    if (visible.isEmpty) {
      return Center(child: Text(_query.isEmpty ? '还没有消息，在下面写一句吧。' : '没有找到相关消息', style: const TextStyle(color: AppColors.muted, fontSize: 13)));
    }
    return Stack(
      children: [
        ListView.builder(
      reverse: false,
      padding: const EdgeInsets.fromLTRB(17, 15, 17, 17),
      controller: _messagesScroll,
      physics: const BouncingScrollPhysics(),
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final originalIndex = visible[index].key;
        final message = visible[index].value;
        final previous = originalIndex > 0 ? _messages[originalIndex - 1] : null;
        final gap = previous == null ? const Duration(days: 1) : message.time.difference(previous.time);
        final sameGroup = !message.isSystem && previous != null && !previous.isSystem && prefs.compact && previous.mine == message.mine && gap >= Duration.zero && gap < const Duration(minutes: 5);
        final dayChanged = previous == null || previous.time.day != message.time.day || previous.time.month != message.time.month || previous.time.year != message.time.year;
        final showTime = prefs.showTime && (dayChanged || gap > const Duration(minutes: 5));
        return Column(children: [
          if (showTime) Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 17),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .8), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFEAE9E8))),
              child: Text(dayChanged ? _dayLabel(message.time) : _clock(message.time), style: const TextStyle(fontSize: 10, letterSpacing: .3, color: AppColors.muted)),
            ),
          ),
          message.isSystem
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 18),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(message.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.5, color: AppColors.muted)),
                    if (message.text.startsWith('连接没有成功：'))
                      TextButton.icon(
                        onPressed: _retryLastUserMessage,
                        icon: const Icon(Icons.refresh_rounded, size: 15),
                        label: const Text('重试这条消息', style: TextStyle(fontSize: 11)),
                        style: TextButton.styleFrom(foregroundColor: AppColors.secondary, visualDensity: VisualDensity.compact),
                      ),
                  ]),
                )
              : _messageRow(message, prefs, sameGroup),
        ]);
      },
    ),
        if (_showJumpLatest)
          Positioned(
            right: 18,
            bottom: 18,
            child: Material(
              color: Colors.white,
              elevation: 3,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _scrollToLatest,
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(Icons.keyboard_double_arrow_down_rounded, color: AppColors.secondary, size: 21),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _messageRow(_ChatMessage message, ChatPreferences prefs, bool compact) {
    final mine = message.mine;
    final avatar = CircleAvatar(
      radius: 17,
      backgroundColor: mine ? const Color(0xFFF0E8EE) : const Color(0xFFE9E3EA),
      child: Text(mine ? '我' : '祁', style: const TextStyle(fontSize: 11, color: Color(0xFF746A75))),
    );
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 7 : 17),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!mine && prefs.showAvatar) ...[
            SizedBox(width: 34, child: compact ? const SizedBox.shrink() : avatar),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 310),
              child: Column(
                crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!mine && prefs.showName && !compact)
                    const Padding(
                      padding: EdgeInsets.only(left: 2, bottom: 5),
                      child: Text('宋祁', style: TextStyle(fontSize: 11, color: AppColors.muted)),
                    ),
                  GestureDetector(
                    onLongPress: () => _showMessageActions(message),
                    child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: mine ? const Color(0xFFEDE5F0) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(!mine && !compact ? 5 : 17),
                        topRight: Radius.circular(mine && !compact ? 5 : 17),
                        bottomLeft: const Radius.circular(17),
                        bottomRight: const Radius.circular(17),
                      ),
                      border: Border.all(color: const Color(0xFFEAE7E9), width: .65),
                      boxShadow: [BoxShadow(color: const Color(0xFF303030).withValues(alpha: .025), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: message.isTyping && message.text.isEmpty
                        ? const SizedBox(width: 34, height: 17, child: Center(child: Text('···', style: TextStyle(fontSize: 20, letterSpacing: 2, color: AppColors.muted))))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (message.imagePath != null && File(message.imagePath!).existsSync())
                                GestureDetector(
                                  onTap: () => _showFullImage(message.imagePath!),
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: message.text.isNotEmpty ? 8 : 0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11),
                                      child: Image.file(
                                        File(message.imagePath!),
                                        width: 220,
                                        height: 220,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const SizedBox(
                                          width: 180, height: 90,
                                          child: Center(child: Text('图片暂时无法显示', style: TextStyle(fontSize: 11, color: AppColors.muted))),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              if (message.text.isNotEmpty)
                                Text(message.text, style: TextStyle(fontSize: prefs.fontSize, height: 1.55, color: AppColors.ink)),
                            ],
                          ),
                    ),
                  ),
                  if (message.isTyping && (message.reasoning ?? '').trim().isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 6, left: 3),
                      child: Text('正在思考…', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                    ),
                  if ((message.reasoning ?? '').trim().isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 7),
                      constraints: const BoxConstraints(maxWidth: 300),
                      decoration: BoxDecoration(color: const Color(0xFFF4F2F4), borderRadius: BorderRadius.circular(12)),
                      child: Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          dense: true,
                          tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                          childrenPadding: const EdgeInsets.fromLTRB(11, 0, 11, 11),
                          title: const Text('思考过程 · 服务商返回', style: TextStyle(fontSize: 10, color: AppColors.muted)),
                          children: [Text(message.reasoning!, style: const TextStyle(fontSize: 11, height: 1.5, color: AppColors.secondary))],
                        ),
                      ),
                    ),
                  if (!compact)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 3, right: 3),
                      child: Text(_clock(message.time), style: const TextStyle(fontSize: 9, color: Color(0xFFB1B0B1))),
                    ),
                ],
              ),
            ),
          ),
          if (mine && prefs.showAvatar) ...[
            const SizedBox(width: 8),
            SizedBox(width: 34, child: compact ? const SizedBox.shrink() : avatar),
          ],
        ],
      ),
    );
  }

  Future<void> _showMessageActions(_ChatMessage message) async {
    if (message.isTyping || message.isSystem ||
        (message.text.isEmpty && message.imagePath == null)) {
      return;
    }
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 18),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('复制消息'),
              onTap: () => Navigator.pop(sheetContext, 'copy'),
            ),
            if (message.mine)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('编辑并重新发送'),
                onTap: () => Navigator.pop(sheetContext, 'edit'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFB65B5B)),
              title: const Text('删除消息', style: TextStyle(color: Color(0xFFB65B5B))),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
          ]),
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: message.text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
    } else if (action == 'delete') {
      setState(() => _messages.remove(message));
      await _persistChat();
    } else if (action == 'edit' && message.mine) {
      final controller = TextEditingController(text: message.text);
      final edited = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('编辑消息'),
          content: TextField(controller: controller, autofocus: true, minLines: 1, maxLines: 5),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
            TextButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('重新发送')),
          ],
        ),
      );
      controller.dispose();
      if (edited != null && edited.isNotEmpty && mounted) {
        setState(() {
          _messages.remove(message);
          _input.text = edited;
        });
        await _saveDraft(edited);
        await _send();
      }
    }
  }

  Widget _buildComposer(ChatPreferences prefs) => Container(
    padding: EdgeInsets.fromLTRB(14, 9, 14, 10 + MediaQuery.paddingOf(context).bottom),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      border: const Border(top: BorderSide(color: Color(0xFFEAE9E8))),
      boxShadow: [BoxShadow(color: const Color(0xFF333333).withValues(alpha: .025), blurRadius: 12, offset: const Offset(0, -3))],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (_pendingImagePath != null)
        Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: const Color(0xFFF7F5F6), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFECE8EB))),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(9), child: Image.file(File(_pendingImagePath!), width: 58, height: 58, fit: BoxFit.cover)),
            const SizedBox(width: 10),
            const Expanded(child: Text('图片已准备好', style: TextStyle(fontSize: 12, color: AppColors.secondary))),
            IconButton(visualDensity: VisualDensity.compact, tooltip: '移除图片', onPressed: () => setState(() => _pendingImagePath = null), icon: const Icon(Icons.close_rounded, size: 18)),
          ]),
        ),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final word in ['在吗', '抱抱', '晚安'])
            Padding(
              padding: const EdgeInsets.only(right: 7),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _send(word),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFFF7F5F6), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFECE8EB))),
                  child: Text(word, style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 9),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: _showAttachmentHint,
          icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.secondary, size: 23),
        ),
        Expanded(
          child: TextField(
            controller: _input,
            onChanged: (value) => unawaited(_saveDraft(value)),
            minLines: 1,
            maxLines: 4,
            textInputAction: prefs.enterSend ? TextInputAction.send : TextInputAction.newline,
            onSubmitted: prefs.enterSend ? (_) => _send() : null,
            decoration: InputDecoration(
              hintText: '输入一条信息',
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
              filled: true,
              fillColor: const Color(0xFFF5F4F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(22), borderSide: const BorderSide(color: AppColors.accent, width: .8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.ink,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: _sending ? _stopGeneration : _send,
            child: SizedBox(
              width: 41,
              height: 41,
              child: Icon(_sending ? Icons.stop_rounded : Icons.arrow_upward_rounded, color: Colors.white, size: 19),
            ),
          ),
        ),
      ]),
    ]),
  );

  void _scrollToLatest() {
    if (!_messagesScroll.hasClients) return;
    _messagesScroll.animateTo(
      _messagesScroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _confirmClear() async {
    if (_sending) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('回复完成后再清空聊天记录')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空聊天记录？'),
        content: const Text('这会删除本机保存的聊天记录，无法撤销。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('清空')),
        ],
      ),
    );
    if (confirmed == true) {
      setState(_messages.clear);
      await ChatMessageStore.clear();
    }
  }

  void _showAttachmentHint() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.image_outlined, color: AppColors.secondary),
            title: const Text('从相册选择图片'),
            subtitle: const Text('支持图片理解的模型可读取图片内容'),
            onTap: () {
              Navigator.pop(sheetContext);
              _pickImage();
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 84,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (picked == null || !mounted) return;
      final source = File(picked.path);
      final size = await source.length();
      if (size > 8 * 1024 * 1024) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('图片仍然太大，请选择 8 MB 以内的图片')),
          );
        }
        return;
      }
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/chat_media');
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      final extension = picked.path.contains('.')
          ? picked.path.split('.').last.toLowerCase()
          : 'jpg';
      final target = File('${mediaDir.path}/image_${DateTime.now().microsecondsSinceEpoch}.$extension');
      await source.copy(target.path);
      if (!mounted) return;
      setState(() => _pendingImagePath = target.path);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择图片失败：$error')),
        );
      }
    }
  }

  void _showFullImage(String path) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(children: [
          Center(child: InteractiveViewer(minScale: .7, maxScale: 4, child: Image.file(File(path), fit: BoxFit.contain))),
          Positioned(top: 4, right: 4, child: IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close_rounded, color: Colors.white))),
        ]),
      ),
    );
  }
}
