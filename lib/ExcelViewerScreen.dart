import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:excel/excel.dart';

class ExcelViewer extends StatefulWidget {
  final String filePath;

  const ExcelViewer({Key? key, required this.filePath}) : super(key: key);

  @override
  State<ExcelViewer> createState() => _ExcelViewerState();
}

class _ExcelViewerState extends State<ExcelViewer> {
  List<Map<String, dynamic>> excelData = [];

  @override
  void initState() {
    super.initState();
    _loadExcelFile();
  }

  Future<void> _loadExcelFile() async {
    try {
      final bytes = File(widget.filePath).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      // Assume first sheet
      final sheet = excel.tables[excel.tables.keys.first]!;

      // Extract headers
      final headers = sheet.rows.first.map((cell) => cell?.value?.toString()).toList();

      // Extract rows
      final rows = sheet.rows.skip(1).map((row) {
        final map = <String, dynamic>{};
        for (int i = 0; i < headers.length; i++) {
          map[headers[i] ?? 'Column $i'] = row[i]?.value ?? '';
        }
        return map;
      }).toList();

      setState(() {
        excelData = rows;
      });
    } catch (e) {
      print('Error reading Excel file: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Excel Viewer')),
      body: excelData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SfDataGrid(
        source: ExcelDataGridSource(excelData),
        columns: excelData.isNotEmpty
            ? excelData.first.keys.map((key) {
          return GridColumn(
            columnName: key,
            label: Container(
              padding: const EdgeInsets.all(8.0),
              alignment: Alignment.centerLeft,
              child: Text(
                key,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }).toList()
            : [],
      ),
    );
  }
}

class ExcelDataGridSource extends DataGridSource {
  final List<DataGridRow> _dataGridRows;

  ExcelDataGridSource(List<Map<String, dynamic>> excelData)
      : _dataGridRows = excelData.map<DataGridRow>((dataRow) {
    return DataGridRow(
      cells: dataRow.entries.map<DataGridCell>((entry) {
        return DataGridCell(columnName: entry.key, value: entry.value);
      }).toList(),
    );
  }).toList();

  @override
  List<DataGridRow> get rows => _dataGridRows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((dataCell) {
        return Container(
          padding: const EdgeInsets.all(8.0),
          alignment: Alignment.centerLeft,
          child: Text(dataCell.value.toString()),
        );
      }).toList(),
    );
  }
}