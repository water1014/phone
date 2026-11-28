// The XML builders intentionally concatenate OOXML fragments; keep these local style lints quiet.
// ignore_for_file: prefer_interpolation_to_compose_strings, curly_braces_in_flow_control_structures

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';


abstract final class ChatDocumentGenerator {
  static Future<Uint8List> generate(String name, String content) async {
    switch (name.split('.').last.toLowerCase()) {
      case 'docx': return _docx(content);
      case 'xlsx': return _xlsx(content);
      case 'pptx': return _pptx(content);
      case 'pdf': return _pdf(content);
      default: throw UnsupportedError('不支持的文件格式');
    }
  }
  static Uint8List _zip(Map<String, String> files) {
    final archive = Archive();
    for (final item in files.entries) {
      final bytes = utf8.encode(item.value);
      archive.addFile(ArchiveFile(item.key, bytes.length, bytes));
    }
    final result = ZipEncoder().encode(archive);
    if (result == null || result.isEmpty) throw StateError('文件打包失败');
    return Uint8List.fromList(result);
  }
  static String _x(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;').replaceAll("'", '&apos;');
  static List<String> _lines(String s) => s.replaceAll('\r\n', '\n').split('\n');
  static List<String> _cells(String line) => line.trim().replaceFirst(RegExp(r'^\|'), '').replaceFirst(RegExp(r'\|$'), '').split('|').map((e) => e.trim()).toList();
  static bool _divider(String s) => RegExp(r'^\|?[\s:|-]+\|?$').hasMatch(s.trim()) && s.contains('-');
  static String _wRun(String s, {bool bold = false}) => '<w:r><w:rPr>' + (bold ? '<w:b/>' : '') + '<w:rFonts w:ascii="Aptos" w:hAnsi="Aptos" w:eastAsia="等线"/></w:rPr><w:t xml:space="preserve">' + _x(s) + '</w:t></w:r>';

  static Uint8List _docx(String source) {
    final lines = _lines(source);
    final body = StringBuffer();
    var i = 0;
    while (i < lines.length) {
      final line = lines[i].trim();
      if (line.isEmpty) { i++; continue; }
      if (line.startsWith('|')) {
        final rows = <List<String>>[];
        while (i < lines.length && lines[i].trim().startsWith('|')) {
          if (!_divider(lines[i])) rows.add(_cells(lines[i]));
          i++;
        }
        body.write('<w:tbl><w:tblPr><w:tblBorders><w:top w:val="single" w:sz="4"/><w:left w:val="single" w:sz="4"/><w:bottom w:val="single" w:sz="4"/><w:right w:val="single" w:sz="4"/><w:insideH w:val="single" w:sz="4"/><w:insideV w:val="single" w:sz="4"/></w:tblBorders></w:tblPr>');
        for (var r = 0; r < rows.length; r++) {
          body.write('<w:tr>');
          for (final cell in rows[r]) body.write('<w:tc><w:tcPr><w:tcW w:w="2400" w:type="dxa"/></w:tcPr><w:p>' + _wRun(cell, bold: r == 0) + '</w:p></w:tc>');
          body.write('</w:tr>');
        }
        body.write('</w:tbl>');
        continue;
      }
      final h = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      final text = h?.group(2) ?? line.replaceFirst(RegExp(r'^[-*+]\s+'), '• ');
      body.write('<w:p><w:pPr>' + (h == null ? '<w:spacing w:after="120"/>' : '<w:pStyle w:val="Heading' + h.group(1)!.length.clamp(1, 3).toString() + '"/>') + '</w:pPr>' + _wRun(text, bold: h != null) + '</w:p>');
      i++;
    }
    return _zip({
      '[Content_Types].xml': '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/><Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/></Types>',
      '_rels/.rels': '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/></Relationships>',
      'word/_rels/document.xml.rels': '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>',
      'word/styles.xml': '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Aptos" w:hAnsi="Aptos" w:eastAsia="等线"/></w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after="120" w:line="360" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults><w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/></w:style><w:style w:type="paragraph" w:styleId="Heading1"><w:name w:val="heading 1"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="240" w:after="120"/></w:pPr><w:rPr><w:b/><w:sz w:val="32"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading2"><w:name w:val="heading 2"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="200" w:after="100"/></w:pPr><w:rPr><w:b/><w:sz w:val="28"/></w:rPr></w:style><w:style w:type="paragraph" w:styleId="Heading3"><w:name w:val="heading 3"/><w:basedOn w:val="Normal"/><w:next w:val="Normal"/><w:qFormat/><w:pPr><w:keepNext/><w:spacing w:before="160" w:after="80"/></w:pPr><w:rPr><w:b/><w:sz w:val="24"/></w:rPr></w:style></w:styles>',
      'word/document.xml': '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>' + body.toString() + '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440"/></w:sectPr></w:body></w:document>',
    });
  }

  static List<List<String>> _parseCsv(String source) {
    final rows = <List<String>>[];
    var row = <String>[];
    final cell = StringBuffer();
    var quoted = false;
    final input = source.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (ch == '"') {
        if (quoted && i + 1 < input.length && input[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = !quoted;
        }
      } else if (ch == ',' && !quoted) {
        row.add(cell.toString());
        cell.clear();
      } else if (ch == '\n' && !quoted) {
        row.add(cell.toString());
        cell.clear();
        if (row.any((value) => value.isNotEmpty)) rows.add(row);
        row = <String>[];
      } else {
        cell.write(ch);
      }
    }
    row.add(cell.toString());
    if (row.any((value) => value.isNotEmpty)) rows.add(row);
    return rows;
  }
  static String _col(int index) {
    var n = index + 1;
    var out = '';
    while (n > 0) { final r = (n - 1) % 26; out = String.fromCharCode(65 + r) + out; n = (n - r - 1) ~/ 26; }
    return out;
  }
  static Uint8List _xlsx(String source) {
    final lines = _lines(source).where((line) => line.trim().isNotEmpty).toList();
    final rows = <List<String>>[];
    final isTable = lines.any((line) => line.trim().startsWith('|'));
    if (isTable) {
      for (final line in lines) {
        if (line.trim().startsWith('|') && !_divider(line)) rows.add(_cells(line));
      }
    } else {
      rows.addAll(_parseCsv(source));
    }
    if (rows.isEmpty) rows.add(['内容']);
    final sheet = StringBuffer(
      '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>',
    );
    for (var r = 0; r < rows.length; r++) {
      sheet.write('<row r="${r + 1}">');
      for (var c = 0; c < rows[r].length; c++) {
        final value = rows[r][c];
        final ref = _col(c) + (r + 1).toString();
        final trimmed = value.trim();
        final numeric = RegExp(r'^-?(?:0|[1-9]\d*)(?:\.\d+)?(?:[eE][+-]?\d+)?$').hasMatch(trimmed);
        if (value.isEmpty) {
          sheet.write('<c r="$ref"/>');
        } else if (numeric && double.tryParse(trimmed) != null) {
          sheet.write('<c r="$ref"><v>$trimmed</v></c>');
        } else {
          sheet.write('<c r="$ref" t="inlineStr"><is><t xml:space="preserve">${_x(value)}</t></is></c>');
        }
      }
      sheet.write('</row>');
    }
    sheet.write('</sheetData></worksheet>');
    return _zip({
      '[Content_Types].xml': '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>',
      '_rels/.rels': '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>',
      'xl/workbook.xml': '<?xml version="1.0" encoding="UTF-8"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="工作表1" sheetId="1" r:id="rId1"/></sheets></workbook>',
      'xl/_rels/workbook.xml.rels': '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>',
      'xl/worksheets/sheet1.xml': sheet.toString(),
    });
  }

  static String _pptText(String text, int size, {bool bold = false}) => '<a:p><a:r><a:rPr lang="zh-CN" sz="' + size.toString() + '"' + (bold ? ' b="1"' : '') + '/><a:t xml:space="preserve">' + _x(text) + '</a:t></a:r></a:p>';
  static String _slide(String title, List<String> lines) {
    final body = StringBuffer();
    for (final line in lines) {
      final clean = line.trim().replaceFirst(RegExp(r'^[-*+]\s+'), '• ').replaceFirst(RegExp(r'^\d+[.)]\s+'), '• ');
      if (clean.isNotEmpty) body.write(_pptText(clean, 1900));
    }
    final titleShape = '<p:sp><p:nvSpPr><p:cNvPr id="2" name="标题"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr><p:spPr><a:xfrm><a:off x="457200" y="274638"/><a:ext cx="8229600" cy="1000000"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/><a:ln><a:noFill/></a:ln></p:spPr><p:txBody><a:bodyPr/><a:lstStyle/>' + _pptText(title, 3000, bold: true) + '</p:txBody></p:sp>';
    final bodyShape = '<p:sp><p:nvSpPr><p:cNvPr id="3" name="正文"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr><p:spPr><a:xfrm><a:off x="548640" y="1500000"/><a:ext cx="8046720" cy="3200000"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/><a:ln><a:noFill/></a:ln></p:spPr><p:txBody><a:bodyPr/><a:lstStyle/>' + body.toString() + '</p:txBody></p:sp>';
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>' + titleShape + bodyShape + '</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>';
  }
  static Uint8List _pptx(String source) {
    var chunks = source.split(RegExp(r'\n\s*---+\s*\n'));
    if (chunks.length > 40) chunks = chunks.take(40).toList();
    if (chunks.isEmpty) chunks = [source];
    final slides = <String, String>{};
    final overrides = StringBuffer();
    final ids = StringBuffer();
    final rels = StringBuffer('<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="slideMasters/slideMaster1.xml"/>');
    for (var i = 0; i < chunks.length; i++) {
      final lines = _lines(chunks[i]);
      var title = '第' + (i + 1).toString() + '页';
      var start = 0;
      if (lines.isNotEmpty && lines.first.trim().startsWith('#')) { title = lines.first.trim().replaceFirst(RegExp(r'^#{1,6}\s*'), ''); start = 1; }
      final num = (i + 1).toString();
      slides['ppt/slides/slide' + num + '.xml'] = _slide(title, lines.skip(start).toList());
      slides['ppt/slides/_rels/slide' + num + '.xml.rels'] = '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/></Relationships>';
      overrides.write('<Override PartName="/ppt/slides/slide' + num + '.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>');
      ids.write('<p:sldId id="' + (256 + i).toString() + '" r:id="rId' + (i + 2).toString() + '"/>');
      rels.write('<Relationship Id="rId' + (i + 2).toString() + '" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" Target="slides/slide' + num + '.xml"/>');
    }
    final files = <String, String>{
      '[Content_Types].xml': '<?xml version="1.0"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/><Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/><Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/><Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>' + overrides.toString() + '</Types>',
      '_rels/.rels': '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="ppt/presentation.xml"/></Relationships>',
      'ppt/presentation.xml': '<?xml version="1.0"?><p:presentation xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst><p:sldIdLst>' + ids.toString() + '</p:sldIdLst><p:sldSz cx="9144000" cy="5143500" type="screen16x9"/><p:notesSz cx="6858000" cy="9144000"/></p:presentation>',
      'ppt/_rels/presentation.xml.rels': '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' + rels.toString() + '</Relationships>',
      'ppt/slideMasters/slideMaster1.xml': '<?xml version="1.0"?><p:sldMaster xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"><p:cSld><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr></p:spTree></p:cSld><p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/><p:sldLayoutIdLst><p:sldLayoutId id="1" r:id="rId1"/></p:sldLayoutIdLst><p:txStyles><p:titleStyle/><p:bodyStyle/><p:otherStyle/></p:txStyles></p:sldMaster>',
      'ppt/slideMasters/_rels/slideMaster1.xml.rels': '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideLayout" Target="../slideLayouts/slideLayout1.xml"/><Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme" Target="../theme/theme1.xml"/></Relationships>',
      'ppt/slideLayouts/slideLayout1.xml': '<?xml version="1.0"?><p:sldLayout xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main" type="blank" preserve="1"><p:cSld name="空白"><p:spTree><p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr><p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr></p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sldLayout>',
      'ppt/slideLayouts/_rels/slideLayout1.xml.rels': '<?xml version="1.0"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slideMaster" Target="../slideMasters/slideMaster1.xml"/></Relationships>',
      'ppt/theme/theme1.xml': '<?xml version="1.0"?><a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="小窝"><a:themeElements><a:clrScheme name="Office"><a:dk1><a:sysClr val="windowText" lastClr="000000"/></a:dk1><a:lt1><a:sysClr val="window" lastClr="FFFFFF"/></a:lt1><a:dk2><a:srgbClr val="1F1F1F"/></a:dk2><a:lt2><a:srgbClr val="F2F2F2"/></a:lt2><a:accent1><a:srgbClr val="444444"/></a:accent1><a:accent2><a:srgbClr val="777777"/></a:accent2><a:accent3><a:srgbClr val="999999"/></a:accent3><a:accent4><a:srgbClr val="BBBBBB"/></a:accent4><a:accent5><a:srgbClr val="D0D0D0"/></a:accent5><a:accent6><a:srgbClr val="E5E5E5"/></a:accent6><a:hlink><a:srgbClr val="0563C1"/></a:hlink><a:folHlink><a:srgbClr val="954F72"/></a:folHlink></a:clrScheme><a:fontScheme name="Office"><a:majorFont><a:latin typeface="Aptos Display"/><a:ea typeface="等线"/><a:cs typeface=""/></a:majorFont><a:minorFont><a:latin typeface="Aptos"/><a:ea typeface="等线"/><a:cs typeface=""/></a:minorFont></a:fontScheme><a:fmtScheme name="Office"><a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst><a:lnStyleLst><a:ln w="6350"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:prstDash val="solid"/></a:ln></a:lnStyleLst><a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst><a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst></a:fmtScheme></a:themeElements></a:theme>',
    };
    files.addAll(slides);
    return _zip(files);
  }

  static Future<Uint8List> _pdf(String source) async {
    final doc = pw.Document();
    pw.Font? font;
    pw.Font? boldFont;
    final cjk = RegExp(r'[\u3400-\u9FFF]').hasMatch(source);
    if (cjk) {
      try {
        font = await PdfGoogleFonts.notoSansSCRegular();
        boldFont = await PdfGoogleFonts.notoSansSCBold();
      } catch (_) {
        const paths = [
          '/system/fonts/NotoSansCJKsc-Regular.otf',
          '/system/fonts/NotoSansSC-Regular.ttf',
          '/system/fonts/DroidSansFallback.ttf',
          '/system/fonts/NotoSansCJK-Regular.ttc',
        ];
        for (final path in paths) {
          final file = File(path);
          if (!await file.exists()) continue;
          try {
            font = pw.Font.ttf(ByteData.sublistView(await file.readAsBytes()));
            break;
          } catch (_) {}
        }
      }
      if (font == null) {
        throw StateError('中文字体暂时无法加载，请连接网络后重试 PDF 生成');
      }
    }
    final blocks = <pw.Widget>[];
    for (final raw in _lines(source)) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        blocks.add(pw.SizedBox(height: 7));
        continue;
      }
      final heading = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line.trim());
      if (heading != null) {
        blocks.add(pw.Padding(
          padding: const pw.EdgeInsets.only(top: 10, bottom: 5),
          child: pw.Text(
            heading.group(2) ?? '',
            style: pw.TextStyle(font: font, fontBold: boldFont, fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ));
      } else {
        final text = line
            .replaceFirst(RegExp(r'^[-*+]\s+'), '• ')
            .replaceFirst(RegExp(r'^\d+[.)]\s+'), '• ')
            .replaceAll('**', '')
            .replaceAll(String.fromCharCode(96), '');
        blocks.add(pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Text(text, style: pw.TextStyle(font: font, fontSize: 11, lineSpacing: 3)),
        ));
      }
    }
    if (blocks.isEmpty) blocks.add(pw.Text('空白文档'));
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(48),
      build: (_) => blocks,
    ));
    return Uint8List.fromList(await doc.save());
  }
}