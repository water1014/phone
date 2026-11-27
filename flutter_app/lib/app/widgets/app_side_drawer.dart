import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

class AppSideDrawer extends StatelessWidget {
  const AppSideDrawer({super.key, required this.active});
  final String active;

  static const _groups = <_DrawerGroup>[
    _DrawerGroup('聊天与关系', [
      _DrawerEntry('聊天', Icons.chat_bubble_outline_rounded, 'chat'),
      _DrawerEntry('联系人', Icons.people_outline_rounded, 'contacts'),
      _DrawerEntry('记忆', Icons.auto_awesome_outlined, 'memory'),
      _DrawerEntry('世界书', Icons.menu_book_outlined, 'worldbook'),
      _DrawerEntry('动态', Icons.dynamic_feed_outlined, 'moments'),
    ]),
    _DrawerGroup('生活与记录', [
      _DrawerEntry('日记', Icons.edit_note_rounded, 'diary'),
      _DrawerEntry('日历', Icons.calendar_month_outlined, 'calendar'),
      _DrawerEntry('安排', Icons.event_note_outlined, 'schedule'),
      _DrawerEntry('记账', Icons.account_balance_wallet_outlined, 'ledger'),
      _DrawerEntry('心情', Icons.mood_outlined, 'mood'),
      _DrawerEntry('健康', Icons.favorite_border_rounded, 'health'),
    ]),
    _DrawerGroup('内容与收藏', [
      _DrawerEntry('相册', Icons.photo_library_outlined, 'album'),
      _DrawerEntry('一起听', Icons.music_note_rounded, 'music'),
      _DrawerEntry('收藏', Icons.bookmark_border_rounded, 'favorite'),
      _DrawerEntry('游戏', Icons.sports_esports_outlined, 'game'),
      _DrawerEntry('生图室', Icons.image_outlined, 'imageStudio'),
    ]),
    _DrawerGroup('系统与扩展', [
      _DrawerEntry('MCP', Icons.extension_outlined, 'mcp'),
      _DrawerEntry('美化', Icons.palette_outlined, 'beautify'),
      _DrawerEntry('设置', Icons.settings_outlined, 'settings'),
    ]),
  ];

  void _open(BuildContext context, _DrawerEntry entry) {
    Navigator.of(context).pop();
    if (entry.id == 'chat') {
      context.go('/chat');
    } else if (entry.id == 'music') {
      context.go('/music');
    } else if (entry.id == 'home') {
      context.go('/');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${entry.title}页面正在按旧版功能迁移，入口先为你保留'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Drawer(
    width: 304,
    backgroundColor: const Color(0xFFFAFAFA),
    surfaceTintColor: Colors.transparent,
    child: SafeArea(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(19, 17, 18, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 43,
                height: 43,
                decoration: BoxDecoration(
                  color: const Color(0xFF242424),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(child: Text('祁', style: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w600))),
              ),
              const SizedBox(width: 11),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('小窝', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.ink)),
                SizedBox(height: 3),
                Text('和宋祁一起生活的地方', style: TextStyle(fontSize: 10, color: AppColors.muted)),
              ])),
              IconButton(
                tooltip: '关闭侧栏',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 19, color: AppColors.muted),
              ),
            ]),
            const SizedBox(height: 17),
            InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => _open(context, const _DrawerEntry('首页', Icons.home_outlined, 'home')),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFFE7E7E7)),
                ),
                child: const Row(children: [
                  Icon(Icons.home_outlined, size: 18, color: AppColors.secondary),
                  SizedBox(width: 10),
                  Text('回到首页', style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: FontWeight.w500)),
                  Spacer(),
                  Icon(Icons.arrow_forward_rounded, size: 15, color: AppColors.muted),
                ]),
              ),
            ),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFE7E7E7)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(13, 17, 13, 20),
            children: [
              for (final group in _groups) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(9, 0, 9, 8),
                  child: Text(group.title, style: const TextStyle(fontSize: 10, letterSpacing: .5, fontWeight: FontWeight.w600, color: AppColors.muted)),
                ),
                for (final entry in group.entries)
                  _DrawerItemTile(
                    entry: entry,
                    selected: active == entry.id,
                    onTap: () => _open(context, entry),
                  ),
                const SizedBox(height: 17),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 17),
          child: Row(children: [
            const Icon(Icons.cloud_outlined, size: 14, color: AppColors.muted),
            const SizedBox(width: 7),
            const Text('小窝 · Flutter', style: TextStyle(fontSize: 10, color: AppColors.muted)),
            const Spacer(),
            Text('侧边导航', style: TextStyle(fontSize: 10, color: AppColors.muted.withValues(alpha: .8))),
          ]),
        ),
      ]),
    ),
  );
}

class _DrawerItemTile extends StatelessWidget {
  const _DrawerItemTile({required this.entry, required this.selected, required this.onTap});
  final _DrawerEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Material(
      color: selected ? const Color(0xFFEAEAEA) : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Row(children: [
            const SizedBox(width: 12),
            Icon(entry.icon, size: 18, color: selected ? const Color(0xFF222222) : AppColors.secondary),
            const SizedBox(width: 12),
            Expanded(child: Text(entry.title, style: TextStyle(fontSize: 12, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.ink : AppColors.secondary))),
            if (selected) Container(
              width: 4,
              height: 4,
              margin: const EdgeInsets.only(right: 13),
              decoration: const BoxDecoration(color: Color(0xFF242424), shape: BoxShape.circle),
            ) else const SizedBox(width: 13),
          ]),
        ),
      ),
    ),
  );
}

class _DrawerGroup {
  const _DrawerGroup(this.title, this.entries);
  final String title;
  final List<_DrawerEntry> entries;
}

class _DrawerEntry {
  const _DrawerEntry(this.title, this.icon, this.id);
  final String title;
  final IconData icon;
  final String id;
}
