import 'package:flutter/material.dart';
import 'crm_service.dart';

class CustomersPage extends StatefulWidget {
  final String tenantId;
  final String tenantName;

  const CustomersPage({Key? key, required this.tenantId, required this.tenantName}) : super(key: key);

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  late Future<List<Map<String, dynamic>>> _customersFuture;

  @override
  void initState() {
    super.initState();
    _customersFuture = CrmService.fetchCustomers(widget.tenantId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Clientes')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _customersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }

          final customers = snapshot.data ?? [];
          if (customers.isEmpty) {
            return const Center(child: Text('Nenhum cliente encontrado'));
          }

          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return ListTile(
                title: Text(customer['name'] ?? 'N/A'),
                subtitle: Text(customer['phone'] ?? customer['email'] ?? 'N/A'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () {
                  // Navigate to customer detail page (to be implemented)
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Visualizando cliente: ${customer['name']}')),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Adicionar novo cliente (não implementado)')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
