import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://clubpadelmudejar.starglob.com/api';

  // INSTALACIONES
  static Future<List<dynamic>> getInstalaciones({String? estado}) async {
    final uri = Uri.parse(
      '$baseUrl/instalaciones',
    ).replace(queryParameters: estado != null ? {'estado': estado} : null);
    final res = await http.get(uri);
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'] as List<dynamic>;
    throw Exception(body['message'] ?? 'Error al cargar instalaciones');
  }

  static Future<Map<String, dynamic>> getInstalacion(String id) async {
    final res = await http.get(Uri.parse('$baseUrl/instalaciones/$id'));
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'];
    throw Exception(body['message'] ?? 'Instalación no encontrada');
  }

  // DISPONIBILIDAD Y RESERVAS

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

  static Future<Map<String, dynamic>> cancelarReserva(int idReserva) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/reservas/$idReserva/cancelar'),
      headers: {
        'Content-Type': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
      },
    );
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getReserva(int idReserva) async {
    final res = await http.get(Uri.parse('$baseUrl/reservas/$idReserva'));
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'];
    throw Exception(body['message'] ?? 'Reserva no encontrada');
  }

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

  // SOCIOS

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
    print('STATUS LOGIN: ${res.statusCode}');
    print('BODY LOGIN: ${res.body}');
    return jsonDecode(res.body);
  }

  static Future<Map<String, dynamic>> getSocio(String dni) async {
    final res = await http.get(Uri.parse('$baseUrl/socios/$dni'));
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'];
    throw Exception(body['message'] ?? 'Socio no encontrado');
  }

  static Future<Map<String, dynamic>> getReservasSocio(String dni) async {
    final res = await http.get(Uri.parse('$baseUrl/socios/$dni/reservas'));
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'];
    throw Exception(body['message'] ?? 'Error al cargar reservas');
  }

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
    print('STATUS REGISTRO: ${res.statusCode}');
    print('BODY REGISTRO: ${res.body}');
    return jsonDecode(res.body);
  }

  // TARIFAS

  static Future<List<dynamic>> getTarifas({bool soloActivas = true}) async {
    final uri = Uri.parse(
      '$baseUrl/tarifas',
    ).replace(queryParameters: soloActivas ? {'activa': 'true'} : null);
    final res = await http.get(uri);
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'] as List<dynamic>;
    throw Exception(body['message'] ?? 'Error al cargar tarifas');
  }

  // RESEÑAS
  static Future<Map<String, dynamic>> getResenas(String idInstalacion) async {
    final res = await http.get(
      Uri.parse('$baseUrl/instalaciones/$idInstalacion/resenas'),
    );
    print('RESENAS STATUS: ${res.statusCode}');
    print('RESENAS BODY: ${res.body}');
    final body = jsonDecode(res.body);
    if (body['success'] == true) return body['data'];
    throw Exception(body['message'] ?? 'Error al cargar reseña');
  }

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

  // TOKENS
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
}
