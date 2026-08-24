import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

bool isDroppedReportExcelColumn(String key) {
  final n = key.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  return n == 'id' || n == 'created_at' || n == 'createdat';
}

String _labelForKey(String key) {
  return key
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String _cellString(dynamic value) {
  if (value == null) return '';
  if (value is num || value is bool) return value.toString();
  return value.toString();
}

/// Builds an .xlsx from the currently displayed report rows, without id / created_at.
Uint8List buildReportExcelFromRows({
  required String sheetName,
  required List<Map<String, dynamic>> rows,
}) {
  final headers = <String>[];
  for (final row in rows) {
    for (final key in row.keys) {
      if (isDroppedReportExcelColumn(key)) continue;
      if (!headers.contains(key)) headers.add(key);
    }
  }

  final headerLabels = headers.map(_labelForKey).toList();
  final data = rows
      .map((row) => headers.map((key) => _cellString(row[key])).toList())
      .toList();

  return buildSimpleXlsx(
    sheetName: sheetName,
    headers: headerLabels,
    rows: data,
  );
}

Uint8List buildSimpleXlsx({
  required String sheetName,
  required List<String> headers,
  required List<List<String>> rows,
}) {
  final safeName = _safeSheetName(sheetName);
  final sheetXml = _sheetXml(headers, rows);

  final archive = Archive()
    ..addFile(
      ArchiveFile.string(
        '[Content_Types].xml',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
</Types>''',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        '_rels/.rels',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'xl/workbook.xml',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="${_escapeXml(safeName)}" sheetId="1" r:id="rId1"/>
  </sheets>
</workbook>''',
      ),
    )
    ..addFile(
      ArchiveFile.string(
        'xl/_rels/workbook.xml.rels',
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
</Relationships>''',
      ),
    )
    ..addFile(ArchiveFile.string('xl/worksheets/sheet1.xml', sheetXml));

  return Uint8List.fromList(ZipEncoder().encode(archive));
}

String _sheetXml(List<String> headers, List<List<String>> rows) {
  final buf = StringBuffer()
    ..write('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>')
    ..write(
      '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>',
    );
  _writeRow(buf, 1, headers);
  for (var i = 0; i < rows.length; i++) {
    _writeRow(buf, i + 2, rows[i]);
  }
  buf.write('</sheetData></worksheet>');
  return buf.toString();
}

void _writeRow(StringBuffer buf, int rowNumber, List<String> cells) {
  buf.write('<row r="$rowNumber">');
  for (var i = 0; i < cells.length; i++) {
    final ref = '${_columnName(i)}$rowNumber';
    buf.write(
      '<c r="$ref" t="inlineStr"><is><t>${_escapeXml(cells[i])}</t></is></c>',
    );
  }
  buf.write('</row>');
}

String _safeSheetName(String name) {
  var cleaned = name.trim().replaceAll(RegExp(r'[:\\/?*\[\]]'), ' ');
  if (cleaned.isEmpty) cleaned = 'Report';
  if (cleaned.length > 31) cleaned = cleaned.substring(0, 31);
  return cleaned;
}

String _columnName(int index) {
  var n = index + 1;
  var name = '';
  while (n > 0) {
    n--;
    name = String.fromCharCode(65 + (n % 26)) + name;
    n ~/= 26;
  }
  return name;
}

String _escapeXml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
