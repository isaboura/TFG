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
import '../screens/horarios/horarios_screen.dart';
import '../screens/auth/cambiar_password_screen.dart';
import '../screens/horarios/detalle_pista_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createRouter(AuthProvider authProvider) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    redirect: (context, state) {
      final loggedIn = authProvider.isLoggedIn;
      final onAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/registro';
      final onCambiarPass = state.matchedLocation == '/cambiar-password';

      if (!loggedIn && !onAuth) return '/login';
      if (loggedIn && onAuth) {
        if (authProvider.necesitaCambiarPassword) return '/cambiar-password';
        return '/home';
      }
      if (loggedIn && !onCambiarPass && authProvider.necesitaCambiarPassword) {
        return '/cambiar-password';
      }
      return null;
    },
    refreshListenable: authProvider,
    routes: [
      // Auth
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/registro',
        builder: (context, state) => const RegistroScreen(),
      ),
      GoRoute(
        path: '/cambiar-password',
        builder: (context, state) => const CambiarPasswordScreen(),
      ),

      // App principal con barra de navegación
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/reservar',
            builder: (context, state) =>  ReservarScreen(
              instalacionInicial: state.extra as Map<String, dynamic>?,
            ),
          ),
          GoRoute(
            path: '/mis-reservas',
            builder: (context, state) => const MisReservasScreen(),
          ),
          GoRoute(
            path: '/horarios',
            builder: (context, state) => const HorariosScreen(),
          ),
          GoRoute(
            path: '/horarios/detalle',
            builder: (context, state) => DetallePistaScreen(
              instalacion: state.extra as Map<String, dynamic>,
            ),
          ),
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const PerfilScreen(),
          ),
        ],
      ),
    ],
  );
}
