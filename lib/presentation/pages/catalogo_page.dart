import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CatalogoPage extends StatefulWidget {
  const CatalogoPage({super.key});

  @override
  State<CatalogoPage> createState() => _CatalogoPageState();
}

class _CatalogoPageState extends State<CatalogoPage> {
  late Future<List<Prenda>> _futurePrendas;
  final Set<int> _favoritos = {};

  @override
  void initState() {
    super.initState();
    _futurePrendas = _fetchPrendas();
  }

  Future<List<Prenda>> _fetchPrendas() async {
    // 🔁 Cambia esta URL por tu propia API si lo deseas
    final url = Uri.parse('https://fakestoreapi.com/products');
    final resp = await http.get(url);

    if (resp.statusCode != 200) {
      throw Exception('Error al cargar el catálogo');
    }

    final List<dynamic> data = jsonDecode(resp.body);

    // Filtra solo algunas categorías de ropa (opcional)
    final ropa = data.where((item) {
      final cat = (item['category'] ?? '').toString().toLowerCase();
      return cat.contains('clothing') || cat.contains('men') || cat.contains('women');
    }).toList();

    return ropa
        .map((json) => Prenda.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  void _toggleFavorito(int id) {
    setState(() {
      if (_favoritos.contains(id)) {
        _favoritos.remove(id);
      } else {
        _favoritos.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // 🎨 Fondo estilo “ProbarPage”: llamativo, tipo app de moda
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0f172a),
              Color(0xFF1d4ed8),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // 🧑‍💼 Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.checkroom, color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Catálogo de prendas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _futurePrendas = _fetchPrendas();
                        });
                      },
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      tooltip: 'Actualizar catálogo',
                    ),
                  ],
                ),
              ),

              // 🧵 Subtítulo
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Explora las prendas disponibles para probar en el probador inteligente.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),

              const SizedBox(height: 12),

              // 📜 Lista de prendas (API)
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
                            style: const TextStyle(color: Colors.white),
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

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: prendas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final prenda = prendas[index];
                        final esFavorito = _favoritos.contains(prenda.id);

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.20),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // 🖼 Imagen
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  bottomLeft: Radius.circular(20),
                                ),
                                child: Container(
                                  width: size.width * 0.28,
                                  height: size.width * 0.28,
                                  color: const Color(0xFF1e293b),
                                  child: prenda.imageUrl != null
                                      ? Image.network(
                                          prenda.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Icon(
                                            Icons.image_not_supported_outlined,
                                            color: Colors.white60,
                                            size: 32,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.checkroom,
                                          color: Colors.white70,
                                          size: 32,
                                        ),
                                ),
                              ),

                              // 📄 Info + botones
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        prenda.nombre,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0f172a),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        prenda.descripcion,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '\$${prenda.precio.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1d4ed8),
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              // 🔘 Botón tipo “Probar” / acción
                                              ElevatedButton(
                                                onPressed: () {
                                                  // Aquí luego puedes navegar a ProbarPage
                                                  // y pasarle la prenda seleccionada.
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.blueAccent,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 14,
                                                    vertical: 8,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                  ),
                                                  elevation: 0,
                                                ),
                                                child: const Text(
                                                  'Probar',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // ❤️ Botón favorito (estático/local)
                                              IconButton(
                                                onPressed: () {
                                                  _toggleFavorito(prenda.id);
                                                },
                                                icon: Icon(
                                                  esFavorito
                                                      ? Icons.favorite
                                                      : Icons
                                                          .favorite_border_rounded,
                                                  color: esFavorito
                                                      ? Colors.pinkAccent
                                                      : Colors.grey,
                                                  size: 22,
                                                ),
                                                tooltip: 'Favorito',
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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
