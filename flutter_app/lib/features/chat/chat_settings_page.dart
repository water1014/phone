import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'chat_preferences.dart';

const _ink = Color(0xFF202729);
const _muted = Color(0xFF89918F);
const _line = Color(0xFFEDF0EE);
const _soft = Color(0xFFF4F6F4);
const _accent = Color(0xFF52776B);

class ChatSettingsPage extends StatelessWidget {
  const ChatSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ChatPreferences>(
    valueListenable: ChatPreferenceStore.value,
    builder: (context, prefs, _) => Scaffold(
      backgroundColor: const Color(0xFFF8F9F8),
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
                      subtitle: '在双方消息旁显示头像',
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

  Future<void> _update(ChatPreferences next) => ChatPreferenceStore.update(next);
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
