import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/logo_widget.dart';

class CambiarPasswordScreen extends StatefulWidget {
  const CambiarPasswordScreen({super.key});

  @override
  State<CambiarPasswordScreen> createState() => _CambiarPasswordScreenState();
}

class _CambiarPasswordScreenState extends State<CambiarPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nuevaCtrl = TextEditingController();
  final _confirmarCtrl = TextEditingController();
  bool _verNueva = false;
  bool _verConfirmar = false;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nuevaCtrl.dispose();
    _confirmarCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _guardando = true;
      _error = null;
    });

    final auth = context.read<AuthProvider>();

    try {
      final result = await ApiService.actualizarSocio(auth.dni, {
        'password': _nuevaCtrl.text.trim(),
      });

      if (!mounted) return;

      if (result['success'] == true) {
        // Actualizar contraseña guardada
        await auth.login(auth.dni, _nuevaCtrl.text.trim());
        if (mounted) context.go('/home');
      } else {
        setState(() {
          _error = result['message'] ?? 'Error al cambiar la contraseña';
          _guardando = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 60),

                const LogoWidget().animate().fadeIn(duration: 500.ms),

                const SizedBox(height: 40),

                Text(
                  'Cambia tu contraseña',
                  style: Theme.of(context).textTheme.displayMedium,
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 8),

                Text(
                  'Por seguridad, establece una contraseña personal',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 40),

                // Nueva contraseña
                TextFormField(
                  controller: _nuevaCtrl,
                  obscureText: !_verNueva,
                  decoration: InputDecoration(
                    hintText: 'Nueva contraseña',
                    prefixIcon: const Icon(
                      Icons.lock_outline_rounded,
                      color: AppTheme.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _verNueva
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppTheme.textLight,
                      ),
                      onPressed: () => setState(() => _verNueva = !_verNueva),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return 'Introduce una contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    final auth = context.read<AuthProvider>();
                    if (v == auth.dni)
                      return 'La contraseña no puede ser tu DNI';
                    return null;
                  },
                ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 12),

                // Confirmar contraseña
                TextFormField(
                  controller: _confirmarCtrl,
                  obscureText: !_verConfirmar,
                  decoration: InputDecoration(
                    hintText: 'Confirmar contraseña',
                    prefixIcon: const Icon(
                      Icons.lock_rounded,
                      color: AppTheme.primary,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _verConfirmar
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppTheme.textLight,
                      ),
                      onPressed: () =>
                          setState(() => _verConfirmar = !_verConfirmar),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                    if (v != _nuevaCtrl.text)
                      return 'Las contraseñas no coinciden';
                    return null;
                  },
                ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.2, end: 0),

                const SizedBox(height: 16),

                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppTheme.danger,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppTheme.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().shake(),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _guardando ? null : _guardar,
                  child: _guardando
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Guardar contraseña'),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 40),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: () async {
                    final auth = context.read<AuthProvider>();
                    await auth.logout();
                    if (mounted) context.go('/login');
                  },
                  child: const Text(
                    'Más tarde',
                    style: TextStyle(color: AppTheme.textMedium),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
