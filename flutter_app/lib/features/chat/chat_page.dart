import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
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
  });
  final String text;
  final bool mine;
  final DateTime time;
  final String? reasoning;
  final bool isSystem;
  final bool isTyping;
  final int? inputTokens;
  final int? outputTokens;
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
  final List<_ChatMessage> _messages = [];
  bool _searching = false;
  bool _loadingHistory = true;
  bool _sending = false;
  CancelToken? _activeCancelToken;
  String _query = '';

  @override
  void initState() {
    super.initState();
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
    )).toList(),
  );

  @override
  void dispose() {
    _input.dispose();
    _search.dispose();
    _messagesScroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? quickText]) async {
    if (_sending) return;
    final value = (quickText ?? _input.text).trim();
    if (value.isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: value, mine: true, time: DateTime.now()));
      _input.clear();
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

      final history = _messages
          .where((message) => !message.isSystem && !message.isTyping && message.text.trim().isNotEmpty)
          .toList()
          .reversed
          .take(20)
          .toList()
          .reversed
          .map((message) => <String, dynamic>{
            'role': message.mine ? 'user' : 'assistant',
            'content': message.text,
          }).toList();

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
            );
          });
        }
      }
      await _persistChat();
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToLatest());
    } catch (error) {
      if (!mounted) return;
      final cancelled = CancelToken.isCancel(error) || cancelToken.isCancelled;
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
    return ListView.builder(
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
                  child: Text(message.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, height: 1.5, color: AppColors.muted)),
                )
              : _messageRow(message, prefs, sameGroup),
        ]);
      },
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
                  Container(
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
                        : Text(message.text, style: TextStyle(fontSize: prefs.fontSize, height: 1.55, color: AppColors.ink)),
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
                          title: const Text('思考过程', style: TextStyle(fontSize: 10, color: AppColors.muted)),
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

  Widget _buildComposer(ChatPreferences prefs) => Container(
    padding: EdgeInsets.fromLTRB(14, 9, 14, 10 + MediaQuery.paddingOf(context).bottom),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .94),
      border: const Border(top: BorderSide(color: Color(0xFFEAE9E8))),
      boxShadow: [BoxShadow(color: const Color(0xFF333333).withValues(alpha: .025), blurRadius: 12, offset: const Offset(0, -3))],
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
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
          onPressed: () => _showAttachmentHint(),
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
      builder: (context) => const SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 8, 22, 28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(leading: Icon(Icons.image_outlined), title: Text('图片与文件'), subtitle: Text('附件选择功能将在媒体模块迁移时接入')),
          ]),
        ),
      ),
    );
  }
}
