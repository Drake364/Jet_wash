import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'storage_service.dart';
import 'supabase_service.dart';

class ServiceOrderPage extends StatefulWidget {
  final String orderId;
  const ServiceOrderPage({super.key, required this.orderId});

  @override
  State<ServiceOrderPage> createState() => _ServiceOrderPageState();
}

class _ServiceOrderPageState extends State<ServiceOrderPage> {
  List<dynamic> _checklist = [];
  bool _loading = false;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadChecklist();
  }

  Future<void> _loadChecklist() async {
    setState(() => _loading = true);
    final res = await Supabase.instance.client
        .from('checklists')
        .select('id, item, status, photo_url, notes')
        .eq('service_order_id', widget.orderId)
        .order('id', ascending: true)
        .execute();
    if (res.error != null) {
      print('Erro checklist: ${res.error!.message}');
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _checklist = res.data as List<dynamic>;
      _loading = false;
    });
  }

  Future<void> _addChecklistItem(String item) async {
    final res = await Supabase.instance.client.from('checklists').insert({
      'service_order_id': widget.orderId,
      'item': item,
      'status': 'pending'
    }).execute();
    if (res.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: ${res.error!.message}')));
      return;
    }
    await _loadChecklist();
  }

  Future<void> _pickAndUploadPhoto(String checklistId) async {
    final x = await _picker.pickImage(source: ImageSource.camera);
    if (x == null) return;
    final file = File(x.path);
    final svc = SupabaseService();
    final tenant = await svc.fetchDefaultTenant();
    final tenantId = tenant?['id'] as String?;
    if (tenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum tenant')));
      return;
    }

    final storage = StorageService();
    final filename = 'check_${widget.orderId}_$checklistId_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'tenants/$tenantId/service_orders/${widget.orderId}/$filename';
    final publicUrl = await storage.uploadPhoto(file, 'public', path, tenantId, refType: 'checklist', refId: checklistId);
    if (publicUrl != null) {
      // atualiza a linha do checklist com a url
      await Supabase.instance.client.from('checklists').update({'photo_url': publicUrl}).eq('id', checklistId).execute();
      await _loadChecklist();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto anexada')));
    }
  }

  Future<void> _toggleStatus(String id, String current) async {
    final next = current == 'pending' ? 'done' : 'pending';
    await Supabase.instance.client.from('checklists').update({'status': next}).eq('id', id).execute();
    await _loadChecklist();
  }

  @override
  Widget build(BuildContext context) {
    final _newCtrl = TextEditingController();
    return Scaffold(
      appBar: AppBar(title: Text('OS ${widget.orderId.substring(0,8)}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _checklist.length,
                  itemBuilder: (context, idx) {
                    final c = _checklist[idx] as Map;
                    return ListTile(
                      title: Text(c['item'] ?? ''),
                      subtitle: Text('Status: ${c['status'] ?? ''}'),
                      leading: c['photo_url'] != null ? FutureBuilder<String?>(
                        future: _resolvePhotoUrl(c['photo_url'] as String),
                        builder: (context, snap) {
                          if (snap.connectionState != ConnectionState.done) return const SizedBox(width:56, height:56);
                          final url = snap.data;
                          if (url == null) return const SizedBox(width:56, height:56);
                          return Image.network(url, width: 56, height: 56, fit: BoxFit.cover);
                        },
                      ) : null,
                      trailing: Wrap(children: [
                        IconButton(icon: const Icon(Icons.camera_alt), onPressed: () => _pickAndUploadPhoto(c['id'])),
                        IconButton(icon: const Icon(Icons.check), onPressed: () => _toggleStatus(c['id'], c['status'] ?? 'pending')),
                      ]),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(children: [
                  Expanded(child: TextField(controller: _newCtrl, decoration: const InputDecoration(hintText: 'Novo item do checklist'))),
                  ElevatedButton(onPressed: () { if (_newCtrl.text.trim().isNotEmpty) { _addChecklistItem(_newCtrl.text.trim()); _newCtrl.clear(); } }, child: const Text('Adicionar'))
                ]),
              )
            ]),
    );
  }

  Future<String?> _resolvePhotoUrl(String stored) async {
    // se já for URL, retorna direto
    if (stored.startsWith('http')) return stored;
    // caso seja um storage path, gere signed URL
    final storage = StorageService();
    final signed = await storage.createSignedUrl('public', stored, expiresIn: 60*60);
    return signed;
  }
}
