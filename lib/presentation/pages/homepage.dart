import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  late final List<Widget> _pages;

  // 🌟 URL del avatar del perfil (tabla profiles.avatar_url)
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _pages = [
      _InicioContent(
        onGoToCatalog: () {
          setState(() => _selectedIndex = 2);
        },
      ),
      const ProbarPage(),
      const CatalogoPage(),
      const FavoritosPage(),
      const PerfilPage(),
    ];

    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    try {
      final resp = await SupabaseConfig.client
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted || resp == null) return;

      setState(() {
        _avatarUrl = (resp['avatar_url'] as String?) ?? '';
      });
    } catch (e) {
      debugPrint('Error cargando avatar: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await SupabaseConfig.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final bool isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color:
              isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? const Color(0xFF38bdf8) : Colors.white70,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? const Color(0xFF38bdf8) : Colors.white70,
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
      // 🧭 AppBar con estilo oscuro a juego con el login
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF020617),
                Color(0xFF020617),
                Color(0xFF0f172a),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF38bdf8), Color(0xFF6366f1)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.checkroom_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Smart Fitting Room',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          // 🔹 Ir a perfil (con avatar real si existe)
          GestureDetector(
            onTap: () async {
              // Navegamos a PerfilPage y esperamos resultado
              final changed = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => const PerfilPage(),
                ),
              );

              // Si PerfilPage hace Navigator.pop(context, true);
              // recargamos el avatar desde Supabase
              if (changed == true) {
                await _loadAvatar();
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white24,
                backgroundImage: (_avatarUrl != null &&
                        _avatarUrl!.isNotEmpty)
                    ? NetworkImage(_avatarUrl!)
                    : null,
                child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Cerrar sesión',
            onPressed: () => _logout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),

      extendBody: true,
      body: _pages[_selectedIndex],

      // 🔻 Bottom nav con glassmorphism
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          color: Colors.black.withOpacity(0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.7),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_rounded, "Inicio", 0),
              _buildNavItem(Icons.vrpano_rounded, "Probar", 1),
              _buildNavItem(Icons.shopping_bag_rounded, "Catálogo", 2),
              _buildNavItem(Icons.favorite_rounded, "Favoritos", 3),
              _buildNavItem(Icons.person_rounded, "Perfil", 4),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFF020617),
    );
  }
}

// ============================================================================
// INICIO – PANTALLA PRINCIPAL CON API DE ROPA + FAVORITOS EN SUPABASE
// ============================================================================

class _InicioContent extends StatefulWidget {
  final VoidCallback onGoToCatalog;

  const _InicioContent({required this.onGoToCatalog, Key? key}) : super(key: key);

  @override
  State<_InicioContent> createState() => _InicioContentState();
}

class _InicioContentState extends State<_InicioContent> {
  bool _loading = true;
  String? _error;
  List<dynamic> _products = [];

  // 🧠 Favoritos por usuario (ids de productos)
  final Set<int> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _loadFavoritesFromSupabase();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final resp =
          await http.get(Uri.parse('https://fakestoreapi.com/products?limit=12'));

      if (resp.statusCode == 200) {
        final List data = json.decode(resp.body);

        // 🔥 Filtrar solo ropa (men's clothing, women's clothing)
        final filtered = data.where((item) {
          final category = (item['category'] as String?)?.toLowerCase() ?? '';
          return category.contains("clothing");
        }).toList();

        // Orden por mejor rating
        filtered.sort((a, b) {
          final ra = (a['rating']['rate'] as num?) ?? 0;
          final rb = (b['rating']['rate'] as num?) ?? 0;
          return rb.compareTo(ra);
        });

        setState(() {
          _products = filtered;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Error al cargar productos (${resp.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _loading = false;
      });
    }
  }

  Future<void> _loadFavoritesFromSupabase() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    try {
      final res = await SupabaseConfig.client
          .from('user_favorites')
          .select('product_id');

      final favIds = (res as List)
          .map((row) => (row['product_id'] as num).toInt())
          .toSet();

      if (!mounted) return;
      setState(() {
        _favoriteIds
          ..clear()
          ..addAll(favIds);
      });
    } catch (e) {
      debugPrint('Error cargando favoritos: $e');
    }
  }

  Future<void> _toggleFavorite(
    int productId,
    String title,
    String imageUrl,
  ) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para guardar favoritos')),
      );
      return;
    }

    final bool isFav = _favoriteIds.contains(productId);

    // UI optimista
    setState(() {
      if (isFav) {
        _favoriteIds.remove(productId);
      } else {
        _favoriteIds.add(productId);
      }
    });

    try {
      if (!isFav) {
        // Insertar favorito
        await SupabaseConfig.client.from('user_favorites').insert({
          'user_id': user.id,
          'product_id': productId,
          'product_title': title,
          'product_image': imageUrl,
        });
      } else {
        // Eliminar favorito
        await SupabaseConfig.client
            .from('user_favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', productId);
      }
    } catch (e) {
      // Revertir UI si algo falla
      setState(() {
        if (isFav) {
          _favoriteIds.add(productId);
        } else {
          _favoriteIds.remove(productId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo actualizar favoritos: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Fondo degradado, igual vibe que login
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF020617),
                Color(0xFF020617),
                Color(0xFF0f172a),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _fetchProducts();
              await _loadFavoritesFromSupabase();
            },
            color: Colors.white,
            backgroundColor: Colors.black,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🟦 Nuevo header de sección con icono en círculo (igual estilo que en Catálogo)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF38bdf8), Color(0xFF6366f1)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.home_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Inicio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 👋 Bienvenida
                  Text(
                    'Hola, estilista',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 22,
                      shadows: [
                        Shadow(
                          blurRadius: 8,
                          color: Colors.black.withOpacity(0.8),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explora las prendas que están marcando tendencia hoy.',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 🌟 Hero card tipo glassmorphism
                  ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.12),
                              Colors.white.withOpacity(0.06),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Encuentra tu\npróximo outfit favorito',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Recomendaciones inteligentes, prendas en tendencia y un probador virtual en tu bolsillo.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  ElevatedButton.icon(
                                    onPressed: widget.onGoToCatalog,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                        vertical: 10,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      elevation: 10,
                                    ),
                                    icon: const Icon(
                                      Icons.shopping_bag_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Explorar catálogo',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Pequeño decor "maniquí" abstracto
                            Container(
                              width: 80,
                              height: 110,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF38bdf8), Color(0xFF6366f1)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.style_rounded,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 26),

                  // Título sección productos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Top prendas de hoy',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 16,
                        ),
                      ),
                      TextButton(
                        onPressed: widget.onGoToCatalog,
                        child: Text(
                          'Ver todo',
                          style: TextStyle(
                            color: const Color(0xFF38bdf8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  SizedBox(
                    height: size.height * 0.30,
                    child: _buildProductsStrip(),
                  ),

                  const SizedBox(height: 26),

                  // 💬 Tarjeta para el chatbot N8N
                  Text(
                    'Asistente inteligente',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 10),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.22),
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.10),
                              Colors.white.withOpacity(0.04),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF38bdf8), Color(0xFF6366f1)],
                                ),
                              ),
                              child: const Icon(
                                Icons.smart_toy_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Tu estilista virtual',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Haz preguntas sobre outfits, combinaciones y más, usando tu chatbot de N8N.',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ChatbotPage(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 8,
                              ),
                              child: const Text(
                                'Abrir chat',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductsStrip() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.redAccent, fontSize: 12),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron prendas.',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final items = _products.take(8).toList();

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (context, index) {
        final p = items[index];
        final int id = (p['id'] as num).toInt();
        final String title = p['title'] ?? '';
        final String imageUrl = p['image'] ?? '';
        final bool isFav = _favoriteIds.contains(id);

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withOpacity(0.08),
                border: Border.all(
                  color: Colors.white.withOpacity(0.16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Imagen de la prenda
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.black12,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_not_supported,
                              color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Spacer(),
                            GestureDetector(
                              onTap: () =>
                                  _toggleFavorite(id, title, imageUrl),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: isFav
                                      ? Colors.white.withOpacity(0.25)
                                      : Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  isFav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFav
                                      ? const Color(0xFFfb7185)
                                      : Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================================
// PÁGINA DEL CHATBOT – UI y hook para N8N
// ============================================================================

class ChatbotPage extends StatefulWidget {
  const ChatbotPage({super.key});

  @override
  State<ChatbotPage> createState() => _ChatbotPageState();
}

class _ChatbotPageState extends State<ChatbotPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];

  bool _sending = false;

  // 👉 Cambia esto por tu webhook de N8N
  final String n8nWebhookUrl =
      'https://angelocuenta2.app.n8n.cloud/webhook/68e17a9d-1d15-4e9d-8de8-02e2ee59d99a';
      
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    // Añadir mensaje del usuario a la UI
    setState(() {
      _messages.add(_ChatMessage(
        fromUser: true,
        text: text,
      ));
    });

    setState(() => _sending = true);

    try {
      // Ejemplo de payload hacia N8N
      final user = SupabaseConfig.client.auth.currentUser;
      final response = await http.post(
        Uri.parse(n8nWebhookUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'userId': user?.id,
          'message': text,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Esperamos algo como { "reply": "texto del bot" }
        final data = jsonDecode(response.body);
        final String reply = data['reply']?.toString() ??
            'Lo siento, no pude entender la respuesta del servidor.';

        setState(() {
          _messages.add(_ChatMessage(
            fromUser: false,
            text: reply,
          ));
        });
      } else {
        setState(() {
          _messages.add(_ChatMessage(
            fromUser: false,
            text:
                'Hubo un problema al contactar al asistente (código ${response.statusCode}).',
          ));
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          fromUser: false,
          text: 'Error de conexión con el chatbot: $e',
        ));
      });
    } finally {
      if (!mounted) return;
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Chat con tu estilista',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Stack(
        children: [
          // Fondo degradado/glass
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF020617),
                  Color(0xFF0f172a),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isUser = msg.fromUser;

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          constraints: BoxConstraints(
                            maxWidth:
                                MediaQuery.of(context).size.width * 0.7,
                          ),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFF38bdf8)
                                : Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 16),
                            ),
                            border: isUser
                                ? null
                                : Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                          ),
                          child: Text(
                            msg.text,
                            style: TextStyle(
                              color: isUser ? Colors.black : Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Input
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.7),
                        blurRadius: 16,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            style: const TextStyle(color: Colors.white),
                            cursorColor: Colors.white,
                            decoration: InputDecoration(
                              hintText: 'Pregúntale algo a tu estilista...',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 13,
                              ),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.08),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(
                                  color: Colors.white,
                                  width: 1.4,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: _sending ? null : _sendMessage,
                          icon: _sending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final bool fromUser;
  final String text;

  _ChatMessage({
    required this.fromUser,
    required this.text,
  });
}
