import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class AuthProvider extends ChangeNotifier {
  Map<String, dynamic>? _socio;
  bool _isLoading = false;
  String? _error;
  String _passwordActual = '';

  Map<String, dynamic>? get socio => _socio;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _socio != null;
  String get passwordActual => _passwordActual;
  bool get necesitaCambiarPassword => _passwordActual == dni;

  String get dni => _socio?['dniUsuario'] ?? '';
  String get nombre => _socio?['usuario']?['nombre'] ?? '';
  String get apellidos => _socio?['usuario']?['apellidos'] ?? '';
  String get nombreCompleto => '$nombre $apellidos'.trim();
  String get email => _socio?['correoElectronico'] ?? '';
  String get telefono => _socio?['usuario']?['telefono'] ?? '';
  String get idCarnet => _socio?['idCarnet']?.toString() ?? '';

  /// Carga sesión guardada al abrir la app
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
          await prefs.remove('dni_sesion');
          await prefs.remove('pass_sesion');
        }
      } catch (_) {
        await prefs.remove('dni_sesion');
        await prefs.remove('pass_sesion');
      }
    }
  }

  /// Login por DNI
  Future<bool> login(String dni, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.loginSocio(dni, password);

      if (result['success'] != true) {
        _error =
            result['message']?.toString() ?? 'DNI o contraseña incorrectos.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _socio = await ApiService.getSocio(dni);
      _passwordActual = password;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dni_sesion', dni);
      await prefs.setString('pass_sesion', password);

      // Registrar token de OneSignal
      try {
        final pushToken = OneSignal.User.pushSubscription.id;
        if (pushToken != null && pushToken.isNotEmpty) {
          await ApiService.registrarPushToken(dni, pushToken);
        }
      } catch (_) {}

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al iniciar sesión. Comprueba tu conexión.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Registro de nuevo socio
  Future<Map<String, dynamic>> registrar(Map<String, dynamic> datos) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await ApiService.registrarSocio(datos);
      if (result['success'] == true) {
        _socio = result['data'];
        final dni = datos['dni'];
        _passwordActual = dni;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('dni_sesion', dni);
        await prefs.setString('pass_sesion', dni);

        // Registrar token de OneSignal
        try {
          final pushToken = OneSignal.User.pushSubscription.id;
          if (pushToken != null && pushToken.isNotEmpty) {
            await ApiService.registrarPushToken(dni, pushToken);
          }
        } catch (_) {}
      }
      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      print('ERROR REGISTRO: $e');
      _error = 'Error: $e';
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Error : $e'};
    }
  }

  /// Actualizar datos del perfil
  Future<bool> actualizarPerfil(Map<String, dynamic> datos) async {
    try {
      final result = await ApiService.actualizarSocio(dni, datos);
      if (result['success'] == true) {
        _socio = await ApiService.getSocio(dni);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Actualizar Perfil
  Future<void> recargarPerfil() async {
    try {
      _socio = await ApiService.getSocio(dni);
      notifyListeners();
    } catch (_) {}
  }

  /// Cerrar sesión
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('dni_sesion');
    await prefs.remove('pass_sesion');
    _socio = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
