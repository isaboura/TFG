import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

/// Pantalla principal de reservas del socio.
/// Muestra dos pestañas:
/// - Próximas: reservas futuras confirmadas (se pueden editar o cancelar)
/// - Historial: reservas pasadas (se puede dejar reseña si está confirmada)
class MisReservasScreen extends StatefulWidget {
  const MisReservasScreen({super.key});

  @override
  State<MisReservasScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasScreen>
    with SingleTickerProviderStateMixin {
  // Controlador para las pestañas Próximas / Historial
  late TabController _tabController;

  // Datos de reservas cargados desde la API
  Map<String, dynamic>? _datos;

  // Estado de carga inicial
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Inicializamos el TabController con 2 pestañas
    _tabController = TabController(length: 2, vsync: this);
    _cargar();
  }

  @override
  void dispose() {
    // Liberamos el controlador al destruir el widget
    _tabController.dispose();
    super.dispose();
  }

  /// Carga las reservas futuras y pasadas del socio desde la API.
  /// Actualiza [_datos] con el resultado y desactiva el indicador de carga.
  Future<void> _cargar() async {
    final auth = context.read<AuthProvider>();
    try {
      final datos = await ApiService.getReservasSocio(auth.dni);
      setState(() {
        _datos = datos;
        _loading = false;
      });
    } catch (_) {
      // Si hay error, ocultamos el indicador de carga igualmente
      setState(() => _loading = false);
    }
  }

  /// Muestra un diálogo de confirmación antes de cancelar una reserva.
  /// Si el usuario confirma, llama a la API y recarga la lista.
  Future<void> _cancelar(int idReserva) async {
    // Diálogo de confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar reserva'),
        content: const Text('¿Estás seguro de que quieres cancelar esta reserva?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí, cancelar', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );

    // Si el usuario cancela el diálogo, salimos
    if (confirm != true) return;

    // Llamada a la API para cancelar la reserva
    final result = await ApiService.cancelarReserva(idReserva);
    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reserva cancelada'), backgroundColor: AppTheme.primary),
        );
        _cargar(); // Recargamos la lista tras cancelar
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['mensaje'] ?? 'Error al cancelar'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  /// Abre el bottom sheet [_EditarReservaBottomSheet] para modificar
  /// la pista, tarifa, fecha y hora de una reserva existente.
  void _mostrarEditarReserva(dynamic reserva) {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => _EditarReservaBottomSheet(
        reserva: reserva,
        dniSocio: auth.dni,
        onActualizada: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reserva actualizada'), backgroundColor: AppTheme.primary),
          );
          _cargar(); // Recargamos tras actualizar
        },
      ),
    );
  }

  /// Abre el bottom sheet [_ResenaBottomSheet] para que el socio
  /// deje una reseña de la pista tras haber jugado.
  void _mostrarBottomSheetResena(dynamic reserva) {
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ResenaBottomSheet(
        idInstalacion: reserva['idInstalacion'] ?? '',
        nombreInstalacion: reserva['instalacion'] ?? '',
        nombreAutor: auth.nombreCompleto,
        dniSocio: auth.dni,
        onEnviada: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Reseña enviada! Gracias por tu opinión'),
              backgroundColor: AppTheme.primary,
            ),
          );
        },
      ),
    );
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
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : NestedScrollView(
                // NestedScrollView permite que el SliverAppBar se oculte
                // automáticamente al hacer scroll hacia abajo y reaparezca al subir
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    // floating: true → el AppBar aparece al empezar a subir
                    // snap: true → aparece completamente de golpe, no a medias
                    floating: true,
                    snap: true,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    // Título de la pantalla en blanco
                    title: const Text(
                      'Mis Reservas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    // TabBar con las pestañas Próximas e Historial
                    bottom: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(text: 'Próximas (${_datos?['totalFuturas'] ?? 0})'),
                        Tab(text: 'Historial (${_datos?['totalPasadas'] ?? 0})'),
                      ],
                    ),
                  ),
                ],
                // Contenido de cada pestaña
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // Pestaña de reservas próximas
                    _buildLista(
                      (_datos?['futuras'] as List<dynamic>? ?? []),
                      futuras: true,
                    ),
                    // Pestaña de historial
                    _buildLista(
                      (_datos?['pasadas'] as List<dynamic>? ?? []),
                      futuras: false,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// Construye la lista de tarjetas de reserva para cada pestaña.
  /// [futuras] determina si mostramos botones de editar/cancelar o de reseña.
  Widget _buildLista(List<dynamic> reservas, {required bool futuras}) {
    // Estado vacío con icono y mensaje descriptivo
    if (reservas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              futuras ? Icons.calendar_today_rounded : Icons.history_rounded,
              size: 60,
              color: Colors.white30,
            ),
            const SizedBox(height: 16),
            Text(
              futuras ? 'No tienes reservas próximas' : 'No tienes historial',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Lista con pull-to-refresh
    return RefreshIndicator(
      onRefresh: _cargar,
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservas.length,
        itemBuilder: (context, i) {
          final r = reservas[i];
          return _ReservaCard(
            reserva: r,
            // Solo mostramos cancelar en futuras confirmadas
            mostrarCancelar: futuras && r['estado'] == 'CONFIRMADA',
            // Solo mostramos editar en futuras confirmadas
            mostrarEditar: futuras && r['estado'] == 'CONFIRMADA',
            // Solo mostramos reseña en pasadas confirmadas
            mostrarResena: !futuras && r['estado'] == 'CONFIRMADA',
            onCancelar: () => _cancelar(r['idReserva']),
            onEditar: () => _mostrarEditarReserva(r),
            onResena: () => _mostrarBottomSheetResena(r),
          )
              .animate()
              .fadeIn(delay: Duration(milliseconds: i * 80))
              .slideY(begin: 0.1, end: 0);
        },
      ),
    );
  }
}

/// Tarjeta individual que muestra los datos de una reserva.
/// Incluye nombre de la pista, fecha, tarifa, precio y estado.
/// Opcionalmente muestra botones de editar/cancelar o de reseña.
class _ReservaCard extends StatelessWidget {
  final dynamic reserva;
  final bool mostrarCancelar;
  final bool mostrarEditar;
  final bool mostrarResena;
  final VoidCallback onCancelar;
  final VoidCallback onEditar;
  final VoidCallback onResena;

  const _ReservaCard({
    required this.reserva,
    required this.mostrarCancelar,
    required this.mostrarEditar,
    required this.mostrarResena,
    required this.onCancelar,
    required this.onEditar,
    required this.onResena,
  });

  /// Devuelve el color del badge según el estado de la reserva.
  /// CONFIRMADA → verde, CANCELADA → rojo, otros → gris
  Color _estadoColor(String estado) {
    switch (estado) {
      case 'CONFIRMADA':
        return AppTheme.primary;
      case 'CANCELADA':
        return AppTheme.danger;
      default:
        return AppTheme.textMedium;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = reserva['estado'] as String? ?? '';
    final fechaStr = reserva['fechaHora'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Las tarjetas se mantienen blancas sobre el fondo verde degradado
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Cabecera: icono + nombre de pista + badge de estado ---
          Row(
            children: [
              // Icono de pista con fondo verde claro
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sports_tennis_rounded, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 12),
              // Nombre de la instalación
              Expanded(
                child: Text(
                  reserva['instalacion'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark),
                ),
              ),
              // Badge de estado (CONFIRMADA / CANCELADA)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _estadoColor(estado).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estado,
                  style: TextStyle(color: _estadoColor(estado), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // --- Información: fecha, tarifa y precio ---
          Row(
            children: [
              _infoChip(Icons.calendar_today_rounded, fechaStr),
              const SizedBox(width: 12),
              _infoChip(Icons.timer_rounded, reserva['tarifa'] ?? ''),
            ],
          ),
          const SizedBox(height: 8),
          _infoChip(Icons.euro_rounded, '€${reserva['precio'] ?? '0'}'),

          // --- Botones de Editar y Cancelar (solo reservas futuras confirmadas) ---
          if (mostrarEditar || mostrarCancelar) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                if (mostrarEditar)
                  Expanded(
                    child: GestureDetector(
                      onTap: onEditar,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_rounded, color: AppTheme.secondary, size: 16),
                          SizedBox(width: 6),
                          Text('Editar',
                              style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                // Separador vertical entre botones
                if (mostrarEditar && mostrarCancelar)
                  Container(width: 1, height: 20, color: Colors.grey.shade200),
                if (mostrarCancelar)
                  Expanded(
                    child: GestureDetector(
                      onTap: onCancelar,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cancel_outlined, color: AppTheme.danger, size: 16),
                          SizedBox(width: 6),
                          Text('Cancelar',
                              style: TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // --- Botón de reseña (solo reservas pasadas confirmadas) ---
          if (mostrarResena) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onResena,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star_rounded, color: AppTheme.accent, size: 18),
                  const SizedBox(width: 6),
                  Text('Dejar reseña',
                      style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Pequeño chip de información con un icono y un texto descriptivo.
  /// Se usa para mostrar fecha, tarifa y precio de forma compacta.
  Widget _infoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.textMedium),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: AppTheme.textMedium, fontSize: 13)),
      ],
    );
  }
}

/// Bottom sheet para editar una reserva existente en 3 pasos:
/// Paso 0: Elegir pista y duración
/// Paso 1: Elegir fecha y hora
/// Paso 2: Confirmar los cambios
class _EditarReservaBottomSheet extends StatefulWidget {
  final dynamic reserva;     // Datos de la reserva a editar
  final String dniSocio;     // DNI del socio para la llamada a la API
  final VoidCallback onActualizada; // Callback cuando la reserva se actualiza

  const _EditarReservaBottomSheet({
    required this.reserva,
    required this.dniSocio,
    required this.onActualizada,
  });

  @override
  State<_EditarReservaBottomSheet> createState() => _EditarReservaBottomSheetState();
}

class _EditarReservaBottomSheetState extends State<_EditarReservaBottomSheet> {
  // Listas de instalaciones y tarifas cargadas de la API
  List<dynamic> _instalaciones = [];
  List<dynamic> _tarifas = [];

  // Selecciones del usuario
  Map<String, dynamic>? _instalacionSeleccionada;
  Map<String, dynamic>? _tarifaSeleccionada;
  DateTime _fechaSeleccionada = DateTime.now().add(const Duration(days: 1));
  String? _horaSeleccionada;
  List<Map<String, dynamic>> _horas = [];

  // Estados de carga
  bool _loading = true;
  bool _loadingHoras = false;
  bool _guardando = false;

  // Paso actual del flujo (0, 1, 2)
  int _paso = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  /// Carga instalaciones y tarifas desde la API.
  /// Preselecciona automáticamente las que tenía la reserva original.
  Future<void> _cargarDatos() async {
    try {
      final inst = await ApiService.getInstalaciones(estado: 'ACTIVA');
      final tar = await ApiService.getTarifas();
      setState(() {
        _instalaciones = inst;
        _tarifas = tar;
        // Preseleccionamos la instalación de la reserva original
        _instalacionSeleccionada = inst.firstWhere(
          (i) => i['idInstalacion'] == widget.reserva['idInstalacion'],
          orElse: () => inst.isNotEmpty ? inst[0] : null,
        );
        // Preseleccionamos la tarifa de la reserva original por nombre
        _tarifaSeleccionada = tar.firstWhere(
          (t) => t['nombre'] == widget.reserva['tarifa'],
          orElse: () => tar.isNotEmpty ? tar[0] : null,
        );
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  /// Carga las horas disponibles para la instalación, tarifa y fecha seleccionadas.
  Future<void> _cargarHoras() async {
    if (_instalacionSeleccionada == null || _tarifaSeleccionada == null) return;
    setState(() {
      _loadingHoras = true;
      _horaSeleccionada = null; // Reseteamos la hora al cambiar fecha/pista/tarifa
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
        _horas = (result['horas'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _loadingHoras = false;
      });
    } catch (_) {
      setState(() => _loadingHoras = false);
    }
  }

  /// Envía los nuevos datos a la API para reagendar la reserva.
  /// Cierra el bottom sheet y llama a [onActualizada] si tiene éxito.
  Future<void> _guardar() async {
    if (_instalacionSeleccionada == null || _tarifaSeleccionada == null || _horaSeleccionada == null) return;
    setState(() => _guardando = true);

    // Formateamos la fecha y hora para la API
    final fecha = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
    final fechaHora = '$fecha $_horaSeleccionada:00';

    try {
      final result = await ApiService.reagendarReserva(widget.reserva['idReserva'], {
        'dniSocio': widget.dniSocio,
        'instalacion': _instalacionSeleccionada!['idInstalacion'],
        'idTarifa': _tarifaSeleccionada!['idTarifa'],
        'fechaHora': fechaHora,
      });
      if (mounted) {
        Navigator.pop(context); // Cerramos el bottom sheet
        if (result['success'] == true) {
          widget.onActualizada(); // Notificamos el éxito
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Error al actualizar'), backgroundColor: AppTheme.danger),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      // Altura del 75% de la pantalla para el bottom sheet
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle visual del bottom sheet (línea gris arriba)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          // Cabecera con botón de retroceso y título del paso actual
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Botón de retroceso (visible desde el paso 1 en adelante)
                if (_paso > 0)
                  GestureDetector(
                    onTap: () => setState(() => _paso--),
                    child: const Icon(Icons.arrow_back_ios_rounded, size: 18, color: AppTheme.textDark),
                  ),
                const SizedBox(width: 8),
                // Título dinámico según el paso actual
                Text(
                  _paso == 0
                      ? 'Editar reserva — Pista'
                      : _paso == 1
                          ? 'Editar reserva — Fecha'
                          : 'Confirmar cambios',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Contenido del paso actual
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: _paso == 0
                        ? _buildPaso0()
                        : _paso == 1
                            ? _buildPaso1()
                            : _buildPaso2(),
                  ),
          ),
        ],
      ),
    );
  }

  /// Paso 0: Selector de pista y duración/tarifa.
  Widget _buildPaso0() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Elige una pista',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
        const SizedBox(height: 12),
        // Lista de instalaciones disponibles
        ..._instalaciones.map((inst) => GestureDetector(
              onTap: () => setState(() => _instalacionSeleccionada = inst),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  // Resaltado verde si está seleccionada
                  color: _instalacionSeleccionada?['idInstalacion'] == inst['idInstalacion']
                      ? AppTheme.primary.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _instalacionSeleccionada?['idInstalacion'] == inst['idInstalacion']
                        ? AppTheme.primary
                        : Colors.grey.shade200,
                    width: _instalacionSeleccionada?['idInstalacion'] == inst['idInstalacion'] ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sports_tennis_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(inst['nombre'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                    // Check de selección
                    if (_instalacionSeleccionada?['idInstalacion'] == inst['idInstalacion'])
                      const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 20),
        const Text('Elige la duración',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
        const SizedBox(height: 12),
        // Lista de tarifas disponibles
        ..._tarifas.map((tar) => GestureDetector(
              onTap: () => setState(() => _tarifaSeleccionada = tar),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _tarifaSeleccionada?['idTarifa'] == tar['idTarifa']
                      ? AppTheme.primary.withValues(alpha: 0.08)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _tarifaSeleccionada?['idTarifa'] == tar['idTarifa'] ? AppTheme.primary : Colors.grey.shade200,
                    width: _tarifaSeleccionada?['idTarifa'] == tar['idTarifa'] ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.timer_rounded, color: AppTheme.primary, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text('${tar['nombre']}',
                            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14))),
                    // Precio de la tarifa
                    Text('€${tar['precio']}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    if (_tarifaSeleccionada?['idTarifa'] == tar['idTarifa']) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.check_circle_rounded, color: AppTheme.primary, size: 20),
                    ],
                  ],
                ),
              ),
            )),
        const SizedBox(height: 24),
        // Botón continuar — solo activo si hay pista y tarifa seleccionadas
        ElevatedButton(
          onPressed: (_instalacionSeleccionada != null && _tarifaSeleccionada != null)
              ? () {
                  setState(() => _paso = 1);
                  _cargarHoras(); // Cargamos horas para la nueva selección
                }
              : null,
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  /// Paso 1: Selector de fecha con calendario y selector de hora disponible.
  Widget _buildPaso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Selecciona la fecha',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
        const SizedBox(height: 12),
        // Calendario para elegir el día
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: TableCalendar(
            // Solo permitimos fechas desde mañana en adelante
            firstDay: DateTime.now().add(const Duration(days: 1)),
            lastDay: DateTime.now().add(const Duration(days: 60)),
            focusedDay: _fechaSeleccionada,
            selectedDayPredicate: (day) => isSameDay(day, _fechaSeleccionada),
            onDaySelected: (selected, focused) {
              setState(() => _fechaSeleccionada = selected);
              _cargarHoras(); // Recargamos horas al cambiar fecha
            },
            calendarStyle: CalendarStyle(
              selectedDecoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
              todayDecoration:
                  BoxDecoration(color: AppTheme.primary.withValues(alpha: 0.3), shape: BoxShape.circle),
            ),
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            locale: 'es_ES',
          ),
        ),
        const SizedBox(height: 20),
        const Text('Elige una hora',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
        const SizedBox(height: 12),
        // Grid de horas disponibles
        if (_loadingHoras)
          const Center(child: CircularProgressIndicator(color: AppTheme.primary))
        else if (_horas.isEmpty)
          const Center(child: Text('No hay horas disponibles', style: TextStyle(color: AppTheme.textMedium)))
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _horas.map((h) {
              final hora = h['hora'] as String;
              final disponible = h['disponible'] as bool;
              final selected = _horaSeleccionada == hora;
              return GestureDetector(
                onTap: disponible ? () => setState(() => _horaSeleccionada = hora) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    // Gris si no disponible, verde si seleccionada, blanco si disponible
                    color: !disponible
                        ? Colors.grey.shade100
                        : selected
                            ? AppTheme.primary
                            : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? AppTheme.primary : Colors.grey.shade200),
                  ),
                  child: Text(hora,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !disponible
                              ? AppTheme.textLight
                              : selected
                                  ? Colors.white
                                  : AppTheme.textDark)),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 24),
        // Botón continuar — solo activo si hay hora seleccionada
        ElevatedButton(
          onPressed: _horaSeleccionada != null ? () => setState(() => _paso = 2) : null,
          child: const Text('Continuar'),
        ),
      ],
    );
  }

  /// Paso 2: Resumen de los cambios antes de confirmar.
  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Confirma los cambios',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
        const SizedBox(height: 16),
        // Tarjeta resumen con todos los detalles de la nueva reserva
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              _resumenRow(Icons.sports_tennis_rounded, 'Pista', _instalacionSeleccionada?['nombre'] ?? ''),
              const Divider(height: 24),
              _resumenRow(Icons.timer_rounded, 'Duración', '${_tarifaSeleccionada?['duracionMinutos']} min'),
              const Divider(height: 24),
              _resumenRow(Icons.calendar_today_rounded, 'Fecha',
                  DateFormat('EEEE d MMMM', 'es').format(_fechaSeleccionada)),
              const Divider(height: 24),
              _resumenRow(Icons.access_time_rounded, 'Hora', _horaSeleccionada ?? ''),
              const Divider(height: 24),
              _resumenRow(Icons.euro_rounded, 'Precio', '€${_tarifaSeleccionada?['precio']}'),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Botón de confirmación final
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          child: _guardando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Confirmar cambios'),
        ),
      ],
    );
  }

  /// Fila del resumen con icono, etiqueta descriptiva y valor.
  Widget _resumenRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: AppTheme.textMedium, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}

/// Bottom sheet para dejar una reseña tras una partida.
/// Permite elegir una puntuación de 1 a 5 estrellas y añadir un comentario opcional.
class _ResenaBottomSheet extends StatefulWidget {
  final String idInstalacion;      // ID de la pista a reseñar
  final String nombreInstalacion;  // Nombre de la pista (para mostrar al usuario)
  final String nombreAutor;        // Nombre completo del socio
  final String dniSocio;           // DNI del socio para la API
  final VoidCallback onEnviada;    // Callback cuando la reseña se envía con éxito

  const _ResenaBottomSheet({
    required this.idInstalacion,
    required this.nombreInstalacion,
    required this.nombreAutor,
    required this.dniSocio,
    required this.onEnviada,
  });

  @override
  State<_ResenaBottomSheet> createState() => _ResenaBottomSheetState();
}

class _ResenaBottomSheetState extends State<_ResenaBottomSheet> {
  // Puntuación seleccionada (1-5), por defecto 5 estrellas
  int _puntuacion = 5;
  final _comentarioCtrl = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    // Liberamos el controlador de texto
    _comentarioCtrl.dispose();
    super.dispose();
  }

  /// Envía la reseña a la API con la puntuación y el comentario del usuario.
  Future<void> _enviar() async {
    setState(() => _enviando = true);
    try {
      final result = await ApiService.crearResena(widget.idInstalacion, {
        'nombreAutor': widget.nombreAutor,
        'puntuacion': _puntuacion,
        'comentario': _comentarioCtrl.text.trim(),
        'dniSocio': widget.dniSocio,
      });
      if (mounted) {
        Navigator.pop(context); // Cerramos el bottom sheet
        if (result['success'] == true) {
          widget.onEnviada(); // Notificamos el éxito
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result['message'] ?? 'Error al enviar reseña'),
                backgroundColor: AppTheme.danger),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error de conexión'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Añadimos el padding del teclado para que no tape el formulario
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle visual del bottom sheet
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          const Text('¿Cómo fue tu partida?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const SizedBox(height: 4),
          // Nombre de la pista reseñada
          Text(widget.nombreInstalacion,
              style: const TextStyle(color: AppTheme.textMedium, fontSize: 14)),
          const SizedBox(height: 24),
          const Text('Puntuación',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 10),
          // Selector de estrellas (1 a 5)
          Row(
            children: List.generate(5, (i) {
              final estrella = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _puntuacion = estrella),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    estrella <= _puntuacion ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppTheme.accent,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          const Text('Comentario (opcional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          const SizedBox(height: 10),
          // Campo de texto para el comentario (máximo 500 caracteres)
          TextField(
            controller: _comentarioCtrl,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Cuéntanos tu experiencia...',
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          // Botón de envío con indicador de carga
          ElevatedButton(
            onPressed: _enviando ? null : _enviar,
            child: _enviando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Enviar reseña'),
          ),
        ],
      ),
    );
  }
}