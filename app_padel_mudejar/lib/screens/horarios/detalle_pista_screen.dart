import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';

class DetallePistaScreen extends StatefulWidget {
  final Map<String, dynamic> instalacion;

  const DetallePistaScreen({super.key, required this.instalacion});

  @override
  State<DetallePistaScreen> createState() => _DetallePistaScreenState();
}

class _DetallePistaScreenState extends State<DetallePistaScreen> {
  DateTime _fechaSeleccionada = DateTime.now();
  List<Map<String, dynamic>> _horas = [];
  bool _loadingHoras = false;

  @override
  void initState() {
    super.initState();
    _cargarHoras();
  }

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
        _horas = (res['horas'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _loadingHoras = false;
      });
    } catch (_) {
      setState(() => _loadingHoras = false);
    }
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
      backgroundColor: AppTheme.background,
      bottomNavigationBar: activa
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: ElevatedButton(
                  onPressed: () => context.push('/reservar', extra: widget.instalacion),
                  child: const Text('Reservar esta pista'),
                ),
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  imagenUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imagenUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(color: Colors.grey.shade200),
                          errorWidget: (context, url, error) => Container(
                            color: AppTheme.primary.withOpacity(0.2),
                            child: const Icon(Icons.sports_tennis_rounded, size: 80, color: AppTheme.primary),
                          ),
                        )
                      : Container(
                          color: AppTheme.primary.withOpacity(0.2),
                          child: const Icon(Icons.sports_tennis_rounded, size: 80, color: AppTheme.primary),
                        ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(nombre, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700)),
                        if (ubicacion != null)
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 13, color: Colors.white70),
                              const SizedBox(width: 3),
                              Text(ubicacion, style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(tipo, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      const Spacer(),
                      if (!_loadingHoras)
                        Text(
                          '$disponibles horas libres hoy',
                          style: TextStyle(
                            color: disponibles > 0 ? AppTheme.primary : AppTheme.danger,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
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
                            _cargarHoras();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 52,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.primary : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('EEE', 'es').format(dia).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: selected ? Colors.white70 : AppTheme.textMedium,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${dia.day}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: selected ? Colors.white : AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Horarios disponibles',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _leyenda(AppTheme.primary, 'Disponible'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_loadingHoras)
                        const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                      else if (_horas.isEmpty)
                        const Center(
                          child: Text('No hay horarios disponibles para este día',
                              style: TextStyle(color: AppTheme.textMedium)),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _horas.map((h) {
                            final disponible = h['disponible'] as bool;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: disponible
                                    ? AppTheme.primary.withOpacity(0.1)
                                    : AppTheme.danger.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: disponible
                                      ? AppTheme.primary.withOpacity(0.3)
                                      : AppTheme.danger.withOpacity(0.2),
                                ),
                              ),
                              child: Text(
                                h['hora'],
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: disponible ? AppTheme.primary : AppTheme.danger,
                                ),
                              ),
                            ).animate().fadeIn(delay: const Duration(milliseconds: 50));
                          }).toList(),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _leyenda(Color color, String texto) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
        ),
        const SizedBox(width: 5),
        Text(texto, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}