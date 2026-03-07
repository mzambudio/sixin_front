import 'package:flutter/material.dart';
import 'package:sixin_front/app/root/auth_gate.dart';
import 'core/theme/theme_controller.dart';
import 'screens/screens.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Carga el theme
  await ThemeController.instance.load();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeData>(
      valueListenable: ThemeController.instance.themeNotifier,
      builder: (context, theme, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Sixin',
          theme: theme,
          initialRoute: '/',
          routes: {
            '/': (_) => const AuthGate(),
            '/forgot': (_) => const ForgotPasswordScreen(),
            '/reset': (_) => const ResetPasswordScreen(),
            '/register': (_) => const RegisterScreen(),
            '/profile': (_) => const SelfProfileScreen(),
            '/edit-profile': (_) => const EditProfileScreen(),
            '/inbox': (_) => const InboxScreen(),
            '/options': (_) => const OptionsScreen(),
          },
        );
      },
    );
  }
}
