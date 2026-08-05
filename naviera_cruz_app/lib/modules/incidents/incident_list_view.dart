import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';
import 'report_incident_view.dart';

class IncidentListView extends StatefulWidget {
  const IncidentListView({super.key});

  @override
  State<IncidentListView> createState() => _IncidentListViewState();
}

class _IncidentListViewState extends State<IncidentListView> {
  final List<Incident> _incidents = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final incidentService = IncidentService();
      final incidents = await incidentService.fetchIncidents();
      setState(() {
        _incidents.clear();
        _incidents.addAll(incidents);
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

  Color _statusColor(IncidentStatus status) {
    switch (status) {
      case IncidentStatus.open: return ColorTheme.danger;
      case IncidentStatus.inReview: return ColorTheme.warning;
      case IncidentStatus.resolved: return ColorTheme.success;
    }
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: FractionallySizedBox(
            heightFactor: 0.85,
            child: ReportIncidentView(
              onIncidentReported: _loadIncidents,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Incidentes de Seguridad",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle, color: ColorTheme.danger),
            onPressed: _showReportSheet,
          ),
        ],
      ),
      body: _isLoading && _incidents.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadIncidents,
              child: _incidents.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(40.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.verified_user,
                              size: 72,
                              color: ColorTheme.success,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage ?? "No hay incidentes de seguridad o HSE reportados.",
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _incidents.length,
                      itemBuilder: (context, index) {
                        final incident = _incidents[index];
                        final statusCol = _statusColor(incident.status);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12.0),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16.0),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 6,
                                      backgroundColor: statusCol,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      incident.status.rawValue,
                                      style: TextStyle(
                                        color: statusCol,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      _formatDate(incident.date),
                                      style: TypographyTheme.caption(context),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  incident.description,
                                  style: TypographyTheme.body(context),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.directions_boat, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text(
                                    "Barco ID: ${incident.shipId}",
                                    style: TypographyTheme.caption(context),
                                  ),
                                  const Spacer(),
                                  if (incident.photoURLs.isNotEmpty)
                                    const Icon(Icons.attach_file, size: 16, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
