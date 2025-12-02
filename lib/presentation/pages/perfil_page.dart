import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:smart_fitting_room/config/supabase_config.dart';
import 'package:smart_fitting_room/presentation/pages/login.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _fullNameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _styleCtrl = TextEditingController();
  String _gender = 'Masculino';

  bool _loading = false;
  String? _avatarUrl;
  XFile? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ============================================================
  // 🔹 Cargar perfil desde Supabase
  // ============================================================
  Future<void> _loadProfile() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    try {
      final resp = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (resp != null) {
        setState(() {
          _fullNameCtrl.text = resp['full_name'] ?? '';
          _usernameCtrl.text = resp['username'] ?? '';
          _bioCtrl.text = resp['bio'] ?? '';
          _phoneCtrl.text = resp['phone'] ?? '';
          _countryCtrl.text = resp['country'] ?? '';
          _styleCtrl.text = resp['style'] ?? '';
          _gender = resp['gender'] ?? _gender;
          _avatarUrl = resp['avatar_url'];
        });
      }
    } on PostgrestException catch (e) {
      debugPrint('Error cargando perfil: $e');
    }
  }

  // ============================================================
  // 🔹 Seleccionar imagen desde el dispositivo
  // ============================================================
  Future<void> _pickAvatar() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      final status = await Permission.photos.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Se necesita permiso para acceder a tus fotos'),
          ),
        );
        return;
      }
    }

    final picker = ImagePicker();
    final img = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 80,
    );

    if (img != null) {
      setState(() => _pickedImage = img);
    }
  }

  // ============================================================
  // 🔹 Subir imagen al Storage
  // ============================================================
  Future<String?> _uploadAvatar(SupabaseClient client, String userId) async {
    if (_pickedImage == null) return _avatarUrl;

    try {
      final bytes = await _pickedImage!.readAsBytes();
      final ext = _pickedImage!.path.split('.').last;
      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await client.storage.from('avatars').uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      final publicUrl =
          client.storage.from('avatars').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      debugPrint('Error subiendo avatar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo subir la foto de perfil: $e')),
      );
      return _avatarUrl;
    }
  }

  // ============================================================
  // 🔹 Guardar perfil
  // ============================================================
  Future<void> _saveProfile() async {
    final user = SupabaseConfig.client.auth.currentUser;
    if (user == null) return;

    setState(() => _loading = true);

    try {
      final newAvatarUrl =
          await _uploadAvatar(SupabaseConfig.client, user.id);

      final payload = {
        'id': user.id,
        'full_name': _fullNameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'style': _styleCtrl.text.trim(),
        'gender': _gender,
        'avatar_url': newAvatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await SupabaseConfig.client.from('profiles').upsert(
            payload,
            onConflict: 'id',
          );

      setState(() {
        _avatarUrl = newAvatarUrl;
        _pickedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } on PostgrestException catch (e) {
      debugPrint('Error guardando perfil: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el perfil: ${e.message}')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      await SupabaseConfig.client.auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cerrar sesión: $e')),
      );
    }
  }

  // ============================================================
  // 🔹 Avatar grande
  // ============================================================
  Widget _buildAvatar() {
    Widget avatarChild;

    if (_pickedImage != null) {
      avatarChild = ClipOval(
        child: Image.file(
          File(_pickedImage!.path),
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        ),
      );
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      avatarChild = ClipOval(
        child: Image.network(
          _avatarUrl!,
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        ),
      );
    } else {
      avatarChild = Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF243B55), Color(0xFF141E30)],
          ),
        ),
        child: const Icon(
          Icons.person,
          size: 60,
          color: Colors.white70,
        ),
      );
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        avatarChild,
        Positioned(
          bottom: 4,
          right: 4,
          child: GestureDetector(
            onTap: _pickAvatar,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: const Icon(
                Icons.camera_alt,
                size: 18,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF15151F),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: controller,
                  maxLines: maxLines,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  // ============================================================
  // 🔹 UI FINAL SIN NAVBAR + HEADER CON ICONO
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Container(
      // Fondo a juego con Home / Catálogo
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
          children: [
            // 🔹 Header interno con icono en círculo + "Tu perfil"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                      Icons.person_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Tu perfil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Actualiza tu información para mejorar tus recomendaciones.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    _buildAvatar(),
                    const SizedBox(height: 12),

                    Text(
                      _fullNameCtrl.text.isEmpty
                          ? 'Tu nombre'
                          : _fullNameCtrl.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF10101A),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        children: [
                          _buildTextField(
                            label: 'Nombre completo',
                            icon: Icons.person_outline,
                            controller: _fullNameCtrl,
                          ),
                          _buildTextField(
                            label: 'Nombre de usuario',
                            icon: Icons.alternate_email,
                            controller: _usernameCtrl,
                          ),
                          _buildTextField(
                            label: 'Bio / descripción',
                            icon: Icons.short_text,
                            controller: _bioCtrl,
                            maxLines: 2,
                          ),
                          _buildTextField(
                            label: 'Teléfono',
                            icon: Icons.phone,
                            controller: _phoneCtrl,
                          ),
                          _buildTextField(
                            label: 'País / Ciudad',
                            icon: Icons.location_on_outlined,
                            controller: _countryCtrl,
                          ),
                          _buildTextField(
                            label:
                                'Estilo favorito (casual, streetwear, formal...)',
                            icon: Icons.checkroom_outlined,
                            controller: _styleCtrl,
                          ),

                          // Género
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Género',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF15151F),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(color: Colors.white10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _gender,
                                      dropdownColor: const Color(0xFF15151F),
                                      iconEnabledColor: Colors.white70,
                                      // 👇 aquí quitamos el fontFamily para que use la fuente global
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      items: const [
                                        DropdownMenuItem(
                                          value: 'Masculino',
                                          child: Text('Masculino'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Femenino',
                                          child: Text('Femenino'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Otro',
                                          child: Text('Otro'),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        if (v != null) {
                                          setState(() => _gender = v);
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 22),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _saveProfile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 14),
                              ),
                              child: Text(
                                _loading ? 'Guardando...' : 'Guardar cambios',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    TextButton.icon(
                      onPressed: () => _logout(context),
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text(
                        'Cerrar sesión',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
