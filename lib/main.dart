import 'dart:async';

import 'package:flutter/material.dart';

import 'screens/auth/login_screen.dart';
import 'screens/pages/splash_screen.dart';
import 'services/auth_service.dart';
import 'widgets/app_theme.dart';

/// Lets non-widget code (session expiry) navigate.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _auth = AuthService.instance;
  bool _wasSignedIn = false;

  @override
  void initState() {
    super.initState();
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  /// When the backend rejects the token (401) while the user is inside the
  /// app, clear the navigation stack and show the sign-in screen with the
  /// reason. Normal logout navigates by itself.
  void _onAuthChanged() {
    final signedIn = _auth.isSignedIn;
    if (_wasSignedIn && !signedIn) {
      final message = _auth.takeSessionEndedMessage();
      if (message != null) {
        unawaited(appNavigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen(notice: message)),
          (route) => false,
        ));
      }
    }
    _wasSignedIn = signedIn;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'TankSpeak',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      home: const SplashScreen(),
    );
  }
}
