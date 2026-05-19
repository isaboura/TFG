import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de perfil del socio.
/// Muestra datos personales, actividad, soporte y botón de cerrar sesión.
/// Toda la pantalla tiene el degradado verde característico de la app.
/// Las secciones son semitransparentes para integrarse con el degradado.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escuchamos el AuthProvider para actualizar la UI en tiempo real
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
                    // Badge con el número de carnet semitransparente
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

                // --- Tarjeta de datos personales semitransparente ---
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
                      Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
                      const SizedBox(height: 8),
                      // Filas con los datos del socio
                      _DataRow(icon: Icons.badge_rounded, label: 'DNI', value: auth.dni),
                      _DataRow(icon: Icons.email_outlined, label: 'Email', value: auth.email),
                      _DataRow(icon: Icons.phone_outlined, label: 'Teléfono', value: auth.telefono),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // --- Tarjeta de actividad semitransparente ---
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
                      // Acceso a reservas próximas (pestaña 0)
                      _ActionRow(
                        icon: Icons.calendar_month_rounded,
                        label: 'Mis reservas',
                        onTap: () => context.go('/mis-reservas'),
                      ),
                      // Acceso al historial — navega a mis-reservas con pestaña 1
                      _ActionRow(
                        icon: Icons.history_rounded,
                        label: 'Historial',
                        onTap: () => context.go('/mis-reservas?tab=1'),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 16),

                // --- Tarjeta de soporte semitransparente ---
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
                        'Soporte',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 12),
                      // Opción para ver cómo usar la app
                      _ActionRow(
                        icon: Icons.help_outline_rounded,
                        label: 'Cómo usar la app',
                        onTap: () => _mostrarComoUsarApp(context),
                      ),
                      // Opción para reportar un problema
                      _ActionRow(
                        icon: Icons.flag_outlined,
                        label: 'Reportar un problema',
                        onTap: () => _mostrarReportarProblema(context),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 24),

                // --- Botón de cerrar sesión en blanco ---
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
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
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
                  icon: const Icon(Icons.logout_rounded, color: Color(0xFF1B4332)),
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
                ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Abre el bottom sheet para editar los datos personales del socio.
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

  /// Abre la pantalla de guía de uso de la app como modal a pantalla completa.
  void _mostrarComoUsarApp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _ComoUsarAppScreen(),
      ),
    );
  }

  /// Abre el bottom sheet para reportar un problema.
  void _mostrarReportarProblema(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ReportarProblemaBottomSheet(),
    );
  }
}

/// Pantalla de guía de uso de la app.
/// Explica paso a paso cómo usar las principales funciones.
/// Tiene el mismo degradado verde que el resto de la app.
class _ComoUsarAppScreen extends StatelessWidget {
  const _ComoUsarAppScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Color de fondo que coincide con el final del degradado
      backgroundColor: const Color(0xFF0D2B1E),
      body: Container(
        // Fondo con degradado verde
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF52B788), Color(0xFF2D6A4F), Color(0xFF0D2B1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Cabecera con botón de cerrar y título
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    // Botón de cerrar la pantalla
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 20),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Cómo usar la app',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Lista de pasos desplazable
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Cada paso explica una funcionalidad de la app
                      _PasoGuia(
                        numero: '1',
                        titulo: 'Explorar las pistas',
                        descripcion:
                            'En la pantalla de inicio verás todas las pistas disponibles del club. Pulsa en cualquiera para ver sus horarios disponibles y reseñas.',
                        icono: Icons.sports_tennis_rounded,
                      ),
                      _PasoGuia(
                        numero: '2',
                        titulo: 'Reservar una pista',
                        descripcion:
                            'Pulsa el botón "Reservar esta pista" en el detalle de una pista, o ve a la pestaña Reservas y pulsa el botón +. Elige la duración, fecha y hora.',
                        icono: Icons.calendar_today_rounded,
                      ),
                      _PasoGuia(
                        numero: '3',
                        titulo: 'Gestionar tus reservas',
                        descripcion:
                            'En la pestaña Reservas → Próximas verás todas tus reservas futuras. Puedes editarlas o cancelarlas hasta antes de que llegue la hora.',
                        icono: Icons.edit_calendar_rounded,
                      ),
                      _PasoGuia(
                        numero: '4',
                        titulo: 'Dejar una reseña',
                        descripcion:
                            'Después de jugar, ve a Reservas → Historial. Pulsa "Dejar reseña" en cualquier reserva pasada para valorar la pista con estrellas y comentario.',
                        icono: Icons.star_rounded,
                      ),
                      _PasoGuia(
                        numero: '5',
                        titulo: 'Ver reseñas de pistas',
                        descripcion:
                            'En la pantalla de inicio, pulsa las estrellas de cualquier pista para ver todas sus reseñas. También puedes editar o eliminar tus propias reseñas.',
                        icono: Icons.rate_review_rounded,
                      ),
                      _PasoGuia(
                        numero: '6',
                        titulo: 'Editar tu perfil',
                        descripcion:
                            'Ve a la pestaña Perfil y pulsa "Editar" en la sección de datos personales para actualizar tu nombre, teléfono o email.',
                        icono: Icons.person_rounded,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget de paso de guía con número, icono, título y descripción.
/// Se usa en la pantalla de cómo usar la app.
class _PasoGuia extends StatelessWidget {
  final String numero;       // Número del paso (1, 2, 3...)
  final String titulo;       // Título corto del paso
  final String descripcion;  // Explicación detallada del paso
  final IconData icono;      // Icono representativo del paso

  const _PasoGuia({
    required this.numero,
    required this.titulo,
    required this.descripcion,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Fondo semitransparente para integrarse con el degradado
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Círculo con el número del paso
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                numero,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila con icono y título
                Row(
                  children: [
                    Icon(icono, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Text(titulo,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 6),
                // Descripción del paso en blanco semitransparente
                Text(descripcion,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1, end: 0);
  }
}

/// Bottom sheet para reportar un problema al club.
/// Solo UI — el envío se implementará cuando haya endpoint disponible.
/// Tiene el mismo degradado verde que el resto de la app.
class _ReportarProblemaBottomSheet extends StatefulWidget {
  const _ReportarProblemaBottomSheet();

  @override
  State<_ReportarProblemaBottomSheet> createState() =>
      _ReportarProblemaBottomSheetState();
}

class _ReportarProblemaBottomSheetState
    extends State<_ReportarProblemaBottomSheet> {
  // Controlador del campo de descripción del problema
  final _descripcionCtrl = TextEditingController();

  // Categoría seleccionada del problema
  String? _categoriaSeleccionada;

  // Estado de envío (simulado, sin endpoint real)
  bool _enviando = false;

  // Lista de categorías de problemas disponibles
  final List<String> _categorias = [
    'Problema con una reserva',
    'Problema con la app',
    'Pista en mal estado',
    'Error en mi perfil',
    'Otro',
  ];

  @override
  void dispose() {
    // Liberamos el controlador de texto
    _descripcionCtrl.dispose();
    super.dispose();
  }

  /// Simula el envío del reporte (sin endpoint real por ahora).
  /// Muestra un mensaje de confirmación al usuario.
  Future<void> _enviar() async {
    if (_categoriaSeleccionada == null || _descripcionCtrl.text.trim().isEmpty) {
      return;
    }
    setState(() => _enviando = true);
    // Simulamos un delay de envío
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reporte enviado. Gracias por tu feedback.'),
          backgroundColor: AppTheme.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Altura del 85% para mostrar todo el formulario
      height: MediaQuery.of(context).size.height * 0.85,
      // Degradado verde igual que el resto de la app
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF1B4332), Color(0xFF0D2B1E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Padding para que el teclado no tape el formulario
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle visual semitransparente
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
          // Título e icono del formulario
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag_outlined,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reportar un problema',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text('Cuéntanos qué ha pasado',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Formulario con scroll
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selector de categoría del problema
                  const Text('Categoría',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  // Lista de chips de categoría seleccionables
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categorias.map((cat) {
                      final seleccionada = _categoriaSeleccionada == cat;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _categoriaSeleccionada = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            // Blanco si seleccionada, semitransparente si no
                            color: seleccionada
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: seleccionada
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              // Texto verde si seleccionada, blanco si no
                              color: seleccionada
                                  ? const Color(0xFF1B4332)
                                  : Colors.white,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  // Campo de descripción del problema
                  const Text('Descripción',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descripcionCtrl,
                    maxLines: 5,
                    maxLength: 500,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Describe el problema con detalle...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.12),
                      counterStyle: const TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2))),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.white, width: 2)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Aviso de que el endpoint aún no está implementado
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Tu reporte será revisado por el equipo del club.',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Botón de envío en blanco con texto verde
                  ElevatedButton(
                    onPressed: (_categoriaSeleccionada != null &&
                            _descripcionCtrl.text.trim().isNotEmpty &&
                            !_enviando)
                        ? _enviar
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1B4332),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _enviando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Color(0xFF1B4332), strokeWidth: 2))
                        : const Text('Enviar reporte',
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
}

/// Bottom sheet para editar los datos personales del socio.
/// Tiene el mismo degradado verde que el resto de la app.
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
  // Controladores precargados con los datos actuales del socio
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidosCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;

  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Precargamos los campos con los datos actuales
    _nombreCtrl = TextEditingController(text: widget.auth.nombre);
    _apellidosCtrl = TextEditingController(text: widget.auth.apellidos);
    _telefonoCtrl = TextEditingController(text: widget.auth.telefono);
    _emailCtrl = TextEditingController(text: widget.auth.email);
  }

  @override
  void dispose() {
    // Liberamos todos los controladores
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
          // Recargamos el perfil para reflejar los cambios en la UI
          await widget.auth.recargarPerfil();
          Navigator.pop(context);
          widget.onActualizado();
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
      height: MediaQuery.of(context).size.height * 0.80,
      // Degradado verde igual que el resto de la app
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF1B4332), Color(0xFF0D2B1E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle visual semitransparente
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
          const Text('Editar perfil',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 20),
          // Formulario con scroll
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _campo('Nombre', _nombreCtrl, Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _campo('Apellidos', _apellidosCtrl, Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _campo('Teléfono', _telefonoCtrl, Icons.phone_outlined,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _campo('Email', _emailCtrl, Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress),
                  // Error de la API si existe
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
                  // Botón guardar en blanco con texto verde
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

  /// Campo de texto con estilo adaptado al fondo verde.
  Widget _campo(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
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
  final IconData icon;
  final String label;
  final String value;

  const _DataRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
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
  final IconData icon;
  final String label;
  final VoidCallback onTap;

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
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            const Spacer(),
            // Flecha indicando navegación
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}