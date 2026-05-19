import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de perfil del socio.
/// Muestra los datos personales, accesos rápidos a reservas e historial,
/// y permite editar los datos o cerrar sesión.
/// Todo el fondo tiene el degradado verde característico de la app.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos los cambios del AuthProvider para actualizar la UI en tiempo real
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      // Color de fondo que coincide con el final del degradado
      backgroundColor: const Color(0xFF0D2B1E),
      body: Container(
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
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 16),

                // --- Avatar con inicial del nombre y número de socio ---
                Column(
                  children: [
                    // Círculo con la inicial del nombre sobre fondo semitransparente
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        auth.nombre.isNotEmpty ? auth.nombre[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn(),
                    const SizedBox(height: 12),
                    // Nombre completo del socio en blanco
                    Text(
                      auth.nombreCompleto,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 4),
                    // Badge con el número de carnet en blanco semitransparente
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Nº Socio: ${auth.idCarnet}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                  ],
                ),

                const SizedBox(height: 28),

                // --- Tarjeta de datos personales (semitransparente sobre degradado) ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // Fondo semitransparente blanco para integrarse con el degradado
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera con título y botón de editar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Datos personales',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
                          // Botón para abrir el bottom sheet de edición
                          GestureDetector(
                            onTap: () => _mostrarEditarPerfil(context, auth),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.edit_rounded,
                                      color: Colors.white, size: 14),
                                  SizedBox(width: 4),
                                  Text('Editar',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Divider semitransparente entre cabecera y datos
                      Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                      const SizedBox(height: 8),
                      // Filas con los datos del socio en blanco
                      _DataRow(icon: Icons.badge_rounded, label: 'DNI', value: auth.dni),
                      _DataRow(icon: Icons.email_outlined, label: 'Email', value: auth.email),
                      _DataRow(icon: Icons.phone_outlined, label: 'Teléfono', value: auth.telefono),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // --- Tarjeta de accesos rápidos de actividad (semitransparente) ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Actividad',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      // Acceso directo a reservas próximas
                      _ActionRow(
                        icon: Icons.calendar_month_rounded,
                        label: 'Mis reservas',
                        onTap: () => context.go('/mis-reservas'),
                      ),
                      // Acceso directo al historial
                      _ActionRow(
                        icon: Icons.history_rounded,
                        label: 'Historial',
                        onTap: () => context.go('/mis-reservas'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // --- Botón de cerrar sesión en blanco sobre degradado ---
                ElevatedButton.icon(
                  onPressed: () async {
                    // Diálogo de confirmación antes de cerrar sesión
                    final shouldLogout = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (dialogContext) => AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        title: const Text('Cerrar sesión'),
                        content: const Text('¿Seguro que quieres salir?'),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            child: const Text('Salir',
                                style: TextStyle(color: AppTheme.danger)),
                          ),
                        ],
                      ),
                    );
                    // Si confirma, hacemos logout y redirigimos al login
                    if (shouldLogout == true) {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout_rounded,
                      color: Color(0xFF1B4332)),
                  label: const Text('Cerrar sesión',
                      style: TextStyle(
                          color: Color(0xFF1B4332),
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ).animate().fadeIn(delay: 500.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Abre el bottom sheet [_EditarPerfilBottomSheet] para modificar
  /// los datos personales del socio.
  void _mostrarEditarPerfil(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditarPerfilBottomSheet(
        auth: auth,
        onActualizado: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Perfil actualizado'),
                backgroundColor: AppTheme.primary),
          );
        },
      ),
    );
  }
}

/// Bottom sheet para editar los datos personales del socio.
/// Tiene el mismo degradado verde que el resto de la app.
/// Permite modificar nombre, apellidos, teléfono y email.
class _EditarPerfilBottomSheet extends StatefulWidget {
  final AuthProvider auth;           // Datos actuales del socio
  final VoidCallback onActualizado;  // Callback al guardar con éxito

  const _EditarPerfilBottomSheet(
      {required this.auth, required this.onActualizado});

  @override
  State<_EditarPerfilBottomSheet> createState() =>
      _EditarPerfilBottomSheetState();
}

class _EditarPerfilBottomSheetState extends State<_EditarPerfilBottomSheet> {
  // Controladores de texto precargados con los datos actuales del socio
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidosCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;

  // Estados del formulario
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Precargamos los campos con los datos actuales del socio
    _nombreCtrl = TextEditingController(text: widget.auth.nombre);
    _apellidosCtrl = TextEditingController(text: widget.auth.apellidos);
    _telefonoCtrl = TextEditingController(text: widget.auth.telefono);
    _emailCtrl = TextEditingController(text: widget.auth.email);
  }

  @override
  void dispose() {
    // Liberamos todos los controladores de texto
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  /// Envía los datos actualizados a la API y recarga el perfil si tiene éxito.
  Future<void> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final result = await ApiService.actualizarSocio(widget.auth.dni, {
        'nombre': _nombreCtrl.text.trim(),
        'apellidos': _apellidosCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'correoElectronico': _emailCtrl.text.trim(),
      });
      if (mounted) {
        if (result['success'] == true) {
          // Recargamos los datos del socio para reflejar los cambios en la UI
          await widget.auth.recargarPerfil();
          Navigator.pop(context); // Cerramos el bottom sheet
          widget.onActualizado(); // Mostramos el snackbar de éxito
        } else {
          setState(() {
            _error = result['message'] ?? 'Error al actualizar';
            _guardando = false;
          });
        }
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
    return Container(
      // Altura del 80% de la pantalla para el bottom sheet
      height: MediaQuery.of(context).size.height * 0.80,
      // El bottom sheet tiene el mismo degradado verde que el resto de la app
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF1B4332), Color(0xFF0D2B1E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Padding extra para que el teclado no tape el formulario
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle visual del bottom sheet en blanco semitransparente
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          // Título del bottom sheet
          const Text('Editar perfil',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 20),
          // Formulario con scroll para cuando el teclado esté visible
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Campos editables del perfil con estilo adaptado al fondo verde
                  _campo('Nombre', _nombreCtrl, Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _campo('Apellidos', _apellidosCtrl,
                      Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _campo('Teléfono', _telefonoCtrl, Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _campo('Email', _emailCtrl, Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  // Mensaje de error si la API devuelve un fallo
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: Colors.redAccent.withValues(alpha: 0.4))),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: Colors.redAccent, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Botón de guardar en blanco con texto verde
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1B4332),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Color(0xFF1B4332), strokeWidth: 2))
                        : const Text('Guardar cambios',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Campo de texto con estilo adaptado al fondo verde degradado.
  /// Texto en blanco, borde semitransparente y fondo semitransparente.
  Widget _campo(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      // Texto en blanco para que se vea sobre el fondo verde
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        // Label en blanco semitransparente
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        filled: true,
        // Fondo semitransparente para integrarse con el degradado
        fillColor: Colors.white.withValues(alpha: 0.12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
        // Borde blanco sólido cuando el campo está enfocado
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white, width: 2)),
      ),
    );
  }
}

/// Fila de dato personal con icono, etiqueta y valor.
/// Adaptada para mostrarse sobre fondo verde (texto en blanco).
class _DataRow extends StatelessWidget {
  final IconData icon;  // Icono descriptivo del dato
  final String label;   // Etiqueta (ej: "DNI", "Email")
  final String value;   // Valor del dato del socio

  const _DataRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Icono en blanco semitransparente
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          // Etiqueta en blanco semitransparente
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          // Valor en blanco sólido
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

/// Fila de acción con icono, texto y flecha de navegación.
/// Adaptada para mostrarse sobre fondo verde (texto en blanco).
class _ActionRow extends StatelessWidget {
  final IconData icon;       // Icono de la acción
  final String label;        // Texto descriptivo de la acción
  final VoidCallback onTap;  // Callback al pulsar la fila

  const _ActionRow(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            // Icono en blanco semitransparente
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 12),
            // Texto de la acción en blanco
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            const Spacer(),
            // Flecha indicando que es navegable en blanco semitransparente
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}