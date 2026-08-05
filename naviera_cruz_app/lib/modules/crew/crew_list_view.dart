import 'package:flutter/material.dart';
import '../../models/models.dart';
import '../../services/services.dart';
import '../../app/theme.dart';

class CrewListView extends StatefulWidget {
  final String? shipId;
  const CrewListView({super.key, this.shipId});

  @override
  State<CrewListView> createState() => _CrewListViewState();
}

class _CrewListViewState extends State<CrewListView> {
  final List<CrewMember> _crewMembers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCrew();
  }

  Future<void> _loadCrew() async {
    setState(() => _isLoading = true);
    try {
      final fleetService = FleetService();
      final crew = await fleetService.fetchCrew(widget.shipId ?? "Generico");
      setState(() {
        _crewMembers.clear();
        _crewMembers.addAll(crew);
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Tripulación", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading && _crewMembers.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _crewMembers.isEmpty
              ? Center(
                  child: Text(
                    "No hay tripulación registrada para ${widget.shipId ?? 'la flota'}.",
                    style: const TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _crewMembers.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final member = _crewMembers[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: ColorTheme.primary.withOpacity(0.15),
                            child: const Icon(
                              Icons.person,
                              color: ColorTheme.primary,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  member.name,
                                  style: TypographyTheme.headline(context).copyWith(fontSize: 15),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  member.role,
                                  style: TypographyTheme.caption(context),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ColorTheme.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              member.shipId,
                              style: const TextStyle(
                                color: ColorTheme.info,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
