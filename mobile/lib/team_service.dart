import 'package:supabase_flutter/supabase_flutter.dart';

class TeamService {
  static final _supabase = Supabase.instance.client;

  /// Fetch all employees (users with role in tenant)
  static Future<List<Map<String, dynamic>>> fetchEmployees(String tenantId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('tenant_id', tenantId)
          .eq('is_active', true)
          .in_('role', ['admin', 'gerente', 'funcionario']);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching employees: $e');
      return [];
    }
  }

  /// Get employee productivity summary for a period
  static Future<Map<String, dynamic>?> getEmployeeProductivity(
    String tenantId,
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase.rpc(
        'get_employee_productivity',
        params: {
          'p_tenant': tenantId,
          'p_employee_id': employeeId,
          'p_period_start': startDate.toIso8601String().split('T')[0],
          'p_period_end': endDate.toIso8601String().split('T')[0],
        },
      );
      if (response is List && response.isNotEmpty) {
        return Map<String, dynamic>.from(response[0]);
      }
      return null;
    } catch (e) {
      print('Error fetching employee productivity: $e');
      return null;
    }
  }

  /// Calculate commissions for an employee in a period
  static Future<num?> calculateCommissions(
    String tenantId,
    String employeeId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _supabase.rpc(
        'calculate_commissions',
        params: {
          'p_tenant': tenantId,
          'p_employee_id': employeeId,
          'p_period_start': startDate.toIso8601String().split('T')[0],
          'p_period_end': endDate.toIso8601String().split('T')[0],
        },
      );
      return response as num?;
    } catch (e) {
      print('Error calculating commissions: $e');
      return null;
    }
  }

  /// Fetch commission records for a tenant
  static Future<List<Map<String, dynamic>>> fetchCommissions(
    String tenantId, {
    String? employeeId,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('commissions')
          .select('*, users(name, email)')
          .eq('tenant_id', tenantId);

      if (employeeId != null) {
        query = query.eq('employee_id', employeeId);
      }
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching commissions: $e');
      return [];
    }
  }

  /// Fetch productivity logs for tracking
  static Future<List<Map<String, dynamic>>> fetchProductivityLog(
    String tenantId, {
    String? employeeId,
    DateTime? fromDate,
  }) async {
    try {
      var query = _supabase
          .from('productivity_log')
          .select('*, users(name)')
          .eq('tenant_id', tenantId);

      if (employeeId != null) {
        query = query.eq('employee_id', employeeId);
      }
      if (fromDate != null) {
        query = query.gte('created_at', fromDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false).limit(100);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching productivity log: $e');
      return [];
    }
  }

  /// Update user role (admin only)
  static Future<void> updateUserRole(
    String userId,
    String newRole,
  ) async {
    try {
      await _supabase.from('users').update({'role': newRole}).eq('id', userId);
    } catch (e) {
      print('Error updating user role: $e');
      rethrow;
    }
  }

  /// Update commission rate for an employee
  static Future<void> updateCommissionRate(
    String userId,
    num commissionRate,
  ) async {
    try {
      await _supabase
          .from('users')
          .update({'commission_rate': commissionRate}).eq('id', userId);
    } catch (e) {
      print('Error updating commission rate: $e');
      rethrow;
    }
  }
}
