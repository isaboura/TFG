import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

/// Pantalla de perfil del socio.
/// Muestra datos personales, actividad, soporte y botón de cerrar sesión.
/// Toda la pantalla tiene el degradado verde característico de la app.
class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  /// Email del administrador del club para soporte
  static const String emailAdmin = 'azeemmuhammadsultana@gmail.com';

  @override
  Widget build(BuildContext context) {
    // Escuchamos el AuthProvider para actualizar la UI en tiempo real
    final auth = context.watch<AuthProvider>();

    return Scaffold(
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
                    // Círculo con la inicial del nombre
                    CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      child: Text(
                        auth.nombre.isNotEmpty
                            ? auth.nombre[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn(),
                    const SizedBox(height: 12),
                    // Nombre completo del socio
                    Text(
                      auth.nombreCompleto,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 4),
                    // Badge con el número de carnet semitransparente
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Nº Socio: ${auth.idCarnet}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
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
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabecera con título y botón de editar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Datos personales',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
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
                      Divider(
                          color: Colors.white.withValues(alpha: 0.2),
                          height: 1),
                      const SizedBox(height: 8),
                      // Filas con los datos del socio
                      _DataRow(
                          icon: Icons.badge_rounded,
                          label: 'DNI',
                          value: auth.dni),
                      _DataRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: auth.email),
                      _DataRow(
                          icon: Icons.phone_outlined,
                          label: 'Teléfono',
                          value: auth.telefono),
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
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Actividad',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 12),
                      // Acceso a reservas próximas (pestaña 0)
                      _ActionRow(
                        icon: Icons.calendar_month_rounded,
                        label: 'Mis reservas',
                        onTap: () => context.go('/mis-reservas'),
                      ),
                      // Acceso al historial (pestaña 1)
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
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Soporte',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      const SizedBox(height: 12),
                      // Opción para ver la guía de uso de la app
                      _ActionRow(
                        icon: Icons.help_outline_rounded,
                        label: 'Cómo usar la app',
                        onTap: () => _mostrarComoUsarApp(context),
                      ),
                      // Opción para contactar con el admin
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

  /// Abre el bottom sheet para reportar un problema al admin.
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
/// Explica paso a paso cómo usar todas las funciones principales.
/// Tiene el mismo degradado verde que el resto de la app.
class _ComoUsarAppScreen extends StatelessWidget {
  const _ComoUsarAppScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2B1E),
      body: Container(
        // Fondo con degradado verde igual que el resto de la app
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
                      // Paso 1: Explorar pistas
                      _PasoGuia(
                        numero: '1',
                        titulo: 'Explorar las pistas',
                        descripcion:
                            'En la pantalla de Inicio verás todas las pistas y canchas del club. Pulsa en cualquiera para ver su disponibilidad horaria y las reseñas de otros socios.',
                        icono: Icons.sports_tennis_rounded,
                      ),
                      // Paso 2: Reservar una pista
                      _PasoGuia(
                        numero: '2',
                        titulo: 'Reservar una pista',
                        descripcion:
                            'Pulsa "Reservar esta pista" en el detalle de una pista de Pádel o Tenis. Elige la duración, la fecha en el calendario y la hora disponible. Confirma los datos y listo.',
                        icono: Icons.calendar_today_rounded,
                      ),
                      // Paso 3: Gestionar reservas
                      _PasoGuia(
                        numero: '3',
                        titulo: 'Gestionar tus reservas',
                        descripcion:
                            'En la pestaña Reservas → Próximas verás todas tus reservas futuras confirmadas. Puedes editarlas para cambiar la fecha u hora, o cancelarlas si ya no puedes ir.',
                        icono: Icons.edit_calendar_rounded,
                      ),
                      // Paso 4: Dejar una reseña
                      _PasoGuia(
                        numero: '4',
                        titulo: 'Dejar una reseña',
                        descripcion:
                            'Después de jugar, ve a Reservas → Historial. Pulsa "Dejar reseña" en cualquier reserva pasada para valorar la pista del 1 al 5 y añadir un comentario.',
                        icono: Icons.star_rounded,
                      ),
                      // Paso 5: Ver y editar reseñas
                      _PasoGuia(
                        numero: '5',
                        titulo: 'Ver y editar reseñas',
                        descripcion:
                            'En el Inicio, pulsa las estrellas de cualquier pista para ver todas sus reseñas. Puedes editar o eliminar tus propias reseñas en cualquier momento.',
                        icono: Icons.rate_review_rounded,
                      ),
                      // Paso 6: Torneos y partidos
                      _PasoGuia(
                        numero: '6',
                        titulo: 'Torneos y partidos',
                        descripcion:
                            'En la pestaña Torneos verás todos los torneos del club con su bracket completo. Si perteneces a un equipo, tus próximos partidos aparecerán en la sección "Mis próximos partidos".',
                        icono: Icons.emoji_events_rounded,
                      ),
                      // Paso 7: Reservar Fútbol
                      _PasoGuia(
                        numero: '7',
                        titulo: 'Reservar Fútbol',
                        descripcion:
                            'Las canchas de Fútbol no se reservan desde la app. Puedes ver la disponibilidad horaria, pero para reservar debes contactar directamente con el gerente del club.',
                        icono: Icons.sports_soccer_rounded,
                      ),
                      // Paso 8: Editar perfil
                      _PasoGuia(
                        numero: '8',
                        titulo: 'Editar tu perfil',
                        descripcion:
                            'Ve a la pestaña Perfil y pulsa "Editar" en la sección de datos personales para actualizar tu nombre, apellidos, teléfono o email en cualquier momento.',
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
  final String numero;      // Número del paso (1, 2, 3...)
  final String titulo;      // Título corto del paso
  final String descripcion; // Explicación detallada del paso
  final IconData icono;     // Icono representativo del paso

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
              child: Text(numero,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila con icono y título del paso
                Row(
                  children: [
                    Icon(icono, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(titulo,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Descripción detallada del paso
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
/// Muestra el email del administrador para contacto directo.
/// Al pulsar el email lo copia al portapapeles.
class _ReportarProblemaBottomSheet extends StatelessWidget {
  /// Email del administrador del club
  static const String emailAdmin = 'azeemmuhammadsultana@gmail.com';

  const _ReportarProblemaBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      // Degradado verde igual que el resto de la app
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2D6A4F), Color(0xFF1B4332), Color(0xFF0D2B1E)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 24),
          // Icono y título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.support_agent_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reportar un problema',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  SizedBox(height: 2),
                  Text('Contacta con el gerente del club',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Descripción del problema
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '¿Tienes algún problema con la app, una reserva o las instalaciones?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Escríbenos directamente al email del administrador del club y lo resolveremos lo antes posible.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Email del admin — pulsar para copiar al portapapeles
          GestureDetector(
            onTap: () {
              Clipboard.setData(const ClipboardData(text: emailAdmin));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Email copiado al portapapeles'),
                  backgroundColor: Color(0xFF2D6A4F),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.mail_outline_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email del administrador',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                        const SizedBox(height: 2),
                        // Email resaltado en blanco
                        Text(emailAdmin,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  // Icono de copiar
                  const Icon(Icons.copy_rounded,
                      color: Colors.white54, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Indicación de que se puede copiar
          const Center(
            child: Text(
              'Pulsa para copiar el email',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          // Botón de cerrar en blanco con texto verde
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B4332),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: const Text('Entendido',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet para editar los datos personales del socio.
/// Tiene el mismo degradado verde que el resto de la app.
/// Valida que ningún campo quede vacío antes de guardar.
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
  String? _error; // Mensaje de error de validación o de la API

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

  /// Valida los campos del formulario antes de enviar a la API.
  /// Devuelve un mensaje de error si hay algún campo inválido, o null si todo está bien.
  String? _validar() {
    if (_nombreCtrl.text.trim().isEmpty) return 'El nombre no puede estar vacío';
    if (_apellidosCtrl.text.trim().isEmpty) return 'Los apellidos no pueden estar vacíos';
    if (_telefonoCtrl.text.trim().isEmpty) return 'El teléfono no puede estar vacío';
    if (_telefonoCtrl.text.trim().length != 9) return 'El teléfono debe tener 9 dígitos';
    if (_emailCtrl.text.trim().isEmpty) return 'El email no puede estar vacío';
    if (!_emailCtrl.text.trim().contains('@')) return 'El email no es válido';
    return null;
  }

  /// Valida los campos y envía los datos actualizados a la API.
  /// Recarga el perfil si la actualización tiene éxito.
  Future<void> _guardar() async {
    // Validamos antes de llamar a la API
    final errorValidacion = _validar();
    if (errorValidacion != null) {
      setState(() => _error = errorValidacion);
      return;
    }

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
          // Comprobamos mounted de nuevo después del await
          if (!mounted) return;
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
        _error = 'Error de conexión';
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
          // Formulario con scroll para cuando el teclado esté visible
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Campos editables del perfil
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
                  // Mensaje de error de validación o de la API
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  Colors.redAccent.withValues(alpha: 0.4))),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(_error!,
                                  style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13))),
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
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.2))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: Colors.white.withValues(alpha: 0.2))),
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
  final String label;  // Etiqueta (ej: "DNI", "Email")
  final String value;  // Valor del dato del socio

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
            // Flecha indicando que es navegable
            const Icon(Icons.chevron_right_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }
}