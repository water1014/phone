import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'chat_preferences.dart';

const _ink = Color(0xFF202020);
const _muted = Color(0xFF888888);
const _line = Color(0xFFE7E7E7);

Color _beautyColor(String value, Color fallback) {
  final raw = value.trim().replaceAll('#', '');
  try {
    if (raw.length == 6) return Color(0xFF000000 | int.parse(raw, radix: 16));
    if (raw.length == 8) return Color(int.parse(raw, radix: 16));
  } catch (_) {}
  final rgba = RegExp(r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)(?:\s*,\s*([\d.]+))?\s*\)', caseSensitive: false).firstMatch(value);
  if (rgba != null) {
    final r = int.parse(rgba.group(1)!).clamp(0, 255);
    final g = int.parse(rgba.group(2)!).clamp(0, 255);
    final b = int.parse(rgba.group(3)!).clamp(0, 255);
    final a = ((double.tryParse(rgba.group(4) ?? '1') ?? 1).clamp(0, 1) * 255).round();
    return Color.fromARGB(a, r, g, b);
  }
  return fallback;
}

String _hex(Color color) => '#\${color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

class ChatBeautifyPage extends StatefulWidget {
  const ChatBeautifyPage({super.key});

  @override
  State<ChatBeautifyPage> createState() => _ChatBeautifyPageState();
}

class _ChatBeautifyPageState extends State<ChatBeautifyPage> {
  bool _busy = false;
  String _notice = '';

  Future<void> _update(ChatPreferences next) => ChatPreferenceStore.update(next);

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ChatPreferences>(
    valueListenable: ChatPreferenceStore.value,
    builder: (context, prefs, _) => Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 8, 18, 12),
            child: Row(children: [
              IconButton(onPressed: () => Navigator.of(context).maybePop(), icon: const Icon(Icons.chevron_left_rounded, size: 28, color: _ink)),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('CHAT BEAUTY STUDIO', style: TextStyle(fontSize: 9, letterSpacing: 1.4, fontWeight: FontWeight.w600, color: _muted)),
                SizedBox(height: 4),
                Text('聊天美化', style: TextStyle(fontSize: 21, height: 1.1, fontWeight: FontWeight.w600, color: _ink)),
              ])),
              IconButton(tooltip: '恢复默认', onPressed: () => _reset(prefs), icon: const Icon(Icons.restart_alt_rounded, color: _muted)),
            ]),
          ),
          Expanded(child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            children: [
              _preview(prefs),
              const SizedBox(height: 17),
              _section('先挑一个顺眼的底子', '预设只是起点，之后每个细节都能继续调整', [
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _presetChip(prefs, '雾白', const Color(0xFFFAFAFA), const Color(0xFF333333), const Color(0xFFFFFFFF), const Color(0xFFE7E7E7), const Color(0xFFF3F8F8)),
                  _presetChip(prefs, '湖光', const Color(0xFFF0F7F8), const Color(0xFF6F9EAA), const Color(0xFFE4F0F1), const Color(0xFFDCE8E9), const Color(0xFFEAF3F4)),
                  _presetChip(prefs, '微信', const Color(0xFFF2F2F2), const Color(0xFF95D39A), const Color(0xFFFFFFFF), const Color(0xFFE4E4E4), const Color(0xFFF2F2F2)),
                  _presetChip(prefs, '深海', const Color(0xFF202D32), const Color(0xFF47636A), const Color(0xFF31464D), const Color(0xFF40545A), const Color(0xFF29383E)),
                  _presetChip(prefs, '黑白', const Color(0xFFF7F7F7), const Color(0xFF222222), const Color(0xFFFFFFFF), const Color(0xFFE0E0E0), const Color(0xFFF0F0F0)),
                ]),
              ]),
              const SizedBox(height: 13),
              _section('界面颜色', '点选色卡，预览会同步变化', [
                _colorRow('聊天底色', prefs.chatPageColor, (v) => _update(prefs.copyWith(chatPageColor: v))),
                _colorRow('顶部栏', prefs.chatHeaderColor, (v) => _update(prefs.copyWith(chatHeaderColor: v))),
                _colorRow('底部输入区', prefs.chatComposerColor, (v) => _update(prefs.copyWith(chatComposerColor: v))),
                _colorRow('输入框', prefs.chatInputColor, (v) => _update(prefs.copyWith(chatInputColor: v))),
                _colorRow('细边框', prefs.chatBorderColor, (v) => _update(prefs.copyWith(chatBorderColor: v))),
              ]),
              const SizedBox(height: 13),
              _section('气泡与文字', '我的消息和宋祁的消息分开调整', [
                _colorRow('我的气泡', prefs.myBubbleColor, (v) => _update(prefs.copyWith(myBubbleColor: v))),
                _colorRow('我的文字', prefs.myTextColor, (v) => _update(prefs.copyWith(myTextColor: v))),
                _colorRow('宋祁的气泡', prefs.partnerBubbleColor, (v) => _update(prefs.copyWith(partnerBubbleColor: v))),
                _colorRow('宋祁的文字', prefs.partnerTextColor, (v) => _update(prefs.copyWith(partnerTextColor: v))),
                _slider('我的气泡透明度', prefs.myBubbleOpacity, 0.35, 1, (v) => _update(prefs.copyWith(myBubbleOpacity: v)), suffix: '%', percent: true),
                _slider('宋祁气泡透明度', prefs.partnerBubbleOpacity, 0.35, 1, (v) => _update(prefs.copyWith(partnerBubbleOpacity: v)), suffix: '%', percent: true),
                _slider('气泡圆角', prefs.bubbleRadius, 8, 30, (v) => _update(prefs.copyWith(bubbleRadius: v)), suffix: ' px'),
                _slider('消息间距', prefs.chatSpacing, 2, 22, (v) => _update(prefs.copyWith(chatSpacing: v)), suffix: ' px'),
                _slider('消息字号', prefs.fontSize, 12, 20, (v) => _update(prefs.copyWith(fontSize: v)), suffix: ' px'),
              ]),
              const SizedBox(height: 13),
              _section('输入框细节', '输入区圆角也可以单独调', [
                _slider('输入框圆角', prefs.chatInputRadius, 10, 32, (v) => _update(prefs.copyWith(chatInputRadius: v)), suffix: ' px'),
              ]),
              const SizedBox(height: 13),
              _section('糯米机装扮兼容', '直接读取 sullyos-chat-decoration v1 结构化装扮包', [
                Row(children: [
                  Expanded(child: OutlinedButton.icon(
                    onPressed: _busy ? null : _importDecoration,
                    icon: const Icon(Icons.file_open_outlined, size: 17),
                    label: const Text('导入糯米机 JSON'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(
                    onPressed: _busy ? null : () => _exportDecoration(prefs),
                    icon: const Icon(Icons.ios_share_rounded, size: 17),
                    label: const Text('导出兼容 JSON'),
                  )),
                ]),
                const SizedBox(height: 7),
                const Text('可自动适配布局、气泡颜色/文字/圆角/透明度、气泡图片与聊天背景。糯米机的原始 CSS、声音和 Flutter 尚未实现的高级效果不会被强行执行，避免导入后界面错乱。', style: TextStyle(fontSize: 10, height: 1.55, color: _muted)),
                if (_notice.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_notice, style: const TextStyle(fontSize: 10, height: 1.5, color: Color(0xFF557E72)))),
              ]),
            ],
          )),
        ]),
      ),
    ),
  );

  Widget _preview(ChatPreferences p) {
    final page = _beautyColor(p.chatPageColor, const Color(0xFFFAFAFA));
    final header = _beautyColor(p.chatHeaderColor, page);
    final composer = _beautyColor(p.chatComposerColor, page);
    final input = _beautyColor(p.chatInputColor, Colors.white);
    final mine = _beautyColor(p.myBubbleColor, const Color(0xFF333333)).withValues(alpha: p.myBubbleOpacity);
    final partner = _beautyColor(p.partnerBubbleColor, Colors.white).withValues(alpha: p.partnerBubbleOpacity);
    final mineText = _beautyColor(p.myTextColor, Colors.white);
    final partnerText = _beautyColor(p.partnerTextColor, _ink);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: page, borderRadius: BorderRadius.circular(23), border: Border.all(color: _line)),
      child: Column(children: [
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(color: header, border: Border(bottom: BorderSide(color: _beautyColor(p.chatBorderColor, _line)))),
          child: Row(children: [
            const Icon(Icons.menu_rounded, size: 18, color: _muted),
            const Spacer(),
            const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('宋祁', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink)),
              Text('在这里陪你', style: TextStyle(fontSize: 8, color: _muted)),
            ]),
            const Spacer(),
            const Icon(Icons.more_horiz_rounded, size: 18, color: _muted),
          ]),
        ),
        Container(
          height: 166,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Align(alignment: Alignment.centerLeft, child: Container(
              constraints: const BoxConstraints(maxWidth: 225),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(color: partner, borderRadius: BorderRadius.circular(p.bubbleRadius)),
              child: Text('今天想和你一起把聊天界面布置得漂亮一点。', style: TextStyle(fontSize: 10, height: 1.4, color: partnerText)),
            )),
            Align(alignment: Alignment.centerRight, child: Container(
              constraints: const BoxConstraints(maxWidth: 220),
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              decoration: BoxDecoration(color: mine, borderRadius: BorderRadius.circular(p.bubbleRadius)),
              child: Text('好呀，我们慢慢调成喜欢的样子。', style: TextStyle(fontSize: 10, height: 1.4, color: mineText)),
            )),
          ]),
        ),
        Container(
          color: composer,
          padding: const EdgeInsets.all(9),
          child: Container(
            height: 39,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: input, borderRadius: BorderRadius.circular(p.chatInputRadius), border: Border.all(color: _beautyColor(p.chatBorderColor, _line))),
            child: const Row(children: [
              Icon(Icons.add_rounded, size: 17, color: _muted),
              SizedBox(width: 8),
              Expanded(child: Text('说点什么吧…', style: TextStyle(fontSize: 10, color: _muted))),
              Icon(Icons.emoji_emotions_outlined, size: 16, color: _muted),
              SizedBox(width: 8),
              Icon(Icons.arrow_upward_rounded, size: 16, color: _muted),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _section(String title, String subtitle, List<Widget> children) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: _line)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(fontSize: 10, color: _muted)),
      const SizedBox(height: 12),
      ...children,
    ]),
  );

  Widget _presetChip(ChatPreferences p, String name, Color page, Color mine, Color partner, Color input, Color composer) {
    final selected = p.chatThemeName == name;
    return ChoiceChip(
      label: Text(name),
      selected: selected,
      onSelected: (_) => _applyPreset(p, name, page, mine, partner, input, composer),
      selectedColor: const Color(0xFFE8EEEE),
      backgroundColor: Colors.white,
      side: BorderSide(color: selected ? const Color(0xFF9AB6B9) : _line),
      showCheckmark: false,
      labelStyle: TextStyle(fontSize: 11, color: selected ? _ink : _muted),
    );
  }

  Future<void> _applyPreset(ChatPreferences p, String name, Color page, Color mine, Color partner, Color input, Color composer) async {
    await _update(p.copyWith(
      chatThemeName: name,
      chatPageColor: _hex(page),
      chatHeaderColor: _hex(page),
      chatComposerColor: _hex(composer),
      chatInputColor: _hex(input),
      chatBorderColor: _hex(page.computeLuminance() > .5 ? const Color(0xFFE2E6E6) : const Color(0xFF40545A)),
      myBubbleColor: _hex(mine),
      partnerBubbleColor: _hex(partner),
      myTextColor: mine.computeLuminance() < .35 ? '#FFFFFF' : '#263238',
      partnerTextColor: partner.computeLuminance() < .35 ? '#FFFFFF' : '#263238',
      myBubbleOpacity: 1,
      partnerBubbleOpacity: 1,
    ));
  }

  Widget _colorRow(String label, String selected, ValueChanged<String> onChanged) {
    const colors = ['#FAFAFA','#F0F7F8','#EAF3F4','#FFFFFF','#F2F2F2','#E7ECEC','#DCE8E9','#DDE9E2','#BFD4D7','#95D39A','#82AEB7','#6F9EAA','#47636A','#333333','#222222','#202D32'];
    final active = selected.toUpperCase();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 11, color: _ink)),
        const SizedBox(height: 7),
        Wrap(spacing: 7, runSpacing: 7, children: colors.map((hex) {
          final color = _beautyColor(hex, Colors.white);
          final isActive = active == hex;
          return GestureDetector(
            onTap: () => onChanged(hex),
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: isActive ? const Color(0xFF638C91) : const Color(0xFFD9DEDE), width: isActive ? 2.2 : .8)),
              child: isActive ? Icon(Icons.check_rounded, size: 13, color: color.computeLuminance() < .35 ? Colors.white : _ink) : null,
            ),
          );
        }).toList()),
      ]),
    );
  }

  Widget _slider(String label, double value, double min, double max, ValueChanged<double> onChanged, {String suffix = '', bool percent = false}) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Column(children: [
      Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 11, color: _ink))),
        Text(percent ? '\${(value * 100).round()}%' : '\${value.round()}$suffix', style: const TextStyle(fontSize: 10, color: _muted)),
      ]),
      Slider(value: value.clamp(min, max).toDouble(), min: min, max: max, activeColor: const Color(0xFF789EA4), onChanged: onChanged),
    ]),
  );

  Future<String?> _storeResource(String? value, String prefix) async {
    if (value == null || value.isEmpty) return null;
    if (!value.startsWith('data:image/')) return null;
    final comma = value.indexOf(',');
    if (comma < 0) return null;
    final header = value.substring(0, comma);
    final mime = RegExp(r'data:image/([\w.+-]+);base64', caseSensitive: false).firstMatch(header);
    if (mime == null) return null;
    final bytes = base64Decode(value.substring(comma + 1));
    if (bytes.length > 18 * 1024 * 1024) throw Exception('图片素材超过 18 MB');
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory('\${dir.path}/chat_beauty_assets');
    if (!await folder.exists()) await folder.create(recursive: true);
    final ext = mime.group(1)!.toLowerCase().replaceAll('jpeg', 'jpg');
    final file = File('\${folder.path}/\${prefix}_\${DateTime.now().microsecondsSinceEpoch}.$ext');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String?> _fileToDataUrl(String path) async {
    if (path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    final ext = path.split('.').last.toLowerCase();
    final mime = ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : ext == 'webp' ? 'image/webp' : 'image/png';
    return 'data:$mime;base64,\${base64Encode(bytes)}';
  }

  Future<void> _importDecoration() async {
    try {
      final picked = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: const ['json'], withData: true);
      if (picked == null || picked.files.isEmpty) return;
      final bytes = picked.files.single.bytes;
      if (bytes == null) throw Exception('无法读取文件内容');
      if (bytes.length > 40 * 1024 * 1024) throw Exception('装扮文件超过 40 MB');
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) throw Exception('这不是有效的糯米机装扮 JSON');
      final root = Map<String, dynamic>.from(decoded);
      Map<String, dynamic> parts;
      if (root['format'] == 'sullyos-chat-decoration' && root['version'] == 1 && root['parts'] is Map) {
        parts = Map<String, dynamic>.from(root['parts'] as Map);
      } else if (root['user'] is Map && root['ai'] is Map) {
        parts = {'bubbles': root};
      } else {
        throw Exception('暂不支持此文件格式，请选择糯米机导出的 sullyos-chat-decoration v1 JSON');
      }
      final current = ChatPreferenceStore.value.value;
      var next = current.copyWith(chatThemeName: (root['name'] ?? picked.files.single.name).toString().replaceAll(RegExp(r'\.json$', caseSensitive: false), ''));
      final layout = parts['layout'];
      if (layout is Map) {
        final visibility = layout['chatAvatarVisibility']?.toString();
        if (visibility == 'both') next = next.copyWith(showAvatar: true);
        if (visibility == 'hide_both') next = next.copyWith(showAvatar: false);
        final spacing = layout['chatMessageSpacing']?.toString();
        if (spacing == 'compact') next = next.copyWith(compact: true, chatSpacing: 4);
        if (spacing == 'default') next = next.copyWith(compact: false, chatSpacing: 9);
        if (spacing == 'spacious') next = next.copyWith(compact: false, chatSpacing: 16);
        final timestamp = layout['chatShowTimestamp']?.toString();
        if (timestamp == 'always') next = next.copyWith(showTime: true);
        if (timestamp == 'never') next = next.copyWith(showTime: false);
        final bubbleStyle = layout['chatBubbleStyle']?.toString();
        if (bubbleStyle != null) next = next.copyWith(bubbleStyle: ['wechat','ios','flat'].contains(bubbleStyle) ? 1 : 0);
        final fontSize = num.tryParse('\${layout['chatBubbleFontSize'] ?? ''}');
        if (fontSize != null && fontSize > 0) next = next.copyWith(fontSize: fontSize.toDouble().clamp(12, 20));
        final headerStyle = layout['chatHeaderStyle']?.toString();
        if (headerStyle == 'minimal') next = next.copyWith(chatHeaderColor: next.chatPageColor);
        if (layout['chatChromeStyle'] == 'flat') next = next.copyWith(chatComposerColor: next.chatPageColor);
      }
      final bubbles = parts['bubbles'];
      if (bubbles is Map) {
        final user = bubbles['user'] is Map ? Map<String, dynamic>.from(bubbles['user']) : <String, dynamic>{};
        final ai = bubbles['ai'] is Map ? Map<String, dynamic>.from(bubbles['ai']) : <String, dynamic>{};
        if (user['backgroundColor'] is String) next = next.copyWith(myBubbleColor: _hex(_beautyColor(user['backgroundColor'], _beautyColor(next.myBubbleColor, const Color(0xFF333333)))));
        if (ai['backgroundColor'] is String) next = next.copyWith(partnerBubbleColor: _hex(_beautyColor(ai['backgroundColor'], _beautyColor(next.partnerBubbleColor, Colors.white))));
        if (user['textColor'] is String) next = next.copyWith(myTextColor: _hex(_beautyColor(user['textColor'], Colors.white)));
        if (ai['textColor'] is String) next = next.copyWith(partnerTextColor: _hex(_beautyColor(ai['textColor'], _ink)));
        final userOpacity = num.tryParse('\${user['opacity'] ?? ''}');
        final aiOpacity = num.tryParse('\${ai['opacity'] ?? ''}');
        if (userOpacity != null) next = next.copyWith(myBubbleOpacity: userOpacity.toDouble().clamp(0, 1));
        if (aiOpacity != null) next = next.copyWith(partnerBubbleOpacity: aiOpacity.toDouble().clamp(0, 1));
        final userRadius = num.tryParse('\${user['borderRadius'] ?? ''}');
        final aiRadius = num.tryParse('\${ai['borderRadius'] ?? ''}');
        final radii = [if (userRadius != null) userRadius.toDouble(), if (aiRadius != null) aiRadius.toDouble()];
        if (radii.isNotEmpty) next = next.copyWith(bubbleRadius: (radii.reduce((a,b)=>a+b) / radii.length).clamp(8, 30));
        final userImage = await _storeResource(user['backgroundImage']?.toString(), 'my_bubble');
        final aiImage = await _storeResource(ai['backgroundImage']?.toString(), 'partner_bubble');
        if (userImage != null) next = next.copyWith(myBubbleImagePath: userImage);
        if (aiImage != null) next = next.copyWith(partnerBubbleImagePath: aiImage);
      }
      final background = parts['background'];
      if (background is Map) {
        final image = await _storeResource(background['image']?.toString(), 'wallpaper');
        if (image != null) next = next.copyWith(chatWallpaperPath: image, wallpaperScale: 1, wallpaperPositionX: 0, wallpaperPositionY: 0);
      }
      await _update(next);
      final unsupported = <String>[];
      if (parts['css'] is String && (parts['css'] as String).trim().isNotEmpty) unsupported.add('自定义 CSS（Flutter 原生界面不能直接执行 CSS）');
      if (parts.containsKey('sound')) unsupported.add('消息提示音');
      if (bubbles is Map && ((bubbles['user'] is Map && (bubbles['user']['decoration'] != null || bubbles['user']['avatarDecoration'] != null)) || (bubbles['ai'] is Map && (bubbles['ai']['decoration'] != null || bubbles['ai']['avatarDecoration'] != null)))) unsupported.add('气泡/头像装饰贴图');
      if (mounted) setState(() => _notice = unsupported.isEmpty ? '导入完成，已应用可兼容的布局、背景与气泡样式。' : '已导入并应用可兼容部分；暂未适配：\${unsupported.join('、')}。');
    } catch (error) {
      if (mounted) setState(() => _notice = '导入失败：$error');
    }
  }

  Future<void> _exportDecoration(ChatPreferences p) async {
    try {
      final userImage = await _fileToDataUrl(p.myBubbleImagePath);
      final aiImage = await _fileToDataUrl(p.partnerBubbleImagePath);
      final wallpaper = await _fileToDataUrl(p.chatWallpaperPath ?? '');
      final data = {
        'format': 'sullyos-chat-decoration',
        'version': 1,
        'name': p.chatThemeName,
        'parts': {
          'layout': {
            'chatAvatarVisibility': p.showAvatar ? 'both' : 'hide_both',
            'chatBubbleStyle': p.bubbleStyle == 1 ? 'wechat' : 'modern',
            'chatMessageSpacing': p.compact ? 'compact' : 'spacious',
            'chatShowTimestamp': p.showTime ? 'always' : 'never',
            'chatBubbleFontSize': p.fontSize,
          },
          'bubbles': {
            'name': p.chatThemeName,
            'user': {
              'backgroundColor': p.myBubbleColor,
              'textColor': p.myTextColor,
              'borderRadius': p.bubbleRadius,
              'opacity': p.myBubbleOpacity,
              if (userImage != null) 'backgroundImage': userImage,
            },
            'ai': {
              'backgroundColor': p.partnerBubbleColor,
              'textColor': p.partnerTextColor,
              'borderRadius': p.bubbleRadius,
              'opacity': p.partnerBubbleOpacity,
              if (aiImage != null) 'backgroundImage': aiImage,
            },
          },
          'background': {'image': wallpaper, 'style': 'plain'},
        },
      };
      final bytes = Uint8List.fromList(utf8.encode(const JsonEncoder.withIndent('  ').convert(data)));
      await FilePicker.platform.saveFile(fileName: '\${p.chatThemeName}_糯米机兼容装扮.json', bytes: bytes);
      if (mounted) setState(() => _notice = '已生成糯米机兼容 JSON 文件。');
    } catch (error) {
      if (mounted) setState(() => _notice = '导出失败：$error');
    }
  }

  Future<void> _reset(ChatPreferences p) async {
    await _update(p.copyWith(
      chatThemeName: '雾白',
      chatPageColor: '#FAFAFA',
      chatHeaderColor: '#FAFAFA',
      chatComposerColor: '#FAFAFA',
      chatInputColor: '#FFFFFF',
      chatBorderColor: '#E7E7E7',
      myBubbleColor: '#333333',
      partnerBubbleColor: '#FFFFFF',
      myTextColor: '#FFFFFF',
      partnerTextColor: '#222222',
      myBubbleOpacity: 1,
      partnerBubbleOpacity: 1,
      myBubbleImagePath: '',
      partnerBubbleImagePath: '',
      bubbleRadius: 19,
      chatInputRadius: 23,
      chatSpacing: 9,
    ));
    if (mounted) setState(() => _notice = '已恢复默认聊天美化。');
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) super.setState(fn);
  }
}
