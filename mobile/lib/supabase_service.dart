import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  /// Busca um tenant default para demo. Em produção, o tenant deve ser
  /// identificado por subdomínio, token ou por usuário autenticado.
  Future<Map<String, dynamic>?> fetchDefaultTenant() async {
    final res = await client
        .from('tenants')
        .select('id, name, nome_fantasia, logo_url, primary_color, secondary_color')
        .limit(1)
        .execute();

    if (res.error != null) {
      // Em dev, apenas retorna null e loga o erro
      print('Erro ao buscar tenant: ${res.error!.message}');
      return null;
    }

    final data = res.data as List<dynamic>?;
    if (data == null || data.isEmpty) return null;
    return Map<String, dynamic>.from(data.first as Map);
  }
}
