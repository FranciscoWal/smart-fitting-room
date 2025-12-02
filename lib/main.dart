import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_fitting_room/config/supabase_config.dart';
import 'package:smart_fitting_room/presentation/pages/login.dart';

Future<void> main() async {
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

      // 🎨 Tema global con CONCERT ONE
      theme: ThemeData(
        brightness: Brightness.dark,   // tu app usa fondo oscuro
        textTheme: GoogleFonts.concertOneTextTheme(),
        primaryTextTheme: GoogleFonts.concertOneTextTheme(),
        scaffoldBackgroundColor: Colors.black,
        useMaterial3: false,
      ),

      home: const LoginPage(),
    );
  }
}
