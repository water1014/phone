import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const _AppDrawer(),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              sliver: SliverList.list(
                children: [
                  Builder(builder: (context) => Row(
                    children: [
                      const Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('OUR LITTLE SPACE', style: TextStyle(
                            fontSize: 10, letterSpacing: 2.2,
                            color: AppColors.muted, fontWeight: FontWeight.w600,
                          )),
                          SizedBox(height: 8),
                          Text('小窝', style: TextStyle(
                            fontSize: 30, height: 1.1,
                            fontWeight: FontWeight.w600, color: AppColors.ink,
                          )),
                        ],
                      )),
                      _RoundAction(
                        icon: Icons.menu_rounded,
                        onTap: () => Scaffold.of(context).openDrawer(),
                      ),
                    ],
                  )),
                  const SizedBox(height: 28),
                  _RelationshipCard(),
                  const SizedBox(height: 22),
                  const Text('我们的日常', style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.ink,
                  )),
                  const SizedBox(height: 12),
                  const _HomeTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: '聊天', subtitle: '留住每一次对话', wide: true,
                  ),
                  const SizedBox(height: 12),
                  const Row(children: [
                    Expanded(child: _HomeTile(
                      icon: Icons.menu_book_rounded, title: '日记', subtitle: '今天的片段',
                    )),
                    SizedBox(width: 12),
                    Expanded(child: _HomeTile(
                      icon: Icons.photo_library_outlined, title: '相册', subtitle: '一起收藏',
                    )),
                  ]),
                  const SizedBox(height: 28),
                  const Text('Flutter 迁移底座已建立', style: TextStyle(
                    color: AppColors.muted, fontSize: 12,
                  )),
                  const SizedBox(height: 6),
                  const Text(
                    '当前页面只是可运行工程壳，不是最终首页。后续会按旧版真实布局与功能逐项还原。',
                    style: TextStyle(color: AppColors.secondary, fontSize: 12, height: 1.7),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelationshipCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(AppRadii.hero),
    ),
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('TOGETHER', style: TextStyle(
          color: AppColors.accent, fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w600,
        )),
        SizedBox(height: 10),
        Text('每一天，都值得被记下', style: TextStyle(
          color: AppColors.ink, fontSize: 19, fontWeight: FontWeight.w600,
        )),
        SizedBox(height: 6),
        Text('我们的故事正在继续', style: TextStyle(color: AppColors.secondary, fontSize: 12)),
      ],
    ),
  );
}

class _HomeTile extends StatelessWidget {
  const _HomeTile({required this.icon, required this.title, required this.subtitle, this.wide = false});
  final IconData icon;
  final String title;
  final String subtitle;
  final bool wide;

  @override
  Widget build(BuildContext context) => Container(
    constraints: BoxConstraints(minHeight: wide ? 104 : 124),
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(AppRadii.card),
      border: Border.all(color: AppColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Icon(icon, size: 21, color: AppColors.secondary),
        const SizedBox(height: 14),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 3),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.muted)),
      ],
    ),
  );
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.fill,
    shape: const CircleBorder(),
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 20)),
    ),
  );
}

class _AppDrawer extends StatelessWidget {
  const _AppDrawer();
  static const groups = <String, List<String>>{
    '聊天与关系': ['聊天', '联系人', '记忆', '世界书', '动态'],
    '生活与记录': ['日记', '日历', '安排', '记账', '心情', '健康'],
    '内容与收藏': ['相册', '一起听', '收藏', '游戏', '生图室'],
    '系统与扩展': ['MCP', '美化', '设置'],
  };

  @override
  Widget build(BuildContext context) => Drawer(
    backgroundColor: AppColors.paper,
    child: SafeArea(child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        const Text('小窝', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w600)),
        const SizedBox(height: 22),
        for (final group in groups.entries) ...[
          Text(group.key, style: const TextStyle(
            color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w600,
          )),
          const SizedBox(height: 8),
          for (final item in group.value)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              dense: true,
              title: Text(item, style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.chevron_right_rounded, size: 18),
              onTap: () => Navigator.of(context).pop(),
            ),
          const SizedBox(height: 16),
        ],
      ],
    )),
  );
}
