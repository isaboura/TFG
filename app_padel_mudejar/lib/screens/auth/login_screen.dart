import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/logo_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _dniController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _verPassword = false;

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      _dniController.text.trim().toUpperCase(),
      _passwordController.text.trim(),
    );
    if (ok && mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF2D6A4F),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF52B788), Color(0xFF2D6A4F), Color(0xFF0D2B1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    size.height -
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

                        const LogoWidget()
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .slideY(begin: -0.3, end: 0),

                        const SizedBox(height: 40),

                        Text(
                          'Iniciar Sesión',
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 8),

                        Text(
                          'Accede con tu DNI y contraseña',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 40),

                        TextFormField(
                              controller: _dniController,
                              textCapitalization: TextCapitalization.characters,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'DNI (ej: 12345678A)',
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                ),
                                prefixIcon: const Icon(
                                  Icons.badge_rounded,
                                  color: Colors.white70,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Colors.redAccent,
                                    width: 2,
                                  ),
                                ),
                                errorStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Introduce tu DNI';
                                if (v.length != 9)
                                  return 'El DNI debe tener 9 caracteres';
                                return null;
                              },
                            )
                            .animate()
                            .fadeIn(delay: 400.ms)
                            .slideX(begin: -0.2, end: 0),

                        const SizedBox(height: 12),

                        TextFormField(
                              controller: _passwordController,
                              obscureText: !_verPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Contraseña',
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline_rounded,
                                  color: Colors.white70,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _verPassword
                                        ? Icons.visibility_off_rounded
                                        : Icons.visibility_rounded,
                                    color: Colors.white54,
                                  ),
                                  onPressed: () => setState(
                                    () => _verPassword = !_verPassword,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.2),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: Colors.redAccent,
                                    width: 2,
                                  ),
                                ),
                                errorStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Introduce tu contraseña';
                                return null;
                              },
                            )
                            .animate()
                            .fadeIn(delay: 450.ms)
                            .slideX(begin: -0.2, end: 0),

                        const SizedBox(height: 16),

                        if (auth.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    auth.error!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn().shake(),

                        const SizedBox(height: 24),

                        ElevatedButton(
                          onPressed: auth.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1B4332),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1B4332),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Entrar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ).animate().fadeIn(delay: 500.ms),

                        const Spacer(),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '¿No eres socio? ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/registro'),
                              child: const Text(
                                'Regístrate',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 600.ms),

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
