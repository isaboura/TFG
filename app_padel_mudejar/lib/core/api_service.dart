import 'dart:convert';
import 'package:http/http.dart' as http;

/// Servicio central de comunicación con la API del Club de Pádel Mudéjar.
/// Todas las llamadas HTTP pasan por aquí.
/// Base URL: https://clubpadelmudejar.starglob.com/api
class ApiService {
  static const String baseUrl = 'https://clubpadelmudejar.starglob.com/api';

  // ─────────────────────────────────────────────
  // INSTALACIONES
  // ─────────────────────────────────────────────

  /// Devuelve la lista de instalaciones.
  /// [estado] opcional: 'ACTIVA' o 'MANTENIMIENTO'
  static Future<List<dynamic>> getInstalaciones({String? estado}) async {
    final uri = Uri.parse(
      '$baseUrl/instalaciones',
    ).replace(queryParameters: estado != null ? {'estado': estado} : null);
    final res = await http.get(uri);
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'] as List<dynamic>;
    throw Exception(body['message'] ?? 'Error al cargar instalaciones');
  }

  /// Devuelve una instalación por su ID.
  static Future<Map<String, dynamic>> getInstalacion(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/instalaciones/$id'));
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'];
    throw Exception(body['message'] ?? 'Instalación no encontrada');
  }

  // ─────────────────────────────────────────────
  // DISPONIBILIDAD Y RESERVAS
  // ─────────────────────────────────────────────

  /// Devuelve las horas disponibles para una pista en una fecha y duración dadas.
  static Future<Map<String, dynamic>> getHorasDisponibles({
    required String fecha,
    required String instalacion,
    required int duracion,
  }) async {
    final uri = Uri.parse('$baseUrl/reservas/horas-disponibles').replace(
      queryParameters: {
        'fecha': fecha,
        'instalacion': instalacion,
        'duracion': duracion.toString(),
      },
    );
    final res = await http.get(uri);
    return jsonDecode(res.body);
  }

  /// Devuelve la primera fecha/hora disponible para una pista y duración.
  /// Busca hasta 30 días hacia adelante.
  static Future<Map<String, dynamic>> getProximaDisponible({
    required String instalacion,
    required int duracion,
  }) async {
    final uri = Uri.parse('$baseUrl/reservas/proxima-disponible').replace(
      queryParameters: {
        'instalacion': instalacion,
        'duracion': duracion.toString(),
      },
    );
    final res = await http.get(uri);
    return jsonDecode(res.body);
  }

  /// Crea una nueva reserva para el socio.
  static Future<Map<String, dynamic>> crearReserva({
    required String dniSocio,
    required String instalacion,
    required int idTarifa,
    required String fechaHora,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/reservas'),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      body: jsonEncode({
        'dniSocio': dniSocio,
        'instalacion': instalacion,
        'idTarifa': idTarifa,
        'fechaHora': fechaHora,
      }),
    );
    return jsonDecode(res.body);
  }

  /// Cancela una reserva por su ID.
  /// Cancela una reserva por su ID.
  /// Requiere el DNI del socio para verificar que es el propietario.
  static Future<Map<String, dynamic>> cancelarReserva(
    int idReserva,
    String dniSocio,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/reservas/$idReserva/cancelar'),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      body: jsonEncode({'dniSocio': dniSocio}),
    );
    return jsonDecode(res.body);
  }

  /// Devuelve los datos de una reserva por su ID.
  static Future<Map<String, dynamic>> getReserva(int idReserva) async {
    final res = await http.get(Uri.parse('$baseUrl/reservas/$idReserva'));
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'];
    throw Exception(body['message'] ?? 'Reserva no encontrada');
  }

  /// Reagenda una reserva existente con nuevos datos de pista, tarifa, fecha y hora.
  static Future<Map<String, dynamic>> reagendarReserva(
    int idReserva,
    Map<String, dynamic> datos,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/reservas/$idReserva/mia'),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      body: jsonEncode(datos),
    );
    return jsonDecode(res.body);
  }

  // ─────────────────────────────────────────────
  // SOCIOS
  // ─────────────────────────────────────────────

  /// Comprueba las credenciales del socio (login).
  /// Devuelve el body completo para manejar éxito/error en el AuthProvider.
  static Future<Map<String, dynamic>> loginSocio(
    String dni,
    String password,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/socios/is-socio'),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      body: jsonEncode({'usuario': dni, 'passwd': password}),
    );
    return jsonDecode(res.body);
  }

  /// Devuelve el perfil completo de un socio por su DNI.
  static Future<Map<String, dynamic>> getSocio(String dni) async {
    final res = await http.get(Uri.parse('$baseUrl/socios/$dni'));
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'];
    throw Exception(body['message'] ?? 'Socio no encontrado');
  }

  /// Devuelve las reservas futuras y pasadas del socio.
  static Future<Map<String, dynamic>> getReservasSocio(String dni) async {
    final res = await http.get(Uri.parse('$baseUrl/socios/$dni/reservas'));
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'];
    throw Exception(body['message'] ?? 'Error al cargar reservas');
  }

  /// Actualiza los datos del perfil del socio.
  /// Solo se envían los campos que se quieren cambiar.
  static Future<Map<String, dynamic>> actualizarSocio(
    String dni,
    Map<String, dynamic> datos,
  ) async {
    final res = await http.put(
      Uri.parse('$baseUrl/socios/$dni'),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'Accept': 'application/json',
      },
      body: jsonEncode(datos),
    );
    return jsonDecode(res.body);
  }

  /// Registra un nuevo socio en el club.
  /// La contraseña inicial es el propio DNI.
  static Future<Map<String, dynamic>> registrarSocio(
    Map<String, dynamic> datos,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/socios'),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      body: jsonEncode(datos),
    );
    return jsonDecode(res.body);
  }

  /// Registra el token de notificaciones push (OneSignal Subscription ID).
  /// Debe llamarse justo después de un login exitoso.
  static Future<Map<String, dynamic>> registrarPushToken(
    String dniSocio,
    String pushToken,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/socios/push-token'),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      body: jsonEncode({'dniSocio': dniSocio, 'push_token': pushToken}),
    );
    return jsonDecode(res.body);
  }

  /// Devuelve los próximos partidos de torneo del socio.
  /// Solo devuelve partidos PENDIENTE con pista y horario asignados.
  /// Si el socio no pertenece a ningún equipo, devuelve lista vacía.
  static Future<List<dynamic>> getPartidosSocio(String dni) async {
    final res = await http.get(Uri.parse('$baseUrl/socios/$dni/partidos'));
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'] as List<dynamic>;
    throw Exception(body['message'] ?? 'Error al cargar partidos');
  }

  // ─────────────────────────────────────────────
  // TARIFAS
  // ─────────────────────────────────────────────

  /// Devuelve la lista de tarifas disponibles.
  /// [soloActivas] filtra solo las tarifas activas.
  static Future<List<dynamic>> getTarifas({bool soloActivas = true}) async {
    final uri = Uri.parse(
      '$baseUrl/tarifas',
    ).replace(queryParameters: soloActivas ? {'activa': 'true'} : null);
    final res = await http.get(uri);
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'] as List<dynamic>;
    throw Exception(body['message'] ?? 'Error al cargar tarifas');
  }

  // ─────────────────────────────────────────────
  // RESEÑAS
  // ─────────────────────────────────────────────

  /// Devuelve las reseñas de una instalación con promedio y total.
  static Future<Map<String, dynamic>> getResenas(String idInstalacion) async {
    final res = await http.get(
      Uri.parse('$baseUrl/instalaciones/$idInstalacion/resenas'),
    );
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'];
    throw Exception(body['message'] ?? 'Error al cargar reseñas');
  }

  /// Crea una nueva reseña para una instalación.
  static Future<Map<String, dynamic>> crearResena(
    String idInstalacion,
    Map<String, dynamic> datos,
  ) async {
    final res = await http.post(
      Uri.parse('$baseUrl/instalaciones/$idInstalacion/resenas'),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      body: jsonEncode(datos),
    );
    return jsonDecode(res.body);
  }

  /// Edita una reseña propia del socio.
  static Future<Map<String, dynamic>> editarResena(
    int idResena,
    Map<String, dynamic> datos,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/resenas/$idResena/mia'),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      body: jsonEncode(datos),
    );
    return jsonDecode(res.body);
  }

  /// Elimina una reseña propia del socio.
  static Future<Map<String, dynamic>> eliminarResena(
    int idResena,
    String dniSocio,
  ) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/resenas/$idResena/mia'),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
      body: jsonEncode({'dniSocio': dniSocio}),
    );
    return jsonDecode(res.body);
  }

  // ─────────────────────────────────────────────
  // TORNEOS
  // ─────────────────────────────────────────────

  /// Devuelve la lista de torneos.
  /// [estado] opcional: 'PENDIENTE', 'EN_CURSO', 'FINALIZADO'
  /// [deporte] opcional: filtra por deporte (ej. 'Fútbol Sala')
  /// Los torneos se devuelven ordenados: EN_CURSO → PENDIENTE → FINALIZADO
  static Future<List<dynamic>> getTorneos({
    String? estado,
    String? deporte,
  }) async {
    final params = <String, String>{};
    if (estado != null) params['estado'] = estado;
    if (deporte != null) params['deporte'] = deporte;
    final uri = Uri.parse(
      '$baseUrl/torneos',
    ).replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri);
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'] as List<dynamic>;
    throw Exception(body['message'] ?? 'Error al cargar torneos');
  }

  /// Devuelve un torneo con su bracket completo (equipos, partidos por ronda y resultados).
  static Future<Map<String, dynamic>> getTorneo(int idTorneo) async {
    final res = await http.get(Uri.parse('$baseUrl/torneos/$idTorneo'));
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'];
    throw Exception(body['message'] ?? 'Torneo no encontrado');
  }
}
