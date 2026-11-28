import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key});

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  static const _ink = Color(0xFF171717);
  static const _muted = Color(0xFF999999);
  static const _line = Color(0xFFE7E7E7);
  static const _storeKey = 'flutter_diary_entries';
  List<_DiaryEntry> _entries = [];
  bool _loading = true;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storeKey);
    final entries = <_DiaryEntry>[];
    if (raw != null) {
      try {
        for (final item in jsonDecode(raw) as List) {
          if (item is Map) entries.add(_DiaryEntry.fromMap(item));
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _entries = entries..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storeKey, jsonEncode(_entries.map((e) => e.toMap()).toList()));
  }

  Future<void> _edit([_DiaryEntry? entry]) async {
    final result = await showModalBottomSheet<_DiaryEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DiaryEditor(entry: entry),
    );
    if (result == null || !mounted) return;
    setState(() {
      final index = _entries.indexWhere((e) => e.id == result.id);
      if (index >= 0) {
        _entries[index] = result;
      } else {
        _entries.insert(0, result);
      }
      _entries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _selectedEntry = result;
    });
    await _persist();
  }

  Future<void> _delete(_DiaryEntry entry) async {
    if (entry.locked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('这篇日记已锁定，请先解锁')));
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这篇日记？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() {
      _entries.removeWhere((e) => e.id == entry.id);
      if (_selectedEntry?.id == entry.id) _selectedEntry = null;
    });
    await _persist();
  }

  Future<void> _toggleLock(_DiaryEntry entry) async {
    setState(() => entry.locked = !entry.locked);
    await _persist();
  }

  String _mode = 'daily';
  _DiaryEntry? _selectedEntry;
  String? _selectedReviewKey;

  DateTime _weekStart(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  Map<String, List<_DiaryEntry>> _groupEntries(bool weekly) {
    final groups = <String, List<_DiaryEntry>>{};
    for (final entry in _entries) {
      final d = weekly ? _weekStart(entry.date) : DateTime(entry.date.year, entry.date.month);
      final key = weekly
          ? '${d.year}-W${((d.difference(DateTime(d.year, 1, 1)).inDays) / 7).floor() + 1}'
          : '${d.year}-${d.month.toString().padLeft(2, '0')}';
      groups.putIfAbsent(key, () => []).add(entry);
    }
    return groups;
  }

  Widget _modeTabs() {
    const tabs = [('daily', '日记'), ('weekly', '周记'), ('monthly', '月记'), ('growth', '成长回顾')];
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(13)),
      child: Row(children: tabs.map((tab) => Expanded(
        child: GestureDetector(
          onTap: () => setState(() { _mode = tab.$1; _selectedEntry = null; _selectedReviewKey = null; }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            decoration: BoxDecoration(color: _mode == tab.$1 ? Colors.white : Colors.transparent, borderRadius: BorderRadius.circular(10), boxShadow: _mode == tab.$1 ? [const BoxShadow(color: Color(0x0D000000), blurRadius: 5, offset: Offset(0, 1))] : []),
            child: Text(tab.$2, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: _mode == tab.$1 ? FontWeight.w600 : FontWeight.w400, color: _mode == tab.$1 ? _ink : _muted)),
          ),
        ),
      )).toList()),
    );
  }

  Widget _reviewList(bool weekly) {
    final groups = _groupEntries(weekly);
    final keys = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    if (keys.isEmpty) return _emptyState('还没有足够的记录', '写下第一篇日记后，这里会自动整理回顾。');

    final selectedKey = _selectedReviewKey;
    final selectedItems = selectedKey == null ? null : groups[selectedKey];
    if (selectedItems != null) {
      final words = selectedItems.fold<int>(0, (sum, e) => sum + e.body.trim().length);
      final tags = selectedItems.expand((e) => e.tags).toSet().toList();
      final title = weekly
          ? '第 ${selectedKey!.split('W').last} 周 · ${selectedKey!.split('-W').first}'
          : '${selectedKey!.replaceFirst('-', ' 年 ')} 月';
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 2, 18, 14),
          child: Row(children: [
            IconButton(
              onPressed: () => setState(() => _selectedReviewKey = null),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17),
              tooltip: '返回时间列表',
            ),
            const SizedBox(width: 4),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _ink))),
            Text('${selectedItems.length} 篇', style: const TextStyle(fontSize: 10, color: _muted)),
          ]),
        ),
        Expanded(child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: _line), borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(weekly ? 'WEEKLY REVIEW' : 'MONTHLY REVIEW', style: const TextStyle(fontSize: 9, letterSpacing: 1.8, color: _muted)),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600, color: _ink)),
                const SizedBox(height: 12),
                Row(children: [
                  _stat('${selectedItems.length}', '日记篇数'),
                  _stat('$words', '记录字数'),
                  _stat('${selectedItems.map((e) => '${e.date.year}-${e.date.month}-${e.date.day}').toSet().length}', '记录天数'),
                ]),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(spacing: 6, runSpacing: 6, children: tags.take(8).map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFFF2F2F2), borderRadius: BorderRadius.circular(20)),
                    child: Text('#$tag', style: const TextStyle(fontSize: 10, color: Color(0xFF666666))),
                  )).toList()),
                ],
              ]),
            ),
            const SizedBox(height: 16),
            const Text('本期日记', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
            const SizedBox(height: 8),
            ...selectedItems.map((entry) => InkWell(
              onTap: () => setState(() { _mode = 'daily'; _selectedEntry = entry; }),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _line))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 52, child: Text('${entry.date.month}/${entry.date.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 11, color: _muted))),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(entry.title.isEmpty ? '无标题日记' : entry.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _ink)),
                    const SizedBox(height: 5),
                    Text(entry.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.7, color: Color(0xFF777777))),
                  ])),
                  const Icon(Icons.chevron_right_rounded, size: 17, color: _muted),
                ]),
              ),
            )),
          ],
        )),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
        child: Row(children: [
          Text(weekly ? '全部周记' : '全部月记', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
          const Spacer(),
          Text('${keys.length} 期', style: const TextStyle(fontSize: 10, color: _muted)),
        ]),
      ),
      Expanded(child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
        itemCount: keys.length,
        separatorBuilder: (_, __) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          final key = keys[index];
          final items = groups[key]!;
          final words = items.fold<int>(0, (sum, e) => sum + e.body.trim().length);
          final tags = items.expand((e) => e.tags).toSet().take(4).toList();
          final title = weekly
              ? '第 ${key.split('W').last} 周 · ${key.split('-W').first}'
              : '${key.replaceFirst('-', ' 年 ')} 月';
          return InkWell(
            onTap: () => setState(() => _selectedReviewKey = key),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 13),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: _line))),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 42, height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(11)),
                  child: Icon(weekly ? Icons.view_week_outlined : Icons.calendar_month_outlined, size: 19, color: const Color(0xFF777777)),
                ),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _ink)),
                  const SizedBox(height: 6),
                  Text('${items.length} 篇记录  ·  $words 字', style: const TextStyle(fontSize: 10, color: _muted)),
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(tags.map((tag) => '#$tag').join('   '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),
                  ],
                ])),
                const Icon(Icons.chevron_right_rounded, size: 18, color: _muted),
              ]),
            ),
          );
        },
      )),
    ]);
  }

  Widget _emptyState(String title, String subtitle) => Center(child: Padding(
    padding: const EdgeInsets.all(30),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.menu_book_outlined, size: 34, color: Color(0xFFBBBBBB)),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontSize: 13, color: _muted)),
      const SizedBox(height: 6),
      Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: _muted)),
    ]),
  ));

  Widget _diaryDateRail(List<_DiaryEntry> visible) {
    if (visible.isEmpty) {
      return _emptyState(_entries.isEmpty ? '还没有日记' : '没有找到相关记录', '点右上角的 +，写下今天的一点心情。');
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
        child: Row(children: [
          const Text('全部日记', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
          const Spacer(),
          Text('${visible.length} 篇', style: const TextStyle(fontSize: 10, color: _muted)),
        ]),
      ),
      Expanded(child: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(height: 0),
        itemBuilder: (context, index) {
          final entry = visible[index];
          final selected = _selectedEntry?.id == entry.id;
          return InkWell(
            onTap: () => setState(() => _selectedEntry = entry),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 13),
              decoration: BoxDecoration(
                color: selected ? const Color(0xFFF0F0F0) : Colors.transparent,
                border: const Border(bottom: BorderSide(color: _line)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 48, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entry.date.day.toString().padLeft(2, '0'), style: const TextStyle(fontSize: 21, height: 1.1, fontWeight: FontWeight.w500, color: _ink)),
                  const SizedBox(height: 4),
                  Text('${entry.date.year}/${entry.date.month.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 9, color: _muted)),
                ])),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(entry.title.isEmpty ? '当天记录' : entry.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
                  const SizedBox(height: 5),
                  Text(entry.locked ? '这篇日记已锁定' : entry.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.65, color: Color(0xFF777777))),
                  if (entry.tags.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Wrap(spacing: 5, children: entry.tags.take(3).map((tag) => Text('#$tag', style: const TextStyle(fontSize: 9, color: Color(0xFF999999)))).toList()),
                  ],
                ])),
                const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFFBBBBBB)),
              ]),
            ),
          );
        },
      )),
    ]);
  }

  Widget _diaryReader(_DiaryEntry entry) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 16, 12),
        child: Row(children: [
          IconButton(onPressed: () => setState(() => _selectedEntry = null), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 17), tooltip: '返回日记列表'),
          const Text('日记详情', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
          const Spacer(),
          IconButton(onPressed: () => _edit(entry), icon: const Icon(Icons.edit_outlined, size: 18), tooltip: '编辑'),
          PopupMenuButton<String>(
            onSelected: (value) => value == 'lock' ? _toggleLock(entry) : _delete(entry),
            itemBuilder: (_) => [
              PopupMenuItem(value: 'lock', child: Text(entry.locked ? '解除锁定' : '锁定日记')),
              const PopupMenuItem(value: 'delete', child: Text('删除日记')),
            ],
          ),
        ]),
      ),
      const Divider(height: 1, color: _line),
      Expanded(child: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 34),
        children: [
          Text('${entry.date.year}年${entry.date.month}月${entry.date.day}日', style: const TextStyle(fontSize: 10, letterSpacing: 1.3, color: _muted)),
          const SizedBox(height: 12),
          Text(entry.title.isEmpty ? '那一天' : entry.title, style: const TextStyle(fontSize: 25, height: 1.35, fontWeight: FontWeight.w600, color: _ink)),
          const SizedBox(height: 9),
          Row(children: [
            if (entry.city.isNotEmpty) ...[
              const Icon(Icons.location_on_outlined, size: 13, color: _muted),
              const SizedBox(width: 3),
              Text(entry.city, style: const TextStyle(fontSize: 10, color: _muted)),
              const SizedBox(width: 12),
            ],
            Text('更新于 ${entry.updatedAt.month}/${entry.updatedAt.day}', style: const TextStyle(fontSize: 10, color: _muted)),
            if (entry.locked) ...[
              const SizedBox(width: 8),
              const Icon(Icons.lock_outline_rounded, size: 13, color: _muted),
            ],
          ]),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Divider(color: _line)),
          Text(entry.locked ? '这篇日记已锁定，解锁后可以阅读。' : entry.body, style: const TextStyle(fontSize: 14, height: 2, color: Color(0xFF333333))),
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 24),
            Wrap(spacing: 8, runSpacing: 8, children: entry.tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(20)),
              child: Text('#$tag', style: const TextStyle(fontSize: 10, color: Color(0xFF777777))),
            )).toList()),
          ],
        ],
      )),
    ]);
  }

  Widget _growthView() {
    final totalWords = _entries.fold<int>(0, (sum, e) => sum + e.body.trim().length);
    final activeDays = _entries.map((e) => '${e.date.year}-${e.date.month}-${e.date.day}').toSet().length;
    final tagCounts = <String, int>{};
    for (final entry in _entries) {
      for (final tag in entry.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }
    final topTags = tagCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 28), children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17), border: Border.all(color: _line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('写给时间的记录', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink)),
          const SizedBox(height: 6),
          const Text('每一次认真记录，都在悄悄拼成自己的故事。', style: TextStyle(fontSize: 11, color: _muted)),
          const SizedBox(height: 20),
          Row(children: [
            _stat('${_entries.length}', '日记篇数'),
            _stat('$activeDays', '记录天数'),
            _stat('$totalWords', '累计字数'),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      if (topTags.isNotEmpty) Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: _line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('常出现的主题', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _ink)),
          const SizedBox(height: 12),
          ...topTags.take(8).map((e) => Padding(padding: const EdgeInsets.only(bottom: 9), child: Row(children: [
            Expanded(child: Text('#${e.key}', style: const TextStyle(fontSize: 11, color: Color(0xFF555555)))),
            Text('${e.value} 次', style: const TextStyle(fontSize: 10, color: _muted)),
          ]))),
        ]),
      ),
      if (_entries.isEmpty) SizedBox(height: 220, child: _emptyState('故事还在第一页', '开始写日记，成长回顾就会慢慢丰富起来。')),
    ]);
  }

  Widget _stat(String value, String label) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: _ink)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(fontSize: 10, color: _muted)),
  ]));

  @override
  Widget build(BuildContext context) {
    final visible = _entries.where((e) =>
      _filter.isEmpty || e.title.toLowerCase().contains(_filter.toLowerCase()) ||
      e.body.toLowerCase().contains(_filter.toLowerCase()) ||
      e.city.toLowerCase().contains(_filter.toLowerCase()) ||
      e.tags.any((tag) => tag.contains(_filter))).toList();
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA), surfaceTintColor: Colors.transparent, elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        title: const Text('日记', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink)),
        centerTitle: true,
        actions: [IconButton(onPressed: () => _edit(), tooltip: '写日记', icon: const Icon(Icons.add_rounded, size: 25)), const SizedBox(width: 4)],
      ),
      body: SafeArea(top: false, child: _loading
        ? const Center(child: CircularProgressIndicator(strokeWidth: 1.5))
        : Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('A LITTLE JOURNAL', style: TextStyle(fontSize: 9, letterSpacing: 2.2, color: _muted)),
                const SizedBox(height: 8),
                const Text('把日子，慢慢整理成故事。', style: TextStyle(fontSize: 22, height: 1.3, fontWeight: FontWeight.w500, color: _ink)),
                const SizedBox(height: 7),
                Text('${_entries.length} 篇记录  ·  ${DateTime.now().year} 年', style: const TextStyle(fontSize: 11, color: _muted)),
              ]),
            ),
            _modeTabs(),
            if (_mode == 'daily') ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: TextField(
                  onChanged: (value) => setState(() => _filter = value.trim()),
                  decoration: InputDecoration(
                    hintText: '搜索日记、城市或标签', hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFB5B5B5)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _muted),
                    filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _line)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _line)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _ink)),
                  ),
                ),
              ),
              Expanded(
                child: _selectedEntry == null
                    ? _diaryDateRail(visible)
                    : _diaryReader(_selectedEntry!),
              ),
            ] else if (_mode == 'weekly') Expanded(child: _reviewList(true))
            else if (_mode == 'monthly') Expanded(child: _reviewList(false))
            else Expanded(child: _growthView()),
          ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(), backgroundColor: _ink, foregroundColor: Colors.white, elevation: 2,
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}

class _DiaryEditor extends StatefulWidget {
  const _DiaryEditor({this.entry});
  final _DiaryEntry? entry;

  @override
  State<_DiaryEditor> createState() => _DiaryEditorState();
}

class _DiaryEditorState extends State<_DiaryEditor> {
  late final TextEditingController _title;
  late final TextEditingController _body;
  late final TextEditingController _tags;
  late final TextEditingController _city;
  late DateTime _date;
  late bool _locked;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _title = TextEditingController(text: entry?.title ?? '');
    _body = TextEditingController(text: entry?.body ?? '');
    _tags = TextEditingController(text: entry?.tags.join(', ') ?? '');
    _city = TextEditingController(text: entry?.city ?? '');
    _date = entry?.date ?? DateTime.now();
    _locked = entry?.locked ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _tags.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(
      height: MediaQuery.of(context).size.height * .88,
      decoration: const BoxDecoration(color: Color(0xFFFAFAFA), borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      child: Column(children: [
        const SizedBox(height: 10),
        Container(width: 34, height: 4, decoration: BoxDecoration(color: const Color(0xFFD8D8D8), borderRadius: BorderRadius.circular(4))),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 12, 8),
          child: Row(children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消', style: TextStyle(color: Color(0xFF777777)))),
            const Spacer(),
            const Text('写日记', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const Spacer(),
            TextButton(
              onPressed: () {
                final body = _body.text.trim();
                if (body.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('先写下一点内容吧')));
                  return;
                }
                final now = DateTime.now();
                final tags = _tags.text.split(RegExp(r'[,，、]')).map((e) => e.trim().replaceFirst(RegExp(r'^#'), '')).where((e) => e.isNotEmpty).toSet().toList();
                Navigator.pop(context, _DiaryEntry(
                  id: widget.entry?.id ?? now.microsecondsSinceEpoch.toString(),
                  title: _title.text.trim(),
                  body: body,
                  date: _date,
                  updatedAt: now,
                  tags: tags,
                  city: _city.text.trim(),
                  locked: _locked,
                ));
              },
              child: const Text('保存', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        const Divider(height: 1, color: Color(0xFFE7E7E7)),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
            children: [
              Row(children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF999999)),
                const SizedBox(width: 8),
                Text('${_date.year}年${_date.month}月${_date.day}日', style: const TextStyle(fontSize: 11, color: Color(0xFF777777))),
                const Spacer(),
                TextButton(
                  onPressed: () async {
                    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)));
                    if (picked != null) setState(() => _date = picked);
                  },
                  child: const Text('更改日期', style: TextStyle(fontSize: 11, color: Colors.black)),
                ),
              ]),
              const SizedBox(height: 15),
              TextField(controller: _title, textCapitalization: TextCapitalization.sentences, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600), decoration: const InputDecoration(hintText: '给今天起个标题', border: InputBorder.none, hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontWeight: FontWeight.w400))),
              const Divider(height: 1, color: Color(0xFFE7E7E7)),
              TextField(controller: _body, autofocus: true, minLines: 8, maxLines: null, keyboardType: TextInputType.multiline, textCapitalization: TextCapitalization.sentences, style: const TextStyle(fontSize: 14, height: 1.9, color: Color(0xFF333333)), decoration: const InputDecoration(hintText: '今天发生了什么？有什么想记住的？', border: InputBorder.none, hintStyle: TextStyle(color: Color(0xFFBBBBBB), fontSize: 13))),
              const SizedBox(height: 14),
              TextField(controller: _city, decoration: const InputDecoration(labelText: '城市（选填）', hintText: '例如：米兰、南京', prefixIcon: Icon(Icons.location_on_outlined, size: 17), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 10),
              TextField(controller: _tags, decoration: const InputDecoration(labelText: '标签', hintText: '用逗号分隔，例如：日常, 开心', prefixIcon: Icon(Icons.tag_rounded, size: 17), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _locked,
                onChanged: (value) => setState(() => _locked = value),
                title: const Text('锁定这篇日记', style: TextStyle(fontSize: 12)),
                subtitle: const Text('锁定后在列表中隐藏正文，避免误删', style: TextStyle(fontSize: 10, color: Color(0xFF999999))),
                activeColor: Colors.black,
              ),
            ],
          ),
        ),
      ]),
    ),
  );
}

class _DiaryEntry {
  _DiaryEntry({required this.id, required this.title, required this.body, required this.date, required this.updatedAt, required this.tags, this.city = '', this.locked = false});

  final String id;
  final String title;
  final String body;
  final DateTime date;
  final DateTime updatedAt;
  final List<String> tags;
  final String city;
  bool locked;

  String get dateLabel => '${date.year.toString().padLeft(4, '0')} / ${date.month.toString().padLeft(2, '0')} / ${date.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toMap() => {
    'id': id, 'title': title, 'body': body, 'date': date.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(), 'tags': tags, 'city': city, 'locked': locked,
  };

  factory _DiaryEntry.fromMap(Map map) => _DiaryEntry(
    id: (map['id'] ?? '').toString(),
    title: (map['title'] ?? '').toString(),
    body: (map['body'] ?? '').toString(),
    date: DateTime.tryParse((map['date'] ?? '').toString()) ?? DateTime.now(),
    updatedAt: DateTime.tryParse((map['updatedAt'] ?? '').toString()) ?? DateTime.now(),
    tags: (map['tags'] is List ? map['tags'] as List : const []).map((e) => e.toString()).toList(),
    city: (map['city'] ?? '').toString(),
    locked: map['locked'] == true,
  );
}