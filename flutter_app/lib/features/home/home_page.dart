import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_side_drawer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const DateTime _togetherSince = DateTime(2026, 10, 28);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final togetherDays = now.difference(_togetherSince).inDays + 1;
    final dateLabel = '${now.year}年${now.month}月${now.day}日';
    final weekday = const ['星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'][now.weekday - 1];

    return Scaffold(
      drawer: const AppSideDrawer(active: 'home'),
      drawerEnableOpenDragGesture: false,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 17, 20, 32),
              sliver: SliverList.list(children: [
                Builder(builder: (scaffoldContext) => Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('OUR LITTLE SPACE', style: TextStyle(
                      fontSize: 9, letterSpacing: 2.1, color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    )),
                    const SizedBox(height: 7),
                    const Text('小窝', style: TextStyle(
                      fontSize: 29, height: 1.05, color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                    )),
                    const SizedBox(height: 6),
                    Text('$dateLabel  ·  $weekday', style: const TextStyle(
                      fontSize: 11, color: AppColors.secondary,
                    )),
                  ])),
                  _RoundAction(
                    icon: Icons.menu_rounded,
                    onTap: () => Scaffold.of(scaffoldContext).openDrawer(),
                  ),
                ])),
                const SizedBox(height: 20),
                _TogetherWidget(days: togetherDays),
                const SizedBox(height: 24),
                const _SectionHeading(title: '我们的小组件', caption: '把日常放在一起'),
                const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                    flex: 11,
                    child: _CalendarWidget(now: now),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    flex: 9,
                    child: Column(children: [
                      _SmallWidget(
                        height: 106,
                        icon: Icons.cloud_outlined,
                        eyebrow: 'A LITTLE NOTE',
                        title: '今日便签',
                        subtitle: '留一句话给彼此',
                        tint: AppColors.blush,
                        iconColor: const Color(0xFFAB8588),
                        onTap: () => _comingSoon(context, '门口便签'),
                      ),
                      const SizedBox(height: 11),
                      _SmallWidget(
                        height: 112,
                        icon: Icons.auto_awesome_outlined,
                        eyebrow: 'MEMORIES',
                        title: '记忆拾光',
                        subtitle: '收藏一些小瞬间',
                        tint: AppColors.sky,
                        iconColor: const Color(0xFF7C98A5),
                        onTap: () => _comingSoon(context, '记忆'),
                      ),
                    ]),
                  ),
                ]),
                const SizedBox(height: 12),
                _RecentWidget(onTap: () => _comingSoon(context, '最近动态')),
                const SizedBox(height: 24),
                const _SectionHeading(title: '我们的房间', caption: '常去的地方'),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _RoomTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: '聊天',
                    subtitle: '去见宋祁',
                    tint: AppColors.accentSoft,
                    onTap: () => context.push('/chat'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _RoomTile(
                    icon: Icons.menu_book_rounded,
                    title: '日记',
                    subtitle: '记下今天',
                    tint: AppColors.blush,
                    onTap: () => _comingSoon(context, '日记'),
                  )),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _RoomTile(
                    icon: Icons.photo_library_outlined,
                    title: '相册',
                    subtitle: '珍藏片段',
                    tint: AppColors.sky,
                    onTap: () => _comingSoon(context, '相册'),
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: _RoomTile(
                    icon: Icons.music_note_rounded,
                    title: '一起听',
                    subtitle: '播放我们的歌',
                    tint: const Color(0xFFF0EEE6),
                    onTap: () => _comingSoon(context, '一起听'),
                  )),
                ]),
                const SizedBox(height: 22),
                const Center(child: Text(
                  '留一点空白，给生活慢慢发生。',
                  style: TextStyle(fontSize: 10, color: AppColors.muted, letterSpacing: .3),
                )),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  static void _comingSoon(BuildContext context, String name) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$name正在按旧版功能迁移，入口先为你保留'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }
}

class _TogetherWidget extends StatelessWidget {
  const _TogetherWidget({required this.days});
  final int days;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(19, 17, 19, 18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEAF2EC), Color(0xFFF4F7F3)],
      ),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: const Color(0xFFE2EBE4)),
    ),
    child: Column(children: [
      Row(children: [
        const Text('TOGETHER', style: TextStyle(
          fontSize: 9, letterSpacing: 2, color: Color(0xFF789384), fontWeight: FontWeight.w700,
        )),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: .72), borderRadius: BorderRadius.circular(20)),
          child: const Text('OUR STORY', style: TextStyle(fontSize: 8, letterSpacing: 1, color: AppColors.secondary)),
        ),
      ]),
      const SizedBox(height: 17),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const _PersonAvatar(label: '我', color: Color(0xFFDCE8E0), size: 58),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 17),
          child: Icon(Icons.favorite_rounded, size: 20, color: Color(0xFFB88C91)),
        ),
        const _PersonAvatar(label: '祁', color: Color(0xFFE5E9E2), size: 58),
      ]),
      const SizedBox(height: 10),
      const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(width: 64, child: Text('我', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600))),
        SizedBox(width: 43),
        SizedBox(width: 64, child: Text('宋祁', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: AppColors.secondary, fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 14),
      Text('相伴第 $days 天', style: const TextStyle(
        fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.ink, letterSpacing: .3,
      )),
      const SizedBox(height: 4),
      const Text('从 2026.10.28 开始，故事还在继续', style: TextStyle(fontSize: 10, color: AppColors.muted)),
    ]),
  );
}

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.label, required this.color, required this.size});
  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: [BoxShadow(color: const Color(0xFF526B5E).withValues(alpha: .08), blurRadius: 12, offset: const Offset(0, 4))],
    ),
    child: Center(child: Text(label, style: const TextStyle(fontSize: 20, color: Color(0xFF61796B), fontWeight: FontWeight.w600))),
  );
}

class _CalendarWidget extends StatelessWidget {
  const _CalendarWidget({required this.now});
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final firstWeekday = DateTime(now.year, now.month, 1).weekday - 1;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final total = ((firstWeekday + daysInMonth + 6) ~/ 7) * 7;
    final cells = List<int?>.generate(total, (index) {
      final day = index - firstWeekday + 1;
      return day < 1 || day > daysInMonth ? null : day;
    });

    return Container(
      constraints: const BoxConstraints(minHeight: 229),
      padding: const EdgeInsets.fromLTRB(13, 14, 13, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.calendar_month_rounded, size: 17, color: AppColors.accent),
          SizedBox(width: 6),
          Text('日历', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
        ]),
        const SizedBox(height: 7),
        Text('${now.year}年 ${now.month}月', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 11),
        const Row(children: [
          for (final day in ['一', '二', '三', '四', '五', '六', '日'])
            Expanded(child: Center(child: Text(day, style: TextStyle(fontSize: 8, color: AppColors.muted)))),
        ]),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 3,
          crossAxisSpacing: 1,
          childAspectRatio: 1.25,
          children: [
            for (final day in cells)
              Center(child: day == null
                ? const SizedBox.shrink()
                : Container(
                    width: 19, height: 19,
                    decoration: BoxDecoration(
                      color: day == now.day ? AppColors.accent : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: Text('$day', style: TextStyle(
                      fontSize: 8,
                      color: day == now.day ? Colors.white : AppColors.secondary,
                      fontWeight: day == now.day ? FontWeight.w700 : FontWeight.w400,
                    ))),
                  )),
          ],
        ),
      ]),
    );
  }
}

class _SmallWidget extends StatelessWidget {
  const _SmallWidget({
    required this.height, required this.icon, required this.eyebrow,
    required this.title, required this.subtitle, required this.tint,
    required this.iconColor, required this.onTap,
  });
  final double height;
  final IconData icon;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Color tint;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(21),
      onTap: onTap,
      child: Container(
        width: double.infinity, height: height,
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(21)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Icon(icon, size: 19, color: iconColor),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(eyebrow, style: TextStyle(fontSize: 7, letterSpacing: 1, color: iconColor.withValues(alpha: .85))),
            const SizedBox(height: 3),
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8, color: AppColors.secondary)),
          ]),
        ]),
      ),
    ),
  );
}

class _RecentWidget extends StatelessWidget {
  const _RecentWidget({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.line)),
        child: Row(children: [
          Container(width: 39, height: 39, decoration: BoxDecoration(color: AppColors.accentSoft, borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.auto_awesome_rounded, size: 19, color: AppColors.accent)),
          const SizedBox(width: 11),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('最近动态', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
            SizedBox(height: 4),
            Text('还没有新的记录，去创造一点小回忆吧', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 9, color: AppColors.muted)),
          ])),
          const Icon(Icons.chevron_right_rounded, color: AppColors.muted, size: 19),
        ]),
      ),
    ),
  );
}

class _RoomTile extends StatelessWidget {
  const _RoomTile({required this.icon, required this.title, required this.subtitle, required this.tint, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(19),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(19), border: Border.all(color: AppColors.line)),
        child: Row(children: [
          Container(width: 37, height: 37, decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 18, color: AppColors.secondary)),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 3),
            Text(subtitle, style: const TextStyle(fontSize: 9, color: AppColors.muted)),
          ])),
        ]),
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, required this.caption});
  final String title;
  final String caption;

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
    const Spacer(),
    Text(caption, style: const TextStyle(fontSize: 9, color: AppColors.muted)),
  ]);
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: const SizedBox(width: 43, height: 43, child: Icon(Icons.menu_rounded, size: 20, color: AppColors.secondary)),
    ),
  );
}
