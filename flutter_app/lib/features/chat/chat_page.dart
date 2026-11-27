import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _input = TextEditingController();
  final _messages = <({String text, bool mine, String time})>[
    (text: '今天也辛苦啦。先坐一会儿，和我说说今天发生了什么？', mine: false, time: '20:16'),
    (text: '今天想把小窝再好好整理一下。', mine: true, time: '20:17'),
    (text: '那我们慢慢来。先把最喜欢的角落留出来，其他的，一点一点添上去。', mine: false, time: '20:17'),
  ];

  @override
  void dispose() { _input.dispose(); super.dispose(); }

  void _send() {
    final value = _input.text.trim();
    if (value.isEmpty) return;
    setState(() {
      _messages.add((text: value, mine: true, time: TimeOfDay.now().format(context)));
      _input.clear();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8F8F8),
    appBar: AppBar(
      leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.chevron_left_rounded, size: 29)),
      titleSpacing: 0,
      title: const Row(children: [
        CircleAvatar(radius: 18, backgroundColor: Color(0xFFE9E2E9), child: Text('祁', style: TextStyle(color: Color(0xFF665A67)))),
        SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('宋祁', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 2),
          Text('在线', style: TextStyle(fontSize: 10, color: Color(0xFF8C9A8D))),
        ]),
      ]),
      actions: [IconButton(
        tooltip: '聊天设置',
        onPressed: () => showModalBottomSheet<void>(
          context: context, showDragHandle: true, backgroundColor: Colors.white,
          builder: (_) => const _ChatSettings(),
        ),
        icon: const Icon(Icons.tune_rounded, size: 21),
      ), const SizedBox(width: 6)],
    ),
    body: Column(children: [
      const SizedBox(height: 14),
      const Text('今天 · 20:16', style: TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: .5)),
      const SizedBox(height: 18),
      Expanded(child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
        physics: const BouncingScrollPhysics(),
        itemCount: _messages.length,
        itemBuilder: (context, index) {
          final message = _messages[index];
          final mine = message.mine;
          return Padding(
            padding: const EdgeInsets.only(bottom: 17),
            child: Row(
              mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!mine) ...[
                  const CircleAvatar(radius: 15, backgroundColor: Color(0xFFE9E2E9), child: Text('祁', style: TextStyle(fontSize: 11, color: Color(0xFF665A67)))),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Column(
                  crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: const BoxConstraints(maxWidth: 290),
                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      decoration: BoxDecoration(
                        color: mine ? const Color(0xFFE8E0EE) : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(19), topRight: const Radius.circular(19),
                          bottomLeft: Radius.circular(mine ? 19 : 6), bottomRight: Radius.circular(mine ? 6 : 19),
                        ),
                        border: Border.all(color: const Color(0xFFECE9EC), width: .6),
                      ),
                      child: Text(message.text, style: const TextStyle(fontSize: 14, height: 1.65, color: AppColors.ink)),
                    ),
                    const SizedBox(height: 5),
                    Text(message.time, style: const TextStyle(fontSize: 9, color: AppColors.muted)),
                  ],
                )),
                if (mine) const SizedBox(width: 8),
              ],
            ),
          );
        },
      )),
      Container(
        padding: EdgeInsets.fromLTRB(14, 11, 14, 12 + MediaQuery.paddingOf(context).bottom),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFECEAEC)))),
        child: Row(children: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.secondary)),
          Expanded(child: TextField(
            controller: _input, minLines: 1, maxLines: 4,
            textInputAction: TextInputAction.send, onSubmitted: (_) => _send(),
            decoration: InputDecoration(
              hintText: '说点什么…', isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              fillColor: const Color(0xFFF5F4F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: AppColors.accent, width: .8)),
            ),
          )),
          const SizedBox(width: 8),
          Material(color: AppColors.ink, shape: const CircleBorder(), child: InkWell(
            customBorder: const CircleBorder(), onTap: _send,
            child: const SizedBox(width: 40, height: 40, child: Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 19)),
          )),
        ]),
      ),
    ]),
  );
}

class _ChatSettings extends StatelessWidget {
  const _ChatSettings();
  @override
  Widget build(BuildContext context) => const SafeArea(child: Padding(
    padding: EdgeInsets.fromLTRB(22, 8, 22, 28),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('聊天设置', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
      SizedBox(height: 18),
      _SettingRow(icon: Icons.palette_outlined, title: '聊天外观', subtitle: '气泡、背景与字体'),
      _SettingRow(icon: Icons.tune_rounded, title: '回复与生成', subtitle: '模型、生成参数与流式输出'),
      _SettingRow(icon: Icons.notifications_none_rounded, title: '消息提醒', subtitle: '通知与主动消息'),
      _SettingRow(icon: Icons.manage_search_rounded, title: '查找聊天', subtitle: '按日期、图片和文件查找'),
    ]),
  ));
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Container(width: 40, height: 40,
      decoration: BoxDecoration(color: const Color(0xFFF4F1F4), borderRadius: BorderRadius.circular(13)),
      child: Icon(icon, size: 19, color: AppColors.secondary)),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
    trailing: const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
  );
}
