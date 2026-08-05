import 'package:flutter/material.dart';
import '../../app/theme.dart';

class FinanceView extends StatelessWidget {
  const FinanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Contable", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard Contable",
              style: TypographyTheme.title2(context),
            ),
            const SizedBox(height: 16),
            
            // Executive Summary Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildFinanceRow("Facturación Mensual", "\$1.2M", Colors.green),
                    const Divider(height: 20),
                    _buildFinanceRow("Presupuesto Ejecutado", "\$850k", theme.colorScheme.onSurface),
                    const Divider(height: 20),
                    _buildFinanceRow("Desviación Operativa", "-\$45k", ColorTheme.danger),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Expenses breakdown Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Distribución de Gastos (Flota)",
                      style: TypographyTheme.headline(context),
                    ),
                    const SizedBox(height: 20),
                    _buildExpenseRow("Combustible y Lubricantes", "\$420,000", 0.50, Colors.orange),
                    const SizedBox(height: 16),
                    _buildExpenseRow("Mantenimiento Técnico", "\$250,000", 0.30, Colors.blue),
                    const SizedBox(height: 16),
                    _buildExpenseRow("Sueldos y Personal", "\$130,000", 0.15, Colors.green),
                    const SizedBox(height: 16),
                    _buildExpenseRow("Tasas Portuarias y Seguros", "\$50,000", 0.05, Colors.purple),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceRow(String title, String amount, Color amountColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(
          amount,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: amountColor),
        ),
      ],
    );
  }

  Widget _buildExpenseRow(String label, String amount, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(amount, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  height: 8,
                  width: constraints.maxWidth * percentage,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
