import 'package:supabase_flutter/supabase_flutter.dart';

class ErpService {
  static final _supabase = Supabase.instance.client;

  /// Get cash flow for a period
  static Future<Map<String, dynamic>?> getCashFlow(
    String tenantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_cash_flow',
        params: {
          'p_tenant': tenantId,
          'p_start_date': startDate.toIso8601String().split('T')[0],
          'p_end_date': endDate.toIso8601String().split('T')[0],
        },
      );
      if (response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response[0]);
      }
      return null;
    } catch (e) {
      print('Error fetching cash flow: $e');
      return null;
    }
  }

  /// Get cash flow broken down by category
  static Future<List<Map<String, dynamic>>> getCashFlowByCategory(
    String tenantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_cash_flow_by_category',
        params: {
          'p_tenant': tenantId,
          'p_start_date': startDate.toIso8601String().split('T')[0],
          'p_end_date': endDate.toIso8601String().split('T')[0],
        },
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching cash flow by category: $e');
      return [];
    }
  }

  /// Fetch accounts payable
  static Future<List<Map<String, dynamic>>> fetchAccountsPayable(
    String tenantId, {
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('accounts_payable')
          .select()
          .eq('tenant_id', tenantId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('due_date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching accounts payable: $e');
      return [];
    }
  }

  /// Fetch accounts receivable
  static Future<List<Map<String, dynamic>>> fetchAccountsReceivable(
    String tenantId, {
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('accounts_receivable')
          .select('*, customers(name), service_orders(service_type)')
          .eq('tenant_id', tenantId);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('due_date', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching accounts receivable: $e');
      return [];
    }
  }

  /// Create an account payable entry
  static Future<void> createAccountPayable({
    required String tenantId,
    required String vendorName,
    required num amount,
    DateTime? dueDate,
    String? category,
    String? invoiceNumber,
    String? notes,
  }) async {
    try {
      await _supabase.from('accounts_payable').insert({
        'tenant_id': tenantId,
        'vendor_name': vendorName,
        'amount': amount,
        'due_date': dueDate?.toIso8601String().split('T')[0],
        'category': category,
        'invoice_number': invoiceNumber,
        'notes': notes,
      });
    } catch (e) {
      print('Error creating account payable: $e');
      rethrow;
    }
  }

  /// Create an account receivable entry
  static Future<void> createAccountReceivable({
    required String tenantId,
    required String customerId,
    required num amount,
    DateTime? dueDate,
    String? paymentMethod,
    String? notes,
    String? serviceOrderId,
  }) async {
    try {
      await _supabase.from('accounts_receivable').insert({
        'tenant_id': tenantId,
        'customer_id': customerId,
        'service_order_id': serviceOrderId,
        'amount': amount,
        'due_date': dueDate?.toIso8601String().split('T')[0],
        'payment_method': paymentMethod,
        'notes': notes,
      });
    } catch (e) {
      print('Error creating account receivable: $e');
      rethrow;
    }
  }

  /// Mark account payable as paid
  static Future<void> markAccountPayableAsPaid(String id) async {
    try {
      await _supabase.from('accounts_payable').update({
        'status': 'pago',
        'paid_date': DateTime.now().toIso8601String().split('T')[0],
      }).eq('id', id);
    } catch (e) {
      print('Error marking account payable as paid: $e');
      rethrow;
    }
  }

  /// Mark account receivable as paid
  static Future<void> markAccountReceivableAsPaid(String id) async {
    try {
      await _supabase.from('accounts_receivable').update({
        'status': 'pago',
        'paid_date': DateTime.now().toIso8601String().split('T')[0],
      }).eq('id', id);
    } catch (e) {
      print('Error marking account receivable as paid: $e');
      rethrow;
    }
  }

  /// Export financial report data
  static Future<List<Map<String, dynamic>>?> exportFinancialReport(
    String tenantId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase.rpc(
        'export_financial_report',
        params: {
          'p_tenant': tenantId,
          'p_start_date': startDate.toIso8601String().split('T')[0],
          'p_end_date': endDate.toIso8601String().split('T')[0],
        },
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error exporting financial report: $e');
      return null;
    }
  }
}
