import 'package:app_padel_mudejar/screens/perfil/perfil_scree.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/registro_screen.dart';
import '../screens/main_scaffold.dart';
import '../screens/home/home_screen.dart';
import '../screens/reservas/reservar_screen.dart';
import '../screens/reservas/mis_reservas_screen.dart';
import '../screens/auth/cambiar_password_screen.dart';
import '../screens/horarios/detalle_pista_screen.dart';
import '../screens/torneos/torneos_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Crea y configura el router de la app con go_router.
/// Gestiona la navegación y las redirecciones según el estado de autenticación.
GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',

    /// Lógica de redirección según el estado del socio:
    /// - Sin sesión → /login
    /// - Con sesión pero contraseña por defecto → /cambiar-password
    /// - Con sesión normal → /home
    redirect: (context, state) {
      final loggedIn = authProvider.isLoggedIn;
      final onAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/registro';
      final onCambiarPass =
          state.matchedLocation == '/cambiar-password';

      // Si no está logueado y no está en auth, mandamos al login
      if (!loggedIn && !onAuth) return '/login';

      // Si está logueado y está en auth, mandamos al home o a cambiar contraseña
      if (loggedIn && onAuth) {
        if (authProvider.necesitaCambiarPassword) return '/cambiar-password';
        return '/home';
      }

      // Si está logueado pero necesita cambiar contraseña, bloqueamos el acceso
      if (loggedIn &&
          !onCambiarPass &&
          authProvider.necesitaCambiarPassword) {
        return '/cambiar-password';
      }

      return null;
    },
    refreshListenable: authProvider,
    routes: [
      // --- Rutas de autenticación (sin bottom nav) ---
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/registro',
        builder: (context, state) => const RegistroScreen(),
      ),
      GoRoute(
        path: '/cambiar-password',
        builder: (context, state) => const CambiarPasswordScreen(),
      ),

      // --- App principal con bottom nav ---
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          // Pantalla de inicio con lista de pistas y reseñas
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          // Pantalla de nueva reserva (recibe instalación preseleccionada opcionalmente)
          GoRoute(
            path: '/reservar',
            builder: (context, state) => ReservarScreen(
              instalacionInicial: state.extra as Map<String, dynamic>?,
            ),
          ),
          // Pantalla de mis reservas con pestañas Próximas e Historial
          GoRoute(
            path: '/mis-reservas',
            builder: (context, state) => const MisReservasScreen(),
          ),
          // Detalle de una pista con horarios disponibles y botón de reservar
          GoRoute(
            path: '/horarios/detalle',
            builder: (context, state) => DetallePistaScreen(
              instalacion: state.extra as Map<String, dynamic>,
            ),
          ),
          // Pantalla de torneos con lista y mis próximos partidos
          GoRoute(
            path: '/torneos',
            builder: (context, state) => const TorneosScreen(),
          ),
          // Detalle de un torneo con bracket completo por rondas
          GoRoute(
            path: '/torneos/detalle',
            builder: (context, state) => TorneoDetalleScreen(
              torneo: state.extra as Map<String, dynamic>,
            ),
          ),
          // Pantalla de perfil del socio
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const PerfilScreen(),
          ),
        ],
      ),
    ],
  );
}