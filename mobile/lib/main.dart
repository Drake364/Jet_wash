import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'supabase_service.dart';
import 'auth_service.dart';
import 'auth_page.dart';
import 'onboarding_page.dart';
import 'parking_page.dart';
import 'ocr_service.dart';
import 'storage_service.dart';
import 'realtime_logs_page.dart';
import 'customers_page.dart';
import 'employees_page.dart';
import 'financial_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const JetWashApp());
}

class JetWashApp extends StatefulWidget {
  const JetWashApp({super.key});

  @override
  State<JetWashApp> createState() => _JetWashAppState();
}

class _JetWashAppState extends State<JetWashApp> {
  Map<String, dynamic>? tenant;

  @override
  void initState() {
    super.initState();
    _loadTenant();
    // Listen to auth changes to rebuild UI accordingly
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {});
    });
  }

  Future<void> _loadTenant() async {
    // Exemplo: carrega tenant settings do Supabase; em produção, identifique o tenant pelo subdomínio ou credencial
    final service = SupabaseService();
    final t = await service.fetchDefaultTenant();
    setState(() => tenant = t);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = tenant != null && tenant!['primary_color'] != null
        ? Color(int.parse(tenant!['primary_color'].toString().replaceAll('#', '0xFF')))
        : const Color(0xFF1E88E5);

    final user = Supabase.instance.client.auth.currentUser;

    return MaterialApp(
      title: tenant != null ? tenant!['nome_fantasia'] ?? 'JetWash Pro' : 'JetWash Pro',
      theme: ThemeData(
        primaryColor: primaryColor,
        colorScheme: ColorScheme.fromSeed(seedColor: primaryColor),
      ),
      home: user == null ? const AuthPage() : const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    
    return Scaffold(
      appBar: AppBar(title: const Text('JetWash Pro'), actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await supabase.auth.signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthPage()),
                (route) => false,
              );
            }
          },
        ),
      ]),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: SupabaseService.fetchDefaultTenant(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final tenant = snapshot.data;
          final tenantId = tenant?['id'] as String? ?? '';
          final tenantName = tenant?['nome_fantasia'] as String? ?? 'JetWash Pro';

          return SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(Icons.local_car_wash, size: 72),
                      const SizedBox(height: 12),
                      Text(tenantName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
                _buildMenuButton(
                  context,
                  label: 'Pátio (Ordens de Serviço)',
                  icon: Icons.local_car_wash,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParkingPage())),
                ),
                _buildMenuButton(
                  context,
                  label: 'Clientes',
                  icon: Icons.people,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomersPage(tenantId: tenantId, tenantName: tenantName),
                    ),
                  ),
                ),
                _buildMenuButton(
                  context,
                  label: 'Equipe',
                  icon: Icons.group,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EmployeesPage(tenantId: tenantId)),
                  ),
                ),
                _buildMenuButton(
                  context,
                  label: 'Financeiro',
                  icon: Icons.attach_money,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FinancialPage(tenantId: tenantId, tenantName: tenantName),
                    ),
                  ),
                ),
                _buildMenuButton(
                  context,
                  label: 'Onboarding / White-label',
                  icon: Icons.palette,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingPage())),
                ),
                _buildMenuButton(
                  context,
                  label: 'OCR de Placa (câmera)',
                  icon: Icons.camera_alt,
                  onPressed: () async {
                    final picker = ImagePicker();
                    final x = await picker.pickImage(source: ImageSource.camera);
                    if (x == null) return;
                    final ocr = OcrService();
                    final plate = await ocr.scanPlate(File(x.path));
                    if (plate != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Placa detectada: $plate')));
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhuma placa detectada')));
                    }
                  },
                ),
                _buildMenuButton(
                  context,
                  label: 'Upload de Foto (Storage)',
                  icon: Icons.image,
                  onPressed: () async {
                    final picker = ImagePicker();
                    final x = await picker.pickImage(source: ImageSource.gallery);
                    if (x == null) return;
                    final storage = StorageService();
                    final filename = 'upload_${DateTime.now().millisecondsSinceEpoch}.png';
                    final path = 'tenants/$tenantId/$filename';
                    final url = await storage.uploadPhoto(File(x.path), 'public', path, tenantId, refType: 'demo_upload');
                    if (url != null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Upload realizado')));
                    }
                  },
                ),
                _buildMenuButton(
                  context,
                  label: 'Logs Realtime',
                  icon: Icons.bug_report,
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RealtimeLogsPage())),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onPressed,
      ),
    );
  }
}
