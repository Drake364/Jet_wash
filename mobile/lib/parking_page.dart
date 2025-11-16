import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'service_order_page.dart';

class ParkingPage extends StatefulWidget {
  const ParkingPage({super.key});

  @override
  State<ParkingPage> createState() => _ParkingPageState();
}

class _ParkingPageState extends State<ParkingPage> {
  List<dynamic> _orders = [];
  bool _loading = false;
  String? _tenantId;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    // fetch tenant id once for logging purposes
    SupabaseService().fetchDefaultTenant().then((t) {
      setState(() {
        _tenantId = t != null ? t['id'] as String? : null;
      });
    });
    // subscribe to realtime changes for service_orders
    final client = Supabase.instance.client;
    final channel = client.channel('public:service_orders');
    channel.on(RealtimeListenTypes.postgresChanges, ChannelFilter(event: '*', schema: 'public', table: 'service_orders'), (payload, [ref]) async {
      // payload is dynamic map — attempt to apply incremental patch instead of full reload
      bool handled = false;
      try {
        final map = payload as Map<String, dynamic>;

        // detect event type in common fields
        final event = (map['type'] ?? map['eventType'] ?? map['event'] ?? map['action'] ?? '').toString().toUpperCase();
        final newRow = map['new'] ?? map['record'] ?? map['data'] ?? map['payload'] ?? null;
        final oldRow = map['old'] ?? null;

        if (event.contains('INSERT')) {
          if (newRow != null) {
            setState(() {
              _orders.insert(0, newRow);
            });
            handled = true;
          }
        } else if (event.contains('UPDATE')) {
          if (newRow != null) {
            final id = newRow['id'];
            final idx = _orders.indexWhere((e) => e['id'] == id);
            if (idx >= 0) {
              setState(() { _orders[idx] = newRow; });
            } else {
              setState(() { _orders.insert(0, newRow); });
            }
            handled = true;
          }
        } else if (event.contains('DELETE')) {
          final id = oldRow != null ? oldRow['id'] : null;
          if (id != null) {
            setState(() { _orders.removeWhere((e) => e['id'] == id); });
            handled = true;
          }
        }
      } catch (e) {
        // ignore here — handled remains false
      }

      if (!handled) {
        // fallback: try to detect nested payload shapes
        try {
          if (payload is Map && payload.containsKey('new') && payload['new'] != null) {
            final newRow = payload['new'];
            setState(() { _orders.insert(0, newRow); });
            handled = true;
          }
        } catch (_) {}
      }

      if (!handled) {
        // não reconhecido — log local e envie para log remoto para diagnóstico (RPC)
        try {
          print('Realtime payload não reconhecido — enviando para log RPC:');
          print(payload);

          final tenantId = _tenantId;
          if (tenantId != null) {
            final rpcRes = await Supabase.instance.client.rpc('log_realtime_payload', params: {
              'p_tenant': tenantId,
              'p_payload': payload,
              'p_source': 'mobile_realtime_unrecognized'
            }).execute();
            if (rpcRes.error != null) {
              print('Erro RPC log_realtime_payload: ${rpcRes.error!.message}');
            } else {
              print('Payload enviado ao servidor para diagnóstico.');
            }
          } else {
            print('TenantId não disponível — não foi possível enviar payload ao RPC.');
          }
        } catch (e) {
          // swallow errors from logging but print for developer visibility
          print('Erro ao registrar payload não reconhecido: $e');
        }

        // reload as last resort
        _loadOrders();
      }
    });
    channel.subscribe();
    _channel = channel;
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    final client = Supabase.instance.client;
    final res = await client.from('service_orders').select('id, status, open_at, close_at, total, notes').order('open_at', ascending: false).execute();
    if (res.error != null) {
      print('Erro ao carregar OS: ${res.error!.message}');
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _orders = res.data as List<dynamic>;
      _loading = false;
    });
  }

  Future<void> _createOrder() async {
    final client = Supabase.instance.client;
    final res = await client.from('service_orders').insert({
      'status': 'open',
      'notes': 'Criada via app',
    }).execute();
    if (res.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${res.error!.message}')));
      return;
    }
    await _loadOrders();
  }

  RealtimeChannel? _channel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pátio / OS em tempo real')),
      floatingActionButton: FloatingActionButton(
        onPressed: _createOrder,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, idx) {
                final o = _orders[idx] as Map;
                return ListTile(
                  title: Text('OS ${o['id'].toString().substring(0, 8)}'),
                  subtitle: Text('${o['status']} — ${o['notes'] ?? ''}'),
                  trailing: Text('R\$ ${o['total'] ?? 0}'),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ServiceOrderPage(orderId: o['id']))),
                );
              },
            ),
    );
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }
}
