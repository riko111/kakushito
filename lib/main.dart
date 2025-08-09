import 'package:flutter/material.dart';
import 'features/home/home_screen.dart';
import 'features/settings/settings_screen.dart';

void main() {
  runApp(const KakushitoApp());
}

class KakushitoApp extends StatelessWidget {
  const KakushitoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/settings': (context) => const SettingsScreen(),
      },
      title: 'かくしーと',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.redAccent),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
