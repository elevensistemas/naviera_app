import 'package:flutter/material.dart';
import '../../app/theme.dart';

class StatsView extends StatelessWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Estadísticas", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Rendimiento de Flota",
              style: TypographyTheme.title2(context),
            ),
            const SizedBox(height: 16),
            
            // KPI Grid
            Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    context,
                    title: "Viajes Activos",
                    value: "12",
                    icon: Icons.swap_calls,
                    color: ColorTheme.info,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPICard(
                    context,
                    title: "Eficiencia",
                    value: "94%",
                    icon: Icons.trending_up,
                    color: ColorTheme.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildKPICard(
                    context,
                    title: "Carga Total Mensual",
                    value: "45k t",
                    icon: Icons.widgets,
                    color: ColorTheme.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildKPICard(
                    context,
                    title: "Incidentes HSE",
                    value: "3",
                    icon: Icons.warning,
                    color: ColorTheme.danger,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Custom Histogram Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Eficiencia de Viaje Semanal",
                      style: TypographyTheme.headline(context),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 180,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildBarChartElement("Sem 1", 0.85, "85%", ColorTheme.info),
                          _buildBarChartElement("Sem 2", 0.90, "90%", ColorTheme.info),
                          _buildBarChartElement("Sem 3", 0.94, "94%", ColorTheme.success),
                          _buildBarChartElement("Sem 4", 0.88, "88%", ColorTheme.info),
                          _buildBarChartElement("Sem 5", 0.92, "92%", ColorTheme.info),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartElement(String label, double value, String efficiency, Color color) {
    return Expanded(
      child: Column(
        children: [
          const Spacer(),
          Text(
            efficiency,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 6),
          Container(
            height: 120 * value,
            width: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.85),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
