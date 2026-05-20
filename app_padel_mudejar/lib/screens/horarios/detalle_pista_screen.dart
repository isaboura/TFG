import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';

/// Pantalla de detalle de una instalación/pista.
/// Muestra imagen, horarios disponibles y permite reservar.
/// Para pistas de Fútbol Sala: muestra los horarios pero NO permite reservar,
/// en su lugar muestra un mensaje para contactar con el administrador.
class DetallePistaScreen extends StatefulWidget {
  final Map<String, dynamic> instalacion;

  const DetallePistaScreen({super.key, required this.instalacion});

  @override
  State<DetallePistaScreen> createState() => _DetallePistaScreenState();
}

class _DetallePistaScreenState extends State<DetallePistaScreen> {
  // Fecha seleccionada en el selector horizontal
  DateTime _fechaSeleccionada = DateTime.now();

  // Lista de horas disponibles para la fecha seleccionada
  List<Map<String, dynamic>> _horas = [];

  // Estado de carga de horas
  bool _loadingHoras = false;

  @override
  void initState() {
    super.initState();
    _cargarHoras();
  }

  /// Carga las horas disponibles para la instalación y fecha seleccionadas.
  /// Usa duración de 60 minutos por defecto para mostrar la disponibilidad general.
  Future<void> _cargarHoras() async {
    setState(() {
      _loadingHoras = true;
      _horas = [];
    });
    try {
      final fecha = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
      final res = await ApiService.getHorasDisponibles(
        fecha: fecha,
        instalacion: widget.instalacion['idInstalacion'],
        duracion: 60,
      );
      setState(() {
        _horas = (res['horas'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        _loadingHoras = false;
      });
    } catch (_) {
      setState(() => _loadingHoras = false);
    }
  }

  /// Determina si la pista es de Fútbol Sala.
  /// Las pistas de Fútbol Sala no se pueden reservar desde la app.
  bool get _esFutbolSala {
    final tipo = (widget.instalacion['tipo'] as String? ?? '').toLowerCase();
    return tipo.contains('fútbol') ||
        tipo.contains('futbol') ||
        tipo.contains('fútbol sala') ||
        tipo.contains('futbol sala');
  }

  @override
  Widget build(BuildContext context) {
    final imagenUrl = widget.instalacion['imagen_url'] as String?;
    final nombre = widget.instalacion['nombre'] ?? '';
    final tipo = widget.instalacion['tipo'] ?? '';
    final ubicacion = widget.instalacion['ubicacion'] as String?;
    final activa = widget.instalacion['estadoPista'] == 'ACTIVA';
    final disponibles = _horas.where((h) => h['disponible'] == true).length;

    return Scaffold(
      // Color de fondo que coincide con el final del degradado
      backgroundColor: const Color(0xFF0D2B1E),
      // Bottom bar: botón de reservar para pádel/tenis, mensaje para fútbol sala
      bottomNavigationBar: activa
          ? Container(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: _esFutbolSala
                      // --- Fútbol Sala: botón para copiar email del admin ---
                      ? _ContactarAdminButton()
                      // --- Pádel/Tenis: botón normal de reservar ---
                      : ElevatedButton(
                          onPressed: () => context
                              .push('/reservar', extra: widget.instalacion)
                              .then((_) => _cargarHoras()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1B4332),
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Reservar esta pista',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                        ),
                ),
              ),
            )
          : null,
      body: Container(
        // Fondo con degradado verde claro → verde oscuro
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF52B788), Color(0xFF2D6A4F), Color(0xFF0D2B1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // --- AppBar con imagen de la pista ---
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.transparent,
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Imagen de la pista o placeholder
                    imagenUrl != null
                        ? CachedNetworkImage(
                            imageUrl: imagenUrl,
                            fit: BoxFit.cover,
                            placeholder: (context, url) =>
                                Container(color: const Color(0xFF1B4332)),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFF1B4332),
                              child: const Icon(Icons.sports_tennis_rounded,
                                  size: 80, color: Colors.white54),
                            ),
                          )
                        : Container(
                            color: const Color(0xFF1B4332),
                            child: const Icon(Icons.sports_tennis_rounded,
                                size: 80, color: Colors.white54),
                          ),
                    // Overlay oscuro en la parte inferior para legibilidad
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0x80000000)],
                        ),
                      ),
                    ),
                    // Nombre y ubicación de la pista
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nombre,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                          if (ubicacion != null)
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 13, color: Colors.white70),
                                const SizedBox(width: 3),
                                Text(ubicacion,
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 13)),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Tipo de pista y horas libres ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        // Badge con el tipo de pista
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(tipo,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                        const Spacer(),
                        // Número de horas disponibles hoy
                        if (!_loadingHoras)
                          Text(
                            '$disponibles horas libres hoy',
                            style: TextStyle(
                              color: disponibles > 0
                                  ? Colors.white
                                  : Colors.redAccent,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // --- Aviso de Fútbol Sala (no reservable desde app) ---
                  if (_esFutbolSala) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          // Fondo naranja semitransparente para destacar el aviso
                          color: Colors.orangeAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: Colors.orangeAccent.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: Colors.orangeAccent, size: 20),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Las reservas de Fútbol Sala se gestionan directamente con el gerente del club.',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // --- Selector horizontal de fechas (14 días) ---
                  SizedBox(
                    height: 70,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: 14,
                      itemBuilder: (context, i) {
                        final dia = DateTime.now().add(Duration(days: i));
                        final selected = _isSameDay(dia, _fechaSeleccionada);
                        return GestureDetector(
                          onTap: () {
                            setState(() => _fechaSeleccionada = dia);
                            _cargarHoras(); // Recargamos horas al cambiar fecha
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              // Blanco si seleccionado, semitransparente si no
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Día de la semana abreviado
                                Text(
                                  DateFormat('EEE', 'es')
                                      .format(dia)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? AppTheme.primary
                                        : Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                // Número del día
                                Text(
                                  '${dia.day}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: selected
                                        ? AppTheme.primary
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Grid de horarios disponibles ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Horarios disponibles',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        if (_loadingHoras)
                          const Center(
                              child:
                                  CircularProgressIndicator(color: Colors.white))
                        else if (_horas.isEmpty)
                          const Center(
                            child: Text(
                              'No hay horarios disponibles para este día',
                              style: TextStyle(color: Colors.white70),
                            ),
                          )
                        else
                          // Chips de horas con color según disponibilidad
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _horas.map((h) {
                              final disponible = h['disponible'] as bool;
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  // Verde semitransparente si disponible, rojo si ocupado
                                  color: disponible
                                      ? Colors.white.withValues(alpha: 0.2)
                                      : Colors.red.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: disponible
                                        ? Colors.white.withValues(alpha: 0.5)
                                        : Colors.redAccent
                                            .withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Text(
                                  h['hora'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: disponible
                                        ? Colors.white
                                        : Colors.redAccent,
                                  ),
                                ),
                              ).animate().fadeIn(
                                    delay: const Duration(milliseconds: 50));
                            }).toList(),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Botón para contactar con el administrador del club.
/// Muestra el email y al pulsarlo lo copia al portapapeles.
/// Se usa en pistas de Fútbol Sala que no se pueden reservar desde la app.
class _ContactarAdminButton extends StatelessWidget {
  static const String emailAdmin = 'azeemmuhammadsultana@gmail.com';

  const _ContactarAdminButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Copiamos el email al portapapeles al pulsar
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          // Fondo semitransparente blanco
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono y título
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline_rounded,
                    color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text(
                  '¿Quieres reservar esta cancha?',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Instrucción y email del admin
            const Text(
              'Contacta con el gerente del club:',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 4),
            // Email resaltado con fondo semitransparente
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    emailAdmin,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  // Icono de copiar
                  const Icon(Icons.copy_rounded,
                      color: Colors.white70, size: 14),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Pulsa para copiar el email',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}