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
        width: 75,
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
          children: const [
            Icon(
              Icons.checkroom, // ícono tipo camisa
              color: Colors.blueAccent,
              size: 30,
            ),
            SizedBox(width: 8),
            Text(
              'Smart Fitting Room',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          // 🔹 Icono de perfil (izquierda del botón de logout)
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = 4; // Ir a perfil
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

          // 🔹 Botón de cerrar sesión
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

class _InicioContent extends StatefulWidget {
  const _InicioContent();

  @override
  State<_InicioContent> createState() => _InicioContentState();
}

class _InicioContentState extends State<_InicioContent> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<String> _carouselImages = [
    'assets/images/carrusel_1.jpeg',
    'assets/images/carrusel_2.jpeg',
    'assets/images/carrusel_3.jpeg',
    'assets/images/carrusel_4.jpeg',
    'assets/images/carrusel_5.jpeg',
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        const SizedBox(height: 15),

        // 🔹 Texto superior de bienvenida
        const Text(
          'Bienvenido usuario',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 10),

        // 🔹 Imagen principal
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity,
            height: size.height * 0.38,
            child: Image.asset(
              'assets/images/prenda_principal.jpeg',
              fit: BoxFit.cover,
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 🔹 Texto llamativo debajo de la imagen principal
        const Text(
          '¡¡LA MÁS POPULAR!!',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),

        const SizedBox(height: 25),

        // 🔹 Carrusel simple de imágenes (sin sombra ni borde redondeado)
        SizedBox(
          height: size.height * 0.3,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              PageView.builder(
                controller: _pageController,
                itemCount: _carouselImages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Image.asset(
                      _carouselImages[index],
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  );
                },
              ),

              // 🔹 Indicadores inferiores
              Positioned(
                bottom: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _carouselImages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 12 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.blueAccent
                            : Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
