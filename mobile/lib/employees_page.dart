import 'package:flutter/material.dart';
import 'team_service.dart';

class EmployeesPage extends StatefulWidget {
  final String tenantId;

  const EmployeesPage({Key? key, required this.tenantId}) : super(key: key);

  @override
  State<EmployeesPage> createState() => _EmployeesPageState();
}

class _EmployeesPageState extends State<EmployeesPage> {
  late Future<List<Map<String, dynamic>>> _employeesFuture;

  @override
  void initState() {
    super.initState();
    _employeesFuture = TeamService.fetchEmployees(widget.tenantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Equipe')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _employeesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final employees = snapshot.data ?? [];
          if (employees.isEmpty) {
            return const Center(child: Text('Nenhum funcionário encontrado'));
          }

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              final role = employee['role'] ?? 'funcionario';
              final roleLabel = {
                'admin': 'Administrador',
                'gerente': 'Gerente',
                'funcionario': 'Funcionário',
              }[role] ??
                  role;

              return ListTile(
                title: Text(employee['name'] ?? 'N/A'),
                subtitle: Text(roleLabel),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Visualizando: ${employee['name']}')),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
