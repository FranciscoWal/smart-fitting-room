import 'package:flutter/material.dart';
import 'package:smart_fitting_room/config/supabase_config.dart';
import 'package:smart_fitting_room/presentation/pages/login.dart';
import 'probar_page.dart';
import 'catalogo_page.dart';
import 'favoritos_page.dart';
import 'perfil_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _InicioContent(),
    const ProbarPage(),
    const CatalogoPage(),
    const FavoritosPage(),
    const PerfilPage(),
  ];

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

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        width: 80,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[100] : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? Colors.blue : Colors.grey[700],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.blue : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        title: Row(
          children: [
            // Icono del logotipo (izquierda)
            const Icon(
              Icons.checkroom, // icono tipo camisa/ropa
              color: Colors.blueAccent,
              size: 30,
            ),
            const SizedBox(width: 8),
            const Text(
              'Smart Fitting Room',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // Avatar del usuario (ahora va antes del logout)
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = 4; // Ir a la página de Perfil
              });
            },
            child: const Padding(
              padding: EdgeInsets.only(right: 6),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.blueAccent,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ),
          ),
          // 🔒 Botón de cerrar sesión
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.grey),
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black12,
              offset: Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home, "Inicio", 0),
            _buildNavItem(Icons.vrpano, "Probar", 1),
            _buildNavItem(Icons.shopping_bag, "Catálogo", 2),
            _buildNavItem(Icons.favorite, "Favoritos", 3),
            _buildNavItem(Icons.person, "Perfil", 4),
          ],
        ),
      ),
    );
  }
}

class _InicioContent extends StatelessWidget {
  const _InicioContent();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        '¡Bienvenido a Smart Fitting Room!',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
      ),
    );
  }
}
