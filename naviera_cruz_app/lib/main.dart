import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/storage.dart';
import 'app/theme.dart';
import 'modules/auth/login_view.dart';
import 'modules/main/main_tab_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa la sesión y preferencias locales
  await SessionManager.shared.init();
  
  runApp(
    ChangeNotifierProvider<SessionManager>.value(
      value: SessionManager.shared,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Provider.of<SessionManager>(context);
    
    return MaterialApp(
      title: 'Naviera Cruz del Sur',
      debugShowCheckedModeBanner: false,
      theme: ColorTheme.lightTheme,
      darkTheme: ColorTheme.darkTheme,
      themeMode: session.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: session.isAuthenticated ? const MainTabView() : const LoginView(),
    );
  }
}
