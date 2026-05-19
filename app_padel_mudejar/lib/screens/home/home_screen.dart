import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

/// Pantalla principal (Home) de la app.
/// Muestra la lista de pistas/instalaciones del club con su imagen,
/// estado, valoración y reseñas. Tiene degradado verde en toda la pantalla,
/// incluyendo las cards y los bottom sheets.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Lista de instalaciones cargadas desde la API
  List<dynamic> _instalaciones = [];

  // Mapa de reseñas por ID de instalación
  Map<String, Map<String, dynamic>> _resenasPorPista = {};

  // Estado de carga inicial
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  /// Carga todas las instalaciones y sus reseñas desde la API.
  /// Actualiza el estado con los datos recibidos.
  Future<void> _cargar() async {
    try {
      final inst = await ApiService.getInstalaciones();
      final Map<String, Map<String, dynamic>> resenas = {};
      // Para cada instalación cargamos sus reseñas individualmente
      for (final i in inst) {
        try {
          final r = await ApiService.getResenas(i['idInstalacion']);
          resenas[i['idInstalacion']] = r;
        } catch (_) {}
      }
      setState(() {
        _instalaciones = inst;
        _resenasPorPista = resenas;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  /// Abre el bottom sheet con degradado para ver las reseñas de una pista.
  /// Solo se abre si hay reseñas disponibles.
  void _mostrarResenas(BuildContext context, dynamic instalacion, Map<String, dynamic>? resenas) {
    if (resenas == null) return;
    final auth = context.read<AuthProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ResenasPistaBottomSheet(
        nombreInstalacion: instalacion['nombre'] ?? '',
        idInstalacion: instalacion['idInstalacion'] ?? '',
        resenas: resenas,
        dniSocio: auth.dni,
        onResenasActualizadas: _cargar, // Recargamos tras actualizar reseñas
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchamos el AuthProvider para mostrar el nombre del socio
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
        child: RefreshIndicator(
          onRefresh: _cargar,
          color: Colors.white,
          child: CustomScrollView(
            slivers: [
              // --- AppBar flotante con nombre del socio y avatar ---
              SliverAppBar(
                expandedHeight: 100,
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Saludo con el nombre del socio
                                Text(
                                  'Hola, ${auth.nombre} 👋',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ).animate().fadeIn().slideX(begin: -0.2, end: 0),
                                const SizedBox(height: 4),
                                // Nombre del club en blanco semitransparente
                                Text(
                                  'Club de Pádel Mudéjar',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ).animate().fadeIn(delay: 100.ms),
                              ],
                            ),
                          ),
                          // Avatar con la inicial del nombre del socio
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            child: Text(
                              auth.nombre.isNotEmpty ? auth.nombre[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.8, 0.8)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // --- Lista de pistas o indicador de carga ---
              if (_loading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Colors.white)),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final inst = _instalaciones[i];
                        final resenas = _resenasPorPista[inst['idInstalacion']];
                        // Cada card aparece con animación de fade + slide
                        return _PistaCard(
                          instalacion: inst,
                          resenas: resenas,
                          onTap: () => context.push('/horarios/detalle', extra: inst),
                          onResenasTap: () => _mostrarResenas(context, inst, resenas),
                        ).animate().fadeIn(delay: Duration(milliseconds: i * 80)).slideY(begin: 0.1, end: 0);
                      },
                      childCount: _instalaciones.length,
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

/// Card de pista con fondo semitransparente sobre el degradado verde.
/// Muestra imagen, estado, nombre, tipo, ubicación y valoración.
/// Al pulsar navega al detalle de la pista.
class _PistaCard extends StatelessWidget {
  final dynamic instalacion;          // Datos de la instalación
  final Map<String, dynamic>? resenas; // Reseñas de la instalación
  final VoidCallback onTap;           // Callback al pulsar la card
  final VoidCallback onResenasTap;    // Callback al pulsar las estrellas

  const _PistaCard({
    required this.instalacion,
    required this.resenas,
    required this.onTap,
    required this.onResenasTap,
  });

  @override
  Widget build(BuildContext context) {
    final estado = instalacion['estadoPista'] as String? ?? '';
    final activa = estado == 'ACTIVA';
    final imagenUrl = instalacion['imagen_url'] as String?;
    // Calculamos el promedio de reseñas si existe
    final promedio = resenas?['promedio'] != null
        ? (resenas!['promedio'] as num).toDouble()
        : null;
    final total = resenas?['total'] as int? ?? 0;

    return GestureDetector(
      onTap: activa ? onTap : null, // Solo navegamos si la pista está activa
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          // Card semitransparente sobre el degradado verde
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Imagen de la pista con badge de estado ---
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  // Imagen de la pista o placeholder si no hay imagen
                  imagenUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imagenUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                              height: 160,
                              color: Colors.white.withValues(alpha: 0.1),
                              child: const Center(child: CircularProgressIndicator(color: Colors.white))),
                          errorWidget: (context, url, error) => Container(
                              height: 160,
                              color: Colors.white.withValues(alpha: 0.1),
                              child: const Icon(Icons.sports_tennis_rounded, size: 60, color: Colors.white30)),
                        )
                      : Container(
                          height: 160,
                          color: Colors.white.withValues(alpha: 0.1),
                          child: const Center(
                              child: Icon(Icons.sports_tennis_rounded, size: 60, color: Colors.white30))),
                  // Badge de disponibilidad (ACTIVA / MANTENIMIENTO)
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        // Verde para activa, rojo para mantenimiento
                        color: activa
                            ? Colors.green.shade600
                            : Colors.redAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Punto indicador de estado
                          Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                          const SizedBox(width: 5),
                          Text(activa ? 'Disponible' : 'Mantenimiento',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                  // Overlay oscuro si la pista no está activa
                  if (!activa)
                    Container(height: 160, color: Colors.black.withValues(alpha: 0.4)),
                ],
              ),
            ),

            // --- Información de la pista: nombre, tipo, ubicación y reseñas ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre de la pista en blanco
                        Text(instalacion['nombre'] ?? '',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 4),
                        // Tipo de pista en blanco semitransparente
                        Text(instalacion['tipo'] ?? '',
                            style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        // Ubicación si está disponible
                        if (instalacion['ubicacion'] != null) ...[
                          const SizedBox(height: 2),
                          Row(children: [
                            const Icon(Icons.location_on_rounded, size: 12, color: Colors.white54),
                            const SizedBox(width: 3),
                            Text(instalacion['ubicacion'],
                                style: const TextStyle(fontSize: 12, color: Colors.white54)),
                          ]),
                        ],
                        // Estrellas y promedio si hay reseñas
                        if (promedio != null) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: onResenasTap, // Abre el bottom sheet de reseñas
                            child: Row(
                              children: [
                                // Generamos las 5 estrellas según el promedio
                                ...List.generate(5, (i) => Icon(
                                  i < promedio.floor()
                                      ? Icons.star_rounded
                                      : (i < promedio && promedio % 1 >= 0.5)
                                          ? Icons.star_half_rounded
                                          : Icons.star_outline_rounded,
                                  color: AppTheme.accent, size: 16,
                                )),
                                const SizedBox(width: 6),
                                Text('$promedio ($total reseñas)',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(width: 4),
                                const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white54),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          // Texto si no hay reseñas aún
                          const Text('Sin reseñas aún',
                              style: TextStyle(fontSize: 12, color: Colors.white54)),
                        ],
                      ],
                    ),
                  ),
                  // Flecha de navegación si la pista está activa
                  if (activa)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet que muestra las reseñas de una pista específica.
/// Tiene el mismo degradado verde que el resto de la app.
/// Permite editar y eliminar las reseñas propias del socio.
class _ResenasPistaBottomSheet extends StatefulWidget {
  final String nombreInstalacion;      // Nombre de la pista para el título
  final String idInstalacion;          // ID para recargar reseñas
  final Map<String, dynamic> resenas;  // Reseñas iniciales
  final String dniSocio;               // DNI para identificar las reseñas propias
  final VoidCallback onResenasActualizadas; // Callback al modificar reseñas

  const _ResenasPistaBottomSheet({
    required this.nombreInstalacion,
    required this.idInstalacion,
    required this.resenas,
    required this.dniSocio,
    required this.onResenasActualizadas,
  });

  @override
  State<_ResenasPistaBottomSheet> createState() => _ResenasPistaBottomSheetState();
}

class _ResenasPistaBottomSheetState extends State<_ResenasPistaBottomSheet> {
  // Lista de reseñas mostradas
  late List<dynamic> _lista;
  // Promedio de puntuación
  late double? _promedio;
  // Total de reseñas
  late int _total;

  @override
  void initState() {
    super.initState();
    // Inicializamos con los datos recibidos del padre
    _lista = (widget.resenas['resenas'] as List<dynamic>? ?? []);
    _promedio = widget.resenas['promedio'] != null
        ? (widget.resenas['promedio'] as num).toDouble()
        : null;
    _total = widget.resenas['total'] as int? ?? 0;
  }

  /// Recarga las reseñas desde la API y actualiza el estado.
  Future<void> _recargar() async {
    try {
      final r = await ApiService.getResenas(widget.idInstalacion);
      setState(() {
        _lista = (r['resenas'] as List<dynamic>? ?? []);
        _promedio = r['promedio'] != null ? (r['promedio'] as num).toDouble() : null;
        _total = r['total'] as int? ?? 0;
      });
      widget.onResenasActualizadas(); // Notificamos al padre
    } catch (_) {}
  }

  /// Muestra un diálogo de confirmación y elimina la reseña si el usuario acepta.
  Future<void> _eliminar(int idResena) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar reseña'),
        content: const Text('¿Seguro que quieres eliminar esta reseña?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Eliminar', style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirm != true) return;

    // Llamada a la API para eliminar la reseña
    final result = await ApiService.eliminarResena(idResena, widget.dniSocio);
    if (result['success'] == true) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Reseña eliminada'), backgroundColor: AppTheme.primary));
      _recargar();
    } else {
      messenger.showSnackBar(SnackBar(
          content: Text(result['message'] ?? 'Error al eliminar'),
          backgroundColor: AppTheme.danger));
    }
  }

  /// Abre el bottom sheet para editar una reseña propia.
  void _mostrarEditar(dynamic resena) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditarResenaBottomSheet(
        resena: resena,
        dniSocio: widget.dniSocio,
        onActualizada: () {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Reseña actualizada'),
                  backgroundColor: AppTheme.primary));
          _recargar();
        },
      ),
    );
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
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
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
          // Título con el nombre de la pista en blanco
          Text('Reseñas — ${widget.nombreInstalacion}',
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          // Promedio de puntuación con estrellas
          if (_promedio != null)
            Row(
              children: [
                // Número del promedio en dorado
                Text('$_promedio',
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.w800, color: AppTheme.accent)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estrellas del promedio
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < _promedio!.floor()
                            ? Icons.star_rounded
                            : (i < _promedio! && _promedio! % 1 >= 0.5)
                                ? Icons.star_half_rounded
                                : Icons.star_outline_rounded,
                        color: AppTheme.accent, size: 20,
                      )),
                    ),
                    // Total de reseñas en blanco semitransparente
                    Text('$_total reseñas',
                        style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ],
            ),
          // Divider semitransparente
          Divider(color: Colors.white.withValues(alpha: 0.2), height: 24),
          // Lista de reseñas o mensaje vacío
          Expanded(
            child: _lista.isEmpty
                ? const Center(
                    child: Text('Sin reseñas aún',
                        style: TextStyle(color: Colors.white70)))
                : ListView.builder(
                    itemCount: _lista.length,
                    itemBuilder: (context, i) {
                      final r = _lista[i];
                      final puntuacion = r['puntuacion'] as int? ?? 0;
                      final comentario = r['comentario'] as String?;
                      final autor = r['nombreAutor'] as String? ?? 'Anónimo';
                      final fecha = r['created_at'] as String? ?? '';
                      final fechaCorta = fecha.isNotEmpty ? fecha.substring(0, 10) : '';
                      // Identificamos si la reseña es del socio actual
                      final esMia = r['dniSocio'] == widget.dniSocio;
                      final idResena = r['id'] as int? ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar con la inicial del autor
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              child: Text(
                                  autor.isNotEmpty ? autor[0].toUpperCase() : 'A',
                                  style: const TextStyle(
                                      color: Colors.white, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Nombre del autor en blanco
                                      Expanded(
                                          child: Text(autor,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                  color: Colors.white))),
                                      // Botones de editar/eliminar solo en reseñas propias
                                      if (esMia) ...[
                                        GestureDetector(
                                            onTap: () => _mostrarEditar(r),
                                            child: const Icon(Icons.edit_rounded,
                                                size: 16, color: Colors.white70)),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                            onTap: () => _eliminar(idResena),
                                            child: const Icon(Icons.delete_outline_rounded,
                                                size: 16, color: Colors.redAccent)),
                                        const SizedBox(width: 4),
                                      ] else
                                        // Fecha en reseñas de otros
                                        Text(fechaCorta,
                                            style: const TextStyle(
                                                fontSize: 11, color: Colors.white54)),
                                    ],
                                  ),
                                  // Fecha en reseñas propias (debajo del nombre)
                                  if (esMia)
                                    Text(fechaCorta,
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.white54)),
                                  const SizedBox(height: 4),
                                  // Estrellas de la puntuación
                                  Row(
                                    children: List.generate(5, (j) => Icon(
                                      j < puntuacion
                                          ? Icons.star_rounded
                                          : Icons.star_outline_rounded,
                                      color: AppTheme.accent, size: 14,
                                    )),
                                  ),
                                  // Comentario si existe
                                  if (comentario != null && comentario.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(comentario,
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.white70)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet para editar una reseña propia.
/// Tiene el mismo degradado verde que el resto de la app.
/// Permite modificar la puntuación y el comentario.
class _EditarResenaBottomSheet extends StatefulWidget {
  final dynamic resena;         // Datos de la reseña a editar
  final String dniSocio;        // DNI del socio para la API
  final VoidCallback onActualizada; // Callback al guardar con éxito

  const _EditarResenaBottomSheet(
      {required this.resena, required this.dniSocio, required this.onActualizada});

  @override
  State<_EditarResenaBottomSheet> createState() => _EditarResenaBottomSheetState();
}

class _EditarResenaBottomSheetState extends State<_EditarResenaBottomSheet> {
  // Puntuación actual de la reseña
  late int _puntuacion;
  // Controlador del campo de comentario precargado con el texto actual
  late TextEditingController _comentarioCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Precargamos los valores actuales de la reseña
    _puntuacion = widget.resena['puntuacion'] as int? ?? 5;
    _comentarioCtrl = TextEditingController(
        text: widget.resena['comentario'] as String? ?? '');
  }

  @override
  void dispose() {
    // Liberamos el controlador de texto
    _comentarioCtrl.dispose();
    super.dispose();
  }

  /// Guarda los cambios de la reseña en la API.
  Future<void> _guardar() async {
    setState(() => _guardando = true);
    try {
      final idResena = widget.resena['id'] as int? ?? 0;
      final result = await ApiService.editarResena(idResena, {
        'dniSocio': widget.dniSocio,
        'puntuacion': _puntuacion,
        'comentario': _comentarioCtrl.text.trim(),
        'nombreAutor': widget.resena['nombreAutor'],
      });
      if (mounted) {
        Navigator.pop(context); // Cerramos el bottom sheet
        if (result['success'] == true) {
          widget.onActualizada(); // Notificamos el éxito
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(result['message'] ?? 'Error al actualizar'),
              backgroundColor: AppTheme.danger));
        }
      }
    } catch (_) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Error de conexión'), backgroundColor: AppTheme.danger));
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
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
      // Padding extra para que el teclado no tape el formulario
      padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24),
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
          const SizedBox(height: 20),
          // Título en blanco
          const Text('Editar reseña',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 20),
          const Text('Puntuación',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
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
          const Text('Comentario',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 10),
          // Campo de texto con estilo adaptado al fondo verde
          TextField(
            controller: _comentarioCtrl,
            maxLines: 3,
            maxLength: 500,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tu comentario...',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.12),
              counterStyle: const TextStyle(color: Colors.white54),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2))),
              // Borde blanco sólido al enfocar
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white, width: 2)),
            ),
          ),
          const SizedBox(height: 16),
          // Botón guardar en blanco con texto verde
          ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1B4332),
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _guardando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        color: Color(0xFF1B4332), strokeWidth: 2))
                : const Text('Guardar cambios',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}