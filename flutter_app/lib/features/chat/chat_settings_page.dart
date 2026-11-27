import 'package:flutter/material.dart';
import 'chat_preferences.dart';
import '../../app/theme/app_theme.dart';

class ChatSettingsPage extends StatelessWidget {
  const ChatSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ChatPreferences>(
    valueListenable: ChatPreferenceStore.value,
    builder: (context, prefs, _) => Scaffold(
      backgroundColor: const Color(0xFFF7F8F7),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 18, 13),
            child: Row(children: [
              IconButton(
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.chevron_left_rounded, size: 28, color: AppColors.secondary),
              ),
              const SizedBox(width: 4),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('聊天设置', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
                SizedBox(height: 3),
                Text('只影响当前聊天界面', style: TextStyle(fontSize: 11, color: AppColors.muted)),
              ])),
            ]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(15, 3, 15, 28),
              children: [
                _SettingsCard(
                  title: '消息显示',
                  children: [
                    _PreferenceSwitch(
                      title: '显示头像',
                      subtitle: '在双方消息旁显示头像',
                      value: prefs.showAvatar,
                      onChanged: (v) => _update(prefs.copyWith(showAvatar: v)),
                    ),
                    _PreferenceSwitch(
                      title: '显示对方昵称',
                      subtitle: '在对方每组消息上方显示昵称',
                      value: prefs.showName,
                      onChanged: (v) => _update(prefs.copyWith(showName: v)),
                    ),
                    _PreferenceSwitch(
                      title: '显示日期与时间',
                      subtitle: '显示日期分隔和较长间隔的时间',
                      value: prefs.showTime,
                      onChanged: (v) => _update(prefs.copyWith(showTime: v)),
                    ),
                    _PreferenceSwitch(
                      title: '合并连续消息',
                      subtitle: '同一方短时间内连续发送时收紧间距',
                      value: prefs.compact,
                      onChanged: (v) => _update(prefs.copyWith(compact: v)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 15, 0, 11),
                      child: Row(children: [
                        const Expanded(child: Text('消息字体大小', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w550, color: AppColors.ink))),
                        Text('${prefs.fontSize.round()} px', style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                      ]),
                    ),
                    Slider(
                      value: prefs.fontSize.clamp(12, 20).toDouble(),
                      min: 12,
                      max: 20,
                      divisions: 8,
                      activeColor: AppColors.accent,
                      onChanged: (v) => _update(prefs.copyWith(fontSize: v)),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                _SettingsCard(
                  title: '输入习惯',
                  children: [
                    _PreferenceSwitch(
                      title: '按 Enter 发送',
                      subtitle: '关闭后，Enter 换行，点击发送按钮发送',
                      value: prefs.enterSend,
                      onChanged: (v) => _update(prefs.copyWith(enterSend: v)),
                      last: true,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.fromLTRB(15, 13, 15, 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F1EF).withValues(alpha: .8),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: AppColors.muted),
                    SizedBox(width: 9),
                    Expanded(child: Text(
                      '这些选项保存在本机，只调整聊天页面的显示方式，不会修改聊天记录、角色资料或 API 配置。',
                      style: TextStyle(fontSize: 11, height: 1.6, color: AppColors.muted),
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

  Future<void> _update(ChatPreferences next) => ChatPreferenceStore.update(next);
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(15, 14, 15, 10),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(19),
      border: Border.all(color: const Color(0xFFE9E9E8)),
      boxShadow: [BoxShadow(color: const Color(0xFF333333).withValues(alpha: .025), blurRadius: 14, offset: const Offset(0, 3))],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 9),
        child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w650, color: AppColors.secondary)),
      ),
      ...children,
    ]),
  );
}

class _PreferenceSwitch extends StatelessWidget {
  const _PreferenceSwitch({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.last = false,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 63),
    padding: const EdgeInsets.symmetric(vertical: 9),
    decoration: BoxDecoration(
      border: last ? null : const Border(bottom: BorderSide(color: Color(0xFFF0EEEE))),
    ),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w550, color: AppColors.ink)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 10, height: 1.4, color: AppColors.muted)),
      ])),
      const SizedBox(width: 12),
      Switch.adaptive(
        value: value,
        activeColor: AppColors.accent,
        onChanged: onChanged,
      ),
    ]),
  );
}
