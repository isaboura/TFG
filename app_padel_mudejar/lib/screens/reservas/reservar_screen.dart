import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class ReservarScreen extends StatefulWidget {
  final Map<String, dynamic>? instalacionInicial;

  const ReservarScreen({super.key, this.instalacionInicial});

  @override
  State<ReservarScreen> createState() => _ReservarScreenState();
}

class _ReservarScreenState extends State<ReservarScreen> {
  List<dynamic> _instalaciones = [];
  List<dynamic> _tarifas = [];
  Map<String, dynamic>? _instalacionSeleccionada;
  Map<String, dynamic>? _tarifaSeleccionada;
  DateTime _fechaSeleccionada = DateTime.now();
  String? _horaSeleccionada;
  List<Map<String, dynamic>> _horas = [];

  bool _loadingInstalaciones = true;
  bool _loadingHoras = false;
  bool _guardando = false;

  int _paso = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final inst = await ApiService.getInstalaciones(estado: 'ACTIVA');
      final tar = await ApiService.getTarifas();
      setState(() {
        _instalaciones = inst;
        _tarifas = tar;
        if (widget.instalacionInicial != null) {
          _instalacionSeleccionada = inst.firstWhere(
            (i) =>
                i['idInstalacion'] ==
                widget.instalacionInicial!['idInstalacion'],
            orElse: () => inst.isNotEmpty ? inst[0] : null,
          );
          // Preseleccionar primera tarifa por defecto
          if (tar.isNotEmpty) {
            _tarifaSeleccionada = tar[0];
          }
        }
        _loadingInstalaciones = false;
      });
      // Cargar horas si viene con pista preseleccionada
      if (widget.instalacionInicial != null) {
        _cargarHoras();
      }
    } catch (e) {
      setState(() => _loadingInstalaciones = false);
    }
  }

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
      final horas = (result['horas'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      setState(() {
        _horas = horas;
        _loadingHoras = false;
      });
    } catch (_) {
      setState(() => _loadingHoras = false);
    }
  }

  Future<void> _confirmarReserva() async {
    if (_instalacionSeleccionada == null ||
        _tarifaSeleccionada == null ||
        _horaSeleccionada == null)
      return;

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

  void _mostrarExito() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F8EF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppTheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Reserva confirmada!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
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
              Navigator.of(context, rootNavigator: true).pop();
              context.pop();
            },
            child: const Text(
              'Aceptar',
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppTheme.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Reservar Pista'),
        leading: _paso > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded),
                onPressed: () => setState(() => _paso--),
              )
            : null,
      ),
      body: _loadingInstalaciones
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : Column(
              children: [
                _buildStepIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: [_buildPaso0(), _buildPaso1(), _buildPaso2()][_paso],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStepIndicator() {
    final labels = ['Pista', 'Fecha', 'Confirmar'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        children: List.generate(3, (i) {
          final active = i == _paso;
          final done = i < _paso;
          return Expanded(
            child: Row(
              children: [
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: done ? AppTheme.primary : Colors.grey.shade200,
                    ),
                  ),
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: done || active
                            ? AppTheme.primary
                            : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: done
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : Text(
                                '${i + 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: active
                                      ? Colors.white
                                      : AppTheme.textLight,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 10,
                        color: active || done
                            ? AppTheme.primary
                            : AppTheme.textLight,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                if (i < 2)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i < _paso
                          ? AppTheme.primary
                          : Colors.grey.shade200,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPaso0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.instalacionInicial == null) ...[
          _sectionTitle('Elige una pista'),
          const SizedBox(height: 12),
          ..._instalaciones.map(
            (inst) => _InstalacionCard(
              instalacion: inst,
              selected:
                  _instalacionSeleccionada?['idInstalacion'] ==
                  inst['idInstalacion'],
              onTap: () => setState(() => _instalacionSeleccionada = inst),
            ),
          ),
          const SizedBox(height: 24),
        ],
        _sectionTitle('Elige la duración'),
        const SizedBox(height: 12),
        ..._tarifas.map(
          (tarifa) => _TarifaCard(
            tarifa: tarifa,
            selected: _tarifaSeleccionada?['idTarifa'] == tarifa['idTarifa'],
            onTap: () => setState(() => _tarifaSeleccionada = tarifa),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed:
              (_instalacionSeleccionada != null && _tarifaSeleccionada != null)
              ? () {
                  setState(() => _paso = 1);
                  _cargarHoras();
                }
              : null,
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _buildPaso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Selecciona la fecha'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            focusedDay: _fechaSeleccionada,
            selectedDayPredicate: (day) => isSameDay(day, _fechaSeleccionada),
            onDaySelected: (selected, focused) {
              setState(() => _fechaSeleccionada = selected);
              _cargarHoras();
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
              todayDecoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            locale: 'es_ES',
          ),
        ),
        const SizedBox(height: 24),
        _sectionTitle('Elige una hora'),
        const SizedBox(height: 12),
        if (_loadingHoras)
          const Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          )
        else if (_horas.isEmpty)
          const Center(
            child: Text(
              'No hay horas disponibles para este día',
              style: TextStyle(color: AppTheme.textMedium),
            ),
          )
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
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: !disponible
                        ? Colors.grey.shade100
                        : selected
                        ? AppTheme.primary
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: selected ? AppTheme.primary : Colors.grey.shade200,
                    ),
                  ),
                  child: Text(
                    hora,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: !disponible
                          ? AppTheme.textLight
                          : selected
                          ? Colors.white
                          : AppTheme.textDark,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _horaSeleccionada != null
              ? () => setState(() => _paso = 2)
              : null,
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Confirma tu reserva'),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _resumenRow(
                Icons.sports_tennis_rounded,
                'Pista',
                _instalacionSeleccionada?['nombre'] ?? '',
              ),
              const Divider(height: 24),
              _resumenRow(
                Icons.timer_rounded,
                'Duración',
                '${_tarifaSeleccionada?['duracionMinutos']} min',
              ),
              const Divider(height: 24),
              _resumenRow(
                Icons.calendar_today_rounded,
                'Fecha',
                DateFormat('EEEE d MMMM', 'es').format(_fechaSeleccionada),
              ),
              const Divider(height: 24),
              _resumenRow(
                Icons.access_time_rounded,
                'Hora',
                _horaSeleccionada ?? '',
              ),
              const Divider(height: 24),
              _resumenRow(
                Icons.euro_rounded,
                'Precio',
                '€${_tarifaSeleccionada?['precio']}',
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _guardando ? null : _confirmarReserva,
          child: _guardando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Confirmar reserva'),
        ).animate().fadeIn(delay: 200.ms),
      ],
    );
  }

  Widget _resumenRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMedium, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppTheme.textDark,
      ),
    );
  }
}

class _InstalacionCard extends StatelessWidget {
  final dynamic instalacion;
  final bool selected;
  final VoidCallback onTap;

  const _InstalacionCard({
    required this.instalacion,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.sports_tennis_rounded,
                color: AppTheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    instalacion['nombre'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (instalacion['ubicacion'] != null)
                    Text(
                      instalacion['ubicacion'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
          ],
        ),
      ),
    );
  }
}

class _TarifaCard extends StatelessWidget {
  final dynamic tarifa;
  final bool selected;
  final VoidCallback onTap;

  const _TarifaCard({
    required this.tarifa,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.primary : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.timer_rounded, color: AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${tarifa['nombre']} — ${tarifa['descripcion'] ?? ''}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
            Text(
              '€${tarifa['precio']}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppTheme.primary,
                fontSize: 15,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.check_circle_rounded,
                color: AppTheme.primary,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
