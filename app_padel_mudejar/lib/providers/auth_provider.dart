import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

/// Provider de autenticación de la app.
/// Gestiona el estado del socio logueado, login, registro, logout
/// y recarga de perfil. Usa SharedPreferences para persistir la sesión.
class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _socio;
  bool _isLoading = false;
  String? _error;
  String _passwordActual = '';

  // --- Getters de estado ---
  Map<String, dynamic>? get socio => _socio;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _socio != null;
  String get passwordActual => _passwordActual;

  /// True si la contraseña actual es igual al DNI (contraseña por defecto).
  /// En ese caso el router redirige a /cambiar-password.
  bool get necesitaCambiarPassword => _passwordActual == dni;

  // --- Getters de datos del socio ---
  String get dni => _socio?['dniUsuario'] ?? '';
  String get nombre => _socio?['usuario']?['nombre'] ?? '';
  String get apellidos => _socio?['usuario']?['apellidos'] ?? '';
  String get nombreCompleto => '$nombre $apellidos'.trim();
  String get email => _socio?['correoElectronico'] ?? '';
  String get telefono => _socio?['usuario']?['telefono'] ?? '';
  String get idCarnet => _socio?['idCarnet']?.toString() ?? '';

  /// Intenta restaurar la sesión guardada en SharedPreferences al abrir la app.
  /// Si las credenciales ya no son válidas, las elimina.
  Future<void> cargarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final dniGuardado = prefs.getString('dni_sesion');
    final passGuardado = prefs.getString('pass_sesion');
    if (dniGuardado != null && passGuardado != null) {
      try {
        final result = await ApiService.loginSocio(dniGuardado, passGuardado);
        if (result['success'] == true) {
          _socio = await ApiService.getSocio(dniGuardado);
          _passwordActual = passGuardado;
          notifyListeners();
        } else {
          // Credenciales inválidas — limpiamos la sesión guardada
          await prefs.remove('dni_sesion');
          await prefs.remove('pass_sesion');
        }
      } catch (_) {
        // Error de red — limpiamos por precaución
        await prefs.remove('dni_sesion');
        await prefs.remove('pass_sesion');
      }
    }
  }

  /// Realiza el login del socio con DNI y contraseña.
  /// Guarda la sesión en SharedPreferences y registra el token push de OneSignal.
  /// Devuelve true si el login fue exitoso.
  Future<bool> login(String dni, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.loginSocio(dni, password);

      if (result['success'] != true) {
        // La API usa 'message' en algunos casos y 'mensaje' en otros
        _error = result['message']?.toString() ??
            result['mensaje']?.toString() ??
            'DNI o contraseña incorrectos.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Cargamos el perfil completo del socio
      _socio = await ApiService.getSocio(dni);
      _passwordActual = password;

      // Persistimos la sesión para restaurarla al reabrir la app
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dni_sesion', dni);
      await prefs.setString('pass_sesion', password);

      // Registramos el token de push de OneSignal si está disponible
      try {
        final pushToken = OneSignal.User.pushSubscription.id;
        if (pushToken != null && pushToken.isNotEmpty) {
          await ApiService.registrarPushToken(dni, pushToken);
        }
      } catch (_) {
        // No bloqueamos el login si falla el registro del token push
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Error al iniciar sesión. Comprueba tu conexión.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registra un nuevo socio en el club.
  /// Tras el registro exitoso, inicia sesión automáticamente.
  /// La contraseña inicial es el propio DNI.
  Future<Map<String, dynamic>> registrar(Map<String, dynamic> datos) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.registrarSocio(datos);
      if (result['success'] == true) {
        _socio = result['data'];
        final dni = datos['dni'] as String;
        _passwordActual = dni; // Contraseña inicial = DNI

        // Persistimos la sesión del nuevo socio
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('dni_sesion', dni);
        await prefs.setString('pass_sesion', dni);

        // Registramos el token de push si está disponible
        try {
          final pushToken = OneSignal.User.pushSubscription.id;
          if (pushToken != null && pushToken.isNotEmpty) {
            await ApiService.registrarPushToken(dni, pushToken);
          }
        } catch (_) {
          // No bloqueamos el registro si falla el token push
        }
      }
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _error = 'Error al registrarse. Comprueba tu conexión.';
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  /// Recarga el perfil del socio desde la API.
  /// Se llama tras editar los datos personales para reflejar los cambios en la UI.
  Future<void> recargarPerfil() async {
    try {
      _socio = await ApiService.getSocio(dni);
      notifyListeners();
    } catch (_) {
      // Si falla la recarga no hacemos nada — los datos locales siguen siendo válidos
    }
  }

  /// Cierra la sesión del socio.
  /// Elimina las credenciales de SharedPreferences y limpia el estado.
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dni_sesion');
    await prefs.remove('pass_sesion');
    _socio = null;
    _passwordActual = '';
    notifyListeners();
  }

  /// Limpia el mensaje de error actual.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}