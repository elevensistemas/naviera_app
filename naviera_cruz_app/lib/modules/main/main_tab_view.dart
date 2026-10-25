import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/home_view.dart';
import '../fleet/fleet_view.dart';
import '../chat/chat_list_view.dart';
import '../schedule/schedule_view.dart';
import '../incidents/incident_list_view.dart';
import '../stats/stats_view.dart';
import '../bulletins/bulletins_view.dart';
import '../crew/crew_home_view.dart';
import '../crew/crew_seguridad_view.dart';
import '../assistant/crew_assistant_view.dart';
import '../crew/crew_faq_search_view.dart';
import '../incidents/report_incident_view.dart';
import '../../app/drawer_widget.dart';
import '../../core/storage.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    try {
      final tabParam = int.tryParse(Uri.base.queryParameters['tab'] ?? '');
      if (tabParam != null) {
        _currentIndex = tabParam;
      }
      final viewParam = Uri.base.queryParameters['view'];
      if (viewParam != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (viewParam == 'assistant' || viewParam == 'faq') {
            if (SessionManager.shared.isTripulanteMode) {
              setState(() {
                _currentIndex = 4;
              });
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CrewAssistantView()),
              );
            }
          } else if (viewParam == 'incident') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportIncidentView()),
            );
          } else if (viewParam == 'drawer') {
            _scaffoldKey.currentState?.openEndDrawer();
          }
        });
      }
    } catch (_) {}
  }

  // Vistas para el rol de OFICINA / ADMINISTRACIÓN (6 pestañas)
  final List<Widget> _officeViews = const [
    HomeView(),
    FleetView(),
    ScheduleView(),
    IncidentListView(),
    TrainingView(),
    ChatListView(),
  ];

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionManager>(context);
    final bool isTripulante = session.isTripulanteMode;
    print(">>> MAIN_TAB_VIEW_BUILDING: isTripulante=$isTripulante, currentIndex=$_currentIndex, auth=${session.isAuthenticated} <<<");

    // Vistas para el rol de TRIPULANTE (5 módulos: Inicio, Seguridad, Boletines, Cursos, FAQ)
    final List<Widget> tripulanteViews = [
      CrewHomeView(
        onNavigateTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      const IncidentListView(),
      const BulletinsView(),
      const TrainingView(),
      CrewFaqSearchView(
        isTabModule: true,
        onNavigateTab: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    ];

    final activeViews = isTripulante ? tripulanteViews : _officeViews;

    // Asegurar que el índice actual no exceda el rango al alternar entre modos
    if (_currentIndex >= activeViews.length) {
      _currentIndex = 0;
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: session.isDarkMode ? const Color(0xFF0A0F1D) : const Color(0xFFF1F5F9),
      endDrawer: const NavieraDrawer(), // side drawer for settings and profile details
      body: activeViews[_currentIndex],
      bottomNavigationBar: NavieraBottomBar(
        isTripulante: isTripulante,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class NavieraBottomBar extends StatelessWidget {
  final bool isTripulante;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NavieraBottomBar({
    super.key,
    this.isTripulante = false,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 5 módulos exclusivos para Tripulante: Inicio, Seguridad, Boletines, Cursos, FAQ
    final tripulanteItems = const [
      _NavItemData(label: "Inicio", icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
      _NavItemData(label: "Seguridad", icon: Icons.shield_outlined, activeIcon: Icons.shield_rounded),
      _NavItemData(label: "Boletines", icon: Icons.description_outlined, activeIcon: Icons.description_rounded),
      _NavItemData(label: "Cursos", icon: Icons.school_outlined, activeIcon: Icons.school_rounded),
      _NavItemData(label: "FAQ", icon: Icons.quiz_outlined, activeIcon: Icons.quiz_rounded),
    ];

    // 6 módulos para rol corporativo / oficina
    final officeItems = const [
      _NavItemData(label: "Inicio", icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
      _NavItemData(label: "Flota", icon: Icons.anchor_outlined, activeIcon: Icons.anchor_rounded),
      _NavItemData(label: "Programa", icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_month_rounded),
      _NavItemData(label: "Seguridad", icon: Icons.shield_outlined, activeIcon: Icons.shield_rounded),
      _NavItemData(label: "Cursos", icon: Icons.school_outlined, activeIcon: Icons.school_rounded),
      _NavItemData(label: "Chat", icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded),
    ];

    final items = isTripulante ? tripulanteItems : officeItems;
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double barHeight = 70.0 + bottomPadding;

    return Container(
      height: barHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF001F3F), // Navy oscuro corporativo tal cual captura
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = currentIndex == index;
              final item = items[index];

              return Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0066CC) : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.icon,
                            color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
                            size: isSelected ? 21 : 20,
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              softWrap: false,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white.withOpacity(0.85),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 10.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
