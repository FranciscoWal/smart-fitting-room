import 'package:flutter/material.dart';
import 'package:smart_fitting_room/config/supabase_config.dart';
import 'package:smart_fitting_room/presentation/pages/login.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  Future<void> _logout(BuildContext context) async {
    try {
      await SupabaseConfig.client.auth.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cerrar sesión: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/avatar_placeholder.png'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Usuario',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => _logout(context),
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
