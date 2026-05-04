import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../widgets/app_scaffold.dart';
import '../widgets/back_fab.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final supabase = Supabase.instance.client;

  final nombreCtrl = TextEditingController();
  final apellidosCtrl = TextEditingController();
  final telefonoCtrl = TextEditingController();
  final direccionCtrl = TextEditingController();

  final passActualCtrl = TextEditingController();
  final passNuevaCtrl = TextEditingController();
  final passConfirmCtrl = TextEditingController();

  bool _loading = true;
  bool _savingProfile = false;
  bool _savingPassword = false;
  bool _obscureActual = true;
  bool _obscureNueva = true;
  bool _obscureConfirm = true;

  String? _profileError;
  String? _profileSuccess;
  String? _passwordError;
  String? _passwordSuccess;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    // Precargar desde metadata para no mostrar formulario vacio
    // cuando la fila en profiles aun no existe.
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    nombreCtrl.text = (metadata['nombre'] ?? metadata['name'] ?? '')
        .toString()
        .trim();
    apellidosCtrl.text = (metadata['apellidos'] ?? '').toString().trim();
    telefonoCtrl.text = (metadata['telefono'] ?? user.phone ?? '')
        .toString()
        .trim();
    direccionCtrl.text = (metadata['direccion'] ?? '').toString().trim();

    try {
      final data = await supabase
          .from('profiles')
          .select('nombre, apellidos, telefono, direccion')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        final nombre = (data['nombre'] ?? '').toString().trim();
        final apellidos = (data['apellidos'] ?? '').toString().trim();
        final telefono = (data['telefono'] ?? '').toString().trim();
        final direccion = (data['direccion'] ?? '').toString().trim();

        if (nombre.isNotEmpty) nombreCtrl.text = nombre;
        if (apellidos.isNotEmpty) apellidosCtrl.text = apellidos;
        if (telefono.isNotEmpty) telefonoCtrl.text = telefono;
        if (direccion.isNotEmpty) direccionCtrl.text = direccion;
      }
    } catch (_) {
      // Si falla la lectura de profile, mantenemos valores de metadata.
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() {
      _savingProfile = true;
      _profileError = null;
      _profileSuccess = null;
    });

    try {
      final payload = {
        'nombre': nombreCtrl.text.trim(),
        'apellidos': apellidosCtrl.text.trim(),
        'telefono': telefonoCtrl.text.trim(),
        'direccion': direccionCtrl.text.trim(),
      };

      final updated = await supabase
          .from('profiles')
          .update(payload)
          .eq('id', user.id)
          .select('id')
          .maybeSingle();

      // Si no existe fila del perfil, intentamos crearla.
      if (updated == null) {
        final email = (user.email ?? '').toString().trim().toLowerCase();
        await supabase.from('profiles').insert({
          'id': user.id,
          'email': email,
          ...payload,
        });
      }

      if (!mounted) return;
      setState(() {
        _profileSuccess = 'Datos actualizados correctamente.';
        _savingProfile = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profileError =
            'No se pudo guardar. Si es un usuario nuevo, revisa la politica INSERT de profiles en Supabase.\nDetalle: $e';
        _savingProfile = false;
      });
    }
  }

  Future<void> _savePassword() async {
    final actual = passActualCtrl.text;
    final nueva = passNuevaCtrl.text;
    final confirm = passConfirmCtrl.text;

    setState(() {
      _passwordError = null;
      _passwordSuccess = null;
    });

    if (actual.isEmpty || nueva.isEmpty || confirm.isEmpty) {
      setState(() => _passwordError = 'Rellena todos los campos.');
      return;
    }
    if (nueva != confirm) {
      setState(() => _passwordError = 'Las contraseñas nuevas no coinciden.');
      return;
    }
    if (nueva.length < 6) {
      setState(
        () => _passwordError =
            'La nueva contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }

    setState(() => _savingPassword = true);

    try {
      final email = (supabase.auth.currentUser?.email ?? '').trim();
      if (email.isEmpty) {
        setState(() {
          _passwordError = 'No se pudo validar el usuario actual.';
          _savingPassword = false;
        });
        return;
      }

      try {
        await supabase.auth.signInWithPassword(email: email, password: actual);
      } on AuthException {
        setState(() {
          _passwordError = 'La contraseña actual no es correcta.';
          _savingPassword = false;
        });
        return;
      }

      await supabase.auth.updateUser(UserAttributes(password: nueva));

      if (!mounted) return;
      passActualCtrl.clear();
      passNuevaCtrl.clear();
      passConfirmCtrl.clear();
      setState(() {
        _passwordSuccess = 'Contraseña cambiada correctamente.';
        _savingPassword = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _passwordError = 'Error al cambiar contraseña: $e';
        _savingPassword = false;
      });
    }
  }

  @override
  void dispose() {
    nombreCtrl.dispose();
    apellidosCtrl.dispose();
    telefonoCtrl.dispose();
    direccionCtrl.dispose();
    passActualCtrl.dispose();
    passNuevaCtrl.dispose();
    passConfirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ajustes de perfil',
      isAdmin: false,
      floatingActionButton: const BackFAB(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // — DATOS PERSONALES —
                      const Text(
                        'Datos personales',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: nombreCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nombre',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: apellidosCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Apellidos',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: telefonoCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: direccionCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Dirección',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_profileError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            _profileError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (_profileSuccess != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            _profileSuccess!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _savingProfile ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _savingProfile
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Guardar datos'),
                        ),
                      ),

                      const SizedBox(height: 36),
                      const Divider(),
                      const SizedBox(height: 20),

                      // — CAMBIAR CONTRASEÑA —
                      const Text(
                        'Cambiar contraseña',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: passActualCtrl,
                        obscureText: _obscureActual,
                        decoration: InputDecoration(
                          labelText: 'Contraseña actual',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureActual
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscureActual = !_obscureActual,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: passNuevaCtrl,
                        obscureText: _obscureNueva,
                        decoration: InputDecoration(
                          labelText: 'Nueva contraseña',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureNueva
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () =>
                                setState(() => _obscureNueva = !_obscureNueva),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: passConfirmCtrl,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          labelText: 'Confirmar nueva contraseña',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirm
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscureConfirm = !_obscureConfirm,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (_passwordError != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            _passwordError!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (_passwordSuccess != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            _passwordSuccess!,
                            style: const TextStyle(color: Colors.green),
                          ),
                        ),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _savingPassword ? null : _savePassword,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: _savingPassword
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Cambiar contraseña'),
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
