import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF52B788),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF52B788),
              Color(0xFF2D6A4F),
              Color(0xFF0D2B1E),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),

                        const LogoWidget().animate().fadeIn(duration: 500.ms),

                        const SizedBox(height: 40),

                        Text(
                          'Cambia tu contraseña',
                          style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 8),

                        Text(
                          'Por seguridad, establece una contraseña personal',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 40),

                        TextFormField(
                          controller: _nuevaCtrl,
                          obscureText: !_verNueva,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Nueva contraseña',
                            hintStyle: const TextStyle(color: Colors.white54),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: Colors.white70),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _verNueva ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: Colors.white54,
                              ),
                              onPressed: () => setState(() => _verNueva = !_verNueva),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.white, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.white, width: 2),
                            ),
                            errorStyle: const TextStyle(color: Colors.white),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Introduce una contraseña';
                            if (v.length < 6) return 'Mínimo 6 caracteres';
                            final auth = context.read<AuthProvider>();
                            if (v == auth.dni) return 'La contraseña no puede ser tu DNI';
                            return null;
                          },
                        ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.2, end: 0),

                        const SizedBox(height: 12),

                        TextFormField(
                          controller: _confirmarCtrl,
                          obscureText: !_verConfirmar,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'Confirmar contraseña',
                            hintStyle: const TextStyle(color: Colors.white54),
                            prefixIcon: const Icon(Icons.lock_rounded, color: Colors.white70),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _verConfirmar ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: Colors.white54,
                              ),
                              onPressed: () => setState(() => _verConfirmar = !_verConfirmar),
                            ),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.white, width: 2),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.white),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.white, width: 2),
                            ),
                            errorStyle: const TextStyle(color: Colors.white),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                            if (v != _nuevaCtrl.text) return 'Las contraseñas no coinciden';
                            return null;
                          },
                        ).animate().fadeIn(delay: 350.ms).slideX(begin: -0.2, end: 0),

                        const SizedBox(height: 16),

                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().shake(),

                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: _guardando ? null : _guardar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1B4332),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _guardando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1B4332),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Guardar contraseña',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                                ),
                        ).animate().fadeIn(delay: 400.ms),

                        const Spacer(),

                        TextButton(
                          onPressed: () async {
                            final auth = context.read<AuthProvider>();
                            await auth.logout();
                            if (mounted) context.go('/login');
                          },
                          child: const Text(
                            'Más tarde',
                            style: TextStyle(color: Colors.white60, fontSize: 14),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}