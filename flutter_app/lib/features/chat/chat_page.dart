import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:gal/gal.dart';
import 'package:webview_flutter/webview_flutter.dart';
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
    this.attachmentPath,
    this.attachmentName,
    this.attachmentSize,
    this.alternateReplies = const [],
    this.selectedAlternative = 0,
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
  final String? attachmentPath;
  final String? attachmentName;
  final int? attachmentSize;
  final List<String> alternateReplies;
  final int selectedAlternative;
}

Color _mineBubbleColor(int style) => style == 1 ? const Color(0xFF202020) : const Color(0xFF171717);

Color _partnerBubbleColor(int style) => style == 1 ? const Color(0xFFF0F0F0) : const Color(0xFFF4F4F4);

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.tooltip, required this.onTap});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 20, color: const Color(0xFF666666))),
    ),
  );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _search = TextEditingController();
  final _messagesScroll = ScrollController();
  final _api = ChatApiClient();
  final _imagePicker = ImagePicker();
  String? _pendingImagePath;
  String? _pendingFilePath;
  String? _pendingFileName;
  int? _pendingFileSize;
  final List<_ChatMessage> _messages = [];
  bool _searching = false;
  bool _loadingHistory = true;
  bool _sending = false;
  bool _showJumpLatest = false;
  CancelToken? _activeCancelToken;
  String _query = '';
  DateTime? _selectedDay;

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
          attachmentPath: message.attachmentPath,
          attachmentName: message.attachmentName,
          attachmentSize: message.attachmentSize,
          alternateReplies: message.alternateReplies,
          selectedAlternative: message.selectedAlternative,
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
      attachmentPath: message.attachmentPath,
      attachmentName: message.attachmentName,
      attachmentSize: message.attachmentSize,
      alternateReplies: message.alternateReplies,
      selectedAlternative: message.selectedAlternative,
    )).toList(),
  );

  void _handleScroll() {
    if (!_messagesScroll.hasClients) return;
    final shouldShow = _messagesScroll.position.pixels < _messagesScroll.position.maxScrollExtent - 180;
    if (shouldShow != _showJumpLatest && mounted) setState(() => _showJumpLatest = shouldShow);
  }

  @override
  void dispose() {
    _activeCancelToken?.cancel('聊天页面已关闭');
    _messagesScroll.removeListener(_handleScroll);
    _input.dispose();
    _inputFocus.dispose();
    _search.dispose();
    _messagesScroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? quickText]) async {
    if (_sending) return;
    final value = (quickText ?? _input.text).trim();
    final imagePath = quickText == null ? _pendingImagePath : null;
    final attachmentPath = quickText == null ? _pendingFilePath : null;
    final attachmentName = quickText == null ? _pendingFileName : null;
    final attachmentSize = quickText == null ? _pendingFileSize : null;
    if (value.isEmpty && imagePath == null && attachmentPath == null) return;
    setState(() {
      _messages.add(_ChatMessage(text: value, mine: true, time: DateTime.now(), imagePath: imagePath, attachmentPath: attachmentPath, attachmentName: attachmentName, attachmentSize: attachmentSize));
      _input.clear();
      _pendingImagePath = null;
      _pendingFilePath = null;
      _pendingFileName = null;
      _pendingFileSize = null;
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
              (message.text.trim().isNotEmpty || message.imagePath != null || message.attachmentPath != null))
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
        } else if (message.attachmentPath != null && await File(message.attachmentPath!).exists()) {
          final file = File(message.attachmentPath!);
          final extension = message.attachmentName?.split('.').last.toLowerCase() ?? '';
          const readable = {'txt', 'md', 'csv', 'json', 'xml', 'yaml', 'yml', 'log'};
          if (readable.contains(extension)) {
            final content = await file.readAsString();
            history.add({'role': message.mine ? 'user' : 'assistant', 'content': '${message.text.isEmpty ? '' : '${message.text}\n'}[附件：${message.attachmentName}]\n$content'});
          } else {
            history.add({'role': message.mine ? 'user' : 'assistant', 'content': '${message.text.isEmpty ? '' : '${message.text}\n'}[用户附加了文件：${message.attachmentName}。当前接口适配层尚未解析此文件格式。]'});
          }
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
          _followStreamingReply();
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
              attachmentPath: current.attachmentPath,
              attachmentName: current.attachmentName,
              attachmentSize: current.attachmentSize,
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
      _pendingFilePath = failedMessage.attachmentPath;
      _pendingFileName = failedMessage.attachmentName;
      _pendingFileSize = failedMessage.attachmentSize;
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
        backgroundColor: const Color(0xFFFAFAFA),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(prefs),
              if (_searching) _buildSearchBar(),
              if (_selectedDay != null) _buildDayFilterBar(),
              Expanded(child: _buildMessages(prefs)),
              _buildComposer(prefs),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ChatPreferences prefs) => Builder(builder: (scaffoldContext) => Container(
    height: 66,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: const BoxDecoration(
      color: Color(0xFFFAFAFA),
      border: Border(bottom: BorderSide(color: Color(0xFFE7E7E7))),
    ),
    child: Row(children: [
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
          child: const SizedBox(
            width: 42, height: 42,
            child: Icon(Icons.menu_rounded, size: 22, color: Color(0xFF333333)),
          ),
        ),
      ),
      const Spacer(),
      Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: 19,
          backgroundColor: const Color(0xFFEAEAEA),
          backgroundImage: prefs.partnerAvatarPath != null && File(prefs.partnerAvatarPath!).existsSync()
              ? FileImage(File(prefs.partnerAvatarPath!))
              : null,
          child: prefs.partnerAvatarPath != null && File(prefs.partnerAvatarPath!).existsSync()
              ? null
              : Text(
                  prefs.partnerName.trim().isEmpty ? '祁' : prefs.partnerName.trim().substring(0, 1),
                  style: const TextStyle(color: Color(0xFF444444), fontSize: 15, fontWeight: FontWeight.w600),
                ),
        ),
        const SizedBox(width: 9),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(prefs.partnerName.trim().isEmpty ? '宋祁' : prefs.partnerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF202020))),
            const SizedBox(height: 3),
            const Row(children: [
              Icon(Icons.circle, size: 6, color: Color(0xFF555555)),
              SizedBox(width: 5),
              Text('在这里陪你', style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
            ]),
          ],
        ),
      ]),
      const Spacer(),
      _HeaderAction(
        icon: _searching ? Icons.close_rounded : Icons.search_rounded,
        tooltip: '搜索聊天',
        onTap: () => setState(() {
          _searching = !_searching;
          _query = '';
          _search.clear();
        }),
      ),
      const SizedBox(width: 7),
      PopupMenuButton<String>(
        tooltip: '更多',
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF666666), size: 23),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onSelected: (value) {
          if (value == 'settings') context.push('/chat/settings');
          if (value == 'latest') {
            FocusScope.of(context).unfocus();
            _scrollToLatest();
          }
          if (value == 'clear') _confirmClear();
          if (value == 'search') setState(() => _searching = true);
          if (value == 'date') _chooseChatDate();
          if (value == 'all') setState(() => _selectedDay = null);
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: 'search', child: Text('搜索聊天记录')),
          PopupMenuItem(value: 'date', child: Text('按日期查看')),
          PopupMenuItem(value: 'all', child: Text('显示全部消息')),
          PopupMenuItem(value: 'settings', child: Text('聊天设置')),
          PopupMenuItem(value: 'latest', child: Text('回到最新消息')),
          PopupMenuItem(value: 'clear', child: Text('清空对话')),
        ],
      ),
    ]),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: Color(0xFFE7E7E7))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(17), borderSide: const BorderSide(color: Color(0xFFE7E7E7))),
      ),
    ),
  );

  Widget _buildDayFilterBar() {
    final day = _selectedDay!;
    final count = _messages.where((message) =>
      message.time.year == day.year &&
      message.time.month == day.month &&
      message.time.day == day.day).length;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Row(children: [
        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF777777)),
        const SizedBox(width: 8),
        Expanded(child: Text(
          '${day.year}年${day.month}月${day.day}日 · $count 条消息',
          style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
        )),
        InkWell(
          onTap: () => setState(() => _selectedDay = null),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF888888)),
          ),
        ),
      ]),
    );
  }

  Future<void> _chooseChatDate() async {
    final dates = _messages.map((message) => message.time).toList();
    dates.sort();
    final earliest = dates.isEmpty
        ? DateTime(2000)
        : DateTime(dates.first.year, dates.first.month, dates.first.day);
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay ?? (dates.isEmpty ? now : dates.last),
      firstDate: earliest.isAfter(now) ? now : earliest,
      lastDate: now,
      helpText: '选择要查看的聊天日期',
      cancelText: '取消',
      confirmText: '查看',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF222222),
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF222222),
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDay = DateTime(picked.year, picked.month, picked.day);
      _searching = false;
      _query = '';
      _search.clear();
    });
  }

  String _searchableText(_ChatMessage message) => [
    message.text,
    message.reasoning ?? '',
    message.attachmentName ?? '',
    message.isSystem ? '系统消息' : '',
    message.imagePath != null ? '图片 image' : '',
    message.attachmentPath != null ? '文件 附件 file' : '',
  ].join(' ').toLowerCase();

  Widget _buildMessages(ChatPreferences prefs) {
    if (_loadingHistory) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
    }
    final visible = _messages.asMap().entries.where((entry) {
      final dayMatches = _selectedDay == null ||
          (entry.value.time.year == _selectedDay!.year &&
           entry.value.time.month == _selectedDay!.month &&
           entry.value.time.day == _selectedDay!.day);
      return dayMatches && (_query.isEmpty || _searchableText(entry.value).contains(_query));
    }).toList();
    if (visible.isEmpty) {
      return Center(child: Text(_selectedDay != null ? '这一天还没有聊天记录' : (_query.isEmpty ? '还没有消息，在下面写一句吧。' : '没有找到相关消息'), style: const TextStyle(color: AppColors.muted, fontSize: 13)));
    }
    return Stack(
      children: [
        ListView.builder(
      reverse: false,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
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
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: .8), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFFE7E7E7))),
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
    final mediaOnly = (message.imagePath != null || message.attachmentPath != null) && message.text.trim().isEmpty;
    final myLabel = prefs.myName.trim().isEmpty ? '我' : prefs.myName.trim();
    final partnerLabel = prefs.partnerName.trim().isEmpty ? '宋祁' : prefs.partnerName.trim();
    final avatarLabel = mine ? myLabel.substring(0, 1) : partnerLabel.substring(0, 1);
    final mineBubble = _mineBubbleColor(prefs.bubbleStyle);
    final partnerBubble = _partnerBubbleColor(prefs.bubbleStyle);
    final isHelloTalk = prefs.bubbleStyle == 0;

    final avatarPath = mine ? prefs.myAvatarPath : prefs.partnerAvatarPath;
    final avatarFile = avatarPath == null ? null : File(avatarPath);
    final avatar = CircleAvatar(
      radius: 17,
      backgroundColor: mine ? const Color(0xFFE6E6E6) : Colors.white,
      backgroundImage: avatarFile != null && avatarFile.existsSync() ? FileImage(avatarFile) : null,
      child: avatarFile != null && avatarFile.existsSync()
          ? null
          : Text(
              avatarLabel,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF555555)),
            ),
    );
    final avatarSlot = SizedBox(
      width: 40,
      child: Align(
        alignment: mine ? Alignment.topRight : Alignment.topLeft,
        child: prefs.showAvatar ? avatar : const SizedBox(width: 34, height: 34),
      ),
    );
    final bubbleRadius = isHelloTalk
        ? BorderRadius.only(
            topLeft: Radius.circular(!mine && !compact ? 8 : 19),
            topRight: Radius.circular(mine && !compact ? 8 : 19),
            bottomLeft: const Radius.circular(19),
            bottomRight: const Radius.circular(19),
          )
        : BorderRadius.only(
            topLeft: const Radius.circular(19),
            topRight: const Radius.circular(19),
            bottomLeft: Radius.circular(mine ? 19 : 6),
            bottomRight: Radius.circular(mine ? 6 : 19),
          );

    final content = Flexible(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .72),
        child: Column(
          crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!mine && prefs.showName && !compact)
              Padding(
                padding: const EdgeInsets.only(left: 2, bottom: 3),
                child: Text(partnerLabel, style: const TextStyle(fontSize: 11, color: Color(0xFF777777), fontWeight: FontWeight.w500)),
              ),
            if (!mine && prefs.showReasoning && message.isTyping && (message.reasoning ?? '').trim().isEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 2, bottom: 5),
                child: Text('正在思考…', style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
              ),
            if (!mine && prefs.showReasoning && (message.reasoning ?? '').trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 1, bottom: 5),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    dense: true,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(left: 2, right: 4, bottom: 7),
                    shape: const Border(),
                    collapsedShape: const Border(),
                    iconColor: const Color(0xFF888888),
                    collapsedIconColor: const Color(0xFFAAAAAA),
                    trailing: const Icon(Icons.keyboard_arrow_down_rounded, size: 15),
                    title: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.psychology_outlined, size: 13, color: Color(0xFF888888)),
                        SizedBox(width: 5),
                        Text('已思考 · 查看过程', style: TextStyle(fontSize: 10, color: Color(0xFF888888), fontWeight: FontWeight.w400)),
                      ],
                    ),
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.only(left: 9, top: 2, bottom: 3),
                        decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: Color(0xFFCCCCCC), width: 1)),
                        ),
                        child: Text(message.reasoning!, style: const TextStyle(fontSize: 11, height: 1.6, color: Color(0xFF777777))),
                      ),
                    ],
                  ),
                ),
              ),
            if (message.imagePath != null && File(message.imagePath!).existsSync())
              GestureDetector(
                onTap: () => _showFullImage(message.imagePath!),
                onLongPress: () => _showMessageActions(message),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.file(
                      File(message.imagePath!),
                      width: 250,
                      height: 250,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox(
                        width: 180, height: 90,
                        child: Center(child: Text('图片暂时无法显示', style: TextStyle(fontSize: 11, color: Color(0xFF777777)))),
                      ),
                    ),
                  ),
                ),
              ),
            if (message.attachmentPath != null)
              GestureDetector(
                onTap: () => _openAttachment(message),
                onLongPress: () => _showMessageActions(message),
                child: _buildAttachmentCard(message),
              ),
            if (message.text.isNotEmpty || message.isTyping)
              GestureDetector(
                onLongPress: () => _showMessageActions(message),
                child: Container(
                  padding: mediaOnly ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
                  decoration: BoxDecoration(
                    color: mediaOnly ? Colors.transparent : (mine ? mineBubble : partnerBubble),
                    borderRadius: bubbleRadius,
                    border: !mine && !mediaOnly && isHelloTalk
                        ? Border.all(color: const Color(0xFFE8E8E8), width: .7)
                        : null,
                    boxShadow: !mediaOnly && isHelloTalk
                        ? [BoxShadow(color: Colors.black.withValues(alpha: .035), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: message.isTyping && message.text.isEmpty
                      ? const SizedBox(
                          width: 34,
                          height: 17,
                          child: Center(child: Text('···', style: TextStyle(fontSize: 20, letterSpacing: 2, color: Color(0xFF777777)))),
                        )
                      : Text(
                          message.text,
                          style: TextStyle(
                            fontSize: prefs.fontSize,
                            height: 1.5,
                            color: mine ? Colors.white : const Color(0xFF222222),
                          ),
                        ),
                ),
              ),
            if (prefs.showTime && !compact)
              Padding(
                padding: const EdgeInsets.only(top: 5, left: 3, right: 3),
                child: Text(_clock(message.time), style: const TextStyle(fontSize: 10, color: Color(0xFF9A9A9A))),
              ),
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.only(top: compact ? 1 : 9, bottom: compact ? 2 : 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: mine
            ? [content, const SizedBox(width: 6), avatarSlot]
            : [avatarSlot, const SizedBox(width: 6), content],
      ),
    );
  }

  Future<void> _showMessageActions(_ChatMessage message) async {
    if (message.isTyping || message.isSystem ||
        (message.text.isEmpty && message.imagePath == null && message.attachmentPath == null)) {
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
            if (message.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('复制消息'),
                onTap: () => Navigator.pop(sheetContext, 'copy'),
              ),
            if (message.mine && message.text.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('编辑并重新发送'),
                onTap: () => Navigator.pop(sheetContext, 'edit'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFF666666)),
              title: const Text('删除消息', style: TextStyle(color: Color(0xFF666666))),
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
    padding: EdgeInsets.fromLTRB(14, 11, 14, 10 + MediaQuery.paddingOf(context).bottom),
    decoration: const BoxDecoration(
      color: Color(0xFFFAFAFA),
      border: Border(top: BorderSide(color: Color(0xFFE7E7E7))),
    ),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (_pendingImagePath != null)
        Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7E7E7))),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_pendingImagePath!), width: 58, height: 58, fit: BoxFit.cover)),
            const SizedBox(width: 10),
            const Expanded(child: Text('图片已准备好', style: TextStyle(fontSize: 12, color: Color(0xFF666666)))),
            IconButton(visualDensity: VisualDensity.compact, tooltip: '移除图片', onPressed: () => setState(() => _pendingImagePath = null), icon: const Icon(Icons.close_rounded, size: 18)),
          ]),
        ),
      if (_pendingFilePath != null)
        Container(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFE7E7E7))),
          child: Row(children: [
            Container(width: 35, height: 38, decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.insert_drive_file_outlined, size: 19, color: Color(0xFF444444))),
            const SizedBox(width: 9),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_pendingFileName ?? '附件', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF333333))),
              Text(_formatFileSize(_pendingFileSize ?? 0), style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
            ])),
            IconButton(visualDensity: VisualDensity.compact, tooltip: '移除文件', onPressed: () => setState(() {
              _pendingFilePath = null; _pendingFileName = null; _pendingFileSize = null;
            }), icon: const Icon(Icons.close_rounded, size: 18)),
          ]),
        ),
      if (prefs.quickReplies.isNotEmpty)
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: prefs.quickReplies.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final phrase = prefs.quickReplies[index];
              return Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    _input.value = TextEditingValue(
                      text: phrase,
                      selection: TextSelection.collapsed(offset: phrase.length),
                    );
                    unawaited(_saveDraft(phrase));
                    FocusScope.of(context).requestFocus(_inputFocus);
                  },
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE7E7E7)),
                    ),
                    child: Text(phrase, style: const TextStyle(fontSize: 11, color: Color(0xFF666666))),
                  ),
                ),
              );
            },
          ),
        ),
      if (prefs.quickReplies.isNotEmpty) const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: const Color(0xFFE7E7E7)),
          boxShadow: [BoxShadow(color: const Color(0xFF666666).withValues(alpha: .045), blurRadius: 18, offset: const Offset(0, 5))],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Material(
            color: const Color(0xFFF3F3F3),
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: _showAttachmentHint,
              child: const SizedBox(width: 42, height: 42, child: Icon(Icons.add_rounded, color: Color(0xFF444444), size: 23)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: TextField(
                controller: _input,
                focusNode: _inputFocus,
                onChanged: (value) => unawaited(_saveDraft(value)),
                minLines: 1,
                maxLines: 5,
                textInputAction: prefs.enterSend ? TextInputAction.send : TextInputAction.newline,
                onSubmitted: prefs.enterSend ? (_) => _send() : null,
                decoration: const InputDecoration(
                  hintText: '说点什么吧…',
                  hintStyle: TextStyle(color: Color(0xFF999999), fontSize: 14),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 11),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 7),
          Material(
            color: const Color(0xFF333333),
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: _sending ? _stopGeneration : _send,
              child: SizedBox(
                width: 42, height: 42,
                child: Icon(_sending ? Icons.stop_rounded : Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ]),
      ),
    ]),
  );

  void _scrollToLatest() {
    if (!_messagesScroll.hasClients) return;
    _messagesScroll.animateTo(
      _messagesScroll.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    ).then((_) {
      if (mounted && _showJumpLatest) setState(() => _showJumpLatest = false);
    });
  }

  void _followStreamingReply() {
    if (_showJumpLatest) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _showJumpLatest || !_messagesScroll.hasClients) return;
      _messagesScroll.jumpTo(_messagesScroll.position.maxScrollExtent);
    });
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
          padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.image_outlined, color: AppColors.secondary),
              title: const Text('从相册选择图片'),
              subtitle: const Text('图片会单独显示，不放进聊天气泡'),
              onTap: () { Navigator.pop(sheetContext); _pickImage(); },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.attach_file_rounded, color: AppColors.secondary),
              title: const Text('选择文件'),
              subtitle: const Text('支持文档、文本、表格及其他常见文件，单个最大 15 MB'),
              onTap: () { Navigator.pop(sheetContext); _pickFile(); },
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: false,
      );
      if (result == null || result.files.isEmpty || !mounted) return;
      final picked = result.files.single;
      final sourcePath = picked.path;
      if (sourcePath == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('无法读取这个文件')));
        return;
      }
      if (picked.size > 15 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('文件太大，请选择 15 MB 以内的文件')));
        return;
      }
      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/chat_media');
      if (!await mediaDir.exists()) await mediaDir.create(recursive: true);
      final extension = picked.name.contains('.') ? picked.name.split('.').last.toLowerCase() : 'bin';
      final target = File('${mediaDir.path}/file_${DateTime.now().microsecondsSinceEpoch}.$extension');
      await File(sourcePath).copy(target.path);
      if (!mounted) return;
      setState(() {
        _pendingFilePath = target.path;
        _pendingFileName = picked.name;
        _pendingFileSize = picked.size;
        _pendingImagePath = null;
      });
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('选择文件失败：$error')));
    }
  }

  Widget _buildAttachmentCard(_ChatMessage message) {
    final name = message.attachmentName ?? '附件';
    final ext = name.contains('.') ? name.split('.').last.toUpperCase() : 'FILE';
    return Container(
      width: 238,
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Row(children: [
        Container(
          width: 39, height: 43,
          decoration: BoxDecoration(color: const Color(0xFFEAEAEA), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.insert_drive_file_outlined, color: Color(0xFF444444), size: 21),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.35, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
          const SizedBox(height: 4),
          Text('$ext · ${_formatFileSize(message.attachmentSize ?? 0)}', style: const TextStyle(fontSize: 9, color: Color(0xFF999999))),
        ])),
        const Icon(Icons.open_in_new_rounded, size: 15, color: Color(0xFF999999)),
      ]),
    );
  }

  Future<void> _openAttachment(_ChatMessage message) async {
    final path = message.attachmentPath;
    if (path == null || !await File(path).exists()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('附件文件不存在')));
      return;
    }
    await OpenFilex.open(path);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
      setState(() {
        _pendingImagePath = target.path;
        _pendingFilePath = null;
        _pendingFileName = null;
        _pendingFileSize = null;
      });
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
