import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:gal/gal.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:record/record.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_side_drawer.dart';
import 'chat_preferences.dart';
import 'chat_api_client.dart';
import 'chat_message.dart';
import 'chat_message_store.dart';
import 'chat_document_generator.dart';

String _resolveWorldbookContext(String raw, String conversationContext) {
  try {
    final decoded = jsonDecode(raw);
    dynamic entries;
    if (decoded is Map) {
      final characterBook = decoded['character_book'];
      final data = decoded['data'];
      if (decoded['entries'] != null) {
        entries = decoded['entries'];
      } else if (decoded['worldbook'] != null) {
        entries = decoded['worldbook'];
      } else if (data is Map && data['entries'] != null) {
        entries = data['entries'];
      } else if (characterBook is Map) {
        entries = characterBook['entries'];
      }
    } else if (decoded is List) {
      entries = decoded;
    }
    final values = entries is Map
        ? entries.values.whereType<Map>().toList()
        : entries is List
            ? entries.whereType<Map>().toList()
            : <Map>[];
    final context = conversationContext.toLowerCase();
    final selected = <String>[];
    for (final entry in values) {
      if (entry['enabled'] == false || entry['disable'] == true) continue;
      final content = (entry['content'] ?? '').toString().trim();
      if (content.isEmpty) continue;
      final primary = _worldbookKeywords(entry['key'] ?? entry['keys']);
      final secondary = _worldbookKeywords(entry['keysecondary'] ?? entry['secondary_keys']);
      final constant = entry['constant'] == true || entry['always_active'] == true;
      final primaryMatch = primary.isNotEmpty && primary.any((word) => context.contains(word.toLowerCase()));
      final secondaryMatch = secondary.isEmpty || secondary.any((word) => context.contains(word.toLowerCase()));
      if (!constant && !(primaryMatch && secondaryMatch)) continue;
      final title = (entry['comment'] ?? entry['name'] ?? '').toString().trim();
      selected.add('[${title.isEmpty ? '世界书设定' : title}]\n$content');
      if (selected.join('\n\n').length >= 10000) break;
    }
    if (selected.isEmpty) return '';
    final combined = selected.join('\n\n');
    return combined.length > 10000 ? combined.substring(0, 10000) : combined;
  } catch (_) {
    return '';
  }
}

List<String> _worldbookKeywords(dynamic value) {
  if (value is List) {
    return value.map((item) => item.toString().trim()).where((item) => item.isNotEmpty).toList();
  }
  if (value is String) {
    return value.split(RegExp(r'[,，;；\\n]')).map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
  }
  return const [];
}

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
    this.stickerUrl,
    this.audioPath,
    this.audioDurationMs,
    this.attachmentPath,
    this.attachmentName,
    this.attachmentSize,
    this.alternateReplies = const [],
    this.selectedAlternative = 0,
    this.replyToText,
    this.replyToMine,
    this.replyLayoutOverride,
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
  final String? stickerUrl;
  final String? audioPath;
  final int? audioDurationMs;
  final String? attachmentPath;
  final String? attachmentName;
  final int? attachmentSize;
  final List<String> alternateReplies;
  final int selectedAlternative;
  final String? replyToText;
  final bool? replyToMine;
  final int? replyLayoutOverride;
}

// Read and encode image attachments away from the UI isolate so large images
// do not freeze scrolling, typing, or the streaming response animation.
Future<String> _encodeImageFileForRequest(String path) async {
  final bytes = await File(path).readAsBytes();
  return base64Encode(bytes);
}

class _GeneratedTextArtifact {
  const _GeneratedTextArtifact({
    required this.fileName,
    required this.content,
    required this.message,
  });

  final String fileName;
  final String content;
  final String message;
}

_GeneratedTextArtifact? _extractGeneratedTextArtifact(String response) {
  // Only accept explicitly named, UTF-8 text artifacts. Binary Office/PDF
  // formats need real format encoders and must never be faked with text files.
  const supportedExtensions = {
    'html', 'htm', 'txt', 'md', 'markdown', 'csv', 'json', 'xml',
    'yaml', 'yml', 'log', 'css', 'js', 'mjs', 'ts', 'tsx', 'jsx',
    'dart', 'py', 'java', 'kt', 'kts', 'swift', 'c', 'h', 'cpp',
    'hpp', 'rs', 'go', 'php', 'rb', 'sh', 'bash', 'sql', 'toml',
    'ini', 'conf', 'properties', 'gradle', 'svg', 'pdf', 'docx', 'pptx', 'xlsx',
  };
  final pattern = RegExp(
    r"""\x60\x60\x60([A-Za-z0-9_+#.-]*)[ \t]+(?:filename|file)=["']([^"']+)["'][^\r\n]*\r?\n([\s\S]*?)\x60\x60\x60""",
  );
  final match = pattern.firstMatch(response);
  if (match == null) return null;
  final requestedName = match.group(2)?.trim() ?? '';
  if (requestedName.isEmpty) return null;
  final fileName = requestedName
      .split(RegExp(r'[/\\\\]'))
      .last
      .replaceAll(RegExp(r'[<>:"|?*]'), '_')
      .trim();
  if (fileName.isEmpty || !fileName.contains('.')) return null;
  final extension = fileName.split('.').last.toLowerCase();
  if (!supportedExtensions.contains(extension)) return null;
  final content = match.group(3) ?? '';
  if (content.trim().isEmpty) return null;
  final message = (response.substring(0, match.start) +
          response.substring(match.end))
      .trim();
  return _GeneratedTextArtifact(
    fileName: fileName,
    content: content,
    message: message,
  );
}

List<String> _chatReplySegments(String text, bool splitMode) {
  final trimmed = text.trim();
  if (!splitMode || trimmed.isEmpty) return [text];

  final lines = trimmed.split('\n');
  // Keep code, tables, lists, headings and quoted Markdown as one readable unit.
  final hasStructuredMarkdown = trimmed.contains('```') ||
      lines.any((line) =>
          line.trim().startsWith('|') ||
          RegExp(r'^\s{0,3}(#{1,6}\s|>|[-*+]\s|\d+[.)]\s)').hasMatch(line));
  if (hasStructuredMarkdown) return [text];

  // Blank lines are intentional paragraph boundaries. Never split every short line
  // into its own bubble; merge them into a natural paragraph first.
  final paragraphs = trimmed
      .split(RegExp(r'\n\s*\n+'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty);

  final result = <String>[];
  for (final paragraph in paragraphs) {
    if (paragraph.length <= 110) {
      result.add(paragraph);
      continue;
    }

    final sentences = paragraph
        .split(RegExp(r'(?<=[。！？!?])'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (sentences.length <= 1) {
      result.add(paragraph);
      continue;
    }

    var chunk = '';
    for (final sentence in sentences) {
      final candidate = chunk.isEmpty ? sentence : '$chunk$sentence';
      if (chunk.isNotEmpty && chunk.length >= 65 && candidate.length > 125) {
        result.add(chunk);
        chunk = sentence;
      } else {
        chunk = candidate;
      }
    }
    if (chunk.isNotEmpty) result.add(chunk);
  }
  return result.isEmpty ? [text] : result;
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

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  final _search = TextEditingController();
  final _messagesScroll = ScrollController();
  final _api = ChatApiClient();
  final _imagePicker = ImagePicker();
  final _recorder = AudioRecorder();
  final _voicePlayer = AudioPlayer();
  static const _stickerStorageKey = 'chat.stickers.v1';
  static const _defaultStickerCategories = ['常用', '表情', '日常', '爱心'];
  List<Map<String, String>> _stickers = [];
  bool _recordingVoice = false;
  DateTime? _recordingStartedAt;
  String? _playingVoicePath;
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
  Timer? _draftSaveTimer;
  String _query = '';
  DateTime? _selectedDay;
  _ChatMessage? _replyingTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messagesScroll.addListener(_handleScroll);
    unawaited(ChatPreferenceStore.load());
    unawaited(_loadChat());
    unawaited(_restoreDraft());
    unawaited(_loadStickers());
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

  void _scheduleDraftSave(String value) {
    _draftSaveTimer?.cancel();
    _draftSaveTimer = Timer(const Duration(milliseconds: 350), () {
      unawaited(_saveDraft(value));
    });
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
          stickerUrl: message.stickerUrl,
          audioPath: message.audioPath,
          audioDurationMs: message.audioDurationMs,
          attachmentPath: message.attachmentPath,
          attachmentName: message.attachmentName,
          attachmentSize: message.attachmentSize,
          alternateReplies: message.alternateReplies,
          selectedAlternative: message.selectedAlternative,
          replyToText: message.replyToText,
          replyToMine: message.replyToMine,
          replyLayoutOverride: message.replyLayoutOverride,
        )));
      _loadingHistory = false;
    });
    _scrollToLatest(immediate: true);
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
      stickerUrl: message.stickerUrl,
      audioPath: message.audioPath,
      audioDurationMs: message.audioDurationMs,
      attachmentPath: message.attachmentPath,
      attachmentName: message.attachmentName,
      attachmentSize: message.attachmentSize,
      alternateReplies: message.alternateReplies,
      selectedAlternative: message.selectedAlternative,
      replyToText: message.replyToText,
      replyToMine: message.replyToMine,
      replyLayoutOverride: message.replyLayoutOverride,
    )).toList(),
  );

  void _handleScroll() {
    if (!_messagesScroll.hasClients) return;
    final shouldShow = _messagesScroll.position.pixels < _messagesScroll.position.maxScrollExtent - 180;
    if (shouldShow != _showJumpLatest && mounted) setState(() => _showJumpLatest = shouldShow);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_showJumpLatest) {
      _scrollToLatest(immediate: true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeCancelToken?.cancel('聊天页面已关闭');
    _draftSaveTimer?.cancel();
    _messagesScroll.removeListener(_handleScroll);
    _input.dispose();
    _inputFocus.dispose();
    _search.dispose();
    _messagesScroll.dispose();
    _recorder.dispose();
    _voicePlayer.dispose();
    super.dispose();
  }

  Future<void> _send([String? quickText, String? voicePath, int? voiceDurationMs, String? stickerPath, String? stickerUrl]) async {
    if (_sending) return;
    final value = (quickText ?? _input.text).trim();
    final imagePath = quickText == null ? _pendingImagePath : stickerPath;
    final attachmentPath = quickText == null ? _pendingFilePath : null;
    final attachmentName = quickText == null ? _pendingFileName : null;
    final attachmentSize = quickText == null ? _pendingFileSize : null;
    final replyTarget = quickText == null ? _replyingTo : null;
    if (value.isEmpty && imagePath == null && attachmentPath == null && voicePath == null && stickerUrl == null) return;
    setState(() {
      _messages.add(_ChatMessage(text: value, mine: true, time: DateTime.now(), imagePath: imagePath, stickerUrl: stickerUrl, audioPath: voicePath, audioDurationMs: voiceDurationMs, attachmentPath: attachmentPath, attachmentName: attachmentName, attachmentSize: attachmentSize, replyToText: replyTarget?.text, replyToMine: replyTarget?.mine));
      _input.clear();
      _pendingImagePath = null;
      _pendingFilePath = null;
      _pendingFileName = null;
      _pendingFileSize = null;
      _replyingTo = null;
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
              (message.text.trim().isNotEmpty || message.imagePath != null || message.stickerUrl != null || message.audioPath != null || message.attachmentPath != null))
          .toList()
          .reversed
          .take(20)
          .toList()
          .reversed;
      final history = <Map<String, dynamic>>[];
      for (final message in historyMessages) {
        final requestText = message.replyToText == null
            ? message.text
            : '[引用消息：${message.replyToMine == true ? '我' : '宋祁'}：${message.replyToText}]\\n${message.text}';
        final imagePath = message.imagePath;
        if (imagePath != null && await File(imagePath).exists()) {
          final extension = imagePath.toLowerCase().split('.').last;
          final mime = extension == 'png' ? 'image/png' :
              extension == 'webp' ? 'image/webp' : 'image/jpeg';
          final encodedImage = await compute(_encodeImageFileForRequest, imagePath);
          if (!mounted) return;
          history.add({
            'role': message.mine ? 'user' : 'assistant',
            'content': [
              if (requestText.trim().isNotEmpty)
                {'type': 'text', 'text': requestText},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:$mime;base64,$encodedImage'},
              },
            ],
          });
        } else if (message.stickerUrl != null) {
          history.add({
            'role': message.mine ? 'user' : 'assistant',
            'content': [
              if (requestText.trim().isNotEmpty) {'type': 'text', 'text': requestText},
              {'type': 'image_url', 'image_url': {'url': message.stickerUrl}},
            ],
          });
        } else if (message.audioPath != null && await File(message.audioPath!).exists()) {
          final duration = ((message.audioDurationMs ?? 0) / 1000).ceil();
          history.add({
            'role': message.mine ? 'user' : 'assistant',
            'content': '[用户发送了一条语音消息，时长约 $duration 秒。当前接口尚未配置语音转写或音频输入，因此请自然回应用户的语音消息，不要假装听到了具体内容。]',
          });
        } else if (message.attachmentPath != null && await File(message.attachmentPath!).exists()) {
          final file = File(message.attachmentPath!);
          final extension = message.attachmentName?.split('.').last.toLowerCase() ?? '';
          const readable = {'txt', 'md', 'csv', 'json', 'xml', 'yaml', 'yml', 'log', 'html', 'htm', 'css', 'js', 'mjs', 'ts', 'tsx', 'jsx', 'dart', 'py', 'java', 'kt', 'kts', 'swift', 'c', 'h', 'cpp', 'hpp', 'rs', 'go', 'php', 'rb', 'sh', 'bash', 'sql', 'toml', 'ini', 'conf', 'properties', 'gradle', 'svg'};
          if (readable.contains(extension)) {
            final content = await file.readAsString();
            history.add({'role': message.mine ? 'user' : 'assistant', 'content': '${requestText.isEmpty ? '' : '$requestText\n'}[附件：${message.attachmentName}]\n$content'});
          } else {
            history.add({'role': message.mine ? 'user' : 'assistant', 'content': '${requestText.isEmpty ? '' : '$requestText\n'}[用户附加了文件：${message.attachmentName}。当前接口适配层尚未解析此文件格式。]'});
          }
        } else {
          history.add({
            'role': message.mine ? 'user' : 'assistant',
            'content': requestText,
          });
        }
      }

      final chatPrefs = ChatPreferenceStore.value.value;
      final narratorInstruction = chatPrefs.narratorEnabled
          ? '可以自然使用括号描写动作、神态和环境，不要每句话都写旁白。'
          : '以直接对话为主，不主动添加括号动作、神态或环境旁白。';
      final replyLayoutInstruction = chatPrefs.replyLayout == 1
          ? '回复时采用即时聊天分句模式：把自然的短句或一个完整意思作为一条独立消息，每条消息单独换行，不要加编号或项目符号；长回复分成数条短消息，节奏自然，不要把每句话挤成一整堵文字。代码、表格和文件内容必须保持原样，不要拆坏。'
          : '回复时采用完整长段模式：允许根据情境写连贯、完整的长段落，不要为了短而刻意拆成多条消息。';
      final systemPrompt = '你在「小窝」这个私人空间里。你就是你自己，不是客服。说话自然、有体温，偶尔走神、偶尔说重一点。$narratorInstruction $replyLayoutInstruction 不要列条目。用户要求制作文件时，必须把完整成品放进一个带明确文件名的代码围栏，围栏外只写简短交付说明，不要把源码散落在聊天气泡。格式要求：HTML/CSS/JS/TXT/Markdown/CSV/JSON/XML/SVG/代码等文本文件使用对应语言围栏并写 filename="作品.扩展名"；DOCX 使用 ```docx filename="作品.docx"，正文用 Markdown 标题、段落和表格；XLSX 使用 ```xlsx filename="作品.xlsx"，正文优先输出 CSV，每行一条记录，字段用逗号分隔，含逗号的字段用双引号包裹，或输出 Markdown 表格；PPTX 使用 ```pptx filename="作品.pptx"，每页以单独的 Markdown 标题开头，页面之间用单独一行 --- 分隔，正文使用短段落和项目符号；PDF 使用 ```pdf filename="作品.pdf"，正文使用 Markdown 标题和段落。DOCX/PPTX/XLSX/PDF 会由客户端生成真实二进制文件，不要输出 Base64，也不要只给伪代码。';
      final worldbookContext = chatPrefs.worldbookEnabled
          ? _resolveWorldbookContext(
              chatPrefs.worldbookJson,
              historyMessages.where((message) => message.mine).map((message) => message.text).join('\n'),
            )
          : '';

      final requestMessages = <Map<String, dynamic>>[
        {'role': 'system', 'content': systemPrompt},
        if (chatPrefs.additionalSystemPrompt.trim().isNotEmpty)
          {'role': 'system', 'content': chatPrefs.additionalSystemPrompt.trim()},
        if (worldbookContext.isNotEmpty)
          {'role': 'system', 'content': '以下是本轮匹配到的世界书设定。请将其作为背景资料使用，不要逐字复述，也不要覆盖更高优先级的系统规则：\\n$worldbookContext'},
        ...history,
      ];

      final replyIndex = _messages.length;
      setState(() {
        _messages.add(_ChatMessage(text: '', mine: false, time: DateTime.now(), isTyping: true));
      });

      var pendingText = '';
      var pendingReasoning = '';
      int? pendingInputTokens;
      int? pendingOutputTokens;
      var lastUiFlush = DateTime.now();
      await for (final event in _api.streamReply(
        config: config,
        messages: requestMessages,
        cancelToken: cancelToken,
      )) {
        if (!mounted) return;
        pendingText += event.textDelta;
        pendingReasoning += event.reasoningDelta;
        pendingInputTokens = event.inputTokens ?? pendingInputTokens;
        pendingOutputTokens = event.outputTokens ?? pendingOutputTokens;
        final hasPending = pendingText.isNotEmpty ||
            pendingReasoning.isNotEmpty ||
            pendingInputTokens != null ||
            pendingOutputTokens != null;
        final shouldFlush = event.finished ||
            DateTime.now().difference(lastUiFlush) >= const Duration(milliseconds: 48);
        if (hasPending && shouldFlush) {
          final textDelta = pendingText;
          final reasoningDelta = pendingReasoning;
          final inputTokens = pendingInputTokens;
          final outputTokens = pendingOutputTokens;
          pendingText = '';
          pendingReasoning = '';
          pendingInputTokens = null;
          pendingOutputTokens = null;
          lastUiFlush = DateTime.now();
          setState(() {
            final current = _messages[replyIndex];
            _messages[replyIndex] = _ChatMessage(
              text: current.text + textDelta,
              mine: false,
              time: current.time,
              reasoning: (current.reasoning ?? '') + reasoningDelta,
              isTyping: !event.finished,
              inputTokens: inputTokens ?? current.inputTokens,
              outputTokens: outputTokens ?? current.outputTokens,
              alternateReplies: current.alternateReplies,
              selectedAlternative: current.selectedAlternative,
            );
          });
          _followStreamingReply();
        } else if (event.finished) {
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
              stickerUrl: current.stickerUrl,
              audioPath: current.audioPath,
              audioDurationMs: current.audioDurationMs,
              attachmentPath: current.attachmentPath,
              attachmentName: current.attachmentName,
              attachmentSize: current.attachmentSize,
              alternateReplies: current.alternateReplies,
              selectedAlternative: current.selectedAlternative,
            );
          });
        }
      }
      if (!mounted) return;
      if (pendingText.isNotEmpty || pendingReasoning.isNotEmpty ||
          pendingInputTokens != null || pendingOutputTokens != null) {
        setState(() {
          final current = _messages[replyIndex];
          _messages[replyIndex] = _ChatMessage(
            text: current.text + pendingText,
            mine: false,
            time: current.time,
            reasoning: (current.reasoning ?? '') + pendingReasoning,
            inputTokens: pendingInputTokens ?? current.inputTokens,
            outputTokens: pendingOutputTokens ?? current.outputTokens,
            alternateReplies: current.alternateReplies,
            selectedAlternative: current.selectedAlternative,
          );
        });
      }
      if (_messages[replyIndex].isTyping) {
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
            stickerUrl: current.stickerUrl,
            audioPath: current.audioPath,
            audioDurationMs: current.audioDurationMs,
            attachmentPath: current.attachmentPath,
            attachmentName: current.attachmentName,
            attachmentSize: current.attachmentSize,
            alternateReplies: current.alternateReplies,
            selectedAlternative: current.selectedAlternative,
          );
        });
      }
      final artifact = _extractGeneratedTextArtifact(_messages[replyIndex].text);
      if (artifact != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final outputDir = Directory('${appDir.path}/chat_generated');
        if (!await outputDir.exists()) {
          await outputDir.create(recursive: true);
        }
        final safeName = '${DateTime.now().microsecondsSinceEpoch}_${artifact.fileName}';
        final outputFile = File('${outputDir.path}/$safeName');
        final extension = artifact.fileName.split('.').last.toLowerCase();
        if (const {'pdf', 'docx', 'pptx', 'xlsx'}.contains(extension)) {
          final bytes = await ChatDocumentGenerator.generate(artifact.fileName, artifact.content);
          await outputFile.writeAsBytes(bytes, flush: true);
        } else {
          await outputFile.writeAsString(artifact.content, flush: true);
        }
        final outputSize = await outputFile.length();
        final current = _messages[replyIndex];
        setState(() {
          _messages[replyIndex] = _ChatMessage(
            text: artifact.message,
            mine: current.mine,
            time: current.time,
            reasoning: current.reasoning,
            inputTokens: current.inputTokens,
            outputTokens: current.outputTokens,
            attachmentPath: outputFile.path,
            attachmentName: artifact.fileName,
            attachmentSize: outputSize,
            alternateReplies: current.alternateReplies,
            selectedAlternative: current.selectedAlternative,
          );
        });
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
              alternateReplies: current.alternateReplies,
              selectedAlternative: current.selectedAlternative,
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

  Future<void> _rerollReply(_ChatMessage target) async {
    if (_sending || target.mine || target.isSystem || target.text.trim().isEmpty) return;
    final replyIndex = _messages.indexOf(target);
    final latestReply = _messages.lastIndexWhere((message) => !message.mine && !message.isSystem);
    if (replyIndex < 1 || replyIndex != latestReply) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('目前只能重新生成最新一条回复')));
      return;
    }
    var userIndex = replyIndex - 1;
    while (userIndex >= 0 && !_messages[userIndex].mine) {
      userIndex--;
    }
    if (userIndex < 0) return;
    final userMessage = _messages[userIndex];
    final oldReply = target;
    final previousMessages = List<_ChatMessage>.from(_messages);
    setState(() {
      _messages.removeAt(replyIndex);
      _messages.removeAt(userIndex);
      _input.text = userMessage.text;
      _pendingImagePath = userMessage.imagePath;
      _pendingFilePath = userMessage.attachmentPath;
      _pendingFileName = userMessage.attachmentName;
      _pendingFileSize = userMessage.attachmentSize;
    });
    await _saveDraft(userMessage.text);
    final minimumNewIndex = _messages.length;
    await _send();
    if (!mounted) return;
    final newIndex = _messages.lastIndexWhere((message) => !message.mine && !message.isSystem);
    if (newIndex >= minimumNewIndex && _messages[newIndex].text.trim().isNotEmpty) {
      final current = _messages[newIndex];
      setState(() {
        _messages[newIndex] = _ChatMessage(
          text: current.text,
          mine: false,
          time: current.time,
          reasoning: current.reasoning,
          inputTokens: current.inputTokens,
          outputTokens: current.outputTokens,
          alternateReplies: [...oldReply.alternateReplies, oldReply.text],
        );
      });
      await _persistChat();
    } else {
      setState(() {
        _messages
          ..clear()
          ..addAll(previousMessages);
      });
      await _persistChat();
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
        if (prefs.showAvatar) ...[
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
        ],
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
    message.imagePath != null || message.stickerUrl != null ? '图片 表情包 image sticker' : '',
    message.audioPath != null ? '语音 voice' : '',
    message.attachmentPath != null ? '文件 附件 file' : '',
  ].join(' ').toLowerCase();

  Widget _buildMessages(ChatPreferences prefs) {
    if (_loadingHistory) {
      return const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)));
    }
    // In the normal chat view, avoid rebuilding a full filtered copy of the
    // conversation on every streaming update. Only create the index list when
    // the user is actively searching or viewing a specific day.
    final hasFilter = _selectedDay != null || _query.isNotEmpty;
    final visible = hasFilter
        ? _messages.asMap().entries.where((entry) {
            final dayMatches = _selectedDay == null ||
                (entry.value.time.year == _selectedDay!.year &&
                 entry.value.time.month == _selectedDay!.month &&
                 entry.value.time.day == _selectedDay!.day);
            return dayMatches &&
                (_query.isEmpty || _searchableText(entry.value).contains(_query));
          }).toList()
        : null;
    final visibleCount = visible?.length ?? _messages.length;
    if (visibleCount == 0) {
      return Center(child: Text(_selectedDay != null ? '这一天还没有聊天记录' : (_query.isEmpty ? '还没有消息，在下面写一句吧。' : '没有找到相关消息'), style: const TextStyle(color: AppColors.muted, fontSize: 13)));
    }
    final wallpaperPath = prefs.chatWallpaperPath;
    final wallpaperFile = wallpaperPath == null || wallpaperPath.isEmpty
        ? null
        : File(wallpaperPath);
    final hasWallpaper = wallpaperFile != null && wallpaperFile.existsSync();
    return Stack(
      children: [
        if (hasWallpaper)
          Positioned.fill(
            child: Image.file(
              wallpaperFile,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFFAFAFA)),
            ),
          ),
        if (hasWallpaper)
          Positioned.fill(
            child: ColoredBox(color: Colors.white.withValues(alpha: .38)),
          ),
        ListView.builder(
      reverse: false,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      controller: _messagesScroll,
      physics: const BouncingScrollPhysics(),
      itemCount: visibleCount,
      itemBuilder: (context, index) {
        final originalIndex = visible == null ? index : visible[index].key;
        final message = visible == null ? _messages[index] : visible[index].value;
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
    final myLabel = prefs.myName.trim().isEmpty ? '我' : prefs.myName.trim();
    final partnerLabel = prefs.partnerName.trim().isEmpty ? '宋祁' : prefs.partnerName.trim();
    final avatarLabel = mine ? myLabel.substring(0, 1) : partnerLabel.substring(0, 1);
    final mineBubble = _mineBubbleColor(prefs.bubbleStyle);
    final partnerBubble = _partnerBubbleColor(prefs.bubbleStyle);
    final isHelloTalk = prefs.bubbleStyle == 0;
    final effectiveReplyLayout = message.replyLayoutOverride ?? prefs.replyLayout;
    final replyParts = _chatReplySegments(message.text, !mine && effectiveReplyLayout == 1);

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
        // Match Mio: hide repeated avatars but keep their column so bubbles align.
        child: compact ? const SizedBox(width: 34, height: 34) : avatar,
      ),
    );
    final bubbleRadius = isHelloTalk
        ? BorderRadius.only(
            topLeft: Radius.circular(!mine && !compact ? 8 : prefs.bubbleRadius),
            topRight: Radius.circular(mine && !compact ? 8 : prefs.bubbleRadius),
            bottomLeft: Radius.circular(prefs.bubbleRadius),
            bottomRight: Radius.circular(prefs.bubbleRadius),
          )
        : BorderRadius.only(
            topLeft: Radius.circular(prefs.bubbleRadius),
            topRight: Radius.circular(prefs.bubbleRadius),
            bottomLeft: Radius.circular(mine ? prefs.bubbleRadius : 6),
            bottomRight: Radius.circular(mine ? 6 : prefs.bubbleRadius),
          );

    final content = Flexible(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * (prefs.showBubbles ? .78 : .92)),
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
                onLongPress: () => _showMessageActions(message, prefs),
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
            if (message.stickerUrl != null)
              GestureDetector(
                onTap: () => _showStickerImage(message.stickerUrl!),
                onLongPress: () => _showMessageActions(message, prefs),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      message.stickerUrl!, width: 190, height: 190, fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 150, height: 70, child: Center(child: Text('表情包链接无法加载'))),
                    ),
                  ),
                ),
              ),
            if (message.audioPath != null)
              _voiceMessageBubble(message),
            if (message.attachmentPath != null)
              GestureDetector(
                onTap: () => _openAttachment(message),
                onLongPress: () => _showMessageActions(message, prefs),
                child: _buildAttachmentCard(message),
              ),
            if (message.text.isNotEmpty || message.isTyping)
              GestureDetector(
                onLongPress: () => _showMessageActions(message, prefs),
                child: Column(
                  crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.isTyping && message.text.isEmpty)
                      Container(
                        padding: prefs.showBubbles ? const EdgeInsets.symmetric(horizontal: 15, vertical: 11) : EdgeInsets.zero,
                        decoration: prefs.showBubbles ? BoxDecoration(color: mine ? mineBubble : partnerBubble, borderRadius: bubbleRadius) : null,
                        child: const SizedBox(width: 34, height: 17, child: Center(child: Text('···', style: TextStyle(fontSize: 20, letterSpacing: 2, color: Color(0xFF777777)))),),
                      )
                    else
                      ...replyParts.asMap().entries.map((entry) {
                        final isFirst = entry.key == 0;
                        final textColor = prefs.showBubbles && mine ? Colors.white : const Color(0xFF222222);
                        return Container(
                          margin: EdgeInsets.only(bottom: entry.key == replyParts.length - 1 ? 0 : 5),
                          padding: prefs.showBubbles ? const EdgeInsets.symmetric(horizontal: 15, vertical: 11) : EdgeInsets.zero,
                          decoration: prefs.showBubbles ? BoxDecoration(
                            color: mine ? mineBubble : partnerBubble,
                            borderRadius: bubbleRadius,
                            border: !mine && isHelloTalk ? Border.all(color: const Color(0xFFE8E8E8), width: .7) : null,
                            boxShadow: isHelloTalk ? [BoxShadow(color: Colors.black.withValues(alpha: .035), blurRadius: 8, offset: const Offset(0, 2))] : null,
                          ) : null,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isFirst && message.replyToText != null && message.replyToText!.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 7),
                                  padding: const EdgeInsets.fromLTRB(9, 6, 9, 6),
                                  decoration: BoxDecoration(
                                    color: prefs.showBubbles ? (mine ? Colors.white.withValues(alpha: .16) : const Color(0xFFEAEAEA)) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border(left: BorderSide(color: mine && prefs.showBubbles ? Colors.white70 : const Color(0xFF999999), width: 2)),
                                  ),
                                  child: Text('${message.replyToMine == true ? '我' : '宋祁'}：${message.replyToText}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, height: 1.35, color: prefs.showBubbles && mine ? Colors.white70 : const Color(0xFF777777))),
                                ),
                              Text(entry.value, style: TextStyle(fontSize: prefs.fontSize, height: 1.5, color: textColor)),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            if (!mine && !message.isTyping && !message.isSystem)
              Padding(
                padding: const EdgeInsets.only(top: 3, left: 1),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _rerollReply(message),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.refresh_rounded, size: 13, color: Color(0xFF888888)),
                        SizedBox(width: 3),
                        Text('Reroll', style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
                      ]),
                    ),
                  ),
                  if (message.alternateReplies.isNotEmpty)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showReplyVersions(message),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                        child: Text('版本 ${message.alternateReplies.length + 1}', style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                      ),
                    ),
                ]),
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
        children: !prefs.showAvatar
            ? [content]
            : mine
                ? [content, const SizedBox(width: 6), avatarSlot]
                : [avatarSlot, const SizedBox(width: 6), content],
      ),
    );
  }

  Future<void> _showReplyVersions(_ChatMessage message) async {
    final index = _messages.indexOf(message);
    if (index < 0 || message.alternateReplies.isEmpty) return;
    final versions = [...message.alternateReplies, message.text];
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            const Padding(padding: EdgeInsets.fromLTRB(4, 4, 4, 12), child: Text('回复版本', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
            for (var i = 0; i < versions.length; i++)
              ListTile(
                leading: Icon(i == versions.length - 1 ? Icons.check_circle_rounded : Icons.history_rounded, color: const Color(0xFF666666)),
                title: Text('版本 ${i + 1}', style: const TextStyle(fontSize: 13)),
                subtitle: Text(versions[i], maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11)),
                onTap: () => Navigator.pop(sheetContext, i),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted || selected == versions.length - 1) return;
    final current = _messages[index];
    final chosen = versions[selected];
    final nextVersions = [...versions]..removeAt(selected);
    setState(() {
      _messages[index] = _ChatMessage(
        text: chosen, mine: current.mine, time: current.time, reasoning: current.reasoning,
        inputTokens: current.inputTokens, outputTokens: current.outputTokens,
        imagePath: current.imagePath, stickerUrl: current.stickerUrl, audioPath: current.audioPath, audioDurationMs: current.audioDurationMs, attachmentPath: current.attachmentPath,
        attachmentName: current.attachmentName, attachmentSize: current.attachmentSize,
        alternateReplies: nextVersions,
        replyLayoutOverride: current.replyLayoutOverride,
      );
    });
    await _persistChat();
  }

  Future<void> _showMessageActions(_ChatMessage message, ChatPreferences prefs) async {
    final currentReplyLayout = message.replyLayoutOverride ?? prefs.replyLayout;
    if (message.isTyping || message.isSystem ||
        (message.text.isEmpty && message.imagePath == null && message.stickerUrl == null && message.audioPath == null && message.attachmentPath == null)) {
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
                leading: const Icon(Icons.reply_rounded),
                title: const Text('引用回复'),
                onTap: () => Navigator.pop(sheetContext, 'reply'),
              ),
            if (!message.mine && message.text.isNotEmpty)
              ListTile(
                leading: Icon(currentReplyLayout == 1 ? Icons.notes_rounded : Icons.forum_outlined),
                title: Text(currentReplyLayout == 1 ? '改为完整长段' : '改为聊天分句'),
                subtitle: const Text('只改变这一条消息，不影响其他回复'),
                onTap: () => Navigator.pop(sheetContext, 'toggle_reply_layout'),
              ),
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
            if (!message.mine && !message.isTyping)
              ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: const Text('Reroll · 重新生成'),
                subtitle: const Text('保留当前回复，生成另一个版本'),
                onTap: () => Navigator.pop(sheetContext, 'reroll'),
              ),
            if (message.attachmentPath != null)
              ListTile(
                leading: const Icon(Icons.download_for_offline_outlined),
                title: const Text('保存附件到手机'),
                subtitle: Text(message.attachmentName ?? '文件'),
                onTap: () => Navigator.pop(sheetContext, 'save_attachment'),
              ),
            if (message.imagePath != null || message.stickerUrl != null)
              ListTile(
                leading: const Icon(Icons.save_alt_rounded),
                title: const Text('保存照片到相册'),
                onTap: () => Navigator.pop(sheetContext, 'save_image'),
              ),
            if (!message.mine && RegExp(r'```[a-zA-Z0-9_+-]*\s*\n[\s\S]*?```').hasMatch(message.text))
              ListTile(
                leading: const Icon(Icons.file_download_outlined),
                title: const Text('把代码保存为文件'),
                subtitle: const Text('可生成 HTML、文本或代码文件'),
                onTap: () => Navigator.pop(sheetContext, 'save_code'),
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
    if (action == 'toggle_reply_layout') {
      final nextLayout = currentReplyLayout == 1 ? 0 : 1;
      setState(() {
        final index = _messages.indexOf(message);
        if (index >= 0) {
          _messages[index] = _ChatMessage(
            text: message.text,
            mine: message.mine,
            time: message.time,
            reasoning: message.reasoning,
            isSystem: message.isSystem,
            inputTokens: message.inputTokens,
            outputTokens: message.outputTokens,
            imagePath: message.imagePath,
            stickerUrl: message.stickerUrl,
            audioPath: message.audioPath,
            audioDurationMs: message.audioDurationMs,
            attachmentPath: message.attachmentPath,
            attachmentName: message.attachmentName,
            attachmentSize: message.attachmentSize,
            alternateReplies: message.alternateReplies,
            selectedAlternative: message.selectedAlternative,
            replyToText: message.replyToText,
            replyToMine: message.replyToMine,
            replyLayoutOverride: nextLayout,
          );
        }
      });
      await _persistChat();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(nextLayout == 1 ? '这条回复已改为聊天分句' : '这条回复已改为完整长段')),
        );
      }
    } else if (action == 'reply') {
      setState(() => _replyingTo = message);
      FocusScope.of(context).requestFocus(_inputFocus);
    } else if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: message.text));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
    } else if (action == 'reroll') {
      await _rerollReply(message);
    } else if (action == 'save_image') {
      await _saveChatImage(message);
    } else if (action == 'save_attachment') {
      await _saveAttachmentToDevice(message);
    } else if (action == 'save_code') {
      await _saveCodeBlockAsFile(message);
    } else if (action == 'delete') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('删除这条消息？'),
          content: const Text('删除后会从本机聊天记录中移除，且无法直接撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFB04444)),
              child: const Text('删除'),
            ),
          ],
        ),
      );
      if (confirmed == true && mounted) {
        setState(() {
          _messages.remove(message);
          if (identical(_replyingTo, message)) _replyingTo = null;
        });
        await _persistChat();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('消息已删除')),
          );
        }
      }
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
      if (_replyingTo != null)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.fromLTRB(11, 8, 5, 8),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(13), border: Border.all(color: const Color(0xFFE7E7E7))),
          child: Row(children: [
            Container(width: 2, height: 30, color: const Color(0xFF888888)),
            const SizedBox(width: 9),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('回复${_replyingTo!.mine ? '我' : '宋祁'}', style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
              Text(_replyingTo!.text.isEmpty ? '媒体消息' : _replyingTo!.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: Color(0xFF444444))),
            ])),
            IconButton(tooltip: '取消引用', visualDensity: VisualDensity.compact, onPressed: () => setState(() => _replyingTo = null), icon: const Icon(Icons.close_rounded, size: 17)),
          ]),
        ),
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
      if (_recordingVoice)
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Row(children: [Icon(Icons.fiber_manual_record_rounded, color: Color(0xFF555555), size: 12), SizedBox(width: 7), Text('正在录音 · 再点一次结束并发送', style: TextStyle(fontSize: 11, color: Color(0xFF666666)))]),
        ),
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
          IconButton(
            tooltip: '表情',
            visualDensity: VisualDensity.compact,
            onPressed: _showEmojiPicker,
            icon: const Icon(Icons.emoji_emotions_outlined, size: 21, color: Color(0xFF777777)),
          ),
          IconButton(
            tooltip: '表情包',
            visualDensity: VisualDensity.compact,
            onPressed: _showStickerPicker,
            icon: const Icon(Icons.sticky_note_2_outlined, size: 20, color: Color(0xFF777777)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: TextField(
                controller: _input,
                focusNode: _inputFocus,
                onChanged: _scheduleDraftSave,
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
          const SizedBox(width: 3),
          IconButton(
            tooltip: _recordingVoice ? '结束并发送语音' : '录制语音',
            visualDensity: VisualDensity.compact,
            onPressed: _toggleVoiceRecording,
            icon: Icon(_recordingVoice ? Icons.stop_circle_rounded : Icons.mic_none_rounded, color: _recordingVoice ? const Color(0xFF333333) : const Color(0xFF777777), size: 22),
          ),
          const SizedBox(width: 3),
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

  Future<void> _loadStickers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_stickerStorageKey);
    if (raw == null || raw.isEmpty || !mounted) return;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      setState(() {
        _stickers = decoded.whereType<Map>().map((item) => {
          'source': (item['source'] ?? '').toString(),
          'category': (item['category'] ?? '常用').toString(),
          'type': (item['type'] ?? 'url').toString(),
        }).where((item) => item['source']!.isNotEmpty).toList();
      });
    } catch (_) {}
  }

  Future<void> _saveStickers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_stickerStorageKey, jsonEncode(_stickers));
  }

  Future<void> _showStickerPicker() async {
    var selectedCategory = '全部';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, refresh) {
        final categories = ['全部', ...{..._defaultStickerCategories, ..._stickers.map((item) => item['category']!)}];
        final visible = _stickers.where((item) => selectedCategory == '全部' || item['category'] == selectedCategory).toList();
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height * .62,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(17, 0, 17, 10),
                child: Row(children: [
                  const Expanded(child: Text('我的表情包', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                  TextButton.icon(onPressed: () async {
                    await _addStickerFromGallery();
                    if (sheetContext.mounted) refresh(() {});
                  }, icon: const Icon(Icons.add_photo_alternate_outlined, size: 17), label: const Text('上传')),
                  TextButton.icon(onPressed: () async {
                    await _addStickerLink();
                    if (sheetContext.mounted) refresh(() {});
                  }, icon: const Icon(Icons.link_rounded, size: 17), label: const Text('图床链接')),
                ]),
              ),
              SizedBox(
                height: 40,
                child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 14), children: [
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: GestureDetector(
                        onLongPress: category == '全部'
                            ? null
                            : () async {
                                final action = await showModalBottomSheet<String>(
                                  context: context,
                                  backgroundColor: Colors.white,
                                  showDragHandle: true,
                                  builder: (menuContext) => SafeArea(
                                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(18, 5, 18, 12),
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text('管理「$category」分类', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                                        ),
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.edit_outlined),
                                        title: const Text('重命名分类'),
                                        onTap: () => Navigator.pop(menuContext, 'rename'),
                                      ),
                                      if (category != '常用')
                                        ListTile(
                                          leading: const Icon(Icons.delete_outline_rounded),
                                          title: const Text('删除分类'),
                                          subtitle: const Text('分类中的表情包会移动到「常用」'),
                                          onTap: () => Navigator.pop(menuContext, 'delete'),
                                        ),
                                    ]),
                                  ),
                                );
                                if (action == 'rename' && sheetContext.mounted) {
                                  final renamed = await _renameStickerCategory(category);
                                  if (renamed != null && renamed != category) {
                                    for (final sticker in _stickers) {
                                      if (sticker['category'] == category) sticker['category'] = renamed;
                                    }
                                    await _saveStickers();
                                    if (sheetContext.mounted) refresh(() => selectedCategory = renamed);
                                  }
                                } else if (action == 'delete' && sheetContext.mounted) {
                                  final confirmed = await showDialog<bool>(
                                    context: sheetContext,
                                    builder: (dialogContext) => AlertDialog(
                                      title: const Text('删除这个分类？'),
                                      content: Text('分类「$category」中的表情包会保留，并移动到「常用」。'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
                                        TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('删除')),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true) {
                                    for (final sticker in _stickers) {
                                      if (sticker['category'] == category) sticker['category'] = '常用';
                                    }
                                    await _saveStickers();
                                    if (sheetContext.mounted) refresh(() => selectedCategory = '全部');
                                  }
                                }
                              },
                        child: ChoiceChip(
                          label: Text(category),
                          selected: selectedCategory == category,
                          onSelected: (_) => refresh(() => selectedCategory = category),
                          selectedColor: const Color(0xFFEAEAEA),
                          backgroundColor: const Color(0xFFF7F7F7),
                          labelStyle: const TextStyle(fontSize: 11, color: Color(0xFF333333)),
                          side: BorderSide.none,
                        ),
                      ),
                    ),
                ]),
              ),
              const SizedBox(height: 8),
              Expanded(child: visible.isEmpty
                ? const Center(child: Text('还没有表情包，上传图片或添加图床链接吧', style: TextStyle(fontSize: 12, color: Color(0xFF888888))))
                : GridView.builder(
                    padding: const EdgeInsets.all(14),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10),
                    itemCount: visible.length,
                    itemBuilder: (_, index) {
                      final item = visible[index];
                      final local = item['type'] == 'file';
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _sendSticker(item);
                        },
                        onLongPress: () async {
                          final confirmed = await showDialog<bool>(
                            context: sheetContext,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('删除这个表情包？'),
                              content: const Text('只会删除表情包收藏，不会影响已经发送的聊天记录。'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, false),
                                  child: const Text('取消'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext, true),
                                  child: const Text('删除'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            _stickers.remove(item);
                            await _saveStickers();
                            if (sheetContext.mounted) refresh(() {});
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(color: const Color(0xFFF7F7F7), borderRadius: BorderRadius.circular(13)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: local
                              ? Image.file(File(item['source']!), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined))
                              : Image.network(item['source']!, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined)),
                          ),
                        ),
                      );
                    },
                  )),
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: Text('点击发送 · 长按删除 · 支持本地图片和图床 URL', style: TextStyle(fontSize: 10, color: Color(0xFF999999))),
              ),
            ]),
          ),
        );
      }),
    );
  }

  Future<String?> _renameStickerCategory(String category) async {
    final controller = TextEditingController(text: category);
    final renamed = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重命名分类'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 16,
          decoration: const InputDecoration(hintText: '输入新的分类名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (renamed == null || renamed.isEmpty) return null;
    return renamed;
  }

  Future<String?> _askStickerCategory() async {
    final controller = TextEditingController(text: '常用');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('表情包分类'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: '例如：表情、日常、爱心')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('保存')),
        ],
      ),
    );
    controller.dispose();
    return result == null || result.isEmpty ? null : result;
  }

  Future<void> _addStickerFromGallery() async {
    final picked = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 90, maxWidth: 1200, maxHeight: 1200);
    if (picked == null || !mounted) return;
    final category = await _askStickerCategory();
    if (category == null || !mounted) return;
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/chat_stickers');
    if (!await dir.exists()) await dir.create(recursive: true);
    final ext = picked.path.contains('.') ? picked.path.split('.').last : 'jpg';
    final target = File('${dir.path}/sticker_${DateTime.now().microsecondsSinceEpoch}.$ext');
    await File(picked.path).copy(target.path);
    _stickers.add({'source': target.path, 'category': category, 'type': 'file'});
    await _saveStickers();
  }

  Future<void> _addStickerLink() async {
    final urlController = TextEditingController();
    final categoryController = TextEditingController(text: '常用');
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('添加图床表情包'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: urlController, keyboardType: TextInputType.url, autocorrect: false, decoration: const InputDecoration(labelText: '图片 URL', hintText: 'https://…')),
          const SizedBox(height: 9),
          TextField(controller: categoryController, decoration: const InputDecoration(labelText: '分类', hintText: '常用 / 表情 / 日常')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('添加')),
        ],
      ),
    );
    final url = urlController.text.trim();
    final category = categoryController.text.trim();
    urlController.dispose();
    categoryController.dispose();
    if (result != true || !mounted) return;
    final uri = Uri.tryParse(url);
    if (uri == null || !{'http', 'https'}.contains(uri.scheme) || uri.host.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入有效的图片链接')));
      return;
    }
    _stickers.add({'source': url, 'category': category.isEmpty ? '常用' : category, 'type': 'url'});
    await _saveStickers();
  }

  void _sendSticker(Map<String, String> sticker) {
    final local = sticker['type'] == 'file';
    unawaited(_send('', null, null, local ? sticker['source'] : null, local ? null : sticker['source']));
  }

  void _showStickerImage(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(onTap: () => Navigator.pop(dialogContext), child: InteractiveViewer(child: Image.network(url, fit: BoxFit.contain))),
      ),
    );
  }

  Future<void> _toggleVoiceRecording() async {
    if (_recordingVoice) {
      final path = await _recorder.stop();
      final duration = _recordingStartedAt == null ? Duration.zero : DateTime.now().difference(_recordingStartedAt!);
      if (!mounted) return;
      setState(() => _recordingVoice = false);
      _recordingStartedAt = null;
      if (path == null || duration < const Duration(milliseconds: 400)) {
        if (path != null) { try { await File(path).delete(); } catch (_) {} }
        return;
      }
      await _send('', path, duration.inMilliseconds);
      return;
    }
    try {
      if (!await _recorder.hasPermission()) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('需要麦克风权限才能录制语音')));
        return;
      }
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/chat_voice');
      if (!await dir.exists()) await dir.create(recursive: true);
      final path = '${dir.path}/voice_${DateTime.now().microsecondsSinceEpoch}.wav';
      await _recorder.start(const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1), path: path);
      if (!mounted) return;
      _recordingStartedAt = DateTime.now();
      setState(() => _recordingVoice = true);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('无法开始录音：$error')));
    }
  }

  Future<void> _playVoice(String path) async {
    try {
      setState(() => _playingVoicePath = path);
      await _voicePlayer.setFilePath(path);
      await _voicePlayer.play();
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('语音播放失败：$error')));
    }
  }

  Widget _voiceMessageBubble(_ChatMessage message) {
    final path = message.audioPath!;
    final seconds = ((message.audioDurationMs ?? 0) / 1000).ceil();
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Material(
        color: message.mine ? const Color(0xFF202020) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _playVoice(path),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              StreamBuilder<PlayerState>(
                stream: _voicePlayer.playerStateStream,
                builder: (_, snapshot) {
                  final playing = _playingVoicePath == path && (snapshot.data?.playing ?? false);
                  return Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: message.mine ? Colors.white : const Color(0xFF333333), size: 21);
                },
              ),
              const SizedBox(width: 7),
              Icon(Icons.graphic_eq_rounded, color: message.mine ? Colors.white70 : const Color(0xFF777777), size: 18),
              const SizedBox(width: 9),
              Text('$seconds″', style: TextStyle(fontSize: 12, color: message.mine ? Colors.white : const Color(0xFF333333))),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _showEmojiPicker() async {
    const emojis = [
      '😀','😃','😄','😁','😆','🥹','😂','🤣','🥲','😊','😍','🥰',
      '😘','😚','😋','😛','🤪','🤔','🥺','😭','😤','😳','🙈','🙉',
      '🙊','😴','🤗','🤭','🫶','❤️','🩷','🧡','💛','💚','🩵','💙',
      '💜','🤍','🖤','💔','💕','💞','💓','💗','💖','💘','💝','💟',
      '👍','👎','👏','🙌','🙏','🤝','💪','🫂','👀','✨','⭐','🌙',
      '☀️','🌧️','🌸','🌷','🌹','🍀','🍓','🍑','🍰','🎂','☕','🎧',
    ];
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 18),
          child: SizedBox(
            height: 245,
            child: GridView.builder(
              itemCount: emojis.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemBuilder: (_, index) => InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  final value = _input.text;
                  final selection = _input.selection;
                  final start = selection.isValid ? selection.start : value.length;
                  final end = selection.isValid ? selection.end : value.length;
                  final next = value.replaceRange(start, end, emojis[index]);
                  _input.value = TextEditingValue(
                    text: next,
                    selection: TextSelection.collapsed(offset: start + emojis[index].length),
                  );
                  unawaited(_saveDraft(next));
                  Navigator.pop(sheetContext);
                  _inputFocus.requestFocus();
                },
                child: Center(child: Text(emojis[index], style: const TextStyle(fontSize: 25))),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _scrollToLatest({bool immediate = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_messagesScroll.hasClients) return;
      final position = _messagesScroll.position;
      if (!position.hasContentDimensions) return;
      final target = position.maxScrollExtent;
      if (immediate) {
        position.jumpTo(target);
      } else {
        _messagesScroll.animateTo(
          target,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
      if (_showJumpLatest) {
        setState(() => _showJumpLatest = false);
      }
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
        IconButton(
          tooltip: '保存到手机',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          onPressed: () => _saveAttachmentToDevice(message),
          icon: const Icon(Icons.download_rounded, size: 19, color: Color(0xFF666666)),
        ),
      ]),
    );
  }

  Future<void> _openAttachment(_ChatMessage message) async {
    final path = message.attachmentPath;
    if (path == null || !await File(path).exists()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('附件文件不存在')));
      return;
    }
    final extension = path.split('.').last.toLowerCase();
    if (extension == 'html' || extension == 'htm') {
      await _previewHtml(path);
    } else if (extension == 'pdf') {
      await _previewPdf(path, message.attachmentName ?? 'PDF 预览');
    } else if ({'mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'}.contains(extension)) {
      await _playAudio(path);
    } else {
      await OpenFilex.open(path);
    }
  }

  Future<void> _previewPdf(String path, String fileName) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.sizeOf(context).height * .86,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
              child: Row(children: [
                const Icon(Icons.picture_as_pdf_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close_rounded)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(child: PdfPreview(
              build: (_) => File(path).readAsBytes(),
              pdfFileName: fileName,
              canChangeOrientation: false,
              canChangePageFormat: false,
            )),
          ]),
        ),
      ),
    );
  }

  Future<void> _previewHtml(String path) async {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null || uri.scheme == 'file' || uri.scheme == 'about' || uri.scheme == 'data') return NavigationDecision.navigate;
          return NavigationDecision.prevent;
        },
      ))
      ..loadFile(path);
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(10),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.sizeOf(context).height * .82,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 9, 6, 9),
              child: Row(children: [
                const Icon(Icons.code_rounded, size: 18),
                const SizedBox(width: 8),
                const Expanded(child: Text('HTML 作品预览', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close_rounded)),
              ]),
            ),
            const Divider(height: 1),
            Expanded(child: WebViewWidget(controller: controller)),
          ]),
        ),
      ),
    );
  }

  Future<void> _playAudio(String path) async {
    final player = AudioPlayer();
    try {
      await player.setFilePath(path);
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.music_note_rounded, size: 34, color: Color(0xFF444444)),
              const SizedBox(height: 8),
              Text(path.split(Platform.pathSeparator).last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 14),
              StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, snapshot) {
                  final position = snapshot.data ?? Duration.zero;
                  final total = player.duration ?? Duration.zero;
                  final max = total.inMilliseconds.toDouble().clamp(1, double.infinity).toDouble();
                  return Column(children: [
                    Slider(value: position.inMilliseconds.toDouble().clamp(0, max).toDouble(), max: max, activeColor: const Color(0xFF333333), onChanged: (value) => player.seek(Duration(milliseconds: value.round()))),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text(_clockDuration(position), style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                      Text(_clockDuration(total), style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                    ]),
                  ]);
                },
              ),
              StreamBuilder<PlayerState>(
                stream: player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: const Color(0xFF222222), foregroundColor: Colors.white),
                    iconSize: 28,
                    onPressed: () => playing ? player.pause() : player.play(),
                    icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                  );
                },
              ),
            ]),
          ),
        ),
      );
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('无法播放音频：$error')));
    } finally {
      await player.dispose();
    }
  }

  String _clockDuration(Duration value) {
    final minutes = value.inMinutes.toString().padLeft(2, '0');
    final seconds = (value.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _saveChatImage(_ChatMessage message) async {
    String? imagePath = message.imagePath;
    File? downloadedFile;
    try {
      if (imagePath == null && message.stickerUrl != null) {
        final uri = Uri.tryParse(message.stickerUrl!);
        if (uri == null || !{'http', 'https'}.contains(uri.scheme)) {
          throw Exception('图片链接无效');
        }
        final response = await Dio().get<List<int>>(
          message.stickerUrl!,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: true,
            receiveTimeout: const Duration(seconds: 25),
            headers: const {'Accept': 'image/*'},
          ),
        );
        final bytes = response.data;
        if (bytes == null || bytes.isEmpty) throw Exception('没有获取到图片内容');
        if (bytes.length > 20 * 1024 * 1024) throw Exception('图片超过 20 MB，暂不支持保存');
        final contentType = response.headers.value(Headers.contentTypeHeader) ?? '';
        if (!contentType.toLowerCase().startsWith('image/')) {
          throw Exception('链接返回的内容不是图片');
        }
        final rawExtension = uri.pathSegments.isEmpty
            ? ''
            : uri.pathSegments.last.split('.').last.toLowerCase();
        final extension = const {'jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'}
                .contains(rawExtension)
            ? rawExtension
            : (contentType.toLowerCase().contains('png') ? 'png' : 'jpg');
        final tempDir = await getTemporaryDirectory();
        downloadedFile = File(
          '${tempDir.path}/chat_sticker_${DateTime.now().microsecondsSinceEpoch}.$extension',
        );
        await downloadedFile.writeAsBytes(bytes, flush: true);
        imagePath = downloadedFile.path;
      }
      if (imagePath == null || !await File(imagePath).exists()) {
        throw Exception('图片文件不存在');
      }
      await Gal.putImage(imagePath, album: 'Phone聊天');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('照片已保存到相册')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存照片失败：$error')),
        );
      }
    } finally {
      if (downloadedFile != null && await downloadedFile.exists()) {
        try {
          await downloadedFile.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> _saveAttachmentToDevice(_ChatMessage message) async {
    final sourcePath = message.attachmentPath;
    if (sourcePath == null) return;
    final source = File(sourcePath);
    if (!await source.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('附件文件不存在，可能已被系统清理')),
        );
      }
      return;
    }
    try {
      final bytes = await source.readAsBytes();
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: '保存聊天附件',
        fileName: message.attachmentName ?? source.uri.pathSegments.last,
        bytes: bytes,
      );
      if (!mounted || savedPath == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('附件已保存到你选择的位置')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存附件失败：$error')),
      );
    }
  }

  Future<void> _saveCodeBlockAsFile(_ChatMessage message) async {
    final match = RegExp(r'```([a-zA-Z0-9_+-]*)\s*\n([\s\S]*?)\n?```').firstMatch(message.text);
    if (match == null) return;
    final language = (match.group(1) ?? '').toLowerCase();
    final extension = switch (language) {
      'html' => 'html', 'css' => 'css', 'js' || 'javascript' => 'js',
      'dart' => 'dart', 'py' || 'python' => 'py', 'json' => 'json',
      'md' || 'markdown' => 'md', 'xml' => 'xml', 'svg' => 'svg',
      'txt' || '' => 'txt', _ => language.replaceAll(RegExp(r'[^a-z0-9]'), '').isEmpty ? 'txt' : language,
    };
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/chat_media');
    if (!await mediaDir.exists()) await mediaDir.create(recursive: true);
    final target = File('${mediaDir.path}/assistant_${DateTime.now().microsecondsSinceEpoch}.$extension');
    await target.writeAsString(match.group(2) ?? '');
    if (!mounted) return;
    final index = _messages.indexOf(message);
    if (index < 0) return;
    setState(() {
      _messages[index] = _ChatMessage(text: message.text, mine: message.mine, time: message.time, reasoning: message.reasoning, imagePath: message.imagePath, stickerUrl: message.stickerUrl, audioPath: message.audioPath, audioDurationMs: message.audioDurationMs, attachmentPath: target.path, attachmentName: target.uri.pathSegments.last, attachmentSize: target.lengthSync(), alternateReplies: message.alternateReplies, selectedAlternative: message.selectedAlternative);
    });
    await _persistChat();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已生成文件：${target.uri.pathSegments.last}')));
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
