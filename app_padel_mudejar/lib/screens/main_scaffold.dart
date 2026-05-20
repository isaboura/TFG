import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Scaffold principal de la app con bottom navigation bar transparente.
/// Contiene 4 pestañas: Inicio, Reservas, Torneos y Perfil.
/// El fondo es transparente para que el degradado de cada pantalla se vea completo.
class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  /// Determina el índice activo según la ruta actual.
  /// 0 = Inicio, 1 = Reservas, 2 = Torneos, 3 = Perfil
  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/home')) {
      return 0;
    }
    if (location.startsWith('/reservar') ||
        location.startsWith('/mis-reservas')) {
      return 1;
    }
    if (location.startsWith('/torneos')) {
      return 2;
    }
    if (location.startsWith('/perfil')) {
      return 3;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Color de fondo que coincide con el final del degradado de las pantallas
      backgroundColor: const Color(0xFF0D2B1E),
      body: child,
      bottomNavigationBar: Container(
        // Transparente para integrarse con el degradado de la pantalla activa
        decoration: const BoxDecoration(color: Colors.transparent),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Pestaña Inicio
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Inicio',
                  selected: _currentIndex(context) == 0,
                  onTap: () => context.go('/home'),
                ),
                // Pestaña Reservas
                _NavItem(
                  icon: Icons.calendar_month_rounded,
                  label: 'Reservas',
                  selected: _currentIndex(context) == 1,
                  onTap: () => context.go('/mis-reservas'),
                ),
                // Pestaña Torneos
                _NavItem(
                  icon: Icons.emoji_events_rounded,
                  label: 'Torneos',
                  selected: _currentIndex(context) == 2,
                  onTap: () => context.go('/torneos'),
                ),
                // Pestaña Perfil
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Perfil',
                  selected: _currentIndex(context) == 3,
                  onTap: () => context.go('/perfil'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Item del bottom navigation bar.
/// Muestra icono y etiqueta, con fondo semitransparente cuando está seleccionado.
class _NavItem extends StatelessWidget {
  final IconData icon;      // Icono del item
  final String label;       // Etiqueta del item
  final bool selected;      // Si está seleccionado actualmente
  final VoidCallback onTap; // Callback al pulsar

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Fondo blanco semitransparente cuando está seleccionado
          color: selected
              ? Colors.white.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono blanco sólido si seleccionado, semitransparente si no
            Icon(
              icon,
              color: selected ? Colors.white : Colors.white60,
              size: 24,
            ),
            const SizedBox(height: 2),
            // Etiqueta con peso de fuente según selección
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? Colors.white : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}