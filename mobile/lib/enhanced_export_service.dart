import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

class EnhancedExportService {
  /// Export realtime logs to CSV (already exists, but improved format)
  static Future<String> exportLogsToCSV(List<dynamic> logs) async {
    final header = ['id', 'tenant_id', 'user_id', 'source', 'created_at', 'payload'];

    final rows = <List<String>>[];
    rows.add(header);

    for (final item in logs) {
      final map = item as Map<String, dynamic>;
      final payload = map['payload'];
      final payloadStr = payload != null ? jsonEncode(payload) : '';
      rows.add([
        (map['id'] ?? '').toString(),
        (map['tenant_id'] ?? '').toString(),
        (map['user_id'] ?? '').toString(),
        (map['source'] ?? '').toString(),
        (map['created_at'] ?? '').toString(),
        payloadStr.replaceAll('\n', ' '),
      ]);
    }

    final buffer = StringBuffer();
    for (final row in rows) {
      final escaped = row.map((cell) {
        final s = cell.replaceAll('"', '""');
        return '"$s"';
      }).join(',');
      buffer.writeln(escaped);
    }

    final dir = await getTemporaryDirectory();
    final fileName = 'realtime_logs_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString(), flush: true);
    return file.path;
  }

  /// Export commissions report to CSV
  static Future<String> exportCommissionsToCSV(List<dynamic> commissions) async {
    final header = ['employee_id', 'employee_name', 'service_order_id', 'amount', 'period', 'status', 'created_at'];

    final rows = <List<String>>[];
    rows.add(header);

    for (final item in commissions) {
      final map = item as Map<String, dynamic>;
      rows.add([
        (map['employee_id'] ?? '').toString(),
        (map['users']?['name'] ?? '').toString(),
        (map['service_order_id'] ?? '').toString(),
        (map['amount'] ?? '0').toString(),
        '${map['period_start'] ?? ''} to ${map['period_end'] ?? ''}',
        (map['status'] ?? '').toString(),
        (map['created_at'] ?? '').toString(),
      ]);
    }

    final buffer = StringBuffer();
    for (final row in rows) {
      final escaped = row.map((cell) {
        final s = cell.replaceAll('"', '""');
        return '"$s"';
      }).join(',');
      buffer.writeln(escaped);
    }

    final dir = await getTemporaryDirectory();
    final fileName = 'commissions_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString(), flush: true);
    return file.path;
  }

  /// Export financial data (cash flow, receivable, payable) to CSV
  static Future<String> exportFinancialToCSV({
    required String title,
    required List<dynamic> data,
    required List<String> columns,
  }) async {
    final rows = <List<String>>[];
    rows.add([title]);
    rows.add([]); // blank line
    rows.add(columns);

    for (final item in data) {
      final map = item as Map<String, dynamic>;
      final row = columns.map((col) => (map[col] ?? '').toString()).toList();
      rows.add(row);
    }

    final buffer = StringBuffer();
    for (final row in rows) {
      final escaped = row.map((cell) {
        final s = cell.replaceAll('"', '""');
        return '"$s"';
      }).join(',');
      buffer.writeln(escaped);
    }

    final dir = await getTemporaryDirectory();
    final fileName =
        'financial_${title.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString(), flush: true);
    return file.path;
  }

  /// Export commissions report to PDF
  static Future<String> exportCommissionsToPDF({
    required String tenantName,
    required DateTime startDate,
    required DateTime endDate,
    required List<dynamic> commissions,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Relatório de Comissões',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Empresa: $tenantName', style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            'Período: ${dateFormat.format(startDate)} a ${dateFormat.format(endDate)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Funcionário', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Valor (R\$)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ...commissions.map((item) {
                final map = item as Map<String, dynamic>;
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text((map['users']?['name'] ?? 'N/A').toString()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text((map['amount'] ?? '0').toString()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text((map['status'] ?? 'N/A').toString()),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Gerado em: ${dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName = 'commissions_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  /// Export financial cash flow to PDF
  static Future<String> exportCashFlowToPDF({
    required String tenantName,
    required DateTime startDate,
    required DateTime endDate,
    required Map<String, dynamic> cashFlow,
    required List<dynamic> byCategory,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Relatório de Fluxo de Caixa',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text('Empresa: $tenantName', style: const pw.TextStyle(fontSize: 12)),
          pw.Text(
            'Período: ${dateFormat.format(startDate)} a ${dateFormat.format(endDate)}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 20),
          pw.Text('Resumo Geral', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Descrição', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Valor (R\$)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Receita Total'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(currencyFormat.format(cashFlow['total_revenue'] ?? 0)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Despesa Total'),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(currencyFormat.format(cashFlow['total_expenses'] ?? 0)),
                  ),
                ],
              ),
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Fluxo Líquido', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text(currencyFormat.format(cashFlow['net_cash_flow'] ?? 0),
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Por Categoria', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Categoria', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Tipo', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Total (R\$)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
              ...byCategory.map((item) {
                final map = item as Map<String, dynamic>;
                return pw.TableRow(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text((map['category'] ?? 'N/A').toString()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text((map['type'] ?? 'N/A').toString()),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(currencyFormat.format(map['total_amount'] ?? 0)),
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Gerado em: ${dateFormat.format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final fileName = 'cashflow_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pdf';
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file.path;
  }

  /// Share exported file (CSV or PDF)
  static Future<void> shareFile(String filePath, {String? subject}) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('File not found: $filePath');
        return;
      }

      final bytes = await file.readAsBytes();
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: subject ?? 'Export Report',
      );
    } catch (e) {
      print('Error sharing file: $e');
      rethrow;
    }
  }

  /// Open file (on mobile, typically opens file manager or appropriate app)
  static Future<void> openFile(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        print('File not found: $filePath');
        return;
      }
      // On Android/iOS, you'd typically use a method channel or plugin
      // For now, just share it for the user to select an app
      await shareFile(filePath);
    } catch (e) {
      print('Error opening file: $e');
      rethrow;
    }
  }
}
