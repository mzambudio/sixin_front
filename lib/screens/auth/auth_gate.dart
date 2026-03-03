import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:sixin_front/core/settings/settings_controller.dart';
import '../auth/login_screen.dart';
import '../home/home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? _sub;

  @override
  void initState() {
    super.initState();

    _sub = FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (user == null) {
        SettingsController.instance.stop();
      } else {
        await SettingsController.instance.start();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sub = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen(isGuest: false);
        }

        return const LoginScreen();
      },
    );
  }
}
