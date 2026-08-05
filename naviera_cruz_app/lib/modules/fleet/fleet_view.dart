import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import '../crew/crew_list_view.dart';
import 'sbs_camera_player.dart';

class FleetView extends StatefulWidget {
  const FleetView({super.key});

  @override
  State<FleetView> createState() => _FleetViewState();
}

class _FleetViewState extends State<FleetView> {
  final List<Ship> _ships = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShips();
  }

  Future<void> _loadShips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fleetService = FleetService();
      final ships = await fleetService.fetchShips();
      setState(() {
        _ships.clear();
        _ships.addAll(ships);
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Color _statusColor(ShipStatus status) {
    switch (status) {
      case ShipStatus.active: return Colors.green;
      case ShipStatus.maintenance: return Colors.orange;
      case ShipStatus.docked: return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Dashboard de Flota",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadShips,
          ),
        ],
      ),
      body: _isLoading && _ships.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadShips,
              child: _ships.isEmpty
                  ? Center(
                      child: Text(
                        _errorMessage ?? "No hay barcos disponibles.",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _ships.length,
                      itemBuilder: (context, index) {
                        final ship = _ships[index];
                        final statusCol = _statusColor(ship.status);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      ship.name,
                                      style: TypographyTheme.headline(context),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusCol.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        ship.status.rawValue,
                                        style: TextStyle(
                                          color: statusCol,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Carga Total",
                                          style: TypographyTheme.caption(context),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "${ship.totalCargo.toInt()} tons",
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "Ubicación",
                                          style: TypographyTheme.caption(context),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Lat: ${ship.latitude.toStringAsFixed(2)}, Lon: ${ship.longitude.toStringAsFixed(2)}",
                                          style: TypographyTheme.caption(context),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Video Player or Fallback for SBS camera
                                if (ship.cameraUrl != null && ship.cameraUrl!.isNotEmpty)
                                  SBSCameraPlayer(url: ship.cameraUrl!)
                                else
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.videocam_off, color: Colors.grey),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Cámara SBS no disponible",
                                            style: TypographyTheme.caption(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(color: theme.colorScheme.primary),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CrewListView(shipId: ship.id),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.people),
                                    label: const Text("Ver Tripulación"),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
