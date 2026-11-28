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
    setState(() => _entries.removeWhere((e) => e.id == entry.id));
    await _persist();
  }

  Future<void> _toggleLock(_DiaryEntry entry) async {
    setState(() => entry.locked = !entry.locked);
    await _persist();
  }

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
        backgroundColor: const Color(0xFFFAFAFA),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18)),
        title: const Text('日记', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: _ink)),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () => _edit(), tooltip: '写日记', icon: const Icon(Icons.add_rounded, size: 25)),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 1.5))
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('A LITTLE JOURNAL', style: TextStyle(fontSize: 9, letterSpacing: 2.2, color: _muted)),
                      const SizedBox(height: 8),
                      const Text('把今天，轻轻收好。', style: TextStyle(fontSize: 24, height: 1.3, fontWeight: FontWeight.w500, color: _ink)),
                      const SizedBox(height: 8),
                      Text('${_entries.length} 篇记录  ·  ${DateTime.now().year} 年', style: const TextStyle(fontSize: 11, color: _muted)),
                      const SizedBox(height: 18),
                      TextField(
                        onChanged: (value) => setState(() => _filter = value.trim()),
                        decoration: InputDecoration(
                          hintText: '搜索日记或标签',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFFB5B5B5)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _muted),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _line)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _line)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: _ink)),
                        ),
                      ),
                    ]),
                  ),
                ),
                if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.menu_book_outlined, size: 32, color: Color(0xFFBBBBBB)),
                          const SizedBox(height: 12),
                          Text(_entries.isEmpty ? '还没有日记' : '没有找到相关记录', style: const TextStyle(fontSize: 13, color: _muted)),
                          if (_entries.isEmpty) ...[
                            const SizedBox(height: 6),
                            const Text('点右上角的 +，写下今天的一点心情。', style: TextStyle(fontSize: 11, color: _muted)),
                          ],
                        ]),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = visible[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 11),
                            child: _DiaryCard(
                              entry: entry,
                              onTap: () => _edit(entry),
                              onLock: () => _toggleLock(entry),
                              onDelete: () => _delete(entry),
                            ),
                          );
                        },
                        childCount: visible.length,
                      ),
                    ),
                  ),
              ],
            ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(),
        backgroundColor: _ink,
        foregroundColor: Colors.white,
        elevation: 2,
        child: const Icon(Icons.edit_rounded),
      ),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  const _DiaryCard({required this.entry, required this.onTap, required this.onLock, required this.onDelete});
  final _DiaryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onLock;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(15),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 15, 13, 14),
        decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE7E7E7)), borderRadius: BorderRadius.circular(15)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(entry.dateLabel, style: const TextStyle(fontSize: 10, letterSpacing: 1.1, color: Color(0xFF999999)))),
            if (entry.city.isNotEmpty) ...[\n              const Icon(Icons.location_on_outlined, size: 13, color: Color(0xFF999999)),\n              const SizedBox(width: 3),\n              Text(entry.city, style: const TextStyle(fontSize: 10, color: Color(0xFF888888))),\n              const SizedBox(width: 7),\n            ],\n            if (entry.locked) const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF999999)),
            PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 130),
              icon: const Icon(Icons.more_horiz_rounded, size: 19, color: Color(0xFF999999)),
              onSelected: (value) => value == 'lock' ? onLock() : onDelete(),
              itemBuilder: (_) => [
                PopupMenuItem(value: 'lock', child: Text(entry.locked ? '解除锁定' : '锁定日记')),
                const PopupMenuItem(value: 'delete', child: Text('删除')),
              ],
            ),
          ]),
          if (entry.title.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(entry.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
          ],
          const SizedBox(height: 7),
          Text(entry.locked ? '这篇日记已锁定' : entry.body, maxLines: 5, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, height: 1.85, color: Color(0xFF444444))),
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: 11),
            Wrap(spacing: 6, runSpacing: 5, children: entry.tags.map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(20)),
              child: Text('#$tag', style: const TextStyle(fontSize: 10, color: Color(0xFF777777))),
            )).toList()),
          ],
        ]),
      ),
    ),
  );
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
  late final TextEditingController _tags;\n  late final TextEditingController _city;
  late DateTime _date;
  late bool _locked;

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _title = TextEditingController(text: entry?.title ?? '');
    _body = TextEditingController(text: entry?.body ?? '');
    _tags = TextEditingController(text: entry?.tags.join(', ') ?? '');\n    _city = TextEditingController(text: entry?.city ?? '');
    _date = entry?.date ?? DateTime.now();
    _locked = entry?.locked ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    _tags.dispose();\n    _city.dispose();
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
              TextField(controller: _city, decoration: const InputDecoration(labelText: '城市（选填）', hintText: '例如：米兰、南京', prefixIcon: Icon(Icons.location_on_outlined, size: 17), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), style: const TextStyle(fontSize: 12)),\n              const SizedBox(height: 10),\n              TextField(controller: _tags, decoration: const InputDecoration(labelText: '标签', hintText: '用逗号分隔，例如：日常, 开心', prefixIcon: Icon(Icons.tag_rounded, size: 17), border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))), style: const TextStyle(fontSize: 12)),
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
    locked: map['locked'] == true,
  );
}
