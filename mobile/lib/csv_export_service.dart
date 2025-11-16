import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class CsvExportService {
  /// Recebe uma lista de logs (maps) e gera um arquivo CSV.
  /// Retorna o caminho absoluto do arquivo gerado.
  static Future<String> exportRealtimeLogsToCsv(List<dynamic> logs) async {
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

    // Build CSV string with proper escaping
    final buffer = StringBuffer();
    for (final row in rows) {
      final escaped = row.map((cell) {
        final s = cell.replaceAll('"', '""');
        return '"$s"';
      }).join(',');
      buffer.writeln(escaped);
    }

    final csvString = buffer.toString();

    final dir = await getTemporaryDirectory();
    final fileName = 'realtime_logs_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(csvString, flush: true);
    return file.path;
  }
}
