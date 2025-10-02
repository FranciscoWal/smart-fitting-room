import 'package:flutter/material.dart';
import 'package:smart_fitting_room/presentation/pages/login.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginPage(), // 👈 aquí tu page
    );
  }
}
