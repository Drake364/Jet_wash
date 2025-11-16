import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'storage_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _nameCtrl = TextEditingController();
  final _colorCtrl = TextEditingController(text: '#1E88E5');
  File? _logoFile;
  bool _isSaving = false;

  final _picker = ImagePicker();

  Future<void> _pickLogo() async {
    final x = await _picker.pickImage(source: ImageSource.gallery);
    if (x != null) setState(() => _logoFile = File(x.path));
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final client = Supabase.instance.client;
      // Assumindo tenant já existente; busca primeiro tenant
      final svc = SupabaseService();
      final tenant = await svc.fetchDefaultTenant();
      if (tenant == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum tenant encontrado')));
        return;
      }

      final tenantId = tenant['id'] as String;

      String? logoUrl;
      if (_logoFile != null) {
        final storage = StorageService();
        final filename = 'logo_${DateTime.now().millisecondsSinceEpoch}.png';
        final path = 'tenants/$tenantId/$filename';
        // agora upload retorna o storage path (para bucket privado)
        final storedPath = await storage.uploadPhoto(_logoFile!, 'public', path, tenantId, refType: 'tenant_logo');
        logoUrl = storedPath;
      }

      final update = await client.from('tenants').update({
        'nome_fantasia': _nameCtrl.text.trim(),
        'primary_color': _colorCtrl.text.trim(),
        'logo_url': logoUrl,
      }).eq('id', tenantId).execute();

      if (update.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao salvar: ${update.error!.message}')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configurações salvas')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding / White‑label')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Nome fantasia')),
          const SizedBox(height: 8),
          TextField(controller: _colorCtrl, decoration: const InputDecoration(labelText: 'Cor primária (hex)')),
          const SizedBox(height: 12),
          Row(children: [
            ElevatedButton(onPressed: _pickLogo, child: const Text('Escolher logo')),
            const SizedBox(width: 12),
            if (_logoFile != null) const Text('Logo selecionado')
          ]),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _isSaving ? null : _save, child: _isSaving ? const CircularProgressIndicator() : const Text('Salvar')),
        ]),
      ),
    );
  }
}
