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
    final styles = archive.findFile('word/styles.xml');
    final rels = archive.findFile('word/_rels/document.xml.rels');
    expect(styles, isNotNull);
    expect(utf8.decode(styles!.content as List<int>), contains('Heading1'));
    expect(rels, isNotNull);
  });

  test('XLSX contains a worksheet with table values', () async {
    final bytes = await ChatDocumentGenerator.generate('sample.xlsx', '| 名称 | 数量 |\n| --- | --- |\n| 苹果 | 3 |');
    final archive = ZipDecoder().decodeBytes(bytes);
    final sheet = archive.findFile('xl/worksheets/sheet1.xml');
    expect(sheet, isNotNull);
    final xml = utf8.decode(sheet!.content as List<int>);
    expect(xml, contains('苹果'));
    expect(xml, contains('<c r="B2"><v>3</v></c>'));
    expect(xml, isNot(contains('<c r="B2" t="inlineStr">')));
  });

  test('PPTX contains separate slide files', () async {
    final bytes = await ChatDocumentGenerator.generate('sample.pptx', '# 第一页\n内容\n---\n# 第二页\n更多内容');
    final archive = ZipDecoder().decodeBytes(bytes);
    expect(archive.findFile('ppt/slides/slide1.xml'), isNotNull);
    expect(archive.findFile('ppt/slides/slide2.xml'), isNotNull);
    expect(archive.findFile('ppt/_rels/presentation.xml.rels'), isNotNull);
    expect(archive.findFile('ppt/slides/_rels/slide1.xml.rels'), isNotNull);
    final types = archive.findFile('[Content_Types].xml');
    expect(types, isNotNull);
    expect(utf8.decode(types!.content as List<int>), contains('/ppt/presentation.xml'));
  });

  test('XLSX preserves quoted commas and multiline CSV cells', () async {
    final bytes = await ChatDocumentGenerator.generate('sample.xlsx', 'Name,Note,Amount\\nApple,"fresh, red",12.5\\nPear,"line one\\nline two",-3');
    final archive = ZipDecoder().decodeBytes(bytes);
    final xml = utf8.decode(archive.findFile('xl/worksheets/sheet1.xml')!.content as List<int>);
    expect(xml, contains('fresh, red'));
    expect(xml, contains('line one&#10;line two'));
    expect(xml, contains('<c r="C2"><v>12.5</v></c>'));
    expect(xml, contains('<c r="C3"><v>-3</v></c>'));
  });

  test('PDF output has a real PDF signature', () async {
    final bytes = await ChatDocumentGenerator.generate('sample.pdf', '# Sample\nHello world');
    expect(utf8.decode(bytes.take(5).toList()), '%PDF-');
  });
}
