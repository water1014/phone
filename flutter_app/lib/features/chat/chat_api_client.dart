import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatApiConfig {
  const ChatApiConfig({
    this.provider = 'deepseek',
    this.baseUrl = 'https://api.deepseek.com',
    this.model = 'deepseek-chat',
    this.apiKey = '',
    this.customHeaders = '',
  });

  final String provider;
  final String baseUrl;
  final String model;
  final String apiKey;
  final String customHeaders;

  bool get usesOpenCodeSession => provider == 'opencode';

  ChatApiConfig copyWith({
    String? provider,
    String? baseUrl,
    String? model,
    String? apiKey,
    String? customHeaders,
  }) => ChatApiConfig(
    provider: provider ?? this.provider,
    baseUrl: baseUrl ?? this.baseUrl,
    model: model ?? this.model,
    apiKey: apiKey ?? this.apiKey,
    customHeaders: customHeaders ?? this.customHeaders,
  );

  static ChatApiConfig defaultsFor(String provider) {
    switch (provider) {
      case 'opencode':
        return const ChatApiConfig(
          provider: 'opencode',
          baseUrl: 'https://opencode.ai/inference/go',
          model: 'deepseek-v4.1-flash',
        );
      case 'openai':
        return const ChatApiConfig(provider: 'openai', baseUrl: '', model: '');
      default:
        return const ChatApiConfig();
    }
  }
}

abstract final class ChatApiConfigStore {
  static const _secure = FlutterSecureStorage();
  static const _providerKey = 'chat.api.provider';
  static const _urlKey = 'chat.api.url';
  static const _modelKey = 'chat.api.model';
  static const _apiKeyKey = 'chat.api.key';
  static const _headersKey = 'chat.api.headers';

  static Future<ChatApiConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final provider = prefs.getString(_providerKey) ?? 'deepseek';
    final defaults = ChatApiConfig.defaultsFor(provider);
    return ChatApiConfig(
      provider: provider,
      baseUrl: prefs.getString(_urlKey) ?? defaults.baseUrl,
      model: prefs.getString(_modelKey) ?? defaults.model,
      apiKey: await _secure.read(key: _apiKeyKey) ?? '',
      customHeaders: await _secure.read(key: _headersKey) ?? '',
    );
  }

  static Future<void> save(ChatApiConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_providerKey, config.provider);
    await prefs.setString(_urlKey, config.baseUrl.trim());
    await prefs.setString(_modelKey, config.model.trim());
    await _secure.write(key: _apiKeyKey, value: config.apiKey);
    await _secure.write(key: _headersKey, value: config.customHeaders);
  }
}

class ChatStreamEvent {
  const ChatStreamEvent({
    this.textDelta = '',
    this.reasoningDelta = '',
    this.inputTokens,
    this.outputTokens,
    this.finished = false,
  });

  final String textDelta;
  final String reasoningDelta;
  final int? inputTokens;
  final int? outputTokens;
  final bool finished;
}

class ChatApiClient {
  ChatApiClient({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static bool validateHeaders(String source) {
    final decoded = jsonDecode(source);
    return decoded is Map<String, dynamic>;
  }

  String _base(String url) => url.trim().replaceAll(RegExp(r'/+$'), '')
      .replaceFirst(RegExp(r'/chat/completions$'), '');

  List<String> _completionCandidates(String url) {
    final raw = url.trim().replaceAll(RegExp(r'/+$'), '');
    final base = _base(raw);
    if (base.isEmpty) return const [];
    final candidates = <String>[];
    if (raw.endsWith('/chat/completions')) candidates.add(raw);
    candidates.add('$base/v1/chat/completions');
    candidates.add('$base/chat/completions');
    return candidates.toSet().toList();
  }

  Future<Map<String, dynamic>> _headers(ChatApiConfig config) async {
    final result = <String, dynamic>{
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream, application/json',
    };
    if (config.apiKey.trim().isNotEmpty) {
      result['Authorization'] = 'Bearer ${config.apiKey.trim()}';
    }
    if (config.customHeaders.trim().isNotEmpty) {
      final decoded = jsonDecode(config.customHeaders);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('自定义请求头必须是 JSON 对象');
      }
      decoded.forEach((key, value) {
        if (key.trim().isNotEmpty && value != null) result[key] = value.toString();
      });
    }
    if (config.usesOpenCodeSession &&
        !result.keys.any((key) => key.toLowerCase() == 'x-opencode-session')) {
      final prefs = await SharedPreferences.getInstance();
      var session = prefs.getString('chat.opencode.session');
      if (session == null || session.isEmpty) {
        session = 'xw-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
        await prefs.setString('chat.opencode.session', session);
      }
      result['x-opencode-session'] = session;
    }
    return result;
  }

  Stream<ChatStreamEvent> streamReply({
    required ChatApiConfig config,
    required List<Map<String, dynamic>> messages,
  }) async* {
    if (config.apiKey.trim().isEmpty) {
      throw Exception('请先在聊天设置中填写 API Key');
    }
    if (config.baseUrl.trim().isEmpty) {
      throw Exception('请先填写接口地址');
    }
    if (config.model.trim().isEmpty) {
      throw Exception('请先填写模型名称');
    }

    final headers = await _headers(config);
    final candidates = _completionCandidates(config.baseUrl);
    if (candidates.isEmpty) throw Exception('接口地址无效');
    Object? lastError;

    for (final url in candidates) {
      Response<ResponseBody> response;
      try {
        response = await _dio.post<ResponseBody>(
          url,
          data: {
            'model': config.model.trim(),
            'messages': messages,
            'stream': true,
          },
          options: Options(
            responseType: ResponseType.stream,
            headers: headers,
            validateStatus: (status) => status != null && status < 500,
            receiveTimeout: const Duration(minutes: 3),
          ),
        );
      } on DioException catch (error) {
        lastError = error;
        continue;
      }

      final status = response.statusCode ?? 0;
      if (status == 404 || status == 405) {
        lastError = Exception('接口路径不存在：$url');
        continue;
      }
      if (status < 200 || status >= 300) {
        final detail = response.data == null ? '' : await utf8.decoder.bind(response.data!.stream).join();
        throw Exception('HTTP $status${detail.isEmpty ? '' : '：${detail.substring(0, detail.length < 240 ? detail.length : 240)}'}');
      }

      final contentType = response.headers.value('content-type') ?? '';
      if (contentType.contains('application/json')) {
        final raw = await utf8.decoder.bind(response.data!.stream).join();
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final choice = (decoded['choices'] as List?)?.firstOrNull as Map?;
        final message = choice?['message'] as Map?;
        final content = message?['content'];
        final text = content is String
            ? content
            : content is List
                ? content.map((part) => part is Map ? part['text'] ?? '' : '').join()
                : '';
        final reasoning = message?['reasoning_content'] ?? message?['reasoning'] ?? '';
        final usage = decoded['usage'] as Map?;
        yield ChatStreamEvent(
          textDelta: text.toString(),
          reasoningDelta: reasoning.toString(),
          inputTokens: (usage?['prompt_tokens'] as num?)?.toInt(),
          outputTokens: (usage?['completion_tokens'] as num?)?.toInt(),
        );
        yield const ChatStreamEvent(finished: true);
        return;
      }

      await for (final line in response.data!.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        if (!line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        if (data.isEmpty) continue;
        if (data == '[DONE]') {
          yield const ChatStreamEvent(finished: true);
          return;
        }
        try {
          final decoded = jsonDecode(data) as Map<String, dynamic>;
          final choice = (decoded['choices'] as List?)?.firstOrNull as Map?;
          final delta = choice?['delta'] as Map? ?? choice?['message'] as Map?;
          final content = delta?['content'];
          final text = content is String
              ? content
              : content is List
                  ? content.map((part) => part is Map ? part['text'] ?? '' : '').join()
                  : '';
          final reasoning = delta?['reasoning_content'] ?? delta?['reasoning'] ?? '';
          final usage = decoded['usage'] as Map?;
          yield ChatStreamEvent(
            textDelta: text.toString(),
            reasoningDelta: reasoning.toString(),
            inputTokens: (usage?['prompt_tokens'] as num?)?.toInt(),
            outputTokens: (usage?['completion_tokens'] as num?)?.toInt(),
          );
        } on FormatException {
          continue;
        }
      }
      yield const ChatStreamEvent(finished: true);
      return;
    }

    throw Exception('连接失败：$lastError');
  }
}
