import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/widgets/app_side_drawer.dart';

/// Flutter 移植版 phone 原生桌面。
/// 页面顺序、组件跨度和 Dock 均以 phone/js/layout.js 为准。
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _ink = Color(0xFF202124);
  static const _muted = Color(0xFF9AA0A6);
  static const _line = Color(0xFFE5E5E5);
  static const _apps = <_AppData>[
    _AppData('calendar','日历',Icons.calendar_month_outlined),
    _AppData('plans','安排',Icons.checklist_rounded),
    _AppData('accounting','记账',Icons.account_balance_wallet_outlined),
    _AppData('mood','心情',Icons.mood_outlined),
    _AppData('health','健康',Icons.favorite_border_rounded),
    _AppData('cycle','经期',Icons.water_drop_outlined),
    _AppData('study','学习',Icons.menu_book_outlined),
    _AppData('quotes','语录',Icons.format_quote_rounded),
    _AppData('letter','情书',Icons.mail_outline_rounded),
    _AppData('music','一起听',Icons.music_note_rounded),
    _AppData('moments','动态',Icons.dynamic_feed_outlined),
    _AppData('favorites','收藏',Icons.star_border_rounded),
    _AppData('games','游戏',Icons.sports_esports_outlined),
    _AppData('studio','生图室',Icons.brush_outlined),
    _AppData('worldbook','世界书',Icons.public_rounded),
    _AppData('windows','窗廊',Icons.window_outlined),
    _AppData('weather','天气',Icons.cloud_outlined),
    _AppData('mcp','MCP',Icons.extension_outlined),
    _AppData('beautify','美化',Icons.auto_awesome_outlined),
    _AppData('settings','设置',Icons.tune_rounded),
  ];
  static const _defaultDock = ['chat','diary','album','memory'];
  final List<String> _dock = List.of(_defaultDock);
  final PageController _pages = PageController();
  int _page = 0;
  bool _editing = false;

  void _open(String id) {
    if (id == 'chat') { context.push('/chat'); return; }
    final matches = _apps.where((a) => a.id == id);
    final app = matches.isEmpty ? null : matches.first;
    final name = app?.name ?? (id == 'memory' ? '记忆' : id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$name功能正在移植，原版入口已保留'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  void dispose() { _pages.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      drawer: const AppSideDrawer(active: 'home'),
      drawerEnableOpenDragGesture: false,
      backgroundColor: Colors.white,
      body: SafeArea(child: Stack(children: [
        Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(13, 5, 14, 3),
            child: Row(children: [
              Builder(builder: (ctx) => IconButton(
                visualDensity: VisualDensity.compact,
                onPressed: () => Scaffold.of(ctx).openDrawer(),
                icon: const Icon(Icons.menu_rounded, color: _ink, size: 23),
                tooltip: '打开侧栏',
              )),
              const Spacer(),
              Text(_editing ? '编辑桌面' : '小窝', style: const TextStyle(fontSize: 13, letterSpacing: 1.4, color: _muted)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _editing = !_editing),
                style: TextButton.styleFrom(foregroundColor: _ink, padding: const EdgeInsets.symmetric(horizontal: 9)),
                child: Text(_editing ? '完成' : '编辑', style: const TextStyle(fontSize: 12)),
              ),
            ]),
          ),
          Expanded(child: PageView(
            controller: _pages,
            onPageChanged: (v) => setState(() => _page = v),
            children: [
              _desktopPage([
                _wide(_PhotoWall(onTap: () => _open('album'))),
                _wide(_DaysCard()),
                _wide(_QuoteCard(onTap: () => _open('diary'))),
              ]),
              _desktopPage([
                _wide(_ClockCard(now: now)),
                _half(_InfoCard(label: 'WEATHER', value: '—', note: '天气信息', icon: Icons.cloud_outlined, onTap: () => _open('weather'))),
                _half(_InfoCard(label: 'QUOTA', value: '—', note: '模型用量', icon: Icons.data_usage_rounded, onTap: () => _open('chat'))),
                ..._appCells(const ['calendar','plans','accounting','mood','health','cycle','study','quotes']),
              ]),
              _desktopPage([
                _wide(_CalendarCard(now: now, onTap: () => _open('calendar'))),
                _wide(_NowPlaying(onTap: () => _open('music'))),
                ..._appCells(const ['letter','music','moments','favorites','games','studio','worldbook','windows']),
              ]),
              _desktopPage(_appCells(const ['weather','mcp','beautify','settings'])),
            ],
          )),
          Padding(
            padding: const EdgeInsets.only(top: 5, bottom: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) =>
              AnimatedContainer(duration: const Duration(milliseconds: 180), margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _page == i ? 15 : 5, height: 5,
                decoration: BoxDecoration(color: _page == i ? _ink : const Color(0xFFD8D8D8), borderRadius: BorderRadius.circular(9))))),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(13, 5, 13, 9),
            padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 5),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(17)),
            child: Row(children: [
              for (final id in _dock) Expanded(child: _DockButton(id: id, onTap: () => _open(id))),
            ]),
          ),
        ]),
        if (_editing) Positioned(left: 14, right: 14, bottom: 83, child: IgnorePointer(child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(color: _ink, borderRadius: BorderRadius.circular(10)),
          child: const Text('左右滑动切换桌面 · 点击完成退出编辑', style: TextStyle(color: Colors.white, fontSize: 10)),
        )))),
      ])),
    );
  }

  Widget _desktopPage(List<_Cell> cells) => LayoutBuilder(builder: (context, c) {
    final width = (c.maxWidth - 30) / 4;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(15, 7, 15, 16),
      child: Wrap(spacing: 0, runSpacing: 12, children: [
        for (final cell in cells)
          SizedBox(width: width * cell.span, child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: cell.child,
          )),
      ]),
    );
  });

  _Cell _wide(Widget child) => _Cell(child, 4);
  _Cell _half(Widget child) => _Cell(child, 2);
  List<_Cell> _appCells(List<String> ids) => ids.map((id) {
    final app = _apps.firstWhere((a) => a.id == id);
    return _Cell(_AppCell(app: app, onTap: () => _open(id)), 1);
  }).toList();
}

class _Cell { const _Cell(this.child, this.span); final Widget child; final int span; }
class _AppData {
  const _AppData(this.id, this.name, this.icon);
  final String id, name; final IconData icon;
}

class _AppCell extends StatelessWidget {
  const _AppCell({required this.app, required this.onTap});
  final _AppData app; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12), onTap: onTap,
    child: SizedBox(height: 76, child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 46, height: 46, decoration: BoxDecoration(color: const Color(0xFFF5F5F5), border: Border.all(color: const Color(0xFFE4E4E4)), borderRadius: BorderRadius.circular(13)),
        child: Icon(app.icon, size: 21, color: const Color(0xFF333333))),
      const SizedBox(height: 5),
      Text(app.name, maxLines: 1, style: const TextStyle(fontSize: 10.5, color: Color(0xFF777777))),
    ])),
  );
}

class _DockButton extends StatelessWidget {
  const _DockButton({required this.id, required this.onTap});
  final String id; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final data = switch (id) {
      'chat' => (Icons.chat_bubble_outline_rounded, '聊天'),
      'diary' => (Icons.menu_book_outlined, '日记'),
      'album' => (Icons.photo_outlined, '相册'),
      _ => (Icons.bookmark_border_rounded, '记忆'),
    };
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(data.$1, size: 21, color: const Color(0xFF626262)),
        const SizedBox(height: 4),
        Text(data.$2, style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
      ]),
    ));
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(15), this.onTap});
  final Widget child; final EdgeInsets padding; final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white, borderRadius: BorderRadius.circular(17),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(17),
      child: Container(width: double.infinity, padding: padding,
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE5E5E5)), borderRadius: BorderRadius.circular(17)),
        child: child)),
  );
}

class _PhotoWall extends StatefulWidget {
  const _PhotoWall({required this.onTap});
  final VoidCallback onTap;
  @override
  State<_PhotoWall> createState() => _PhotoWallState();
}

class _PhotoWallState extends State<_PhotoWall> {
  int _mode = 0;
  @override
  Widget build(BuildContext context) => _Card(
    onTap: widget.onTap,
    padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        const Text('照片墙', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _HomePageState._ink)),
        const Spacer(),
        for (var i = 0; i < 3; i++)
          GestureDetector(
            onTap: () => setState(() => _mode = i),
            child: Padding(
              padding: EdgeInsets.only(left: i == 0 ? 0 : 13),
              child: Text(
                const ['全部', '最近', '收藏'][i],
                style: TextStyle(fontSize: 10, color: _mode == i ? const Color(0xFF333333) : const Color(0xFFB0B0B0), fontWeight: _mode == i ? FontWeight.w600 : FontWeight.normal),
              ),
            ),
          ),
      ]),
      const SizedBox(height: 11),
      SizedBox(height: 142, child: Row(children: [
        Expanded(flex: 2, child: _tile(Icons.add_photo_alternate_outlined, radius: 11)),
        const SizedBox(width: 7),
        Expanded(child: Column(children: [
          Expanded(child: _tile(Icons.add_photo_alternate_outlined, radius: 9)),
          const SizedBox(height: 7),
          Expanded(child: _tile(Icons.add_photo_alternate_outlined, radius: 9)),
          const SizedBox(height: 7),
          Expanded(child: _tile(Icons.add_photo_alternate_outlined, radius: 9)),
        ])),
      ])),
      const SizedBox(height: 9),
      const Text('点这里，收好你们的照片', style: TextStyle(fontSize: 10, color: Color(0xFFAAAAAA), letterSpacing: .3)),
    ]),
  );

  Widget _tile(IconData icon, {required double radius}) => Container(
    width: double.infinity,
    decoration: BoxDecoration(color: const Color(0xFFF4F4F4), border: Border.all(color: const Color(0xFFEAEAEA)), borderRadius: BorderRadius.circular(radius)),
    child: Icon(icon, size: 19, color: const Color(0xFFC3C3C3)),
  );
}

class _DaysCard extends StatefulWidget {
  @override
  State<_DaysCard> createState() => _DaysCardState();
}

class _DaysCardState extends State<_DaysCard> {
  bool _back = false;
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final since = DateTime(2026, 10, 28);
    final days = now.difference(since).inDays + 1;
    final next = ((days ~/ 100) + 1) * 100;
    return GestureDetector(
      onTap: () => setState(() => _back = !_back),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: _Card(
          key: ValueKey(_back),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: SizedBox(
            height: 158,
            child: _back
              ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('SINCE 2026.10.28', style: _dayLabel),
                  const SizedBox(height: 12),
                  Text('${next}', style: const TextStyle(fontSize: 43, height: 1, color: _HomePageState._ink, fontWeight: FontWeight.w400)),
                  const SizedBox(height: 5),
                  const Text('NEXT MILESTONE', style: _dayLabel),
                  const SizedBox(height: 12),
                  Text('距离下一个整百天还有 ${next - days} 天', style: const TextStyle(fontSize: 11, color: Color(0xFF888888))),
                  const SizedBox(height: 10),
                  const Text('轻点卡片，回到正面', style: TextStyle(fontSize: 9, color: Color(0xFFB0B0B0))),
                ])
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('TOGETHER', style: _dayLabel),
                  const SizedBox(height: 13),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _person('宋', '宋祁'),
                    const SizedBox(width: 17),
                    Column(children: [
                      Text('${days}', style: const TextStyle(fontSize: 45, height: .98, color: _HomePageState._ink, fontWeight: FontWeight.w400, letterSpacing: -1.2)),
                      const Text('D A Y S', style: _dayLabel),
                    ]),
                    const SizedBox(width: 17),
                    _person('我', '我'),
                  ]),
                  const SizedBox(height: 13),
                  const Text('轻点卡片，看看纪念日', style: TextStyle(fontSize: 9, color: Color(0xFFB0B0B0))),
                ]),
          ),
        ),
      ),
    );
  }

  static const _dayLabel = TextStyle(fontSize: 9, letterSpacing: 2.2, color: Color(0xFFB0B0B0));
  Widget _person(String mark, String name) => Column(children: [
    Container(width: 34, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFF3F3F3), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFE5E5E5))), child: Text(mark, style: const TextStyle(fontSize: 12, color: Color(0xFF666666)))),
    const SizedBox(height: 5),
    Text(name, style: const TextStyle(fontSize: 10, color: Color(0xFF777777))),
  ]);
}

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({required this.onTap}); final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _Card(onTap: onTap, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Text('NOTE', style: TextStyle(fontSize: 10, letterSpacing: 2.5, color: Color(0xFFB6BEC6))), Spacer(), Text('还没写', style: TextStyle(fontSize: 10, color: Color(0xFFC6CDD4)))]),
    SizedBox(height: 9),
    Text('今天也可以就这么过。\n想写的时候，点这里。', style: TextStyle(fontSize: 14, height: 1.8, color: Color(0xFF46494D))),
  ]));
}

class _ClockCard extends StatelessWidget {
  const _ClockCard({required this.now}); final DateTime now;
  @override
  Widget build(BuildContext context) {
    final time = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';
    final week = const ['星期一','星期二','星期三','星期四','星期五','星期六','星期日'][now.weekday-1];
    return _Card(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('LOCAL TIME', style: TextStyle(fontSize: 10, letterSpacing: 3, color: Color(0xFFB6BEC6))),
      const SizedBox(height: 9),
      Text(time, style: const TextStyle(fontSize: 43, height: 1, fontWeight: FontWeight.w400, letterSpacing: -1, color: Color(0xFF24262A))),
      const SizedBox(height: 7),
      Text('${now.year}年${now.month}月${now.day}日  ·  $week', style: const TextStyle(fontSize: 11, color: Color(0xFFA4AEB8))),
    ]));
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value, required this.note, required this.icon, required this.onTap});
  final String label, value, note; final IconData icon; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _Card(onTap: onTap, padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(icon, size: 15, color: const Color(0xFF7F8790)), const Spacer(), Text(label, style: const TextStyle(fontSize: 9, letterSpacing: 1.4, color: Color(0xFFB6BEC6)))]),
    const SizedBox(height: 9),
    Text(value, style: const TextStyle(fontSize: 27, color: Color(0xFF24262A))),
    Text(note, style: const TextStyle(fontSize: 10, color: Color(0xFFA4AEB8))),
  ]));
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.now, required this.onTap}); final DateTime now; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final first = DateTime(now.year, now.month, 1).weekday % 7;
    final count = DateTime(now.year, now.month + 1, 0).day;
    return _Card(onTap: onTap, child: Column(children: [
      Row(children: [const Text('CALENDAR', style: TextStyle(fontSize: 10, letterSpacing: 2.5, color: Color(0xFFB6BEC6))), const Spacer(), Text('${now.year}年 ${now.month}月', style: const TextStyle(fontSize: 12, color: Color(0xFF8D9AA8)))]),
      const SizedBox(height: 10),
      Row(children: [for(final d in ['日','一','二','三','四','五','六']) Expanded(child: Center(child: Text(d, style: const TextStyle(fontSize: 10, color: Color(0xFFC6CDD4))))) ]),
      const SizedBox(height: 5),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: ((first+count+6)~/7)*7,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1.5),
        itemBuilder: (context, i) {
          final day = i-first+1; if(day<1 || day>count) return const SizedBox.shrink();
          final today = day==now.day;
          return Center(child: Container(width: 27,height: 27, decoration: BoxDecoration(color: today?const Color(0xFF222222):Colors.transparent, shape: BoxShape.circle),
            alignment: Alignment.center, child: Text('$day', style: TextStyle(fontSize: 11, color: today?Colors.white:const Color(0xFF55595E)))));
        }),
    ]));
  }
}

class _NowPlaying extends StatelessWidget {
  const _NowPlaying({required this.onTap}); final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => _Card(onTap: onTap, child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [Icon(Icons.graphic_eq_rounded, size: 16, color: Color(0xFF89939C)), SizedBox(width: 7), Text('NOW PLAYING', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Color(0xFFB6BEC6)))]),
    SizedBox(height: 12),
    Text('还没挑一首。点这里去加。', style: TextStyle(fontSize: 13, color: Color(0xFF8D969F))),
  ]));
}
