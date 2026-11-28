import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'chat_preferences.dart';

const _ink = Color(0xFF202020);
const _muted = Color(0xFF888888);
const _line = Color(0xFFE7E7E7);
const _soft = Color(0xFFF3F3F3);
const _accent = Color(0xFF333333);

class ChatSettingsPage extends StatelessWidget {
  const ChatSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ChatPreferences>(
    valueListenable: ChatPreferenceStore.value,
    builder: (context, prefs, _) => Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 8, 20, 17),
            child: Row(children: [
              IconButton(
                tooltip: '返回聊天',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.chevron_left_rounded, size: 29, color: _ink),
              ),
              const SizedBox(width: 5),
              const Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CHAT PREFERENCES', style: TextStyle(fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w600, color: _muted)),
                  SizedBox(height: 4),
                  Text('聊天设置', style: TextStyle(fontSize: 22, height: 1.1, fontWeight: FontWeight.w600, color: _ink)),
                  SizedBox(height: 4),
                  Text('把聊天调整成舒服的样子', style: TextStyle(fontSize: 11, color: _muted)),
                ],
              )),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
              children: [
                _SettingsSection(
                  icon: Icons.chat_bubble_outline_rounded,
                  title: '消息外观',
                  subtitle: '对话中的头像、昵称与排版',
                  children: [
                    _PreferenceSwitch(
                      icon: Icons.account_circle_outlined,
                      title: '显示头像',
                      subtitle: '关闭后气泡直接贴近左右边缘，不保留头像空位',
                      value: prefs.showAvatar,
                      onChanged: (v) => _update(prefs.copyWith(showAvatar: v)),
                    ),
                    _PreferenceSwitch(
                      icon: Icons.badge_outlined,
                      title: '显示对方昵称',
                      subtitle: '在每组对方消息上方显示昵称',
                      value: prefs.showName,
                      onChanged: (v) => _update(prefs.copyWith(showName: v)),
                    ),
                    _SettingsAction(
                    icon: Icons.person_outline_rounded,
                    title: '对方昵称',
                    value: prefs.partnerName,
                    onTap: () => _editName(context, prefs, partner: true),
                  ),
                  _SettingsAction(
                    icon: Icons.person_rounded,
                    title: '我的昵称',
                    value: prefs.myName,
                    onTap: () => _editName(context, prefs, partner: false),
                  ),
                  _SettingsAction(
                    icon: Icons.face_rounded,
                    title: '宋祁的头像',
                    value: prefs.partnerAvatarPath == null ? '选择照片' : '已设置 · 更换',
                    onTap: () => _pickAvatar(context, prefs, partner: true),
                  ),
                  _SettingsAction(
                    icon: Icons.account_circle_rounded,
                    title: '我的头像',
                    value: prefs.myAvatarPath == null ? '选择照片' : '已设置 · 更换',
                    onTap: () => _pickAvatar(context, prefs, partner: false),
                  ),
                  const SizedBox(height: 7),
                  _BubbleStylePicker(
                    selected: prefs.bubbleStyle,
                    onChanged: (v) => _update(prefs.copyWith(bubbleStyle: v)),
                  ),
                  _PreferenceSwitch(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: '显示聊天气泡',
                    subtitle: '关闭后保留左右聊天排版，但文字不再放在色块气泡里',
                    value: prefs.showBubbles,
                    onChanged: (v) => _update(prefs.copyWith(showBubbles: v)),
                  ),
                  _ReplyLayoutPicker(
                    selected: prefs.replyLayout,
                    onChanged: (v) => _update(prefs.copyWith(replyLayout: v)),
                  ),
                  _SettingsAction(
                    icon: Icons.flash_on_outlined,
                    title: '常用语',
                    value: prefs.quickReplies.isEmpty ? '未设置' : prefs.quickReplies.join(' · '),
                    onTap: () => _editQuickReplies(context, prefs),
                  ),
                  _PreferenceSwitch(
                      icon: Icons.schedule_rounded,
                      title: '显示消息时间',
                      subtitle: '在消息下方标记发送时间',
                      value: prefs.showTime,
                      onChanged: (v) => _update(prefs.copyWith(showTime: v)),
                    ),
                    _PreferenceSwitch(
                      icon: Icons.notes_rounded,
                      title: '合并连续消息',
                      subtitle: '同一方连续发送时收紧气泡间距',
                      value: prefs.compact,
                      onChanged: (v) => _update(prefs.copyWith(compact: v)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 13, 0, 2),
                      child: Row(children: [
                        const _SettingIcon(icon: Icons.text_fields_rounded),
                        const SizedBox(width: 11),
                        const Expanded(child: Text('消息字体大小', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _ink))),
                        Text('${prefs.fontSize.round()} px', style: const TextStyle(fontSize: 11, color: _muted)),
                      ]),
                    ),
                    Slider(
                      value: prefs.fontSize.clamp(12, 20).toDouble(),
                      min: 12,
                      max: 20,
                      divisions: 8,
                      activeColor: _accent,
                      inactiveColor: const Color(0xFFE7ECE8),
                      onChanged: (v) => _update(prefs.copyWith(fontSize: v)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 0, 2),
                      child: Row(children: [
                        const _SettingIcon(icon: Icons.rounded_corner),
                        const SizedBox(width: 11),
                        const Expanded(child: Text('气泡圆角', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _ink))),
                        Text('${prefs.bubbleRadius.round()} px', style: const TextStyle(fontSize: 11, color: _muted)),
                      ]),
                    ),
                    Slider(
                      value: prefs.bubbleRadius.clamp(12, 26).toDouble(),
                      min: 12,
                      max: 26,
                      divisions: 7,
                      activeColor: _accent,
                      inactiveColor: const Color(0xFFE7E7E7),
                      onChanged: (v) => _update(prefs.copyWith(bubbleRadius: v)),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                _SettingsSection(
                  icon: Icons.wallpaper_outlined,
                  title: '聊天壁纸',
                  subtitle: '可缩放并调整图片上下左右的显示范围，避免主体被裁掉',
                  children: [
                    _SettingsAction(
                      icon: Icons.image_outlined,
                      title: '选择聊天壁纸',
                      value: prefs.chatWallpaperPath == null || prefs.chatWallpaperPath!.isEmpty ? '尚未设置' : '已设置 · 更换',
                      onTap: () => _pickWallpaper(context, prefs),
                    ),
                    if (prefs.chatWallpaperPath != null && prefs.chatWallpaperPath!.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 5, bottom: 2),
                        child: Row(children: [
                          const _SettingIcon(icon: Icons.zoom_in_rounded),
                          const SizedBox(width: 11),
                          const Expanded(child: Text('背景缩放', style: TextStyle(fontSize: 12, color: _ink))),
                          Text('${prefs.wallpaperScale.toStringAsFixed(2)}×', style: const TextStyle(fontSize: 11, color: _muted)),
                        ]),
                      ),
                      Slider(
                        value: prefs.wallpaperScale.clamp(1, 2.5).toDouble(),
                        min: 1,
                        max: 2.5,
                        divisions: 30,
                        activeColor: _accent,
                        onChanged: (v) => _update(prefs.copyWith(wallpaperScale: v)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(children: [
                          const _SettingIcon(icon: Icons.swap_horiz_rounded),
                          const SizedBox(width: 11),
                          const Expanded(child: Text('左右调整显示范围', style: TextStyle(fontSize: 12, color: _ink))),
                          Text(prefs.wallpaperPositionX.toStringAsFixed(1), style: const TextStyle(fontSize: 11, color: _muted)),
                        ]),
                      ),
                      Slider(
                        value: prefs.wallpaperPositionX.clamp(-1, 1).toDouble(),
                        min: -1,
                        max: 1,
                        divisions: 40,
                        activeColor: _accent,
                        onChanged: (v) => _update(prefs.copyWith(wallpaperPositionX: v)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(children: [
                          const _SettingIcon(icon: Icons.swap_vert_rounded),
                          const SizedBox(width: 11),
                          const Expanded(child: Text('上下调整显示范围', style: TextStyle(fontSize: 12, color: _ink))),
                          Text(prefs.wallpaperPositionY.toStringAsFixed(1), style: const TextStyle(fontSize: 11, color: _muted)),
                        ]),
                      ),
                      Slider(
                        value: prefs.wallpaperPositionY.clamp(-1, 1).toDouble(),
                        min: -1,
                        max: 1,
                        divisions: 40,
                        activeColor: _accent,
                        onChanged: (v) => _update(prefs.copyWith(wallpaperPositionY: v)),
                      ),
                      _SettingsAction(
                        icon: Icons.center_focus_weak_rounded,
                        title: '重置背景范围',
                        value: '恢复默认',
                        onTap: () => _update(prefs.copyWith(wallpaperScale: 1, wallpaperPositionX: 0, wallpaperPositionY: 0)),
                      ),
                      _SettingsAction(
                        icon: Icons.delete_outline_rounded,
                        title: '恢复默认背景',
                        value: '清除壁纸',
                        onTap: () => _update(prefs.copyWith(chatWallpaperPath: '')),
                      ),
                    ],
                    const SizedBox(height: 4),
                  ],
                ),
                const SizedBox(height: 13),
                _SettingsSection(
                  icon: Icons.auto_awesome_outlined,
                  title: '思考与生成',
                  subtitle: '控制模型过程信息的呈现',
                  children: [
                    _PreferenceSwitch(
                      icon: Icons.psychology_alt_outlined,
                      title: '显示思考过程',
                      subtitle: '展示接口实际返回的 reasoning 内容',
                      value: prefs.showReasoning,
                      onChanged: (v) => _update(prefs.copyWith(showReasoning: v)),
                      last: true,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                _SettingsSection(
                  icon: Icons.record_voice_over_outlined,
                  title: '旁白与角色表达',
                  subtitle: '控制动作、神态和场景描写',
                  children: [
                    _PreferenceSwitch(
                      icon: Icons.record_voice_over_rounded,
                      title: '允许旁白描写',
                      subtitle: '允许角色自然使用动作、神态和环境描写',
                      value: prefs.narratorEnabled,
                      onChanged: (v) => _update(prefs.copyWith(narratorEnabled: v)),
                    ),
                    _SettingsAction(
                      icon: Icons.edit_note_rounded,
                      title: '附加系统提示',
                      value: prefs.additionalSystemPrompt.trim().isEmpty ? '未设置' : '已设置 · 编辑',
                      onTap: () => _editAdditionalPrompt(context, prefs),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
                const SizedBox(height: 13),
                _SettingsSection(
                  icon: Icons.menu_book_outlined,
                  title: '世界书',
                  subtitle: '导入 Tavern / SillyTavern JSON 设定并按关键词注入',
                  children: [
                    _PreferenceSwitch(
                      icon: Icons.auto_stories_outlined,
                      title: '启用世界书',
                      subtitle: '匹配当前聊天内容后，将相关设定加入本轮请求',
                      value: prefs.worldbookEnabled,
                      onChanged: (v) => _update(prefs.copyWith(worldbookEnabled: v)),
                    ),
                    _SettingsAction(
                      icon: Icons.file_open_outlined,
                      title: '导入世界书 JSON',
                      value: prefs.worldbookJson.isEmpty ? '选择文件' : '${_countWorldbookEntries(prefs.worldbookJson)} 条设定 · 更换',
                      onTap: () => _importWorldbook(context, prefs),
                    ),
                    if (prefs.worldbookJson.isNotEmpty)
                      _SettingsAction(
                        icon: Icons.delete_outline_rounded,
                        title: '移除当前世界书',
                        value: '清除已导入内容',
                        onTap: () => _update(prefs.copyWith(worldbookJson: '', worldbookEnabled: false)),
                      ),
                    const SizedBox(height: 4),
                  ],
                ),
                const SizedBox(height: 13),
                _SettingsSection(
                  icon: Icons.keyboard_alt_outlined,
                  title: '输入方式',
                  subtitle: '按自己的习惯发送消息',
                  children: [
                    _PreferenceSwitch(
                      icon: Icons.keyboard_return_rounded,
                      title: '按 Enter 发送',
                      subtitle: '关闭后，Enter 换行，点击发送按钮发送',
                      value: prefs.enterSend,
                      onChanged: (v) => _update(prefs.copyWith(enterSend: v)),
                      last: true,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(21),
                    onTap: () => context.push('/chat/settings/connection'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(21),
                        border: Border.all(color: _line),
                      ),
                      child: const Row(children: [
                        _SettingIcon(icon: Icons.tune_rounded, color: _accent),
                        SizedBox(width: 11),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('聊天接口配置', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
                            SizedBox(height: 4),
                            Text('DeepSeek、OpenCode Go、自定义兼容接口', style: TextStyle(fontSize: 10, color: _muted)),
                          ],
                        )),
                        Icon(Icons.chevron_right_rounded, color: _muted),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
                  decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(17)),
                  child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline_rounded, size: 15, color: _muted),
                    SizedBox(width: 9),
                    Expanded(child: Text(
                      '这些选项保存在本机，只调整聊天页面的显示方式。思考过程仅显示服务商实际返回的内容，不代表可以读取模型未公开的内部思维。',
                      style: TextStyle(fontSize: 10, height: 1.65, color: _muted),
                    )),
                  ]),
                ),
              ],
            ),
          ),
        ]),
      ),
    ),
  );

  Future<void> _importWorldbook(BuildContext context, ChatPreferences prefs) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final selected = result.files.single;
      final bytes = selected.bytes ?? (selected.path == null ? null : await File(selected.path!).readAsBytes());
      if (bytes == null || bytes.isEmpty) throw Exception('无法读取所选文件');
      if (bytes.length > 2 * 1024 * 1024) throw Exception('世界书文件不能超过 2 MB');
      final raw = utf8.decode(bytes);
      final count = _countWorldbookEntries(raw);
      if (count == 0) throw Exception('没有找到可用的世界书条目，请选择 Tavern / SillyTavern JSON');
      await _update(prefs.copyWith(worldbookJson: raw, worldbookEnabled: true));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已导入 $count 条世界书设定')));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入世界书失败：$error')));
      }
    }
  }

  Future<void> _editAdditionalPrompt(BuildContext context, ChatPreferences prefs) async {
    final controller = TextEditingController(text: prefs.additionalSystemPrompt);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('附加系统提示', style: TextStyle(fontSize: 17, color: _ink)),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 5,
            maxLines: 10,
            maxLength: 3000,
            decoration: InputDecoration(
              hintText: '写下希望角色长期遵守的补充规则……',
              filled: true,
              fillColor: _soft,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('保存')),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await _update(prefs.copyWith(additionalSystemPrompt: value));
  }

  Future<void> _pickWallpaper(BuildContext context, ChatPreferences prefs) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: 3000,
        maxHeight: 3000,
      );
      if (picked == null || !context.mounted) return;
      final crop = await showDialog<_WallpaperCropResult>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _WallpaperCropDialog(
          imagePath: picked.path,
          initialScale: prefs.wallpaperScale,
          initialX: prefs.wallpaperPositionX,
          initialY: prefs.wallpaperPositionY,
        ),
      );
      if (crop == null || !context.mounted) return;
      final directory = await getApplicationDocumentsDirectory();
      final wallpaperDirectory = Directory('${directory.path}/chat_wallpapers');
      if (!await wallpaperDirectory.exists()) {
        await wallpaperDirectory.create(recursive: true);
      }
      final extension = picked.path.split('.').last.toLowerCase();
      final safeExtension = RegExp(r'^[a-z0-9]{2,5}$').hasMatch(extension) ? extension : 'jpg';
      final target = File('${wallpaperDirectory.path}/chat_wallpaper_${DateTime.now().microsecondsSinceEpoch}.$safeExtension');
      await File(picked.path).copy(target.path);
      await _update(prefs.copyWith(
        chatWallpaperPath: target.path,
        wallpaperScale: crop.scale,
        wallpaperPositionX: crop.x,
        wallpaperPositionY: crop.y,
      ));
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('设置聊天壁纸失败：$error')));
      }
    }
  }
  Future<void> _pickAvatar(BuildContext context, ChatPreferences prefs, {required bool partner}) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked == null) return;
      final directory = await getApplicationDocumentsDirectory();
      final avatarDirectory = Directory('${directory.path}/chat_avatars');
      if (!await avatarDirectory.exists()) await avatarDirectory.create(recursive: true);
      final target = File('${avatarDirectory.path}/${partner ? 'partner' : 'me'}_avatar.jpg');
      await File(picked.path).copy(target.path);
      final next = partner
          ? prefs.copyWith(partnerAvatarPath: target.path)
          : prefs.copyWith(myAvatarPath: target.path);
      await _update(next);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('设置头像失败：$error')));
      }
    }
  }

  Future<void> _editName(BuildContext context, ChatPreferences prefs, {required bool partner}) async {
    final controller = TextEditingController(text: partner ? prefs.partnerName : prefs.myName);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text(partner ? '修改对方昵称' : '修改我的昵称', style: const TextStyle(fontSize: 17, color: _ink)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 16,
          decoration: InputDecoration(
            hintText: '输入显示昵称',
            filled: true,
            fillColor: _soft,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, controller.text.trim()), child: const Text('保存')),
        ],
      ),
    );
    controller.dispose();
    if (value == null || value.trim().isEmpty) return;
    await _update(partner ? prefs.copyWith(partnerName: value.trim()) : prefs.copyWith(myName: value.trim()));
  }

  Future<void> _editQuickReplies(BuildContext context, ChatPreferences prefs) async {
    final values = List.generate(
      4,
      (index) => TextEditingController(
        text: index < prefs.quickReplies.length ? prefs.quickReplies[index] : '',
      ),
    );
    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('编辑常用语', style: TextStyle(fontSize: 17, color: _ink)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var index = 0; index < values.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: TextField(
                    controller: values[index],
                    maxLength: 18,
                    decoration: InputDecoration(
                      counterText: '',
                      labelText: '常用语 ${index + 1}',
                      filled: true,
                      fillColor: _soft,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(13),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              const Text(
                '这些短句会出现在输入框上方，点击后填入输入框，不会直接发送。',
                style: TextStyle(fontSize: 10, height: 1.5, color: _muted),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              dialogContext,
              values.map((item) => item.text.trim()).where((item) => item.isNotEmpty).toList(),
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
    for (final controller in values) {
      controller.dispose();
    }
    if (result != null) {
      await _update(prefs.copyWith(quickReplies: result));
    }
  }

  Future<void> _update(ChatPreferences next) => ChatPreferenceStore.update(next);
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({required this.icon, required this.title, required this.value, required this.onTap});
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        _SettingIcon(icon: icon),
        const SizedBox(width: 11),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 12, color: _ink))),
        Text(value, style: const TextStyle(fontSize: 11, color: _muted)),
        const SizedBox(width: 4),
        const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
      ]),
    ),
  );
}

class _ReplyLayoutPicker extends StatelessWidget {
  const _ReplyLayoutPicker({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (value: 0, icon: Icons.notes_rounded, title: '完整长段', subtitle: '保留连贯的大段回复，适合沉浸阅读'),
      (value: 1, icon: Icons.forum_outlined, title: '聊天分句', subtitle: '每个完整句子独立成泡，短句自然合并，长句按语意停顿'),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 9),
            child: Text('对方回复排版', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink)),
          ),
          ...options.map((option) {
            final active = selected == option.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: () => onChanged(option.value),
                borderRadius: BorderRadius.circular(13),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
                  decoration: BoxDecoration(
                    color: active ? const Color(0xFFF2F2F2) : Colors.white,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: active ? _accent : _line, width: active ? 1.3 : 1),
                  ),
                  child: Row(children: [
                    _SettingIcon(icon: option.icon),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(option.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink)),
                        const SizedBox(height: 3),
                        Text(option.subtitle, style: const TextStyle(fontSize: 10, color: _muted)),
                      ],
                    )),
                    Icon(active ? Icons.check_circle_rounded : Icons.circle_outlined, size: 18, color: active ? _accent : const Color(0xFFD0D0D0)),
                  ]),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BubbleStylePicker extends StatelessWidget {
  const _BubbleStylePicker({required this.selected, required this.onChanged});
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = [
      (title: 'HelloTalk', subtitle: '头像在消息旁 · 圆润气泡', value: 0),
      (title: 'iMessage', subtitle: '经典左右对话 · 简洁气泡', value: 1),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 9),
          child: Text('聊天气泡样式', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink)),
        ),
        ...options.map((option) {
          final active = selected == option.value;
          final hello = option.value == 0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 9),
            child: InkWell(
              onTap: () => onChanged(option.value),
              borderRadius: BorderRadius.circular(15),
              child: Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: active ? const Color(0xFFF2F2F2) : Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: active ? _accent : _line, width: active ? 1.4 : 1),
                ),
                child: Row(children: [
                  SizedBox(
                    width: 116,
                    child: Column(children: [
                      Row(
                        children: [
                          Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFFE6E6E6), shape: BoxShape.circle), child: const Center(child: Text('祁', style: TextStyle(fontSize: 9, color: _ink)))),
                          const SizedBox(width: 5),
                          Container(width: 62, height: 24, decoration: BoxDecoration(color: const Color(0xFFF0F0F0), border: Border.all(color: const Color(0xFFE6E6E6)), borderRadius: BorderRadius.only(topLeft: Radius.circular(hello ? 5 : 14), topRight: const Radius.circular(14), bottomLeft: const Radius.circular(14), bottomRight: const Radius.circular(14)))),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(width: 57, height: 24, decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.only(topLeft: const Radius.circular(14), topRight: Radius.circular(hello ? 5 : 14), bottomLeft: const Radius.circular(14), bottomRight: const Radius.circular(14)))),
                          const SizedBox(width: 5),
                          Container(width: 20, height: 20, decoration: const BoxDecoration(color: Color(0xFFE6E6E6), shape: BoxShape.circle), child: const Center(child: Text('我', style: TextStyle(fontSize: 9, color: _ink)))),
                        ],
                      ),
                    ]),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(option.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _ink)),
                    const SizedBox(height: 4),
                    Text(option.subtitle, style: const TextStyle(fontSize: 10, color: _muted)),
                  ])),
                  Icon(active ? Icons.check_circle_rounded : Icons.circle_outlined, size: 18, color: active ? _accent : const Color(0xFFD0D0D0)),
                ]),
              ),
            ),
          );
        }),
        const Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Text('头像可单独关闭；照片、表情包和文件仍以独立内容展示。', style: TextStyle(fontSize: 10, height: 1.5, color: _muted)),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(21),
      border: Border.all(color: _line),
      boxShadow: [BoxShadow(color: const Color(0xFF27332D).withValues(alpha: .025), blurRadius: 16, offset: const Offset(0, 4))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        _SettingIcon(icon: icon, color: _accent),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
          const SizedBox(height: 3),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: _muted)),
        ])),
      ]),
      const SizedBox(height: 7),
      ...children,
    ]),
  );
}

int _countWorldbookEntries(String raw) {
  try {
    final decoded = jsonDecode(raw);
    dynamic entries;
    if (decoded is Map) {
      entries = decoded['entries'] ?? decoded['worldbook'] ?? decoded['data']?['entries'];
    } else if (decoded is List) {
      entries = decoded;
    }
    if (entries is Map) return entries.values.where((entry) => entry is Map && (entry['content'] ?? '').toString().trim().isNotEmpty).length;
    if (entries is List) return entries.where((entry) => entry is Map && (entry['content'] ?? '').toString().trim().isNotEmpty).length;
  } catch (_) {}
  return 0;
}

class _SettingIcon extends StatelessWidget {
  const _SettingIcon({required this.icon, this.color = _muted});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 34,
    height: 34,
    decoration: BoxDecoration(color: _soft, borderRadius: BorderRadius.circular(11)),
    child: Icon(icon, size: 17, color: color),
  );
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 65),
    padding: const EdgeInsets.symmetric(vertical: 8),
    decoration: BoxDecoration(
      border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFF0F2F0))),
    ),
    child: Row(children: [
      _SettingIcon(icon: icon),
      const SizedBox(width: 11),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: _ink)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 10, height: 1.4, color: _muted)),
        ],
      )),
      const SizedBox(width: 7),
      Switch.adaptive(
        value: value,
        activeColor: Colors.white,
        activeTrackColor: _accent,
        inactiveTrackColor: const Color(0xFFE8ECE9),
        inactiveThumbColor: Colors.white,
        onChanged: onChanged,
      ),
    ]),
  );
}

class _WallpaperCropResult {
  const _WallpaperCropResult(this.scale, this.x, this.y);
  final double scale;
  final double x;
  final double y;
}

class _WallpaperCropDialog extends StatefulWidget {
  const _WallpaperCropDialog({
    required this.imagePath,
    required this.initialScale,
    required this.initialX,
    required this.initialY,
  });

  final String imagePath;
  final double initialScale;
  final double initialX;
  final double initialY;

  @override
  State<_WallpaperCropDialog> createState() => _WallpaperCropDialogState();
}

class _WallpaperCropDialogState extends State<_WallpaperCropDialog> {
  late double _scale = widget.initialScale.clamp(1, 2.5).toDouble();
  late double _x = widget.initialX.clamp(-1, 1).toDouble();
  late double _y = widget.initialY.clamp(-1, 1).toDouble();
  late double _startScale = _scale;
  late double _startX = _x;
  late double _startY = _y;

  @override
  Widget build(BuildContext context) => Dialog.fullscreen(
    backgroundColor: const Color(0xFFFAFAFA),
    child: SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
          child: Row(children: [
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
            const Expanded(child: Text('裁剪聊天背景', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink))),
            TextButton(onPressed: () => setState(() { _scale = 1; _x = 0; _y = 0; }), child: const Text('重置')),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(22, 0, 22, 12),
          child: Text('拖动图片调整取景，双指缩放。下面会预览聊天里的实际显示效果。', style: TextStyle(fontSize: 11, color: _muted), textAlign: TextAlign.center),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 6),
              child: LayoutBuilder(builder: (context, constraints) {
                final frameHeight = constraints.maxHeight;
                final frameWidth = constraints.maxWidth;
                return GestureDetector(
                  onScaleStart: (_) {
                    _startScale = _scale;
                    _startX = _x;
                    _startY = _y;
                  },
                  onScaleUpdate: (details) {
                    setState(() {
                      _scale = (_startScale * details.scale).clamp(1, 2.5).toDouble();
                      _x = (_startX + details.focalPointDelta.dx / (frameWidth * .30)).clamp(-1, 1).toDouble();
                      _y = (_startY + details.focalPointDelta.dy / (frameHeight * .30)).clamp(-1, 1).toDouble();
                    });
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: frameWidth,
                      height: frameHeight,
                      color: const Color(0xFFE9E9E9),
                      child: Stack(fit: StackFit.expand, children: [
                        Transform.scale(
                          scale: _scale,
                          alignment: Alignment(_x, _y),
                          child: Image.file(File(widget.imagePath), fit: BoxFit.cover, alignment: Alignment(_x, _y)),
                        ),
                        ColoredBox(color: Colors.white.withValues(alpha: .16)),
                        Positioned(left: 14, top: 18, child: _previewBubble('今天过得怎么样？', false)),
                        Positioned(right: 14, bottom: 20, child: _previewBubble('想和你分享一件事。', true)),
                      ]),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 0),
          child: Row(children: [
            const Icon(Icons.zoom_in_rounded, size: 17, color: _muted),
            const SizedBox(width: 8),
            const Expanded(child: Text('缩放', style: TextStyle(fontSize: 12, color: _ink))),
            Text('${_scale.toStringAsFixed(2)}×', style: const TextStyle(fontSize: 11, color: _muted)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Slider(value: _scale, min: 1, max: 2.5, divisions: 30, activeColor: _accent, onChanged: (v) => setState(() => _scale = v)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Row(children: [
            const Icon(Icons.swap_horiz_rounded, size: 17, color: _muted),
            const SizedBox(width: 8),
            const Expanded(child: Text('左右取景', style: TextStyle(fontSize: 12, color: _ink))),
            Text(_x.toStringAsFixed(1), style: const TextStyle(fontSize: 11, color: _muted)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Slider(value: _x, min: -1, max: 1, divisions: 40, activeColor: _accent, onChanged: (v) => setState(() => _x = v)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Row(children: [
            const Icon(Icons.swap_vert_rounded, size: 17, color: _muted),
            const SizedBox(width: 8),
            const Expanded(child: Text('上下取景', style: TextStyle(fontSize: 12, color: _ink))),
            Text(_y.toStringAsFixed(1), style: const TextStyle(fontSize: 11, color: _muted)),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Slider(value: _y, min: -1, max: 1, divisions: 40, activeColor: _accent, onChanged: (v) => setState(() => _y = v)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13)),
              onPressed: () => Navigator.pop(context, _WallpaperCropResult(_scale, _x, _y)),
              child: const Text('应用这张背景'),
            ),
          ),
        ),
      ]),
    ),
  );

  Widget _previewBubble(String text, bool mine) => Container(
    constraints: const BoxConstraints(maxWidth: 205),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: mine ? const Color(0xE6222222) : const Color(0xEFFFFFFF),
      borderRadius: BorderRadius.circular(15),
    ),
    child: Text(text, style: TextStyle(fontSize: 11, color: mine ? Colors.white : const Color(0xFF333333))),
  );
}
