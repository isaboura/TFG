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
/// Todo tiene el degradado verde de la app, incluyendo cards y bottom sheets.
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
  Future<void> _cargar() async {
    final auth = context.read<AuthProvider>();
    try {
      final datos = await ApiService.getReservasSocio(auth.dni);
      setState(() {
        _datos = datos;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  /// Muestra un diálogo de confirmación antes de cancelar una reserva.
  /// Si el usuario confirma, llama a la API y recarga la lista.
  Future<void> _cancelar(int idReserva) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancelar reserva'),
        content: const Text(
          '¿Estás seguro de que quieres cancelar esta reserva?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    // Llamada a la API para cancelar la reserva
    final result = await ApiService.cancelarReserva(idReserva);
    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reserva cancelada'),
            backgroundColor: AppTheme.primary,
          ),
        );
        _cargar(); // Recargamos la lista tras cancelar
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['mensaje'] ?? 'Error al cancelar'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    }
  }

  /// Abre el bottom sheet con degradado para editar una reserva.
  /// Al actualizarse, recarga la lista de reservas.
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
            const SnackBar(
              content: Text('Reserva actualizada'),
              backgroundColor: AppTheme.primary,
            ),
          );
          _cargar();
        },
      ),
    );
  }

  /// Abre el bottom sheet con degradado para dejar una reseña.
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
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : NestedScrollView(
                // NestedScrollView permite que el SliverAppBar se oculte al hacer scroll
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    // Título en blanco
                    title: const Text(
                      'Mis Reservas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    // TabBar con pestañas Próximas e Historial
                    bottom: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      indicatorColor: Colors.white,
                      indicatorWeight: 3,
                      tabs: [
                        Tab(text: 'Próximas (${_datos?['totalFuturas'] ?? 0})'),
                        Tab(
                          text: 'Historial (${_datos?['totalPasadas'] ?? 0})',
                        ),
                      ],
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // Pestaña de reservas próximas con botones de editar/cancelar
                    _buildLista(
                      (_datos?['futuras'] as List<dynamic>? ?? []),
                      futuras: true,
                    ),
                    // Pestaña de historial con botón de reseña
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
                mostrarCancelar: futuras && r['estado'] == 'CONFIRMADA',
                mostrarEditar: futuras && r['estado'] == 'CONFIRMADA',
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

/// Tarjeta individual de reserva con fondo semitransparente sobre el degradado.
/// Muestra pista, fecha, tarifa, precio y estado.
/// Botones de editar/cancelar para futuras, reseña para pasadas.
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

  /// Color del texto del badge según el estado de la reserva.
  Color _estadoColor(String estado) {
    switch (estado) {
      case 'CONFIRMADA':
        return Colors.white;
      case 'CANCELADA':
        return Colors.redAccent;
      default:
        return Colors.white60;
    }
  }

  /// Color de fondo del badge de estado.
  Color _estadoBgColor(String estado) {
    switch (estado) {
      case 'CONFIRMADA':
        return Colors.white.withValues(alpha: 0.25);
      case 'CANCELADA':
        return Colors.redAccent.withValues(alpha: 0.25);
      default:
        return Colors.white.withValues(alpha: 0.15);
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
        // Card semitransparente para integrarse con el degradado verde
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Cabecera: icono + nombre de pista + badge de estado ---
          Row(
            children: [
              // Icono de pista con fondo semitransparente
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.sports_tennis_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Nombre de la instalación en blanco
              Expanded(
                child: Text(
                  reserva['instalacion'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
              // Badge de estado con color según el estado
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _estadoBgColor(estado),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  estado,
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

          // --- Botones Editar y Cancelar (reservas futuras confirmadas) ---
          if (mostrarEditar || mostrarCancelar) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
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
                          Icon(
                            Icons.edit_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Editar',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Separador entre botones
                if (mostrarEditar && mostrarCancelar)
                  Container(
                    width: 1,
                    height: 20,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                if (mostrarCancelar)
                  Expanded(
                    child: GestureDetector(
                      onTap: onCancelar,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cancel_outlined,
                            color: Colors.white70,
                            size: 16,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Cancelar',
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],

          // --- Botón de reseña (reservas pasadas confirmadas) ---
          if (mostrarResena) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onResena,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Estrella dorada para dejar reseña
                  const Icon(
                    Icons.star_rounded,
                    color: AppTheme.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Dejar reseña',
                    style: TextStyle(
                      color: AppTheme.accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Chip de información con icono y texto en blanco semitransparente.
  Widget _infoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}

/// Bottom sheet para editar una reserva existente en 3 pasos.
/// Tiene el mismo degradado verde que el resto de la app.
/// Las tarifas se filtran según el tipo de pista seleccionada:
/// - Pádel → solo tarifas de pádel y generales
/// - Tenis → solo tarifas de tenis y generales
/// - Fútbol → no debería llegar aquí (no reservable desde app)
class _EditarReservaBottomSheet extends StatefulWidget {
  final dynamic reserva; // Datos de la reserva a editar
  final String dniSocio; // DNI del socio para la API
  final VoidCallback onActualizada; // Callback cuando la reserva se actualiza

  const _EditarReservaBottomSheet({
    required this.reserva,
    required this.dniSocio,
    required this.onActualizada,
  });

  @override
  State<_EditarReservaBottomSheet> createState() =>
      _EditarReservaBottomSheetState();
}

class _EditarReservaBottomSheetState extends State<_EditarReservaBottomSheet> {
  // Listas completas cargadas de la API
  List<dynamic> _instalaciones = [];
  List<dynamic> _todasLasTarifas = []; // Sin filtrar

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

  // Paso actual del flujo (0=pista/tarifa, 1=fecha/hora, 2=confirmar)
  int _paso = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  /// Devuelve las tarifas filtradas según el tipo de la instalación seleccionada.
  /// Igual que en reservar_screen.dart para mantener consistencia.
  /// - Pádel → tarifas cuyo tipo_pista sea 'Pádel' o vacío (generales)
  /// - Tenis → tarifas cuyo tipo_pista sea 'Tenis' o vacío (generales)
  /// - Otros → todas las tarifas
  List<dynamic> get _tarifasFiltradas {
    if (_instalacionSeleccionada == null) return _todasLasTarifas; // o _tarifas
    final tipoPista = (_instalacionSeleccionada!['tipo'] as String? ?? '')
        .toLowerCase();

    return _todasLasTarifas.where((t) {
      // o _tarifas
      final tipoPistaApi = (t['tipo_pista'] as String? ?? '').toLowerCase();

      if (tipoPista.contains('pádel') || tipoPista.contains('padel')) {
        // Pádel: solo generales (null), excluimos tenis y fútbol
        return tipoPistaApi.isEmpty;
      }
      if (tipoPista.contains('tenis')) {
        // Tenis: las propias de tenis + las generales
        return tipoPistaApi.isEmpty || tipoPistaApi.contains('tenis');
      }
      if (tipoPista.contains('fútbol') || tipoPista.contains('futbol')) {
        // Fútbol: solo las de fútbol sala
        return tipoPistaApi.contains('fútbol') ||
            tipoPistaApi.contains('futbol');
      }
      // Cualquier otro tipo: todas
      return true;
    }).toList();
  }

  /// Carga instalaciones y tarifas desde la API.
  /// Preselecciona las de la reserva original.
  Future<void> _cargarDatos() async {
    try {
      final inst = await ApiService.getInstalaciones(estado: 'ACTIVA');
      final tar = await ApiService.getTarifas();
      setState(() {
        _instalaciones = inst;
        _todasLasTarifas = tar;
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

  /// Carga las horas disponibles para la instalación, tarifa y fecha actuales.
  Future<void> _cargarHoras() async {
    if (_instalacionSeleccionada == null || _tarifaSeleccionada == null) {
      return;
    }
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

  /// Envía los nuevos datos a la API para reagendar la reserva.
  Future<void> _guardar() async {
    if (_instalacionSeleccionada == null ||
        _tarifaSeleccionada == null ||
        _horaSeleccionada == null)
      return;
    setState(() => _guardando = true);

    final fecha = DateFormat('yyyy-MM-dd').format(_fechaSeleccionada);
    final fechaHora = '$fecha $_horaSeleccionada:00';

    try {
      final result =
          await ApiService.reagendarReserva(widget.reserva['idReserva'], {
            'dniSocio': widget.dniSocio,
            'instalacion': _instalacionSeleccionada!['idInstalacion'],
            'idTarifa': _tarifaSeleccionada!['idTarifa'],
            'fechaHora': fechaHora,
          });
      if (mounted) {
        Navigator.pop(context); // Cerramos el bottom sheet
        if (result['success'] == true) {
          widget.onActualizada();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al actualizar'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de conexión'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          // Handle visual semitransparente
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Cabecera con botón de retroceso y título del paso actual
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Botón de retroceso visible desde el paso 1
                if (_paso > 0)
                  GestureDetector(
                    onTap: () => setState(() => _paso--),
                    child: const Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                const SizedBox(width: 8),
                // Título dinámico según el paso
                Text(
                  _paso == 0
                      ? 'Editar reserva — Pista'
                      : _paso == 1
                      ? 'Editar reserva — Fecha'
                      : 'Confirmar cambios',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // Divider semitransparente entre cabecera y contenido
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 1),
          // Contenido del paso actual con scroll
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
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

  /// Paso 0: Selector de pista y tarifa filtrada por tipo de pista.
  Widget _buildPaso0() {
    // Tarifas filtradas según el tipo de la pista seleccionada
    final tarifasFiltradas = _tarifasFiltradas;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Elige una pista',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        // Lista de instalaciones
        ..._instalaciones.map(
          (inst) => GestureDetector(
            onTap: () => setState(() {
              _instalacionSeleccionada = inst;
              // Reseteamos la tarifa al cambiar de pista
              _tarifaSeleccionada = null;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                // Blanco si seleccionada, semitransparente si no
                color:
                    _instalacionSeleccionada?['idInstalacion'] ==
                        inst['idInstalacion']
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color:
                      _instalacionSeleccionada?['idInstalacion'] ==
                          inst['idInstalacion']
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.2),
                  width:
                      _instalacionSeleccionada?['idInstalacion'] ==
                          inst['idInstalacion']
                      ? 2
                      : 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sports_tennis_rounded,
                    color:
                        _instalacionSeleccionada?['idInstalacion'] ==
                            inst['idInstalacion']
                        ? const Color(0xFF1B4332)
                        : Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      inst['nombre'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color:
                            _instalacionSeleccionada?['idInstalacion'] ==
                                inst['idInstalacion']
                            ? const Color(0xFF1B4332)
                            : Colors.white,
                      ),
                    ),
                  ),
                  if (_instalacionSeleccionada?['idInstalacion'] ==
                      inst['idInstalacion'])
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF1B4332),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Elige la duración',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        // Mensaje si no hay tarifas para este tipo de pista
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
          // Lista de tarifas filtradas por tipo de pista
          ...tarifasFiltradas.map(
            (tar) => GestureDetector(
              onTap: () => setState(() => _tarifaSeleccionada = tar),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _tarifaSeleccionada?['idTarifa'] == tar['idTarifa']
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _tarifaSeleccionada?['idTarifa'] == tar['idTarifa']
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.2),
                    width: _tarifaSeleccionada?['idTarifa'] == tar['idTarifa']
                        ? 2
                        : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_rounded,
                      color: _tarifaSeleccionada?['idTarifa'] == tar['idTarifa']
                          ? const Color(0xFF1B4332)
                          : Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        // Nombre y descripción de la tarifa
                        '${tar['nombre']} — ${tar['descripcion'] ?? ''}',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color:
                              _tarifaSeleccionada?['idTarifa'] ==
                                  tar['idTarifa']
                              ? const Color(0xFF1B4332)
                              : Colors.white,
                        ),
                      ),
                    ),
                    // Precio de la tarifa
                    Text(
                      '€${tar['precio']}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color:
                            _tarifaSeleccionada?['idTarifa'] == tar['idTarifa']
                            ? const Color(0xFF1B4332)
                            : Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    if (_tarifaSeleccionada?['idTarifa'] ==
                        tar['idTarifa']) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF1B4332),
                        size: 20,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        // Botón continuar en blanco con texto verde
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
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Continuar',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ],
    );
  }

  /// Paso 1: Calendario y selector de hora con estilo verde.
  Widget _buildPaso1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecciona la fecha',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        // Calendario con fondo semitransparente
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: TableCalendar(
            // Solo permite seleccionar desde mañana en adelante
            firstDay: DateTime.now().add(const Duration(days: 1)),
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
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Color(0xFF1B4332),
                fontWeight: FontWeight.w700,
              ),
              todayDecoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
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
                fontSize: 16,
              ),
              leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
              rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(color: Colors.white70, fontSize: 12),
              weekendStyle: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            locale: 'es_ES',
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Elige una hora',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        // Grid de horas disponibles
        if (_loadingHoras)
          const Center(child: CircularProgressIndicator(color: Colors.white))
        else if (_horas.isEmpty)
          const Center(
            child: Text(
              'No hay horas disponibles',
              style: TextStyle(color: Colors.white70),
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
                    // Blanco si seleccionada, casi invisible si ocupada
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
                  child: Text(
                    hora,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: !disponible
                          ? Colors.white30
                          : selected
                          ? const Color(0xFF1B4332)
                          : Colors.white,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 24),
        // Botón continuar en blanco con texto verde
        ElevatedButton(
          onPressed: _horaSeleccionada != null
              ? () => setState(() => _paso = 2)
              : null,
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
            'Continuar',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
      ],
    );
  }

  /// Paso 2: Resumen de los cambios con estilo semitransparente.
  Widget _buildPaso2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Confirma los cambios',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        // Tarjeta resumen semitransparente con todos los datos
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _resumenRow(
                Icons.sports_tennis_rounded,
                'Pista',
                _instalacionSeleccionada?['nombre'] ?? '',
              ),
              Divider(color: Colors.white.withValues(alpha: 0.2), height: 24),
              _resumenRow(
                Icons.timer_rounded,
                'Duración',
                '${_tarifaSeleccionada?['duracionMinutos']} min',
              ),
              Divider(color: Colors.white.withValues(alpha: 0.2), height: 24),
              _resumenRow(
                Icons.calendar_today_rounded,
                'Fecha',
                DateFormat('EEEE d MMMM', 'es').format(_fechaSeleccionada),
              ),
              Divider(color: Colors.white.withValues(alpha: 0.2), height: 24),
              _resumenRow(
                Icons.access_time_rounded,
                'Hora',
                _horaSeleccionada ?? '',
              ),
              Divider(color: Colors.white.withValues(alpha: 0.2), height: 24),
              _resumenRow(
                Icons.euro_rounded,
                'Precio',
                '€${_tarifaSeleccionada?['precio']}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Botón confirmar en blanco con texto verde
        ElevatedButton(
          onPressed: _guardando ? null : _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF1B4332),
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          child: _guardando
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Color(0xFF1B4332),
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Confirmar cambios',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
        ),
      ],
    );
  }

  /// Fila del resumen con icono, etiqueta y valor en blanco.
  Widget _resumenRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

/// Bottom sheet para dejar una reseña tras una partida.
/// Tiene el mismo degradado verde que el resto de la app.
/// Permite elegir una puntuación de 1 a 5 estrellas y añadir comentario.
class _ResenaBottomSheet extends StatefulWidget {
  final String idInstalacion; // ID de la pista a reseñar
  final String nombreInstalacion; // Nombre de la pista
  final String nombreAutor; // Nombre completo del socio
  final String dniSocio; // DNI del socio para la API
  final VoidCallback onEnviada; // Callback cuando la reseña se envía con éxito

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

  /// Envía la reseña a la API con la puntuación y el comentario.
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
          widget.onEnviada();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Error al enviar reseña'),
              backgroundColor: AppTheme.danger,
            ),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error de conexión'),
            backgroundColor: AppTheme.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

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
      // Padding para que el teclado no tape el formulario
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
          // Handle visual semitransparente
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Título y nombre de la pista
          const Text(
            '¿Cómo fue tu partida?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.nombreInstalacion,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 24),
          const Text(
            'Puntuación',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          // Selector de estrellas doradas (1 a 5)
          Row(
            children: List.generate(5, (i) {
              final estrella = i + 1;
              return GestureDetector(
                onTap: () => setState(() => _puntuacion = estrella),
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    estrella <= _puntuacion
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppTheme.accent,
                    size: 36,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          const Text(
            'Comentario (opcional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          // Campo de texto adaptado al fondo verde
          TextField(
            controller: _comentarioCtrl,
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Cuéntanos tu experiencia...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.12),
              counterStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.2),
                ),
              ),
              // Borde blanco sólido al enfocar
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Botón enviar en blanco con texto verde
          ElevatedButton(
            onPressed: _enviando ? null : _enviar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B4332),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
            ),
            child: _enviando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Color(0xFF1B4332),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Enviar reseña',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }
}
