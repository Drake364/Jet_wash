import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'csv_export_service.dart';

class RealtimeLogsPage extends StatefulWidget {
  const RealtimeLogsPage({super.key});

  @override
  State<RealtimeLogsPage> createState() => _RealtimeLogsPageState();
}

class _RealtimeLogsPageState extends State<RealtimeLogsPage> {
  List<dynamic> _logs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => _loading = true);
    final res = await Supabase.instance.client
        .from('realtime_logs')
        .select('id, tenant_id, user_id, source, payload, created_at')
        .order('created_at', ascending: false)
        .limit(20)
        .execute();
    if (res.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao buscar logs: ${res.error!.message}')));
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _logs = res.data as List<dynamic>;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realtime Logs'), actions: [
        IconButton(
          tooltip: 'Exportar CSV',
          icon: const Icon(Icons.download),
          onPressed: () async {
            if (_logs.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum log para exportar')));
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gerando CSV...')));
            try {
              final path = await CsvExportService.exportRealtimeLogsToCsv(_logs);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('CSV gerado: $path')));
              // também printa no console para facilidade
              print('CSV gerado em: $path');
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao gerar CSV: $e')));
            }
          },
        )
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchLogs,
              child: ListView.builder(
                itemCount: _logs.length,
                itemBuilder: (context, idx) {
                  final l = _logs[idx] as Map;
                  final payload = l['payload'];
                  final pretty = JsonEncoder.withIndent('  ').convert(payload ?? {});
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('id: ${l['id'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(l['created_at'] ?? '', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('source: ${l['source'] ?? ''}'),
                          Text('user_id: ${l['user_id'] ?? ''}'),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SelectableText(pretty, style: const TextStyle(fontFamily: 'monospace')),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
