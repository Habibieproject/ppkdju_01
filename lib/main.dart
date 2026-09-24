import 'package:flutter/material.dart';
import 'package:ppkdju_01/day_15/services/preference_handler.dart';
import 'package:ppkdju_01/day_21/views/login_screen.dart';
// import 'package:ppkdju_01/day_21/views/maps_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PreferenceHandler.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PPKD JU 01',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF31AAA9)),
        useMaterial3: true,
      ),
      home: const LoginScreenDay21(),
    );
  }
}
