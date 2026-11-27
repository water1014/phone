import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/widgets/app_side_drawer.dart';

/// Native Flutter port of the redesigned phone home from
/// feature/complete-frontend (js/xw-desk.js + css/xw-desk.css).
/// Keep this as a single scrolling dashboard, not the legacy four-page grid.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _ink = Color(0xFF000000);
  static const _body = Color(0xFF333333);
  static const _muted = Color(0xFF999999);
  static const _line = Color(0xFFE0E0E0);
  static const _soft = Color(0xFFF5F5F5);
  static const _sinceDefault = '2026-10-28';

  DateTime get _now => DateTime.now();
  String _bio = '';
  String _quote = '';
  String _since = _sinceDefault;
  String _avatarPath = '';
  final String _weather = '--';
  final String _weatherDescription = '天气暂不可用';
  List<_HomeMessage> _messages = const [];
  _HomeDiary? _latestDiary;
  int _memoryCount = 0;
  int _diaryCount = 0;
  int _photoCount = 0;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getString('xw_home_messages');
    final savedDiary = prefs.getString('xw_home_latest_diary');
    if (!mounted) return;
    setState(() {
      _bio = prefs.getString('xw_bio') ?? '';
      _quote = prefs.getString('xw_quote') ?? '';
      _since = prefs.getString('xw_loveDate') ?? _sinceDefault;
      _avatarPath = prefs.getString('xw_ava_his') ?? '';
      _memoryCount = prefs.getInt('xw_home_memory_count') ?? 0;
      _diaryCount = prefs.getInt('xw_home_diary_count') ?? 0;
      _photoCount = prefs.getInt('xw_home_photo_count') ?? 0;
      if (savedMessages != null) {
        try {
          _messages = (jsonDecode(savedMessages) as List)
              .whereType<Map>()
              .map((m) => _HomeMessage(
                    text: (m['text'] ?? m['content'] ?? '').toString(),
                    time: (m['time'] ?? m['date'] ?? '').toString(),
                  ))
              .take(3)
              .toList();
        } catch (_) {}
      }
      if (savedDiary != null) {
        try {
          final map = jsonDecode(savedDiary) as Map;
          _latestDiary = _HomeDiary(
            date: (map['date'] ?? map['time'] ?? '').toString(),
            text: (map['text'] ?? map['content'] ?? map['body'] ?? '').toString(),
          );
        } catch (_) {}
      }
    });
  }

  int get _togetherDays {
    final start = DateTime.tryParse(_since);
    if (start == null) return -1;
    return _now.difference(start).inDays.clamp(0, 1000000).toInt();
  }

  Future<void> _editValue(String kind) async {
    final isDate = kind == 'start';
    final initialValue =
        kind == 'bio' ? _bio : kind == 'quote' ? _quote : _since;
    final value = await showDialog<String>(
      context: context,
      builder: (_) => _HomeEditDialog(
        initialValue: initialValue,
        title:
            kind == 'bio' ? '写一句介绍' : kind == 'quote' ? '留下一句话' : '相伴起算日',
        hint: isDate ? '2026-10-28' : '写一点想留下的内容',
        maxLines: kind == 'quote' ? 3 : 1,
        keyboardType:
            isDate ? TextInputType.datetime : TextInputType.text,
      ),
    );
    if (value == null || !mounted) return;
    if (isDate && value.isNotEmpty && DateTime.tryParse(value) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日期格式请使用 2026-10-28')),
      );
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = kind == 'bio'
        ? 'xw_bio'
        : kind == 'quote'
            ? 'xw_quote'
            : 'xw_loveDate';
    if (value.isEmpty) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, value);
    }
    if (!mounted) return;
    setState(() {
      if (kind == 'bio') _bio = value;
      if (kind == 'quote') _quote = value;
      if (isDate) _since = value.isEmpty ? _sinceDefault : value;
    });
  }

  void _open(String id) {
    switch (id) {
      case 'home':
        setState(() {});
        break;
      case 'chat':
        context.push('/chat');
        break;
      case 'diary':
        _showComingSoon('日记');
        break;
      case 'settings':
        _showComingSoon('设置');
        break;
      default:
        _showComingSoon(id);
    }
  }

  void _showComingSoon(String name) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$name入口已保留，正在接入原版功能'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = _togetherDays;
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AppSideDrawer(active: 'home'),
      drawerEnableOpenDragGesture: false,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 108),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 18),
                        _buildProfileCard(days),
                        const SizedBox(height: 4),
                        _buildStats(days),
                        const SizedBox(height: 18),
                        _buildWeatherAndMessages(),
                        const SizedBox(height: 12),
                        _buildQuoteAndPhotos(),
                        if (_latestDiary != null) ...[
                          const SizedBox(height: 12),
                          _buildRecentDiary(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildDock(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Builder(
            builder: (context) => InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _line),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_rounded, size: 18, color: _ink),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(child: _HomeClock()),
        ],
      );

  Widget _buildProfileCard(int days) => _HomeCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _soft,
                shape: BoxShape.circle,
                border: Border.all(color: _line),
                image: _avatarPath.isNotEmpty && File(_avatarPath).existsSync()
                    ? DecorationImage(
                        image: FileImage(File(_avatarPath)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _avatarPath.isEmpty || !File(_avatarPath).existsSync()
                  ? const Icon(Icons.person_outline_rounded,
                      color: Color(0xFFAAAAAA), size: 22)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          '宋祁 & 我',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17,
                            height: 1.3,
                            fontWeight: FontWeight.w600,
                            color: _ink,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Container(
                        width: 13,
                        height: 13,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: _ink,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          '✓',
                          style: TextStyle(
                              fontSize: 8,
                              height: 1,
                              color: Colors.white,
                              fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
                  const Text(
                    '@xiaowo',
                    style: TextStyle(
                        fontSize: 12, letterSpacing: .4, color: _muted),
                  ),
                  if (_bio.isNotEmpty)
                    GestureDetector(
                      onTap: () => _editValue('bio'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _bio,
                          style: const TextStyle(
                              fontSize: 13, height: 1.8, color: _body),
                        ),
                      ),
                    )
                  else
                    _AddTextButton(
                      label: '写一句介绍',
                      onTap: () => _editValue('bio'),
                    ),
                  if (days >= 0)
                    GestureDetector(
                      onTap: () => _editValue('start'),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          '第 $days 天  ·  从 $_since 开始',
                          style: const TextStyle(
                              fontSize: 10.5,
                              letterSpacing: .6,
                              color: _muted),
                        ),
                      ),
                    )
                  else
                    _AddTextButton(
                      label: '设一个起算日',
                      onTap: () => _editValue('start'),
                    ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildStats(int days) => Padding(
        padding: const EdgeInsets.fromLTRB(0, 2, 0, 16),
        child: Column(
          children: [
            const SizedBox(height: 2),
            Row(
              children: [
                _StatItem(value: days >= 0 ? '$days' : '—', label: '天'),
                _StatItem(value: '$_memoryCount', label: '记忆'),
                _StatItem(value: '$_diaryCount', label: '日记'),
                _StatItem(value: '$_photoCount', label: '照片'),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: _line),
          ],
        ),
      );

  Widget _buildWeatherAndMessages() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _HomeCard(
              height: 132,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Kicker('WEATHER'),
                  const SizedBox(height: 10),
                  Text(
                    _weather,
                    style: const TextStyle(
                      fontFamily: 'Georgia',
                      fontSize: 29,
                      height: 1,
                      fontWeight: FontWeight.w300,
                      color: _ink,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _weatherDescription,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 11, height: 1.55, color: _muted),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _HomeCard(
              height: 132,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Kicker('MESSAGES'),
                  const SizedBox(height: 4),
                  if (_messages.isEmpty)
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '还没有消息',
                          style: TextStyle(fontSize: 11.5, color: _muted),
                        ),
                      ),
                    )
                  else
                    ..._messages.take(3).map((message) => _MessagePreview(
                          message: message,
                        )),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildQuoteAndPhotos() => _HomeCard(
        padding: const EdgeInsets.fromLTRB(16, 19, 16, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_quote.isNotEmpty)
              GestureDetector(
                onTap: () => _editValue('quote'),
                child: Text(
                  _quote,
                  style: const TextStyle(
                    fontSize: 17,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: .1,
                    color: _ink,
                  ),
                ),
              )
            else ...[
              const Text(
                '这句话还没写。',
                style: TextStyle(fontSize: 12, height: 1.8, color: _muted),
              ),
              _AddTextButton(
                label: '写一句话',
                onTap: () => _editValue('quote'),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: List.generate(
                3,
                (index) => Expanded(
                  child: Container(
                    height: 62,
                    margin: EdgeInsets.only(right: index == 2 ? 0 : 8),
                    decoration: BoxDecoration(
                      color: _soft,
                      border: Border.all(color: _line),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.photo_outlined,
                        size: 19, color: Color(0xFFC0C0C0)),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildRecentDiary() => _HomeCard(
        onTap: () => _open('diary'),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_latestDiary!.date}  ·  最近写过',
              style: const TextStyle(
                  fontSize: 9.5, letterSpacing: 1.3, color: _muted),
            ),
            const SizedBox(height: 8),
            Text(
              _latestDiary!.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 13, height: 1.9, color: _body),
            ),
          ],
        ),
      );

  Widget _buildDock() => Container(
        height: 64 + MediaQuery.paddingOf(context).bottom,
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .98),
          border: const Border(top: BorderSide(color: _line)),
        ),
        child: Row(
          children: [
            _DockItem(
                icon: Icons.home_outlined,
                label: '首页',
                selected: true,
                onTap: () => _open('home')),
            _DockItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: '聊天',
                onTap: () => _open('chat')),
            _DockItem(
                icon: Icons.menu_book_outlined,
                label: '日记',
                onTap: () => _open('diary')),
            _DockItem(
                icon: Icons.tune_rounded,
                label: '设置',
                onTap: () => _open('settings')),
          ],
        ),
      );
}

class _HomeEditDialog extends StatefulWidget {
  const _HomeEditDialog({
    required this.initialValue,
    required this.title,
    required this.hint,
    required this.maxLines,
    required this.keyboardType,
  });

  final String initialValue;
  final String title;
  final String hint;
  final int maxLines;
  final TextInputType keyboardType;

  @override
  State<_HomeEditDialog> createState() => _HomeEditDialogState();
}

class _HomeEditDialogState extends State<_HomeEditDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      title: Text(
        widget.title,
        style: const TextStyle(fontSize: 16, color: Colors.black),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: widget.maxLines,
        keyboardType: widget.keyboardType,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle:
              const TextStyle(color: Color(0xFFBBBBBB), fontSize: 13),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '取消',
            style: TextStyle(color: Color(0xFF999999)),
          ),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_controller.text.trim()),
          child: const Text(
            '保存',
            style: TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}

class _HomeCard extends StatelessWidget {
  const _HomeCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.height,
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final double? height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE0E0E0)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Kicker extends StatelessWidget {
  const _Kicker(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 1.8,
          color: Color(0xFF999999),
        ),
      );
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'Georgia',
                fontSize: 22,
                height: 1.1,
                color: Colors.black,
                fontWeight: FontWeight.w400,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                letterSpacing: 1.4,
                color: Color(0xFF999999),
              ),
            ),
          ],
        ),
      );
}

class _AddTextButton extends StatelessWidget {
  const _AddTextButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(
                  color: const Color(0xFFC0C0C0), style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+  $label',
              style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
            ),
          ),
        ),
      );
}

class _MessagePreview extends StatelessWidget {
  const _MessagePreview({required this.message});
  final _HomeMessage message;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 7),
        child: Row(
          children: [
            Container(
              width: 19,
              height: 19,
              decoration: const BoxDecoration(
                color: Color(0xFFF5F5F5),
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                    BorderSide(color: Color(0xFFE0E0E0))),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                message.text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 11.5, height: 1.5, color: Color(0xFF333333)),
              ),
            ),
            if (message.time.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                message.time.length >= 5
                    ? message.time.substring(message.time.length - 5)
                    : message.time,
                style: const TextStyle(fontSize: 9, color: Color(0xFFC0C0C0)),
              ),
            ],
          ],
        ),
      );
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => Expanded(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 21,
                  color: selected ? Colors.black : const Color(0xFF999999)),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9.5,
                  color: selected ? Colors.black : const Color(0xFF999999),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
}

class _HomeMessage {
  const _HomeMessage({required this.text, required this.time});
  final String text;
  final String time;
}

class _HomeDiary {
  const _HomeDiary({required this.date, required this.text});
  final String date;
  final String text;
}


class _HomeClock extends StatefulWidget {
  const _HomeClock();

  @override
  State<_HomeClock> createState() => _HomeClockState();
}

class _HomeClockState extends State<_HomeClock> {
  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clock =
        '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';
    final weekday = const [
      '星期一', '星期二', '星期三', '星期四', '星期五', '星期六', '星期日'
    ][_now.weekday - 1];
    return Row(
      children: [
        Expanded(
          child: Text(
            clock,
            style: const TextStyle(
              fontFamily: 'Georgia',
              fontSize: 39,
              height: 1,
              fontWeight: FontWeight.w300,
              letterSpacing: -1.2,
              color: Color(0xFF000000),
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
        Text(
          '${_now.year}年${_now.month}月${_now.day}日\\n$weekday',
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontSize: 10.5,
            height: 1.65,
            letterSpacing: .7,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }
}
