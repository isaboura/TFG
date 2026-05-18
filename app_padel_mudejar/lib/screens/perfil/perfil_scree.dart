import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar y nombre
            Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(
                    auth.nombre.isNotEmpty ? auth.nombre[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                ).animate().scale(begin: const Offset(0.8, 0.8)).fadeIn(),
                const SizedBox(height: 12),
                Text(
                  auth.nombreCompleto,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Nº Socio: ${auth.idCarnet}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),

            const SizedBox(height: 28),

            // Datos personales
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Datos personales',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark),
                      ),
                      GestureDetector(
                        onTap: () => _mostrarEditarPerfil(context, auth),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.edit_rounded, color: AppTheme.primary, size: 14),
                              SizedBox(width: 4),
                              Text('Editar', style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _DataRow(icon: Icons.badge_rounded, label: 'DNI', value: auth.dni),
                  _DataRow(icon: Icons.email_outlined, label: 'Email', value: auth.email),
                  _DataRow(icon: Icons.phone_outlined, label: 'Teléfono', value: auth.telefono),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 16),

            // Actividad
            _SectionCard(
              title: 'Actividad',
              children: [
                _ActionRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'Mis reservas',
                  onTap: () => context.go('/mis-reservas'),
                ),
                _ActionRow(
                  icon: Icons.history_rounded,
                  label: 'Historial',
                  onTap: () => context.go('/mis-reservas'),
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 24),

            // Cerrar sesión
            OutlinedButton.icon(
              onPressed: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Cerrar sesión'),
                    content: const Text('¿Seguro que quieres salir?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        child: const Text('Salir', style: TextStyle(color: AppTheme.danger)),
                      ),
                    ],
                  ),
                );
                if (shouldLogout == true) {
                  await context.read<AuthProvider>().logout();
                  if (context.mounted) context.go('/login');
                }
              },
              icon: const Icon(Icons.logout_rounded, color: AppTheme.danger),
              label: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.danger)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                side: const BorderSide(color: AppTheme.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ).animate().fadeIn(delay: 500.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _mostrarEditarPerfil(BuildContext context, AuthProvider auth) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditarPerfilBottomSheet(
        auth: auth,
        onActualizado: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Perfil actualizado'), backgroundColor: AppTheme.primary),
          );
        },
      ),
    );
  }
}

class _EditarPerfilBottomSheet extends StatefulWidget {
  final AuthProvider auth;
  final VoidCallback onActualizado;

  const _EditarPerfilBottomSheet({required this.auth, required this.onActualizado});

  @override
  State<_EditarPerfilBottomSheet> createState() => _EditarPerfilBottomSheetState();
}

class _EditarPerfilBottomSheetState extends State<_EditarPerfilBottomSheet> {
  late TextEditingController _nombreCtrl;
  late TextEditingController _apellidosCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _emailCtrl;
  bool _guardando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.auth.nombre);
    _apellidosCtrl = TextEditingController(text: widget.auth.apellidos);
    _telefonoCtrl = TextEditingController(text: widget.auth.telefono);
    _emailCtrl = TextEditingController(text: widget.auth.email);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidosCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    setState(() { _guardando = true; _error = null; });
    try {
      final result = await ApiService.actualizarSocio(widget.auth.dni, {
        'nombre': _nombreCtrl.text.trim(),
        'apellidos': _apellidosCtrl.text.trim(),
        'telefono': _telefonoCtrl.text.trim(),
        'correoElectronico': _emailCtrl.text.trim(),
      });
      if (mounted) {
        if (result['success'] == true) {
          // Recargar datos del socio
          await widget.auth.recargarPerfil();
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
        _error = e.toString();
        _guardando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Editar perfil', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _campo('Nombre', _nombreCtrl, Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _campo('Apellidos', _apellidosCtrl, Icons.person_outline_rounded),
                  const SizedBox(height: 12),
                  _campo('Teléfono', _telefonoCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: 12),
                  _campo('Email', _emailCtrl, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppTheme.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                          const SizedBox(width: 8),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    child: _guardando
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Guardar cambios'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _campo(String label, TextEditingController ctrl, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        filled: true,
        fillColor: AppTheme.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.primary, width: 2)),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DataRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primary, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: AppTheme.textMedium, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionRow({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primary, size: 18),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: AppTheme.textDark, fontSize: 14)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
          ],
        ),
      ),
    );
  }
}