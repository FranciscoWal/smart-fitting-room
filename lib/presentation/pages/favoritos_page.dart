import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritosPage extends StatefulWidget {
  const FavoritosPage({super.key});

  @override
  State<FavoritosPage> createState() => _FavoritosPageState();
}

class _FavoritosPageState extends State<FavoritosPage> {
  List<dynamic> _favoritos = [];
  List<dynamic> _recomendados = [];
  bool _loadingFavoritos = true;
  bool _loadingRecs = true;

  @override
  void initState() {
    super.initState();
    _loadFavoritos();
    _loadRecomendados();
  }

  // ============================================================
  // 🔹 Cargar favoritos de Supabase
  // ============================================================
  Future<void> _loadFavoritos() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('user_favorites')
        .select()
        .eq('user_id', user.id);

    setState(() {
      _favoritos = response;
      _loadingFavoritos = false;
    });
  }

  // ============================================================
  // 🔹 Recomendaciones desde API
  // ============================================================
  Future<void> _loadRecomendados() async {
    try {
      final url = Uri.parse(
        "https://fakestoreapi.com/products/category/men's clothing",
      );
      final res = await http.get(url);

      if (res.statusCode == 200) {
        setState(() {
          _recomendados = jsonDecode(res.body);
          _loadingRecs = false;
        });
      }
    } catch (e) {
      print("Error al cargar recomendados: $e");
    }
  }

  // ============================================================
  // 🔹 Tarjetas de productos
  // ============================================================
  Widget _buildItemCard({
    required String title,
    required String image,
    required bool favorite,
    required bool showTryOn,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C27),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Imagen
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Título
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 8),

          // Icono de favorito
          Icon(
            Icons.favorite,
            color: favorite ? Colors.redAccent : Colors.white,
            size: 22,
          ),

          // Botón PROBAR (solo en favoritos)
          if (showTryOn) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null, // sin funcionalidad aún
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white70),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text('Probar'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // 🔹 Header superior con corazón + círculo degradado
  // ============================================================
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                Icons.favorite_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              "Favoritos",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "Las prendas que más te inspiran.",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 22),
      ],
    );
  }

  // ============================================================
  // 🔹 Build principal
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      // 🎨 Fondo degradado consistente con el resto de la app
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              // Header
              _buildHeader(),

              // ======================================================
              // FAVORITOS DEL USUARIO
              // ======================================================
              const Text(
                "Tus prendas guardadas",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              _loadingFavoritos
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : _favoritos.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            "Aún no tienes artículos favoritos 💔",
                            style: TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _favoritos.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.78,
                          ),
                          itemBuilder: (_, i) {
                            final item = _favoritos[i];
                            return _buildItemCard(
                              title: item["product_title"],
                              image: item["product_image"],
                              favorite: true,
                              showTryOn: true,
                            );
                          },
                        ),

              const SizedBox(height: 35),

              // ======================================================
              // RECOMENDADOS
              // ======================================================
              const Text(
                "Quizá también te guste 👕",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              _loadingRecs
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recomendados.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (_, i) {
                        final item = _recomendados[i];
                        return _buildItemCard(
                          title: item["title"],
                          image: item["image"],
                          favorite: false,
                          showTryOn: false,
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
