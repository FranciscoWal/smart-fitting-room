import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_fitting_room/config/supabase_config.dart';
import 'package:smart_fitting_room/presentation/pages/homepage.dart';

class MFAVerificationPage extends StatefulWidget {
  final String email;

  const MFAVerificationPage({super.key, required this.email});

  @override
  State<MFAVerificationPage> createState() => _MFAVerificationPageState();
}

class _MFAVerificationPageState extends State<MFAVerificationPage> {
  bool _loading = false;
  String? _error;
  bool _verified = false;

  // Comprueba si el usuario ya confirmó su correo
  Future<void> _checkEmailVerification() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      
      await SupabaseConfig.client.auth.refreshSession();

      final user = SupabaseConfig.client.auth.currentUser;

      if (user == null) {
        setState(
          () => _error = 'No hay sesión activa. Inicia sesión de nuevo.',
        );
      } else if (user.emailConfirmedAt != null) {
        
        setState(() => _verified = true);

       
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      } else {
       
        setState(() => _error = 'Aún no has confirmado tu correo electrónico.');
      }
    } catch (e) {
      setState(() => _error = 'Error al verificar: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Reenvía el enlace de confirmación
  Future<void> _resendConfirmationEmail() async {
    try {
      setState(() => _loading = true);

      //  Enviamos nuevamente el correo de verificación
      await SupabaseConfig.client.auth.signInWithOtp(
        email: widget.email,
        emailRedirectTo: 'https://tu-dominio-o-app-link.com', 
      );

      setState(() => _loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo de verificación reenviado correctamente.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al reenviar correo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read, color: Colors.white, size: 80),
              const SizedBox(height: 20),
              const Text(
                'Verificación de cuenta',
                style: TextStyle(color: Colors.white, fontSize: 22),
              ),
              const SizedBox(height: 10),
              const Text(
                'Se ha enviado un correo de confirmación.\n'
                'Por favor verifica tu email antes de continuar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 30),

              if (_error != null)
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),

              const SizedBox(height: 25),

              // Botón para verificar estado de correo
              ElevatedButton(
                onPressed: _loading ? null : _checkEmailVerification,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 12,
                  ),
                ),
                child: Text(
                  _loading ? 'Verificando...' : 'Ya confirmé mi correo',
                  style: const TextStyle(fontSize: 16),
                ),
              ),

              const SizedBox(height: 15),

              //  Opción para reenviar correo
              TextButton(
                onPressed: _resendConfirmationEmail,
                child: const Text(
                  'Reenviar correo de confirmación',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
