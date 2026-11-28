import 'package:flutter/material.dart';
import '../chat/chat_memory_store.dart';
import '../../app/widgets/app_side_drawer.dart';

class MemoryPage extends StatefulWidget {
  const MemoryPage({super.key});

  @override
  State<MemoryPage> createState() => _MemoryPageState();
}

class _MemoryPageState extends State<MemoryPage> {
  static const _categories = ['全部', '待确认', '个人信息', '偏好习惯', '重要约定', '共同回忆', '重要记忆'];
  List<ChatMemoryRecord> _records = [];
  String _category = '全部';
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await ChatMemoryStore.backfillFromArchive();
      final records = await ChatMemoryStore.load();
      if (!mounted) return;
      setState(() {
        _records = records;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<ChatMemoryRecord> get _visible {
    final query = _query.trim().toLowerCase();
    return _records.where((item) {
      final categoryMatch = _category == '全部' ||
          (_category == '待确认' ? item.pending : !item.pending && item.category == _category);
      final queryMatch = query.isEmpty ||
          item.content.toLowerCase().contains(query) ||
          item.sourceText.toLowerCase().contains(query);
      return categoryMatch && queryMatch;
    }).toList();
  }

  Future<void> _edit([ChatMemoryRecord? record]) async {
    final content = TextEditingController(text: record?.content ?? '');
    final categories = _categories.skip(1).toList();
    var category = record?.category ?? '重要记忆';
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(record == null ? '添加一条记忆' : '编辑记忆'),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: content,
                  autofocus: true,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: '写下希望宋祁长期记住的内容…',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: categories.contains(category) ? category : '重要记忆',
                  decoration: const InputDecoration(labelText: '记忆分类', border: OutlineInputBorder()),
                  items: categories.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                  onChanged: (value) {
                    if (value != null) setDialogState(() => category = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('保存')),
          ],
        ),
      ),
    );
    if (result == true && content.text.trim().isNotEmpty) {
      if (record == null) {
        await ChatMemoryStore.addManual(content: content.text, category: category);
      } else {
        await ChatMemoryStore.update(record.copyWith(content: content.text.trim(), category: category));
      }
      await _load();
    }
    content.dispose();
  }

  Future<void> _approve(ChatMemoryRecord record) async {
    await ChatMemoryStore.update(record.copyWith(pending: false));
    await _load();
  }

  Future<void> _toggleLock(ChatMemoryRecord record) async {
    await ChatMemoryStore.update(record.copyWith(locked: !record.locked));
    await _load();
  }

  Future<void> _delete(ChatMemoryRecord record) async {
    if (record.locked) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这条记忆？'),
        content: const Text('只会删除独立记忆卡片，不会删除它对应的原始聊天记录。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (confirm == true) {
      await ChatMemoryStore.delete(record.id);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        surfaceTintColor: Colors.transparent,
        title: const Text('记忆', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        leading: Builder(
          builder: (context) => IconButton(
            tooltip: '打开导航',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(onPressed: _load, tooltip: '刷新', icon: const Icon(Icons.refresh_rounded)),
          const SizedBox(width: 4),
        ],
      ),
      drawer: const AppSideDrawer(active: 'memory'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加记忆'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFEAEAE7)),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(color: const Color(0xFFF0EEEA), borderRadius: BorderRadius.circular(13)),
                      child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFF665F55), size: 19),
                    ),
                    const SizedBox(width: 11),
                    const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('宋祁的长期记忆', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(height: 3),
                      Text('独立保存，不会替代或改写聊天原文', style: TextStyle(fontSize: 11, color: Color(0xFF858585))),
                    ])),
                    Text('${_records.length}', style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 15),
                  TextField(
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: '搜索记忆和来源原文',
                      prefixIcon: const Icon(Icons.search_rounded, size: 19),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF7F7F5),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: BorderSide.none),
                    ),
                  ),
                ]),
              ),
            ),
            SizedBox(
              height: 42,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                children: _categories.map((item) => Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: ChoiceChip(
                    label: Text(item),
                    selected: _category == item,
                    onSelected: (_) => setState(() => _category = item),
                    visualDensity: VisualDensity.compact,
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : visible.isEmpty
                      ? _EmptyMemory(onAdd: () => _edit(), hasAny: _records.isNotEmpty)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(17, 8, 17, 100),
                          itemCount: visible.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) => _MemoryCard(
                            record: visible[index],
                            onEdit: () => _edit(visible[index]),
                            onLock: () => _toggleLock(visible[index]),
                            onDelete: () => _delete(visible[index]),
                            onApprove: () => _approve(visible[index]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.record, required this.onEdit, required this.onLock, required this.onDelete, required this.onApprove});
  final ChatMemoryRecord record;
  final VoidCallback onEdit;
  final VoidCallback onLock;
  final VoidCallback onDelete;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final date = record.sourceCreatedAt;
    final sourceDate = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 11, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAE7)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: const Color(0xFFF2F1EE), borderRadius: BorderRadius.circular(8)),
            child: Text(record.category, style: const TextStyle(fontSize: 10, color: Color(0xFF6D675F))),
          ),
          const SizedBox(width: 7),
          if (record.origin == 'manual')
            const Text('手动添加', style: TextStyle(fontSize: 10, color: Color(0xFF999999))),
          const Spacer(),
          if (record.pending)
            const Text('待确认', style: TextStyle(fontSize: 10, color: Color(0xFF9A7441))),
          if (record.locked) const Icon(Icons.lock_rounded, size: 15, color: Color(0xFF8A7652)),
          PopupMenuButton<String>(
            tooltip: '更多操作',
            icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF888888)),
            onSelected: (value) {
              if (value == 'approve') onApprove();
              if (value == 'edit') onEdit();
              if (value == 'lock') onLock();
              if (value == 'delete') onDelete();
            },
            itemBuilder: (context) => [
              if (record.pending) const PopupMenuItem(value: 'approve', child: Text('确认收录')),
              const PopupMenuItem(value: 'edit', child: Text('编辑记忆')),
              PopupMenuItem(value: 'lock', child: Text(record.locked ? '解除锁定' : '锁定记忆')),
              if (!record.locked) const PopupMenuItem(value: 'delete', child: Text('删除记忆')),
            ],
          ),
        ]),
        const SizedBox(height: 7),
        if (record.pending) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: onApprove, icon: const Icon(Icons.check_rounded, size: 16), label: const Text('确认收录这条记忆')),
        ],
        const SizedBox(height: 4),
        Text(record.content, style: const TextStyle(fontSize: 14, height: 1.65, color: Color(0xFF292929))),
        if (record.sourceText.isNotEmpty) ...[
          const SizedBox(height: 11),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: const Color(0xFFF8F8F6), borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.format_quote_rounded, size: 14, color: Color(0xFF99958D)),
                const SizedBox(width: 5),
                const Text('来源原文', style: TextStyle(fontSize: 10, color: Color(0xFF88847D))),
                const Spacer(),
                Text(record.sourceConversationId.isEmpty ? '手动记录' : sourceDate, style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
              ]),
              const SizedBox(height: 5),
              Text(record.sourceText, maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, height: 1.5, color: Color(0xFF777777))),
            ]),
          ),
        ],
      ]),
    );
  }
}

class _EmptyMemory extends StatelessWidget {
  const _EmptyMemory({required this.onAdd, required this.hasAny});
  final VoidCallback onAdd;
  final bool hasAny;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.auto_awesome_outlined, size: 38, color: Color(0xFFB7B2A9)),
        const SizedBox(height: 12),
        Text(hasAny ? '没有找到符合条件的记忆' : '这里还没有记忆', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(hasAny ? '试试其他关键词或分类' : '你可以手动添加，也可以在聊天中告诉宋祁“记住这件事”', textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: Color(0xFF888888), height: 1.5)),
        if (!hasAny) ...[
          const SizedBox(height: 14),
          OutlinedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('添加第一条记忆')),
        ],
      ]),
    ),
  );
}
