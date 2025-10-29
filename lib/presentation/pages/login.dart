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

// -----------------------------------------------------------------------------
// Página principal de Login / Registro
// -----------------------------------------------------------------------------
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
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // 🔹 Abre la página del PDF dentro de la app
  Future<void> _openPrivacyPDF() async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
    );
  }

  // 🔹 Prueba de conexión HTTP (debe fallar si tu config está bien)
  Future<void> _testHttpCleartext() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Probando HTTP sin cifrar...')),
    );
    try {
      final resp = await http.get(Uri.parse('http://example.com')); // <- SIN https
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ HTTP inesperadamente permitido: ${resp.statusCode}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Bloqueado como se esperaba: $e')),
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
        _loading = false;
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'La contraseña debe tener al menos 6 caracteres';
        _loading = false;
      });
      return;
    }

    if (!_isLogin && !_acceptPrivacy) {
      setState(() {
        _errorMessage = 'Debes aceptar el aviso de privacidad para continuar';
        _loading = false;
      });
      return;
    }

    try {
      if (_isLogin) {
        final response = await SupabaseConfig.client.auth.signInWithPassword(
          email: email,
          password: password,
        );

        final user = response.user;
        if (user != null) {
          // 🔐 Verificar si MFA está habilitado
          final mfaEnabled = user.userMetadata?['mfa_enabled'] == true;
          if (mfaEnabled) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MFAVerificationPage(email: email),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          }
        if (!mounted) return;

        if (response.user != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
          );
        } else {
          setState(() {
            _errorMessage = 'Usuario o contraseña incorrectos';
          });
        }
      } else {
        // Registro con opción de MFA
        final response = await SupabaseConfig.client.auth.signUp(
          email: email,
          password: password,
          data: {'mfa_enabled': _enableMFA},
        );

        if (!mounted) return;

        if (response.user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _enableMFA
                    ? 'Cuenta creada con MFA activado. Revisa tu correo.'
                    : 'Cuenta creada con éxito. Revisa tu correo.',
              ),
            ),
          );
          setState(() => _isLogin = true);
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Error: $e');
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
          Image.asset('assets/images/fondo_login.jpeg', fit: BoxFit.cover),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
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

                  // Caja principal
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      border: Border.all(color: Colors.white, width: 2),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          isRegister ? 'Crear cuenta' : 'Iniciar sesión',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Correo
                        TextField(
                          controller: _emailController,
                          decoration: _inputDecoration(
                            'Correo electrónico',
                            Icons.email,
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 15),

                        // Contraseña
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputDecoration(
                            'Contraseña',
                            Icons.lock,
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 20),

                        // Aviso de privacidad
                        if (isRegister)
                          Row(
                            children: [
                              Checkbox(
                                value: _acceptPrivacy,
                                onChanged: (value) {
                                  setState(() => _acceptPrivacy = value!);
                                },
                                activeColor: Colors.white,
                                checkColor: Colors.black,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _openPrivacyPDF,
                                  child: const Text(
                                    'He leído y acepto el aviso de privacidad',
                                    style: TextStyle(
                                      color: Colors.white,
                                      decoration: TextDecoration.none,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                        // Activar MFA
                        if (isRegister)
                          Row(
                            children: [
                              Checkbox(
                                value: _enableMFA,
                                onChanged: (value) {
                                  setState(() => _enableMFA = value!);
                                },
                                activeColor: Colors.white,
                                checkColor: Colors.black,
                              ),
                              const Expanded(
                                child: Text(
                                  'Activar verificación en dos pasos (MFA)',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),

                        const SizedBox(height: 20),
                        if (_errorMessage != null)
                          Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 14,
                            ),
                          ),

                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _loading ? null : _authenticate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 70,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            _loading
                                ? 'Cargando...'
                                : isRegister
                                ? 'Registrarse'
                                : 'Iniciar sesión',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),

                        const SizedBox(height: 15),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _errorMessage = null;
                              _acceptPrivacy = false;
                            });
                          },
                          child: Text(
                            isRegister
                                ? '¿Ya tienes cuenta? Inicia sesión'
                                : '¿No tienes cuenta? Crear una',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        // 🔹 Botón de prueba HTTP (SOLO en debug)
                        if (kDebugMode) ...[
                          const SizedBox(height: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,   // Fondo blanco
                              foregroundColor: Colors.black,   // Texto negro
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                                side: const BorderSide(color: Colors.black, width: 1.5),
                              ),
                            ),
                            onPressed: _testHttpCleartext,
                            child: const Text(
                              'Probar HTTP (debe fallar)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      prefixIcon: Icon(icon, color: Colors.white),
    );
  }
}

// -----------------------------------------------------------------------------
// Página del PDF del Aviso de Privacidad
// -----------------------------------------------------------------------------
class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  String? localPath;

  @override
  void initState() {
    super.initState();
    loadPDF();
  }

  Future<void> loadPDF() async {
    final bytes = await rootBundle.load('assets/docs/aviso_privacidad.pdf');
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/aviso_privacidad.pdf');
    await file.writeAsBytes(bytes.buffer.asUint8List());
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
          "Aviso de Privacidad",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: localPath == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : PDFView(filePath: localPath!),
    );
  }
}
