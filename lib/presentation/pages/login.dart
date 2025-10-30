import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_fitting_room/config/supabase_config.dart';
import 'package:smart_fitting_room/presentation/pages/homepage.dart';
import 'package:smart_fitting_room/presentation/pages/mfa_verification.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kDebugMode;

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  String? _errorMessage;
  bool _acceptPrivacy = false;
  bool _enableMFA = false;

  bool isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // 🔹 Abre el PDF del aviso de privacidad
  Future<void> _openPrivacyPDF() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
    );
  }

  // ✅ PRUEBA DE SEGURIDAD DE RED
  // Esta prueba intenta conectar a http://neverssl.com (sitio sin TLS)
  // ✔️ Si tu política de seguridad funciona → la conexión será bloqueada
  // ❌ Si devuelve 200 → aún permite tráfico HTTP sin cifrar
  Future<void> _testHttpCleartext() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Probando HTTP sin cifrar...')),
    );
    try {
      final resp = await http.get(
        Uri.parse('http://neverssl.com'),
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ HTTP inesperadamente permitido: ${resp.statusCode}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('✅ Bloqueado como se esperaba: $e'),
        ),
      );
    }
  }

  Future<void> _authenticate() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (!isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Correo electrónico inválido';
      });
      _loading = false;
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage =
            'La contraseña debe tener al menos 6 caracteres';
      });
      _loading = false;
      return;
    }

    if (!_isLogin && !_acceptPrivacy) {
      setState(() {
        _errorMessage =
            'Debes aceptar el aviso de privacidad';
      });
      _loading = false;
      return;
    }

    try {
      if (_isLogin) {
        final response = await SupabaseConfig.client.auth
            .signInWithPassword(
          email: email,
          password: password,
        );

        final user = response.user;

        if (user != null) {
          final mfaEnabled =
              user.userMetadata?['mfa_enabled'] == true;

          if (mfaEnabled) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    MFAVerificationPage(email: email),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => const HomePage()),
            );
          }
        }
      } else {
        await SupabaseConfig.client.auth.signUp(
          email: email,
          password: password,
          data: {'mfa_enabled': _enableMFA},
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_enableMFA
                ? 'Cuenta creada con MFA. Revisa tu correo'
                : 'Cuenta creada con éxito'),
          ),
        );

        setState(() => _isLogin = true);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() =>
          _errorMessage = 'Error inesperado: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRegister = !_isLogin;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo
          Image.asset(
            'assets/images/fondo_login.jpeg',
            fit: BoxFit.cover,
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Text(
                    'Smart Fitting Room',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 6,
                          color: Colors.black54,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color:
                          Colors.black.withValues(alpha: 0.4),
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isRegister
                              ? 'Crear cuenta'
                              : 'Iniciar sesión',
                          style: const TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 30),

                        TextField(
                          controller: _emailController,
                          decoration:
                              _inputDecoration('Correo electrónico',
                                  Icons.email),
                          style: const TextStyle(
                              color: Colors.white),
                        ),
                        const SizedBox(height: 15),

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputDecoration(
                              'Contraseña', Icons.lock),
                          style: const TextStyle(
                              color: Colors.white),
                        ),
                        const SizedBox(height: 20),

                        if (isRegister)
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptPrivacy,
                                onChanged: (v) {
                                  setState(() =>
                                      _acceptPrivacy =
                                          v ?? false);
                                },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _openPrivacyPDF,
                                  child: const Text(
                                    'He leído y acepto el aviso de privacidad',
                                    style: TextStyle(
                                        color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        if (isRegister)
                          Row(
                            children: [
                              Checkbox(
                                value: _enableMFA,
                                onChanged: (v) {
                                  setState(() =>
                                      _enableMFA =
                                          v ?? false);
                                },
                              ),
                              const Expanded(
                                child: Text(
                                  'Activar MFA (2FA)',
                                  style: TextStyle(
                                      color: Colors.white),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 15),
                        if (_errorMessage != null)
                          Text(_errorMessage!,
                              style: const TextStyle(
                                  color: Colors.redAccent)),
                        const SizedBox(height: 15),

                        ElevatedButton(
                          onPressed:
                              _loading ? null : _authenticate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          child: Text(
                            _loading
                                ? 'Cargando...'
                                : isRegister
                                    ? 'Registrarse'
                                    : 'Iniciar sesión',
                          ),
                        ),
                        const SizedBox(height: 20),

                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                            });
                          },
                          child: Text(
                            isRegister
                                ? '¿Ya tienes cuenta? Inicia sesión'
                                : 'Crear una nueva cuenta',
                            style: const TextStyle(
                                color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 15),

                        // ✅ Botón de prueba del cifrado en tránsito
                        if (kDebugMode)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                            ),
                            onPressed: _testHttpCleartext,
                            child: const Text(
                                'Probar HTTP (neverssl.com) – debe fallar'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Reutilización de estilos para inputs
  InputDecoration _inputDecoration(
      String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      prefixIcon: Icon(icon, color: Colors.white),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide:
            BorderSide(color: Colors.white, width: 2),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// 🔐 Página del PDF del Aviso de Privacidad
// -----------------------------------------------------------------------------
class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() =>
      _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState
    extends State<PrivacyPolicyPage> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    loadPDF();
  }

  Future<void> loadPDF() async {
    final bytes = await rootBundle
        .load('assets/docs/aviso_privacidad.pdf');
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/aviso_privacidad.pdf');
    await file
        .writeAsBytes(bytes.buffer.asUint8List());

    if (!mounted) return;
    setState(() => localPath = file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Aviso de Privacidad',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: localPath == null
          ? const Center(
              child: CircularProgressIndicator(
                  color: Colors.white))
          : PDFView(filePath: localPath!),
    );
  }
}