import 'package:flutter/material.dart';
import '../home/home_view.dart';
import '../fleet/fleet_view.dart';
import '../chat/chat_list_view.dart';
import '../schedule/schedule_view.dart';
import '../incidents/incident_list_view.dart';
import '../stats/stats_view.dart';
import '../../app/drawer_widget.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _currentIndex = 0;

  final List<Widget> _views = const [
    HomeView(),
    FleetView(),
    ScheduleView(),
    IncidentListView(),
    StatsView(),
    ChatListView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const NavieraDrawer(), // side drawer for settings and profile details
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: NavieraBottomBar(
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
  final int currentIndex;
  final ValueChanged<int> onTap;

  const NavieraBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = const [
      _NavItemData(label: "Inicio", icon: Icons.home_outlined, activeIcon: Icons.home_rounded),
      _NavItemData(label: "Flota", icon: Icons.anchor_outlined, activeIcon: Icons.anchor_rounded),
      _NavItemData(label: "Programa", icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_month_rounded),
      _NavItemData(label: "Seguridad", icon: Icons.shield_outlined, activeIcon: Icons.shield_rounded),
      _NavItemData(label: "Capacitaciones", icon: Icons.school_outlined, activeIcon: Icons.school_rounded),
      _NavItemData(label: "Chat", icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF001D40),
            Color(0xFF003875),
            Color(0xFF00224A),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
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
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final isSelected = currentIndex == index;
              final item = items[index];

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(index),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [
                                Color(0xFF0088FF),
                                Color(0xFF0057B8),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      border: isSelected
                          ? Border.all(
                              color: Colors.white.withOpacity(0.35),
                              width: 1,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: const Color(0xFF007FFF).withOpacity(0.6),
                                blurRadius: 12,
                                spreadRadius: 1,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.75),
                          size: isSelected ? 24 : 22,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white.withOpacity(0.75),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
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
