import 'package:flutter/material.dart';
import 'core/theme/theme_controller.dart';
import 'screens/screens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
          title: 'App',
          theme: theme,
          routes: {
            '/': (_) => const LoginScreen(),
            '/forgot': (_) => const ForgotPasswordScreen(),
            '/reset': (_) => const ResetPasswordScreen(),
            '/home': (_) => const HomeScreen(),
          },
          initialRoute: '/',
        );
      },
    );
  }
}
