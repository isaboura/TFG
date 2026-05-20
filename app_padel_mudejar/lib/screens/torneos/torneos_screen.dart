import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

/// Pantalla principal de Torneos.
/// Muestra dos secciones:
/// - Mis partidos: próximos partidos del socio en torneos
/// - Torneos: lista de todos los torneos del club
/// Todo tiene el degradado verde característico de la app.
class TorneosScreen extends StatefulWidget {
  const TorneosScreen({super.key});

  @override
  State<TorneosScreen> createState() => _TorneosScreenState();
}

class _TorneosScreenState extends State<TorneosScreen> {
  // Lista de torneos cargados desde la API
  List<dynamic> _torneos = [];

  // Lista de partidos del socio cargados desde la API
  List<dynamic> _partidos = [];

  // Estado de carga
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Carga los torneos y los partidos del socio en paralelo.
  Future<void> _cargar() async {
    final auth = context.read<AuthProvider>();
    try {
      // Cargamos torneos y partidos en paralelo para mayor velocidad
      final results = await Future.wait([
        ApiService.getTorneos(),
        ApiService.getPartidosSocio(auth.dni),
      ]);
      setState(() {
        _torneos = results[0];
        _partidos = results[1];
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : RefreshIndicator(
                onRefresh: _cargar,
                color: Colors.white,
                child: CustomScrollView(
                  slivers: [
                    // --- AppBar flotante con título ---
                    SliverAppBar(
                      floating: true,
                      snap: true,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      title: const Text(
                        'Torneos',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // --- Sección: Mis partidos ---
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Título de la sección
                            const Text(
                              'Mis próximos partidos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Lista de partidos o mensaje vacío
                            if (_partidos.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.sports_rounded,
                                      color: Colors.white54,
                                      size: 28,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'No tienes partidos próximos',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              // Mostramos cada partido del socio
                              ..._partidos.asMap().entries.map((e) {
                                return _PartidoCard(partido: e.value)
                                    .animate()
                                    .fadeIn(
                                      delay: Duration(milliseconds: e.key * 80),
                                    )
                                    .slideY(begin: 0.1, end: 0);
                              }),
                            const SizedBox(height: 24),

                            // Título de la sección de torneos
                            const Text(
                              'Todos los torneos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    // --- Lista de torneos ---
                    if (_torneos.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.emoji_events_rounded,
                                  color: Colors.white54,
                                  size: 28,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'No hay torneos disponibles',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, i) {
                            final torneo = _torneos[i];
                            return _TorneoCard(
                                  torneo: torneo,
                                  // Al pulsar navegamos al detalle del torneo
                                  onTap: () => context.push(
                                    '/torneos/detalle',
                                    extra: torneo,
                                  ),
                                )
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: i * 80))
                                .slideY(begin: 0.1, end: 0);
                          }, childCount: _torneos.length),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

/// Card de un partido próximo del socio.
/// Muestra torneo, equipos, fecha y pista asignada.
class _PartidoCard extends StatelessWidget {
  final dynamic partido; // Datos del partido de la API

  const _PartidoCard({required this.partido});

  @override
  Widget build(BuildContext context) {
    // Extraemos los datos del partido
    final torneo = partido['torneo'] as Map<String, dynamic>? ?? {};
    final equipoLocal = partido['equipo_local'] as Map<String, dynamic>? ?? {};
    final equipoVisitante =
        partido['equipo_visitante'] as Map<String, dynamic>? ?? {};
    final reserva = partido['reserva'] as Map<String, dynamic>?;
    final ronda = partido['ronda'] as int? ?? 0;

    // Formateamos la fecha si hay reserva
    String fechaHora = 'Sin fecha asignada';
    if (reserva != null) {
      try {
        final dt = DateTime.parse(reserva['fechaHora'] as String);
        fechaHora = DateFormat('EEE d MMM · HH:mm', 'es').format(dt);
      } catch (_) {}
    }

    // Nombre de la pista si hay reserva
    final pista =
        reserva?['instalacion_relacion']?['nombre'] as String? ??
        'Pista sin asignar';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Card semitransparente sobre el degradado
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: nombre del torneo y ronda
          Row(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                color: AppTheme.accent,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  torneo['nombre'] as String? ?? 'Torneo',
                  style: const TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Badge de ronda
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Ronda $ronda',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Enfrentamiento: equipo local VS visitante
          Row(
            children: [
              Expanded(
                child: Text(
                  equipoLocal['nombre'] as String? ?? 'Local',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              // Separador VS
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  equipoVisitante['nombre'] as String? ?? 'Visitante',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 10),

          // Fecha y pista del partido
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                fechaHora,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const Spacer(),
              const Icon(
                Icons.sports_tennis_rounded,
                color: Colors.white70,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                pista,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Card de un torneo con su nombre, deporte, estado y estadísticas.
/// Al pulsar navega al detalle con el bracket completo.
class _TorneoCard extends StatelessWidget {
  final dynamic torneo; // Datos del torneo
  final VoidCallback onTap; // Callback al pulsar

  const _TorneoCard({required this.torneo, required this.onTap});

  /// Devuelve el color del badge según el estado del torneo.
  Color _estadoColor(String estado) {
    switch (estado) {
      case 'EN_CURSO':
        return Colors.greenAccent;
      case 'PENDIENTE':
        return Colors.orangeAccent;
      case 'FINALIZADO':
        return Colors.white54;
      default:
        return Colors.white54;
    }
  }

  /// Devuelve el texto del estado en español.
  String _estadoTexto(String estado) {
    switch (estado) {
      case 'EN_CURSO':
        return 'En curso';
      case 'PENDIENTE':
        return 'Próximamente';
      case 'FINALIZADO':
        return 'Finalizado';
      default:
        return estado;
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = torneo['nombre'] as String? ?? 'Torneo';
    final deporte = torneo['deporte'] as String? ?? '';
    final estado = torneo['estado'] as String? ?? '';
    final equipos = torneo['equipos_count'] as int? ?? 0;
    final fechaInicio = torneo['fecha_inicio'] as String? ?? '';
    final fechaFin = torneo['fecha_fin'] as String? ?? '';

    // Formateamos las fechas de inicio y fin
    String rango = '';
    try {
      final inicio = DateTime.parse(fechaInicio);
      final fin = DateTime.parse(fechaFin);
      rango =
          '${DateFormat('d MMM', 'es').format(inicio)} — ${DateFormat('d MMM yyyy', 'es').format(fin)}';
    } catch (_) {}

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Card semitransparente sobre el degradado
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icono de trofeo con fondo semitransparente
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre del torneo
                      Text(
                        nombre,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Deporte del torneo
                      Text(
                        deporte,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de estado con color según el estado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _estadoColor(estado).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _estadoColor(estado).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _estadoTexto(estado),
                    style: TextStyle(
                      color: _estadoColor(estado),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 10),
            // Fila inferior: fechas, equipos, partidos y flecha
            Row(
              children: [
                // Rango de fechas del torneo
                if (rango.isNotEmpty) ...[
                  const Icon(
                    Icons.calendar_today_rounded,
                    color: Colors.white54,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    rango,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 12),
                ],
                // Número de equipos
                const Icon(
                  Icons.group_rounded,
                  color: Colors.white54,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  '$equipos equipos',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const Spacer(),
                // Flecha de navegación al detalle
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Pantalla de detalle de un torneo.
/// Muestra el bracket completo con todos los partidos por ronda.
/// Tiene el mismo degradado verde que el resto de la app.
class TorneoDetalleScreen extends StatefulWidget {
  final Map<String, dynamic> torneo; // Datos básicos del torneo (de la lista)

  const TorneoDetalleScreen({super.key, required this.torneo});

  @override
  State<TorneoDetalleScreen> createState() => _TorneoDetalleScreenState();
}

class _TorneoDetalleScreenState extends State<TorneoDetalleScreen> {
  // Datos completos del torneo con bracket
  Map<String, dynamic>? _torneoCompleto;

  // Estado de carga
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Carga los datos completos del torneo incluyendo bracket y resultados.
  Future<void> _cargar() async {
    try {
      final id = widget.torneo['id'] as int;
      final data = await ApiService.getTorneo(id);
      setState(() {
        _torneoCompleto = data;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nombre = widget.torneo['nombre'] as String? ?? 'Torneo';

    return Scaffold(
      // Color de fondo que coincide con el final del degradado
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
              // Cabecera con botón de volver y nombre del torneo
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    // Botón de volver
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Contenido principal con scroll
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : _torneoCompleto == null
                    ? const Center(
                        child: Text(
                          'Error al cargar el torneo',
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // --- Información general del torneo ---
                            _InfoTorneoCard(torneo: _torneoCompleto!),
                            const SizedBox(height: 20),

                            // --- Equipos inscritos ---
                            const Text(
                              'Equipos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _EquiposSection(
                              equipos:
                                  (_torneoCompleto!['equipos']
                                      as List<dynamic>? ??
                                  []),
                            ),
                            const SizedBox(height: 20),

                            // --- Bracket de partidos ---
                            const Text(
                              'Partidos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _BracketSection(
                              partidos:
                                  (_torneoCompleto!['partidos']
                                      as List<dynamic>? ??
                                  []),
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

/// Card con la información general del torneo (deporte, estado, fechas).
class _InfoTorneoCard extends StatelessWidget {
  final Map<String, dynamic> torneo;

  const _InfoTorneoCard({required this.torneo});

  @override
  Widget build(BuildContext context) {
    final deporte = torneo['deporte'] as String? ?? '';
    final estado = torneo['estado'] as String? ?? '';
    final fechaInicio = torneo['fecha_inicio'] as String? ?? '';
    final fechaFin = torneo['fecha_fin'] as String? ?? '';

    // Formateamos las fechas
    String inicio = '', fin = '';
    try {
      inicio = DateFormat(
        'd MMMM yyyy',
        'es',
      ).format(DateTime.parse(fechaInicio));
      fin = DateFormat('d MMMM yyyy', 'es').format(DateTime.parse(fechaFin));
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          // Deporte y estado
          Row(
            children: [
              _infoItem(Icons.sports_rounded, 'Deporte', deporte),
              const SizedBox(width: 16),
              _infoItem(Icons.flag_rounded, 'Estado', estado),
            ],
          ),
          const SizedBox(height: 12),
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          const SizedBox(height: 12),
          // Fechas
          Row(
            children: [
              _infoItem(Icons.play_arrow_rounded, 'Inicio', inicio),
              const SizedBox(width: 16),
              _infoItem(Icons.stop_rounded, 'Fin', fin),
            ],
          ),
        ],
      ),
    );
  }

  /// Item de información con icono, etiqueta y valor.
  Widget _infoItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección con la lista de equipos inscritos en el torneo.
class _EquiposSection extends StatelessWidget {
  final List<dynamic> equipos;

  const _EquiposSection({required this.equipos});

  @override
  Widget build(BuildContext context) {
    if (equipos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Sin equipos inscritos',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: equipos.map((e) {
        final nombre = e['nombre'] as String? ?? 'Equipo';
        final jugadores = (e['jugadores'] as List<dynamic>? ?? []).length;
        // Chip de equipo con nombre y número de jugadores
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_rounded, color: Colors.white70, size: 14),
              const SizedBox(width: 6),
              Text(
                nombre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '($jugadores)',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

/// Sección del bracket con todos los partidos organizados por ronda.
class _BracketSection extends StatelessWidget {
  final List<dynamic> partidos;

  const _BracketSection({required this.partidos});

  @override
  Widget build(BuildContext context) {
    if (partidos.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Sin partidos programados',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Agrupamos los partidos por ronda para mostrarlos organizados
    final Map<int, List<dynamic>> porRonda = {};
    for (final p in partidos) {
      final ronda = p['ronda'] as int? ?? 0;
      porRonda.putIfAbsent(ronda, () => []).add(p);
    }

    return Column(
      children: porRonda.entries.map((entry) {
        final ronda = entry.key;
        final partidosRonda = entry.value;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Etiqueta de ronda
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Ronda $ronda',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Partidos de esta ronda
            ...partidosRonda.map((p) => _PartidoBracketCard(partido: p)),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}

/// Card de un partido en el bracket.
/// Muestra equipos, resultado (si está jugado) o fecha (si está pendiente).
class _PartidoBracketCard extends StatelessWidget {
  final dynamic partido;

  const _PartidoBracketCard({required this.partido});

  @override
  Widget build(BuildContext context) {
    final equipoLocal = partido['equipo_local'] as Map<String, dynamic>? ?? {};
    final equipoVisitante =
        partido['equipo_visitante'] as Map<String, dynamic>? ?? {};
    final estado = partido['estado'] as String? ?? '';
    final resLocal = partido['resultado_local'];
    final resVisitante = partido['resultado_visitante'];
    final ganador = partido['ganador'] as Map<String, dynamic>?;
    final reserva = partido['reserva'] as Map<String, dynamic>?;

    // Formateamos la fecha del partido si hay reserva
    String fechaHora = '';
    if (reserva != null) {
      try {
        final dt = DateTime.parse(reserva['fechaHora'] as String);
        fechaHora = DateFormat('d MMM · HH:mm', 'es').format(dt);
      } catch (_) {}
    }

    // Determinamos si cada equipo es el ganador para resaltarlo
    final localGano = ganador != null && ganador['id'] == equipoLocal['id'];
    final visitanteGano =
        ganador != null && ganador['id'] == equipoVisitante['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Nombre equipo local (negrita si ganó)
              Expanded(
                child: Text(
                  equipoLocal['nombre'] as String? ?? 'Local',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: localGano ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
              // Resultado o VS según el estado del partido
              if (estado == 'JUGADO' &&
                  resLocal != null &&
                  resVisitante != null)
                // Resultado del partido
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$resLocal — $resVisitante',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                )
              else
                // Partido pendiente, mostramos VS
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'VS',
                    style: TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              // Nombre equipo visitante (negrita si ganó)
              Expanded(
                child: Text(
                  equipoVisitante['nombre'] as String? ?? 'Visitante',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: visitanteGano
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          // Fecha y pista del partido si están disponibles
          if (fechaHora.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white54,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  fechaHora,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.sports_tennis_rounded,
                  color: Colors.white54,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  reserva?['instalacion_relacion']?['nombre'] as String? ?? '',
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
