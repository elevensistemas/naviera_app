import 'package:flutter/material.dart';
import '../modules/auth/login_view.dart';
import '../modules/main/main_tab_view.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void navigateToLogin() {
  appNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginView()),
    (route) => false,
  );
}

void navigateToMain() {
  appNavigatorKey.currentState?.pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const MainTabView()),
    (route) => false,
  );
}
