import 'package:supabase_flutter/supabase_flutter.dart';

class CrmService {
  static final _supabase = Supabase.instance.client;

  /// Fetch customers for the current tenant
  static Future<List<Map<String, dynamic>>> fetchCustomers(String tenantId) async {
    try {
      final response = await _supabase
          .from('customers')
          .select()
          .eq('tenant_id', tenantId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching customers: $e');
      return [];
    }
  }

  /// Fetch service history for a customer
  static Future<List<Map<String, dynamic>>> getCustomerServiceHistory(
    String tenantId,
    String customerId,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_customer_service_history',
        params: {'p_tenant': tenantId, 'p_customer_id': customerId},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching service history: $e');
      return [];
    }
  }

  /// Create a new schedule
  static Future<void> createSchedule({
    required String tenantId,
    required String customerId,
    String? vehicleId,
    required DateTime scheduledDate,
    String? scheduledTime,
    String? serviceType,
    String? notes,
  }) async {
    try {
      await _supabase.from('schedules').insert({
        'tenant_id': tenantId,
        'customer_id': customerId,
        'vehicle_id': vehicleId,
        'scheduled_date': scheduledDate.toIso8601String().split('T')[0],
        'scheduled_time': scheduledTime,
        'service_type': serviceType,
        'notes': notes,
        'created_by': _supabase.auth.currentUser?.id,
      });
    } catch (e) {
      print('Error creating schedule: $e');
      rethrow;
    }
  }

  /// Fetch schedules for a tenant
  static Future<List<Map<String, dynamic>>> fetchSchedules(
    String tenantId, {
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      var query = _supabase
          .from('schedules')
          .select('*, customers(name), vehicles(plate)')
          .eq('tenant_id', tenantId);

      if (fromDate != null) {
        query = query.gte('scheduled_date', fromDate.toIso8601String().split('T')[0]);
      }
      if (toDate != null) {
        query = query.lte('scheduled_date', toDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('scheduled_date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching schedules: $e');
      return [];
    }
  }

  /// Send WhatsApp notification (logs intent; actual API integration needed)
  static Future<String?> sendWhatsAppNotification({
    required String tenantId,
    required String customerId,
    required String phone,
    required String messageType,
    required String messageText,
  }) async {
    try {
      final response = await _supabase.rpc(
        'send_whatsapp_notification',
        params: {
          'p_tenant': tenantId,
          'p_customer_id': customerId,
          'p_phone': phone,
          'p_message_type': messageType,
          'p_message_text': messageText,
        },
      );
      return response as String?;
    } catch (e) {
      print('Error sending WhatsApp notification: $e');
      rethrow;
    }
  }

  /// Create a contact for a customer
  static Future<void> createContact({
    required String tenantId,
    required String customerId,
    required String name,
    String? email,
    String? phone,
    String? role,
    String? notes,
  }) async {
    try {
      await _supabase.from('contacts').insert({
        'tenant_id': tenantId,
        'customer_id': customerId,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'notes': notes,
      });
    } catch (e) {
      print('Error creating contact: $e');
      rethrow;
    }
  }

  /// Fetch contacts for a customer
  static Future<List<Map<String, dynamic>>> fetchContacts(String customerId) async {
    try {
      final response = await _supabase
          .from('contacts')
          .select()
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching contacts: $e');
      return [];
    }
  }
}
