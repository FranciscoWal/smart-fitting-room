import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:smart_fitting_room/config/supabase_config.dart';

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  late Future<List<Prenda>> _futurePrendas;

  // 🔖 Favoritos (IDs) sincronizados con Supabase
  final Set<int> _favoriteIds = {};

  @override
  void initState() {
    super.initState();
    _futurePrendas = _fetchPrendas();
    _loadFavoritesFromSupabase();
  }

  // ============================================================
  // 🔹 Traer productos del API (SOLO ROPA)
  // ============================================================
  Future<List<Prenda>> _fetchPrendas() async {
    // Usamos todos los productos, pero luego filtramos solo ropa
    final url = Uri.parse('https://fakestoreapi.com/products');
    final resp = await http.get(url);

    if (resp.statusCode != 200) {
      throw Exception('Error al cargar el catálogo (código ${resp.statusCode})');
    }

    final List<dynamic> data = jsonDecode(resp.body);

    // 🔥 Filtrar SOLO ropa: categorías "men's clothing" y "women's clothing"
    final ropa = data.where((item) {
      final cat = (item['category'] ?? '').toString().toLowerCase();
      return cat.contains('clothing');
    }).toList();

    return ropa
        .map((json) => Prenda.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // ============================================================
  // 🔹 Cargar favoritos desde Supabase
  // ============================================================
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
      debugPrint('Error cargando favoritos en catálogo: $e');
    }
  }

  // ============================================================
  // 🔹 Alternar favorito (con Supabase)
  // ============================================================
  Future<void> _toggleFavorite(Prenda prenda) async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para guardar favoritos'),
        ),
      );
      return;
    }

    final int productId = prenda.id;
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
        // 👉 Insertar en tabla user_favorites
        await SupabaseConfig.client.from('user_favorites').insert({
          'user_id': user.id,
          'product_id': productId,
          'product_title': prenda.nombre,
          'product_image': prenda.imageUrl,
        });
      } else {
        // 👉 Eliminar de la tabla
        await SupabaseConfig.client
            .from('user_favorites')
            .delete()
            .eq('user_id', user.id)
            .eq('product_id', productId);
      }
    } catch (e) {
      // Revertir UI si falla
      setState(() {
        if (isFav) {
          _favoriteIds.add(productId);
        } else {
          _favoriteIds.remove(productId);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo actualizar favoritos: $e'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent, // el fondo real es el gradient interno
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // 🎨 Fondo estilo Home/_InicioContent
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
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🧑‍💼 Header tipo sección (sin AppBar extra y SIN botón recargar)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
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
                        Icons.shopping_bag_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Catálogo de ropa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Explora solo prendas de vestir disponibles en el probador inteligente.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 📜 Grid / lista de catálogo
              Expanded(
                child: FutureBuilder<List<Prenda>>(
                  future: _futurePrendas,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            'Ocurrió un error al cargar el catálogo.\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }

                    final prendas = snapshot.data ?? [];

                    if (prendas.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay prendas disponibles por ahora.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    // 🔹 Catálogo tipo grid (2–3 columnas según ancho)
                    final crossAxisCount = size.width > 700 ? 3 : 2;

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: prendas.length,
                      itemBuilder: (context, index) {
                        final prenda = prendas[index];
                        final esFavorito = _favoriteIds.contains(prenda.id);

                        return _CatalogCard(
                          prenda: prenda,
                          esFavorito: esFavorito,
                          onToggleFavorite: () => _toggleFavorite(prenda),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 🔹 Card visual del catálogo (match con el estilo del Home)
// ============================================================
class _CatalogCard extends StatelessWidget {
  final Prenda prenda;
  final bool esFavorito;
  final VoidCallback onToggleFavorite;

  const _CatalogCard({
    required this.prenda,
    required this.esFavorito,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(
            color: Colors.white.withOpacity(0.20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼 Imagen
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(22),
                  topRight: Radius.circular(22),
                ),
                child: Container(
                  color: const Color(0xFF020617),
                  child: prenda.imageUrl != null
                      ? Image.network(
                          prenda.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.white54,
                              size: 30,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            Icons.checkroom,
                            color: Colors.white70,
                            size: 32,
                          ),
                        ),
                ),
              ),
            ),

            // 📄 Info
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prenda.nombre,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    prenda.descripcion,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '\$${prenda.precio.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF38bdf8),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      // ❤️ Favorito
                      GestureDetector(
                        onTap: onToggleFavorite,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: esFavorito
                                ? Colors.white.withOpacity(0.22)
                                : Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            esFavorito
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 18,
                            color: esFavorito
                                ? const Color(0xFFfb7185)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 🔘 Botón "Probar" (placeholder para integrarlo luego con ProbarPage)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        // TODO: Navegar a ProbarPage pasando esta prenda
                        // Navigator.push(...);
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.6),
                          width: 0.8,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Probar',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modelo sencillo para una prenda,
/// mapeando la API de https://fakestoreapi.com/products
class Prenda {
  final int id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String? imageUrl;

  Prenda({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imageUrl,
  });

  factory Prenda.fromJson(Map<String, dynamic> json) {
    return Prenda(
      id: (json['id'] as num).toInt(),
      nombre: (json['title'] ?? 'Prenda sin nombre').toString(),
      descripcion: (json['description'] ?? '').toString(),
      precio: (json['price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image']?.toString(),
    );
  }
}
