import 'package:flutter/material.dart';
import 'package:smart_fitting_room/config/supabase_config.dart';
import 'package:smart_fitting_room/presentation/pages/login.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      // Usa el cliente de tu clase SupabaseConfig
      await SupabaseConfig.client.auth.signOut();

      // Navega de regreso al login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      // Muestra error si algo sale mal
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          '¡Bienvenido a Smart Fitting Room!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
