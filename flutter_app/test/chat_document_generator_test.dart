import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xiaowo/features/chat/chat_document_generator.dart';

void main() {
  test('DOCX is a readable Office Open XML package', () async {
    final bytes = await ChatDocumentGenerator.generate('sample.docx', '# 标题\n正文内容');
    final archive = ZipDecoder().decodeBytes(bytes);
    final document = archive.findFile('word/document.xml');
    expect(document, isNotNull);
    expect(utf8.decode(document!.content as List<int>), contains('正文内容'));
  });

  test('XLSX contains a worksheet with table values', () async {
    final bytes = await ChatDocumentGenerator.generate('sample.xlsx', '| 名称 | 数量 |\n| --- | --- |\n| 苹果 | 3 |');
    final archive = ZipDecoder().decodeBytes(bytes);
    final sheet = archive.findFile('xl/worksheets/sheet1.xml');
    expect(sheet, isNotNull);
    expect(utf8.decode(sheet!.content as List<int>), contains('苹果'));
  });

  test('PPTX contains separate slide files', () async {
    final bytes = await ChatDocumentGenerator.generate('sample.pptx', '# 第一页\n内容\n---\n# 第二页\n更多内容');
    final archive = ZipDecoder().decodeBytes(bytes);
    expect(archive.findFile('ppt/slides/slide1.xml'), isNotNull);
    expect(archive.findFile('ppt/slides/slide2.xml'), isNotNull);
  });

  test('PDF output has a real PDF signature', () async {
    final bytes = await ChatDocumentGenerator.generate('sample.pdf', '# Sample\nHello world');
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
  });
}
