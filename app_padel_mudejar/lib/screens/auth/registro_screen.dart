import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/logo_widget.dart';

/// Pantalla de registro de nuevo socio.
/// Permite crear una cuenta con DNI, nombre, apellidos, email, teléfono y edad.
/// Si el DNI ya está registrado muestra un mensaje de error inline en la pantalla.
/// Tiene el mismo degradado verde que el resto de la app.
class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  // Clave global del formulario para validación
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto de cada campo del formulario
  final _nombreCtrl = TextEditingController();
  final _apellidosCtrl = TextEditingController();
  final _dniCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _edadCtrl = TextEditingController();

  /// Estado de carga local — evita depender de auth.isLoading
  /// que provoca reconstrucciones del widget que pueden cortar el flujo
  bool _registrando = false;

  /// Mensaje de error que se muestra inline en la pantalla.
  /// Null si no hay error. Se usa en vez de diálogos o snackbars
  /// para evitar problemas de contexto tras operaciones async.
  String? _errorRegistro;

  @override
  void dispose() {
    // Liberamos todos los controladores al salir de la pantalla
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _dniCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _edadCtrl.dispose();
    super.dispose();
  }

  /// Valida el formulario y envía los datos de registro a la API.
  /// Muestra errores inline en la pantalla en vez de diálogos o snackbars.
  /// - Registro exitoso → navega a /home
  /// - DNI duplicado → muestra "Ya existe una cuenta con este DNI"
  /// - Otro error → muestra el mensaje de la API
  Future<void> _registrar() async {
    // Limpiamos el error anterior antes de intentar de nuevo
    setState(() => _errorRegistro = null);

    // Validamos los campos del formulario
    if (!_formKey.currentState!.validate()) return;

    // Activamos el estado de carga local
    setState(() => _registrando = true);

    final auth = context.read<AuthProvider>();
    final result = await auth.registrar({
      'dni': _dniCtrl.text.trim().toUpperCase(),
      'nombre': _nombreCtrl.text.trim(),
      'apellidos': _apellidosCtrl.text.trim(),
      'correoElectronico': _emailCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
      'edad': int.tryParse(_edadCtrl.text.trim()) ?? 0,
    });

    // Comprobamos que el widget sigue montado tras el await
    if (!mounted) return;

    // Desactivamos el estado de carga
    setState(() => _registrando = false);

    if (result['success'] == true) {
      // Registro exitoso — navegamos al home
      context.go('/home');
      return;
    }

    // Procesamos el error — lo mostramos inline en la pantalla
    final errors = result['errors'] as Map?;
    if (errors != null && errors.containsKey('dni')) {
      // DNI ya registrado — mensaje específico con sugerencia de login
      setState(() => _errorRegistro = 'Ya existe una cuenta con este DNI. Prueba a iniciar sesión.');
    } else {
      // Otro error de la API — mostramos el mensaje genérico
      setState(() => _errorRegistro = result['message'] ?? 'Error al registrarse');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        // Fondo con degradado verde claro → verde oscuro
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
                      children: [
                        const SizedBox(height: 40),

                        // Logo del club con animación de fade
                        const LogoWidget().animate().fadeIn(duration: 500.ms),

                        const SizedBox(height: 24),

                        // Título de la pantalla
                        Text(
                          'Registro',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ).animate().fadeIn(delay: 100.ms),

                        const SizedBox(height: 8),

                        // Subtítulo descriptivo
                        Text(
                          'Crea tu cuenta de socio',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 32),

                        // --- Campos del formulario ---

                        // Nombre del socio
                        _buildField(
                          controller: _nombreCtrl,
                          hint: 'Nombre',
                          icon: Icons.person_outline,
                          validator: (v) =>
                              v!.isEmpty ? 'Campo requerido' : null,
                          delay: 300,
                        ),
                        const SizedBox(height: 12),

                        // Apellidos del socio
                        _buildField(
                          controller: _apellidosCtrl,
                          hint: 'Apellidos',
                          icon: Icons.person_outline,
                          validator: (v) =>
                              v!.isEmpty ? 'Campo requerido' : null,
                          delay: 350,
                        ),
                        const SizedBox(height: 12),

                        // DNI — se convierte a mayúsculas automáticamente
                        _buildField(
                          controller: _dniCtrl,
                          hint: 'DNI (ej: 12345678A)',
                          icon: Icons.badge_rounded,
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Campo requerido';
                            }
                            if (v.length != 9) {
                              return 'El DNI debe tener 9 caracteres';
                            }
                            return null;
                          },
                          delay: 400,
                        ),
                        const SizedBox(height: 12),

                        // Email del socio
                        _buildField(
                          controller: _emailCtrl,
                          hint: 'Email',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Campo requerido';
                            }
                            if (!v.contains('@')) return 'Email inválido';
                            return null;
                          },
                          delay: 450,
                        ),
                        const SizedBox(height: 12),

                        // Teléfono del socio
                        _buildField(
                          controller: _telefonoCtrl,
                          hint: 'Teléfono',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: (v) =>
                              v!.isEmpty ? 'Campo requerido' : null,
                          delay: 500,
                        ),
                        const SizedBox(height: 12),

                        // Edad del socio (número entero)
                        _buildField(
                          controller: _edadCtrl,
                          hint: 'Edad',
                          icon: Icons.cake_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Campo requerido';
                            }
                            if (int.tryParse(v) == null) {
                              return 'Introduce un número válido';
                            }
                            return null;
                          },
                          delay: 550,
                        ),

                        const SizedBox(height: 28),

                        // Botón de registrarse — desactivado mientras se procesa
                        ElevatedButton(
                          onPressed: _registrando ? null : _registrar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1B4332),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          // Indicador de carga o texto según el estado
                          child: _registrando
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF1B4332),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Registrarse',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ).animate().fadeIn(delay: 600.ms),

                        // --- Mensaje de error inline ---
                        // Se muestra debajo del botón cuando hay un error de registro.
                        // Más fiable que diálogos o snackbars tras operaciones async.
                        if (_errorRegistro != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.redAccent.withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.redAccent, size: 18),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorRegistro!,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const Spacer(),

                        // Enlace para ir al login si ya tiene cuenta
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: 40, top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '¿Ya eres socio? ',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                              GestureDetector(
                                onTap: () => context.go('/login'),
                                child: const Text(
                                  'Iniciar sesión',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 650.ms),
                        ),
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

  /// Campo de texto del formulario con estilo adaptado al fondo verde.
  /// Texto en blanco, borde semitransparente y animación de entrada.
  Widget _buildField({
    required TextEditingController controller,
    required String hint,                         // Texto de placeholder
    required IconData icon,                        // Icono del campo
    String? Function(String?)? validator,          // Función de validación
    TextInputType? keyboardType,                   // Tipo de teclado
    TextCapitalization textCapitalization = TextCapitalization.none,
    required int delay,                            // Delay de la animación
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      // Texto en blanco para que se vea sobre el fondo verde
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        filled: true,
        // Fondo semitransparente para integrarse con el degradado
        fillColor: Colors.white.withValues(alpha: 0.12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        // Borde blanco sólido cuando el campo está enfocado
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        // Borde de error en blanco para que se vea sobre el fondo verde
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        // Texto de error en blanco para visibilidad
        errorStyle: const TextStyle(color: Colors.white),
      ),
      validator: validator,
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideX(begin: -0.15, end: 0);
  }
}