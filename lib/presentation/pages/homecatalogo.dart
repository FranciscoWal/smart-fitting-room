import 'package:flutter/material.dart';

class ClothingCatalogPage extends StatelessWidget {
  const ClothingCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> products = [
      {
        'name': 'Camisa Casual',
        'image': 'https://m.media-amazon.com/images/I/519-6fgzdQL._UY1000_.jpg',
        'price': '\$299',
      },
      {
        'name': 'Pantalón Denim',
        'image':
            'https://oggi.mx/cdn/shop/files/Jeans_Oggi_Hombre_Mezclilla_Azul_Claro_Risk_80996_Skinny_Frente_09e4139c-a2af-4554-8614-54c4977beff3.jpg?v=1739977435g',
        'price': '\$499',
      },
      {
        'name': 'Vestido Floral',
        'image':
            'https://http2.mlstatic.com/D_NQ_NP_894417-MLM84281115316_052025-O-vestido-con-estampado-floral-completo-y-detalle-de-volantes.webp',
        'price': '\$399',
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo de Ropa'), centerTitle: true),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: products.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          return Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: Image.network(
                      product['image']!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    product['name']!,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  product['price']!,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }
}
