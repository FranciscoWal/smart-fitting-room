import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_fitting_room/config/supabase_config.dart';
import 'package:smart_fitting_room/presentation/pages/homepage.dart';
import 'package:smart_fitting_room/presentation/pages/mfa_verification.dart';
import 'package:http/http.dart' as http;

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

  // 🔹 Prueba HTTP sin botón visible (sigue disponible si la llamas desde otro lado)
  Future<void> _testHttpCleartext() async {
    try {
      final resp = await http.get(Uri.parse('http://neverssl.com'));
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ HTTP inesperadamente permitido: ${resp.statusCode}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Bloqueado como se esperaba: $e'),
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
      setState(() => _errorMessage = 'Correo electrónico inválido');
      _loading = false;
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'La contraseña debe tener al menos 6 caracteres');
      _loading = false;
      return;
    }

    if (!_isLogin && !_acceptPrivacy) {
      setState(() => _errorMessage = 'Debes aceptar el aviso de privacidad');
      _loading = false;
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
          final mfaEnabled = user.userMetadata?['mfa_enabled'] == true;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  mfaEnabled ? MFAVerificationPage(email: email) : const HomePage(),
            ),
          );
        }
      } else {
        await SupabaseConfig.client.auth.signUp(
          email: email,
          password: password,
          data: {'mfa_enabled': _enableMFA},
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _enableMFA
                  ? 'Cuenta creada con MFA. Revisa tu correo'
                  : 'Cuenta creada con éxito',
            ),
          ),
        );

        setState(() => _isLogin = true);
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Error inesperado: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isRegister = !_isLogin;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌈 Fondo con gradiente
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF020617),
                  Color(0xFF0f172a),
                  Color(0xFF020617),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Imagen de fondo con opacidad suave
          Opacity(
            opacity: 0.15,
            child: Image.asset(
              'assets/images/fondo_login.jpeg',
              fit: BoxFit.cover,
            ),
          ),

          // Contenido principal
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo / Icono principal
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.7), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      gradient: const LinearGradient(
                        colors: [Color(0xFF38bdf8), Color(0xFF6366f1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(
                      Icons.checkroom_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Smart Fitting Room',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black.withOpacity(0.7),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    isRegister
                        ? 'Crea tu cuenta para empezar a probar outfits'
                        : 'Inicia sesión para continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 🧊 Tarjeta glassmorphism
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        width: size.width > 480 ? 420 : double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.6),
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              transitionBuilder: (child, anim) => FadeTransition(
                                opacity: anim,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.0, 0.15),
                                    end: Offset.zero,
                                  ).animate(anim),
                                  child: child,
                                ),
                              ),
                              child: Text(
                                isRegister ? 'Crear cuenta' : 'Iniciar sesión',
                                key: ValueKey(isRegister),
                                style: const TextStyle(
                                  fontSize: 22,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(height: 22),

                            _buildInputField(
                              controller: _emailController,
                              label: 'Correo electrónico',
                              icon: Icons.email_rounded,
                            ),

                            const SizedBox(height: 14),

                            _buildInputField(
                              controller: _passwordController,
                              label: 'Contraseña',
                              icon: Icons.lock_rounded,
                              obscure: true,
                            ),

                            const SizedBox(height: 18),

                            // ---------------- CHECKBOX PERSONALIZADOS ----------------
                            if (isRegister)
                              Theme(
                                data: Theme.of(context).copyWith(
                                  checkboxTheme: CheckboxThemeData(
                                    side: const BorderSide(color: Colors.white, width: 2),
                                    checkColor: MaterialStateProperty.all(Colors.blue),
                                    fillColor: MaterialStateProperty.resolveWith((states) {
                                      if (states.contains(MaterialState.selected)) {
                                        return Colors.white;
                                      }
                                      return Colors.transparent;
                                    }),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Checkbox(
                                          value: _acceptPrivacy,
                                          onChanged: (v) =>
                                              setState(() => _acceptPrivacy = v ?? false),
                                        ),
                                        Expanded(
                                          child: GestureDetector(
                                            onTap: _openPrivacyPDF,
                                            child: const Text(
                                              'He leído y acepto el aviso de privacidad',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: _enableMFA,
                                          onChanged: (v) =>
                                              setState(() => _enableMFA = v ?? false),
                                        ),
                                        const Expanded(
                                          child: Text(
                                            'Activar MFA (2FA)',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                            if (!isRegister)
                              Padding(
                                padding: const EdgeInsets.only(top: 6, bottom: 6),
                                child: Center(
                                  child: TextButton(
                                    onPressed: () {
                                      // Futura pantalla de recuperación
                                    },
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                    ),
                                    child: Text(
                                      '¿Olvidaste tu contraseña?',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 12,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            const SizedBox(height: 10),

                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10.0),
                                child: Text(
                                  _errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 13,
                                  ),
                                ),
                              ),

                            const SizedBox(height: 4),

                            // Botón principal
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _loading ? null : _authenticate,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black,
                                  elevation: 8,
                                ),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 200),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.3,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(Colors.black),
                                          ),
                                        )
                                      : Text(
                                          isRegister ? 'Registrarse' : 'Iniciar sesión',
                                          key: ValueKey(isRegister),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Cambiar entre login / register
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isRegister
                                      ? '¿Ya tienes cuenta?'
                                      : '¿Aún no tienes cuenta?',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 13,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isLogin = !_isLogin;
                                      _errorMessage = null;
                                    });
                                  },
                                  child: Text(
                                    isRegister
                                        ? 'Inicia sesión'
                                        : 'Crea una cuenta',
                                    style: const TextStyle(
                                      color: Color(0xFF38bdf8),
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
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
        ],
      ),
    );
  }

  // ----------------------- INPUT DECORATION REUTILIZABLE -----------------------
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 14,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.9)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: Colors.white,
            width: 1.6,
          ),
        ),
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
          'Aviso de Privacidad',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: localPath == null
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : PDFView(filePath: localPath!),
    );
  }
}
