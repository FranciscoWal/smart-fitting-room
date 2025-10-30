import 'package:flutter/material.dart';
import 'package:smart_fitting_room/config/supabase_config.dart';
import 'package:smart_fitting_room/presentation/pages/login.dart';

Future<void> main() async {
  // Asegura la inicialización antes de usar Supabase
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Supabase
  await SupabaseConfig.initialize();

  // Ejecuta la app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Fitting Room',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      home: const LoginPage(), // Página principal (Login)
    );
  }
}