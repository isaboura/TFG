import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

/// Pantalla principal para crear una nueva reserva.
/// Tiene 3 pasos: elegir pista/duración → elegir fecha/hora → confirmar.
/// Puede recibir una [instalacionInicial] si el usuario viene desde el detalle de una pista.
/// Las tarifas se filtran según el tipo de pista seleccionada:
/// - Pádel → tarifas de pádel y generales
/// - Tenis → tarifas de tenis y generales
/// - Fútbol Sala → no se puede reservar desde la app
class ReservarScreen extends StatefulWidget {
  final Map<String, dynamic>? instalacionInicial;

  const ReservarScreen({super.key, this.instalacionInicial});

  @override
  State<ReservarScreen> createState() => _ReservarScreenState();
}

class _ReservarScreenState extends State<ReservarScreen> {
  // --- Datos cargados de la API ---
  List<dynamic> _instalaciones = [];
  List<dynamic> _tarifas = []; // Todas las tarifas sin filtrar

  // --- Selecciones del usuario ---
  Map<String, dynamic>? _instalacionSeleccionada;
  Map<String, dynamic>? _tarifaSeleccionada;
  DateTime _fechaSeleccionada = DateTime.now();
  String? _horaSeleccionada;
  List<Map<String, dynamic>> _horas = [];

  // --- Estados de carga ---
  bool _loadingInstalaciones = true;
  bool _loadingHoras = false;
  bool _guardando = false;

  // --- Paso actual del flujo (0, 1, 2) ---
  int _paso = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  /// Devuelve las tarifas filtradas según el tipo de la instalación seleccionada.
  /// - Pádel → tarifas cuyo tipo_pista sea 'Pádel' o null (generales)
  /// - Tenis → tarifas cuyo tipo_pista sea 'Tenis' o null (generales)
  /// - Otros → todas las tarifas
  List<dynamic> get _tarifasFiltradas {
    if (_instalacionSeleccionada == null) return _tarifas;
    final tipoPista =
        (_instalacionSeleccionada!['tipo'] as String? ?? '').toLowerCase();

    return _tarifas.where((t) {
      final tipoPistaApi =
          (t['tipo_pista'] as String? ?? '').toLowerCase();
      // Las tarifas generales (tipo_pista null o vacío) aplican a todas
      if (tipoPistaApi.isEmpty) return true;
      // Filtramos por tipo de pista
      if (tipoPista.contains('pádel') || tipoPista.contains('padel')) {
        return tipoPistaApi.contains('pádel') ||
            tipoPistaApi.contains('padel');
      }
      if (tipoPista.contains('tenis')) {
        return tipoPistaApi.contains('tenis');
      }
      // Para cualquier otro tipo, mostramos todas
      return true;
    }).toList();
  }

  /// Carga las instalaciones y tarifas desde la API.
  /// Si viene con una instalación preseleccionada, la marca y carga las horas disponibles.
  Future<void> _cargarDatos() async {
    try {
      final inst = await ApiService.getInstalaciones(estado: 'ACTIVA');
      final tar = await ApiService.getTarifas();
      setState(() {
        _instalaciones = inst;
        _tarifas = tar;
        // Si viene desde el detalle de una pista, preseleccionamos esa pista
        if (widget.instalacionInicial != null) {
          _instalacionSeleccionada = inst.firstWhere(
            (i) =>
                i['idInstalacion'] ==
                widget.instalacionInicial!['idInstalacion'],
            orElse: () => inst.isNotEmpty ? inst[0] : null,
          );
          // Preseleccionamos la primera tarifa filtrada por defecto
          final filtradas = _tarifasFiltradas;
          if (filtradas.isNotEmpty) _tarifaSeleccionada = filtradas[0];
        }
        _loadingInstalaciones = false;
      });
      // Si hay pista preseleccionada, cargamos las horas directamente
      if (widget.instalacionInicial != null) _cargarHoras();
    } catch (e) {
      setState(() => _loadingInstalaciones = false);
    }
  }

  /// Carga las horas disponibles para la instalación, tarifa y fecha seleccionadas.
  Future<void> _cargarHoras() async {
    if (_instalacionSeleccionada == null || _tarifaSeleccionada == null) return;
    setState(() {
      _loadingHoras = true;
      _horaSeleccionada = null;
      _horas = [];
    });
    try {
      final fecha = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
      final result = await ApiService.getHorasDisponibles(
        fecha: fecha,
        instalacion: _instalacionSeleccionada!['idInstalacion'],
        duracion: _tarifaSeleccionada!['duracionMinutos'],
      );
      setState(() {
        _horas = (result['horas'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();
        _loadingHoras = false;
      });
    } catch (_) {
      setState(() => _loadingHoras = false);
    }
  }

  /// Envía la reserva a la API y muestra el resultado al usuario.
  Future<void> _confirmarReserva() async {
    if (_instalacionSeleccionada == null ||
        _tarifaSeleccionada == null ||
        _horaSeleccionada == null) return;
    setState(() => _guardando = true);

    final auth = context.read<AuthProvider>();
    final fecha = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
    final fechaHora = '$fecha $_horaSeleccionada';

    try {
      final result = await ApiService.crearReserva(
        dniSocio: auth.dni,
        instalacion: _instalacionSeleccionada!['idInstalacion'],
        idTarifa: _tarifaSeleccionada!['idTarifa'],
        fechaHora: fechaHora,
      );
      if (!mounted) return;
      if (result['success'] == true) {
        _mostrarExito();
      } else {
        _mostrarError(result['message'] ?? 'Error al crear la reserva');
      }
    } catch (e) {
      if (mounted) _mostrarError('Error de conexión');
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Muestra un diálogo de confirmación con los detalles de la reserva creada.
  /// Al aceptar recarga las horas y vuelve al paso 1.
  void _mostrarExito() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono de check en círculo verde
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                  color: Color(0xFFE8F8EF), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded,
                  color: AppTheme.primary, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('¡Reserva confirmada!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            // Detalles de la reserva creada
            Text(
              '${_instalacionSeleccionada!['nombre']}\n'
              '${DateFormat('EEEE d MMMM', 'es').format(_fechaSeleccionada)} a las $_horaSeleccionada',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMedium, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop(); // Cierra el diálogo
              // Volvemos al paso 1 y recargamos las horas actualizadas
              setState(() {
                _paso = 1;
                _horaSeleccionada = null;
                _horas = [];
              });
              _cargarHoras();
            },
            child: const Text('Aceptar',
                style: TextStyle(color: AppTheme.primary)),
          ),
        ],
      ),
    );
  }

  /// Muestra un snackbar con el mensaje de error.
  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Color de fondo que coincide con el inicio del degradado
      backgroundColor: const Color(0xFF52B788),
      appBar: AppBar(
        title: const Text('Reservar Pista',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        // Botón de atrás solo disponible si no estamos en el paso 0
        leading: _paso > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => setState(() => _paso--),
              )
            : null,
      ),
      body: Container(
        // Fondo con degradado verde claro → verde oscuro
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF52B788), Color(0xFF2D6A4F), Color(0xFF0D2B1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _loadingInstalaciones
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Column(
                children: [
                  // Indicador de pasos (1, 2, 3)
                  _buildStepIndicator(),
                  // Contenido del paso actual
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: [_buildPaso0(), _buildPaso1(), _buildPaso2()][_paso],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Construye el indicador de progreso con los 3 pasos.
  Widget _buildStepIndicator() {
    final labels = ['Pista', 'Fecha', 'Confirmar'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (i) {
          final active = i == _paso; // Paso actual
          final done = i < _paso;   // Paso ya completado
          return Expanded(
            child: Row(
              children: [
                // Línea conectora izquierda
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: done
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                // Círculo del paso
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: done || active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(Icons.check,
                                color: Color(0xFF1B4332), size: 14)
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? const Color(0xFF1B4332)
                                      : Colors.white60,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: active || done ? Colors.white : Colors.white60,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                // Línea conectora derecha
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < _paso
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// Paso 0: Selección de pista (si no viene preseleccionada) y duración/tarifa.
  /// Las tarifas se filtran automáticamente según el tipo de pista seleccionada.
  Widget _buildPaso0() {
    // Tarifas filtradas según el tipo de la pista seleccionada
    final tarifasFiltradas = _tarifasFiltradas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Solo mostramos el selector de pista si no viene preseleccionada
        if (widget.instalacionInicial == null) ...[
          _sectionTitle('Elige una pista'),
          const SizedBox(height: 12),
          ..._instalaciones.map((inst) => _InstalacionCard(
                instalacion: inst,
                selected: _instalacionSeleccionada?['idInstalacion'] ==
                    inst['idInstalacion'],
                onTap: () => setState(() {
                  _instalacionSeleccionada = inst;
                  // Reseteamos la tarifa al cambiar de pista para forzar nueva selección
                  _tarifaSeleccionada = null;
                }),
              )),
          const SizedBox(height: 24),
        ],
        _sectionTitle('Elige la duración'),
        const SizedBox(height: 12),
        // Mostramos solo las tarifas compatibles con la pista seleccionada
        if (tarifasFiltradas.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Text(
              'No hay tarifas disponibles para esta pista',
              style: TextStyle(color: Colors.white70),
            ),
          )
        else
          ...tarifasFiltradas.map((tarifa) => _TarifaCard(
                tarifa: tarifa,
                selected:
                    _tarifaSeleccionada?['idTarifa'] == tarifa['idTarifa'],
                onTap: () => setState(() => _tarifaSeleccionada = tarifa),
              )),
        const SizedBox(height: 32),
        // Botón continuar — solo activo si hay pista y tarifa seleccionadas
        ElevatedButton(
          onPressed:
              (_instalacionSeleccionada != null && _tarifaSeleccionada != null)
                  ? () {
                      setState(() => _paso = 1);
                      _cargarHoras();
                    }
                  : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1B4332),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('Continuar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      ],
    );
  }

  /// Paso 1: Selección de fecha con calendario y hora disponible.
  Widget _buildPaso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Selecciona la fecha'),
        const SizedBox(height: 12),
        // Calendario con estilo adaptado al fondo verde
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            focusedDay: _fechaSeleccionada,
            selectedDayPredicate: (day) => isSameDay(day, _fechaSeleccionada),
            onDaySelected: (selected, focused) {
              setState(() => _fechaSeleccionada = selected);
              _cargarHoras(); // Recargamos horas al cambiar fecha
            },
            calendarStyle: CalendarStyle(
              // Día seleccionado en blanco con texto verde
              selectedDecoration: const BoxDecoration(
                  color: Colors.white, shape: BoxShape.circle),
              selectedTextStyle: const TextStyle(
                  color: Color(0xFF1B4332), fontWeight: FontWeight.w700),
              todayDecoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle),
              todayTextStyle: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w700),
              defaultTextStyle: const TextStyle(color: Colors.white),
              weekendTextStyle: const TextStyle(color: Colors.white70),
              outsideTextStyle: const TextStyle(color: Colors.white38),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
              leftChevronIcon:
                  Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon:
                  Icon(Icons.chevron_right, color: Colors.white),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white70, fontSize: 12),
              weekendStyle: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            locale: 'es_ES',
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Elige una hora'),
        const SizedBox(height: 12),
        // Grid de horas disponibles con estilo semitransparente
        if (_loadingHoras)
          const Center(child: CircularProgressIndicator(color: Colors.white))
        else if (_horas.isEmpty)
          const Center(
              child: Text('No hay horas disponibles para este día',
                  style: TextStyle(color: Colors.white70)))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _horas.map((h) {
              final hora = h['hora'] as String;
              final disponible = h['disponible'] as bool;
              final selected = _horaSeleccionada == hora;
              return GestureDetector(
                onTap: disponible
                    ? () => setState(() => _horaSeleccionada = hora)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    // Blanco si seleccionado, semitransparente si disponible
                    color: !disponible
                        ? Colors.white.withValues(alpha: 0.05)
                        : selected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(hora,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: !disponible
                            ? Colors.white30
                            : selected
                                ? const Color(0xFF1B4332)
                                : Colors.white,
                      )),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 32),
        // Botón continuar — solo activo si hay hora seleccionada
        ElevatedButton(
          onPressed: _horaSeleccionada != null
              ? () => setState(() => _paso = 2)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1B4332),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('Continuar',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        ),
      ],
    );
  }

  /// Paso 2: Resumen de la reserva y confirmación final.
  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Confirma tu reserva'),
        const SizedBox(height: 20),
        // Tarjeta resumen semitransparente con todos los datos
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _resumenRow(Icons.sports_tennis_rounded, 'Pista',
                  _instalacionSeleccionada?['nombre'] ?? ''),
              Divider(
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.2)),
              _resumenRow(Icons.timer_rounded, 'Duración',
                  '${_tarifaSeleccionada?['duracionMinutos']} min'),
              Divider(
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.2)),
              _resumenRow(
                  Icons.calendar_today_rounded,
                  'Fecha',
                  DateFormat('EEEE d MMMM', 'es')
                      .format(_fechaSeleccionada)),
              Divider(
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.2)),
              _resumenRow(Icons.access_time_rounded, 'Hora',
                  _horaSeleccionada ?? ''),
              Divider(
                  height: 24,
                  color: Colors.white.withValues(alpha: 0.2)),
              _resumenRow(Icons.euro_rounded, 'Precio',
                  '€${_tarifaSeleccionada?['precio']}'),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        const SizedBox(height: 32),
        // Botón de confirmación final
        ElevatedButton(
          onPressed: _guardando ? null : _confirmarReserva,
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
              : const Text('Confirmar reserva',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16)),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  /// Fila de resumen con icono, etiqueta y valor en blanco.
  Widget _resumenRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
      ],
    );
  }

  /// Título de sección en blanco.
  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white));
  }
}

/// Tarjeta para seleccionar una instalación/pista.
/// Se resalta en blanco cuando está seleccionada.
class _InstalacionCard extends StatelessWidget {
  final dynamic instalacion;
  final bool selected;
  final VoidCallback onTap;

  const _InstalacionCard(
      {required this.instalacion,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          // Blanco si seleccionada, semitransparente si no
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.sports_tennis_rounded,
                color: selected
                    ? const Color(0xFF1B4332)
                    : Colors.white70,
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre de la pista
                  Text(instalacion['nombre'] ?? '',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: selected
                              ? const Color(0xFF1B4332)
                              : Colors.white)),
                  // Ubicación si existe
                  if (instalacion['ubicacion'] != null)
                    Text(instalacion['ubicacion'],
                        style: TextStyle(
                            fontSize: 12,
                            color: selected
                                ? const Color(0xFF2D6A4F)
                                : Colors.white60)),
                ],
              ),
            ),
            // Check de seleccionado
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF1B4332)),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta para seleccionar una tarifa/duración.
/// Solo se muestran las tarifas compatibles con el tipo de pista seleccionada.
class _TarifaCard extends StatelessWidget {
  final dynamic tarifa;
  final bool selected;
  final VoidCallback onTap;

  const _TarifaCard(
      {required this.tarifa,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.2),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.timer_rounded,
                color: selected
                    ? const Color(0xFF1B4332)
                    : Colors.white70,
                size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                // Nombre y descripción de la tarifa
                '${tarifa['nombre']} — ${tarifa['descripcion'] ?? ''}',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: selected
                        ? const Color(0xFF1B4332)
                        : Colors.white),
              ),
            ),
            // Precio de la tarifa
            Text('€${tarifa['precio']}',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF1B4332)
                        : Colors.white,
                    fontSize: 15)),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF1B4332), size: 20),
            ],
          ],
        ),
      ),
    );
  }
}