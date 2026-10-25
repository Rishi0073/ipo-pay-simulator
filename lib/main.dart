import 'package:flutter/material.dart';

import 'controllers/ipo_controller.dart';
import 'data/ipo_repository.dart';
import 'screens/home_screen.dart';

// Thin entry point: wire the layers together, nothing else.
void main() {
  final controller = IpoController(SharedPreferencesIpoRepository());
  runApp(IpoApp(controller: controller));
}

class IpoApp extends StatelessWidget {
  const IpoApp({super.key, required this.controller});

  final IpoController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IPO Pay Simulator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: HomeScreen(controller: controller),
    );
  }
}
