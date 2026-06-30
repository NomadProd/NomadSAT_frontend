import 'package:flutter/material.dart';
import 'package:flutter_web/theme/turan_theme.dart';
import 'Pages/auth_page.dart';
import 'Pages/home_page.dart';
import 'Pages/classes_page.dart';
import 'Widgets/app_route_observer.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TuranSAT',
      theme: buildTuranTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/login',
      navigatorObservers: [appRouteObserver],
      routes: {
        '/login': (context) => const AuthPage(),
        '/home': (context) => const HomePage(),
        '/classes': (context) => const ClassesPage(),
      },
    );
  }
}
