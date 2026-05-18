import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class HorariosScreen extends StatefulWidget {
  const HorariosScreen({super.key});

  @override
  State<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends State<HorariosScreen> {
  List<dynamic> _instalaciones = [];
  Map<String, Map<String, dynamic>> _resenasPorPista = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final inst = await ApiService.getInstalaciones();
      final Map<String, Map<String, dynamic>> resenas = {};
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

  void _mostrarResenas(
    BuildContext context,
    dynamic instalacion,
    Map<String, dynamic>? resenas,
  ) {
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
        onResenasActualizadas: _cargar,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Pistas')),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : RefreshIndicator(
              onRefresh: _cargar,
              color: AppTheme.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _instalaciones.length,
                itemBuilder: (context, i) {
                  final inst = _instalaciones[i];
                  final resenas = _resenasPorPista[inst['idInstalacion']];
                  return _PistaCard(
                        instalacion: inst,
                        resenas: resenas,
                        onTap: () =>
                            context.push('/horarios/detalle', extra: inst),
                        onResenasTap: () =>
                            _mostrarResenas(context, inst, resenas),
                      )
                      .animate()
                      .fadeIn(delay: Duration(milliseconds: i * 80))
                      .slideY(begin: 0.1, end: 0);
                },
              ),
            ),
    );
  }
}

class _PistaCard extends StatelessWidget {
  final dynamic instalacion;
  final Map<String, dynamic>? resenas;
  final VoidCallback onTap;
  final VoidCallback onResenasTap;

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
    final promedio = resenas?['promedio'] != null
        ? (resenas!['promedio'] as num).toDouble()
        : null;
    final total = resenas?['total'] as int? ?? 0;

    return GestureDetector(
      onTap: activa ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Stack(
                children: [
                  imagenUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imagenUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            height: 160,
                            color: Colors.grey.shade100,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.primary,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 160,
                            color: Colors.grey.shade100,
                            child: const Icon(
                              Icons.sports_tennis_rounded,
                              size: 60,
                              color: AppTheme.textLight,
                            ),
                          ),
                        )
                      : Container(
                          height: 160,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: Icon(
                              Icons.sports_tennis_rounded,
                              size: 60,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: activa ? AppTheme.primary : AppTheme.danger,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            activa ? 'Disponible' : 'Mantenimiento',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!activa)
                    Container(
                      height: 160,
                      color: Colors.black.withOpacity(0.4),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instalacion['nombre'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          instalacion['tipo'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        if (instalacion['ubicacion'] != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 12,
                                color: AppTheme.textLight,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                instalacion['ubicacion'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textLight,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (promedio != null) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: onResenasTap,
                            child: Row(
                              children: [
                                ...List.generate(
                                  5,
                                  (i) => Icon(
                                    i < promedio.floor()
                                        ? Icons.star_rounded
                                        : (i < promedio && promedio % 1 >= 0.5)
                                        ? Icons.star_half_rounded
                                        : Icons.star_outline_rounded,
                                    color: AppTheme.accent,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$promedio ($total reseñas)',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMedium,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  size: 14,
                                  color: AppTheme.textLight,
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Sin reseñas aún',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (activa)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.primary,
                      ),
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

class _ResenasPistaBottomSheet extends StatefulWidget {
  final String nombreInstalacion;
  final String idInstalacion;
  final Map<String, dynamic> resenas;
  final String dniSocio;
  final VoidCallback onResenasActualizadas;

  const _ResenasPistaBottomSheet({
    required this.nombreInstalacion,
    required this.idInstalacion,
    required this.resenas,
    required this.dniSocio,
    required this.onResenasActualizadas,
  });

  @override
  State<_ResenasPistaBottomSheet> createState() =>
      _ResenasPistaBottomSheetState();
}

class _ResenasPistaBottomSheetState extends State<_ResenasPistaBottomSheet> {
  late List<dynamic> _lista;
  late double? _promedio;
  late int _total;

  @override
  void initState() {
    super.initState();
    _lista = (widget.resenas['resenas'] as List<dynamic>? ?? []);
    _promedio = widget.resenas['promedio'] as double?;
    _total = widget.resenas['total'] as int? ?? 0;
  }

  Future<void> _recargar() async {
    try {
      final r = await ApiService.getResenas(widget.idInstalacion);
      setState(() {
        _lista = (r['resenas'] as List<dynamic>? ?? []);
        _promedio = r['promedio'] as double?;
        _total = r['total'] as int? ?? 0;
      });
      widget.onResenasActualizadas();
    } catch (_) {}
  }

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
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await ApiService.eliminarResena(idResena, widget.dniSocio);
    if (result['success'] == true) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Reseña eliminada'),
          backgroundColor: AppTheme.primary,
        ),
      );
      _recargar();
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Error al eliminar'),
          backgroundColor: AppTheme.danger,
        ),
      );
    }
  }

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
              backgroundColor: AppTheme.primary,
            ),
          );
          _recargar();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Reseñas — ${widget.nombreInstalacion}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          if (_promedio != null)
            Row(
              children: [
                Text(
                  '$_promedio',
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: List.generate(
                        5,
                        (i) => Icon(
                          i < _promedio!.floor()
                              ? Icons.star_rounded
                              : (i < _promedio! && _promedio! % 1 >= 0.5)
                              ? Icons.star_half_rounded
                              : Icons.star_outline_rounded,
                          color: AppTheme.accent,
                          size: 20,
                        ),
                      ),
                    ),
                    Text(
                      '$_total reseñas',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          const Divider(height: 24),
          Expanded(
            child: _lista.isEmpty
                ? const Center(
                    child: Text(
                      'Sin reseñas aún',
                      style: TextStyle(color: AppTheme.textMedium),
                    ),
                  )
                : ListView.builder(
                    itemCount: _lista.length,
                    itemBuilder: (context, i) {
                      final r = _lista[i];
                      final puntuacion = r['puntuacion'] as int? ?? 0;
                      final comentario = r['comentario'] as String?;
                      final autor = r['nombreAutor'] as String? ?? 'Anónimo';
                      final fecha = r['created_at'] as String? ?? '';
                      final fechaCorta = fecha.isNotEmpty
                          ? fecha.substring(0, 10)
                          : '';
                      final esMia = r['dniSocio'] == widget.dniSocio;
                      final idResena = r['id'] as int? ?? 0;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppTheme.primary.withOpacity(
                                0.1,
                              ),
                              child: Text(
                                autor.isNotEmpty ? autor[0].toUpperCase() : 'A',
                                style: const TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          autor,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14,
                                            color: AppTheme.textDark,
                                          ),
                                        ),
                                      ),
                                      if (esMia) ...[
                                        GestureDetector(
                                          onTap: () => _mostrarEditar(r),
                                          child: const Icon(
                                            Icons.edit_rounded,
                                            size: 16,
                                            color: AppTheme.secondary,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _eliminar(idResena),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            size: 16,
                                            color: AppTheme.danger,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ] else
                                        Text(
                                          fechaCorta,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.textLight,
                                          ),
                                        ),
                                    ],
                                  ),
                                  if (esMia)
                                    Text(
                                      fechaCorta,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textLight,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: List.generate(
                                      5,
                                      (j) => Icon(
                                        j < puntuacion
                                            ? Icons.star_rounded
                                            : Icons.star_outline_rounded,
                                        color: AppTheme.accent,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                  if (comentario != null &&
                                      comentario.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      comentario,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: AppTheme.textMedium,
                                      ),
                                    ),
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

class _EditarResenaBottomSheet extends StatefulWidget {
  final dynamic resena;
  final String dniSocio;
  final VoidCallback onActualizada;

  const _EditarResenaBottomSheet({
    required this.resena,
    required this.dniSocio,
    required this.onActualizada,
  });

  @override
  State<_EditarResenaBottomSheet> createState() =>
      _EditarResenaBottomSheetState();
}

class _EditarResenaBottomSheetState extends State<_EditarResenaBottomSheet> {
  late int _puntuacion;
  late TextEditingController _comentarioCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _puntuacion = widget.resena['puntuacion'] as int? ?? 5;
    _comentarioCtrl = TextEditingController(
      text: widget.resena['comentario'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _comentarioCtrl.dispose();
    super.dispose();
  }

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
        Navigator.pop(context);
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Editar reseña',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Puntuación',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
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
            'Comentario',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _comentarioCtrl,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Tu comentario...',
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _guardando ? null : _guardar,
            child: _guardando
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Guardar cambios'),
          ),
        ],
      ),
    );
  }
}
