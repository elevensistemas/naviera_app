import 'package:flutter/material.dart';
import '../home/home_view.dart';
import '../fleet/fleet_view.dart';
import '../chat/chat_list_view.dart';
import '../schedule/schedule_view.dart';
import '../profile/profile_view.dart';

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
    ChatListView(),
    ScheduleView(),
    ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _views,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_boat),
            label: "Flota",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: "Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_month),
            label: "Agenda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: "Perfil",
          ),
        ],
      ),
    );
  }
}
