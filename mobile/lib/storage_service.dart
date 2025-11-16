import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Faz upload de arquivo para o Storage e registra na tabela `photos`.
  /// Para buckets privados, salvamos o `path` no banco e geramos signed URLs sob demanda.
  /// Retorna o `path` salvo no storage (ex: 'tenants/{tenantId}/photos/{filename}').
  Future<String?> uploadPhoto(File file, String bucket, String path, String tenantId, {String? refType, String? refId}) async {
    try {
      final res = await _client.storage.from(bucket).upload(path, file);
      if (res.error != null) {
        print('Erro upload storage: ${res.error!.message}');
        return null;
      }

      // Em vez de armazenar uma URL pública (que não existe em bucket privado), armazenamos o caminho
      final storagePath = path;

      // registra na tabela photos; url armazena o storagePath
      final insert = await _client.from('photos').insert({
        'tenant_id': tenantId,
        'ref_type': refType,
        'ref_id': refId,
        'url': storagePath,
        'uploaded_by': _client.auth.currentUser?.id,
      }).execute();

      if (insert.error != null) {
        print('Erro ao registrar photo: ${insert.error!.message}');
      }

      return storagePath;
    } catch (e) {
      print('Exceção uploadPhoto: $e');
      return null;
    }
  }

  /// Gera um signed URL temporário para um arquivo armazenado (bucket privado)
  Future<String?> createSignedUrl(String bucket, String path, {int expiresIn = 3600}) async {
    try {
      final res = await _client.storage.from(bucket).createSignedUrl(path, expiresIn);
      if (res.error != null) {
        print('Erro ao criar signed url: ${res.error!.message}');
        return null;
      }
      return res.data as String?;
    } catch (e) {
      print('Exceção createSignedUrl: $e');
      return null;
    }
  }
}
