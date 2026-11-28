import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../app/theme/app_theme.dart';
import '../../app/widgets/app_side_drawer.dart';
import '../chat/chat_message.dart';
import '../chat/chat_message_store.dart';

class WorkspacePage extends StatefulWidget {
  const WorkspacePage({super.key});

  @override
  State<WorkspacePage> createState() => _WorkspacePageState();
}

class _WorkspacePageState extends State<WorkspacePage> {
  List<_WorkspaceFile> _files = [];
  bool _loading = true;
  String _filter = '全部';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    try {
      final directory = await getApplicationDocumentsDirectory();
      final generated = Directory('${directory.path}/chat_generated');
      final found = <String, _WorkspaceFile>{};
      if (await generated.exists()) {
        await for (final entity in generated.list(followLinks: false)) {
          if (entity is File) {
            final item = await _WorkspaceFile.fromFile(entity);
            found[item.path] = item;
          }
        }
      }
      final records = await ChatMessageStore.load();
      for (final ChatMessageRecord record in records) {
        if (record.mine || record.attachmentPath == null || record.attachmentPath!.isEmpty) continue;
        final file = File(record.attachmentPath!);
        if (!await file.exists()) continue;
        found[file.path] = await _WorkspaceFile.fromFile(file, fallbackName: record.attachmentName);
      }
      final files = found.values.toList()
        ..sort((a, b) => b.modified.compareTo(a.modified));
      if (!mounted) return;
      setState(() {
        _files = files;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  List<_WorkspaceFile> get _visibleFiles {
    return _files.where((file) {
      final matchesQuery = _query.isEmpty || file.name.toLowerCase().contains(_query.toLowerCase());
      final matchesFilter = switch (_filter) {
        '文档' => const {'pdf', 'docx', 'pptx', 'xlsx', 'csv', 'txt', 'md', 'rtf'}.contains(file.extension),
        '网页' => const {'html', 'htm', 'css', 'js', 'svg'}.contains(file.extension),
        '图片' => const {'png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'}.contains(file.extension),
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFAFAFA),
    drawer: const AppSideDrawer(active: 'workspace'),
    drawerEnableOpenDragGesture: false,
    body: SafeArea(
      child: Column(children: [
        Builder(builder: (scaffoldContext) => Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(children: [
            _HeaderButton(icon: Icons.menu_rounded, onTap: () => Scaffold.of(scaffoldContext).openDrawer()),
            const SizedBox(width: 13),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('工作区', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.ink)),
              SizedBox(height: 3),
              Text('宋祁为你制作的文件与作品', style: TextStyle(fontSize: 10, color: AppColors.muted)),
            ])),
            _HeaderButton(icon: Icons.refresh_rounded, onTap: _loadFiles),
          ]),
        )),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: TextField(
            onChanged: (value) => setState(() => _query = value.trim()),
            decoration: InputDecoration(
              hintText: '搜索作品名称',
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 11),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFEAEAEA))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Color(0xFFEAEAEA))),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              for (final label in const ['全部', '文档', '网页', '图片'])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: _filter == label,
                    onSelected: (_) => setState(() => _filter = label),
                    selectedColor: const Color(0xFFE7E7E7),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE8E8E8)),
                    labelStyle: TextStyle(fontSize: 11, color: _filter == label ? AppColors.ink : AppColors.secondary),
                    showCheckmark: false,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 7),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : _visibleFiles.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      onRefresh: _loadFiles,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                        padding: const EdgeInsets.fromLTRB(16, 9, 16, 24),
                        itemCount: _visibleFiles.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 9),
                        itemBuilder: (context, index) => _fileCard(_visibleFiles[index]),
                      ),
                    ),
        ),
      ]),
    ),
  );

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(22)),
          child: const Icon(Icons.folder_open_rounded, size: 30, color: AppColors.secondary),
        ),
        const SizedBox(height: 15),
        const Text('这里还没有作品', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 6),
        const Text('在聊天里让宋祁制作 HTML、文档、表格或演示文稿，成品会自动收进这里。', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, height: 1.6, color: AppColors.muted)),
      ]),
    ),
  );

  Widget _fileCard(_WorkspaceFile file) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _preview(file),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(children: [
          Container(
            width: 47,
            height: 49,
            decoration: BoxDecoration(color: const Color(0xFFF1F1F1), borderRadius: BorderRadius.circular(13)),
            child: Icon(_fileIcon(file.extension), color: const Color(0xFF444444), size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.ink)),
            const SizedBox(height: 5),
            Text('${file.extension.toUpperCase()}  ·  ${_formatSize(file.size)}', style: const TextStyle(fontSize: 10, color: AppColors.muted)),
            const SizedBox(height: 3),
            Text(_formatDate(file.modified), style: const TextStyle(fontSize: 10, color: AppColors.muted)),
          ])),
          IconButton(
            tooltip: '保存到手机',
            onPressed: () => _saveFile(file),
            icon: const Icon(Icons.download_outlined, size: 20, color: AppColors.secondary),
          ),
          const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.muted),
        ]),
      ),
    ),
  );

  Future<void> _preview(_WorkspaceFile file) async {
    if (!await File(file.path).exists()) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('这个文件已经不存在了')));
      await _loadFiles();
      return;
    }
    final ext = file.extension;
    if (const {'html', 'htm'}.contains(ext)) {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(NavigationDelegate(onNavigationRequest: (request) {
          final uri = Uri.tryParse(request.url);
          if (uri == null || {'file', 'about', 'data'}.contains(uri.scheme)) return NavigationDecision.navigate;
          return NavigationDecision.prevent;
        }))
        ..loadFile(file.path);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.all(9),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.sizeOf(context).height * .86,
            child: Column(children: [
              _PreviewHeader(title: file.name, onClose: () => Navigator.pop(dialogContext)),
              const Divider(height: 1),
              Expanded(child: WebViewWidget(controller: controller)),
            ]),
          ),
        ),
      );
    } else if (ext == 'pdf') {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.all(9),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.sizeOf(context).height * .86,
            child: Column(children: [
              _PreviewHeader(title: file.name, onClose: () => Navigator.pop(dialogContext)),
              const Divider(height: 1),
              Expanded(child: PdfPreview(build: (_) => File(file.path).readAsBytes(), pdfFileName: file.name, canChangeOrientation: false, canChangePageFormat: false)),
            ]),
          ),
        ),
      );
    } else if (const {'png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'}.contains(ext)) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black87,
        builder: (dialogContext) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: Stack(children: [
            Center(child: InteractiveViewer(child: Image.file(File(file.path), fit: BoxFit.contain))),
            Positioned(top: 2, right: 2, child: IconButton(onPressed: () => Navigator.pop(dialogContext), icon: const Icon(Icons.close_rounded, color: Colors.white))),
          ]),
        ),
      );
    } else if (const {'txt', 'md', 'csv', 'json', 'xml', 'yaml', 'yml', 'log', 'css', 'js', 'svg'}.contains(ext)) {
      final content = await File(file.path).readAsString();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          insetPadding: const EdgeInsets.all(12),
          child: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.sizeOf(context).height * .82,
            child: Column(children: [
              _PreviewHeader(title: file.name, onClose: () => Navigator.pop(dialogContext)),
              const Divider(height: 1),
              Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(15), child: SelectableText(content, style: const TextStyle(fontFamily: 'monospace', fontSize: 11, height: 1.5)))),
            ]),
          ),
        ),
      );
    } else {
      await OpenFilex.open(file.path);
    }
  }

  Future<void> _saveFile(_WorkspaceFile file) async {
    try {
      final bytes = await File(file.path).readAsBytes();
      final path = await FilePicker.platform.saveFile(
        dialogTitle: '保存作品',
        fileName: file.name,
        bytes: bytes,
      );
      if (!mounted || path == null) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('作品已保存到你选择的位置')));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存失败：$error')));
    }
  }

  IconData _fileIcon(String extension) {
    if (extension == 'pdf') return Icons.picture_as_pdf_outlined;
    if (extension == 'docx' || extension == 'rtf') return Icons.description_outlined;
    if (extension == 'pptx') return Icons.slideshow_outlined;
    if (extension == 'xlsx' || extension == 'csv') return Icons.table_chart_outlined;
    if (const {'html', 'htm', 'css', 'js'}.contains(extension)) return Icons.web_outlined;
    if (const {'png', 'jpg', 'jpeg', 'webp', 'gif', 'bmp'}.contains(extension)) return Icons.image_outlined;
    return Icons.insert_drive_file_outlined;
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _formatDate(DateTime date) => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}

class _WorkspaceFile {
  const _WorkspaceFile({required this.path, required this.name, required this.extension, required this.size, required this.modified});
  final String path;
  final String name;
  final String extension;
  final int size;
  final DateTime modified;

  static Future<_WorkspaceFile> fromFile(File file, {String? fallbackName}) async {
    final stat = await file.stat();
    final name = fallbackName?.trim().isNotEmpty == true ? fallbackName!.trim() : file.uri.pathSegments.last;
    return _WorkspaceFile(
      path: file.path,
      name: name,
      extension: name.contains('.') ? name.split('.').last.toLowerCase() : '',
      size: stat.size,
      modified: stat.modified,
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(13),
    child: InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      child: SizedBox(width: 42, height: 42, child: Icon(icon, size: 20, color: AppColors.secondary)),
    ),
  );
}

class _PreviewHeader extends StatelessWidget {
  const _PreviewHeader({required this.title, required this.onClose});
  final String title;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(13, 7, 5, 7),
    child: Row(children: [
      const Icon(Icons.insert_drive_file_outlined, size: 17),
      const SizedBox(width: 8),
      Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
      IconButton(onPressed: onClose, icon: const Icon(Icons.close_rounded, size: 19)),
    ]),
  );
}
