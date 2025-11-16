import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'erp_service.dart';
import 'enhanced_export_service.dart';

class FinancialPage extends StatefulWidget {
  final String tenantId;
  final String tenantName;

  const FinancialPage({Key? key, required this.tenantId, required this.tenantName}) : super(key: key);

  @override
  State<FinancialPage> createState() => _FinancialPageState();
}

class _FinancialPageState extends State<FinancialPage> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  late Future<Map<String, dynamic>?> _cashFlowFuture;

  @override
  void initState() {
    super.initState();
    _loadCashFlow();
  }

  void _loadCashFlow() {
    _cashFlowFuture = ErpService.getCashFlow(widget.tenantId, _startDate, _endDate);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Financeiro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar',
            onPressed: () => _showExportOptions(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('De:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(dateFormat.format(_startDate)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Até:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(dateFormat.format(_endDate)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () async {
                    final picked = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
                    );
                    if (picked != null) {
                      setState(() {
                        _startDate = picked.start;
                        _endDate = picked.end;
                      });
                      _loadCashFlow();
                    }
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>?>(
              future: _cashFlowFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError || snapshot.data == null) {
                  return Center(child: Text('Erro: ${snapshot.error}'));
                }

                final cashFlow = snapshot.data!;
                final revenue = cashFlow['total_revenue'] ?? 0.0;
                final expenses = cashFlow['total_expenses'] ?? 0.0;
                final netFlow = cashFlow['net_cash_flow'] ?? 0.0;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCard(
                        title: 'Receita Total',
                        value: currencyFormat.format(revenue),
                        color: Colors.green,
                      ),
                      _buildCard(
                        title: 'Despesa Total',
                        value: currencyFormat.format(expenses),
                        color: Colors.red,
                      ),
                      _buildCard(
                        title: 'Fluxo Líquido',
                        value: currencyFormat.format(netFlow),
                        color: netFlow >= 0 ? Colors.green : Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ElevatedButton(
                          onPressed: () => _showAccountsView(),
                          child: const Text('Contas a Pagar/Receber'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14)),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showExportOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Exportar como PDF'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final cashFlow = await ErpService.getCashFlow(widget.tenantId, _startDate, _endDate);
                  final byCategory =
                      await ErpService.getCashFlowByCategory(widget.tenantId, _startDate, _endDate);

                  if (cashFlow != null) {
                    final path = await EnhancedExportService.exportCashFlowToPDF(
                      tenantName: widget.tenantName,
                      startDate: _startDate,
                      endDate: _endDate,
                      cashFlow: cashFlow,
                      byCategory: byCategory,
                    );

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('PDF gerado: $path')),
                      );
                    }
                    await EnhancedExportService.shareFile(path, subject: 'Relatório de Fluxo de Caixa');
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao exportar: $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Exportar como CSV'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final byCategory =
                      await ErpService.getCashFlowByCategory(widget.tenantId, _startDate, _endDate);
                  final path = await EnhancedExportService.exportFinancialToCSV(
                    title: 'Fluxo de Caixa',
                    data: byCategory,
                    columns: ['category', 'type', 'total_amount'],
                  );

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('CSV gerado: $path')),
                    );
                  }
                  await EnhancedExportService.shareFile(path, subject: 'Fluxo de Caixa');
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao exportar: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountsView() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              const TabBar(
                tabs: [
                  Tab(text: 'A Receber'),
                  Tab(text: 'A Pagar'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAccountsTab(isReceivable: true),
                    _buildAccountsTab(isReceivable: false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsTab({required bool isReceivable}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: isReceivable
          ? ErpService.fetchAccountsReceivable(widget.tenantId, status: 'pendente')
          : ErpService.fetchAccountsPayable(widget.tenantId, status: 'pendente'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        final accounts = snapshot.data ?? [];
        if (accounts.isEmpty) {
          return const Center(child: Text('Nenhuma conta'));
        }

        final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$ ');

        return ListView.builder(
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];
            final title = isReceivable
                ? (account['customers']?['name'] ?? 'N/A')
                : (account['vendor_name'] ?? 'N/A');
            final amount = account['amount'] ?? 0;
            final dueDate = account['due_date'] ?? 'N/A';

            return ListTile(
              title: Text(title),
              subtitle: Text('Venc: $dueDate'),
              trailing: Text(
                currencyFormat.format(amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        );
      },
    );
  }
}
