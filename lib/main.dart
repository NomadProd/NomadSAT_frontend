import 'package:flutter/material.dart';
import 'package:flutter_web/Services/api_json.dart';
import 'package:flutter_web/theme/turan_theme.dart';
import 'Pages/auth_page.dart';
import 'Pages/home_page.dart';
import 'Pages/classes_page.dart';
import 'Widgets/app_route_observer.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  onUnauthorized = () {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = appNavigatorKey.currentState;
      if (nav == null) return;
      final routeName = ModalRoute.of(nav.context)?.settings.name;
      if (routeName == '/login') return;
      nav.pushNamedAndRemoveUntil('/login', (route) => false);
    });
  };
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
      navigatorKey: appNavigatorKey,
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
