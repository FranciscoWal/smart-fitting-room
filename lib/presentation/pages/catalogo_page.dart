import 'package:flutter/material.dart';

class CatalogoPage extends StatelessWidget {
  const CatalogoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Catálogo de prendas disponibles',
        style: TextStyle(fontSize: 18),
      ),
    );
  }
}
