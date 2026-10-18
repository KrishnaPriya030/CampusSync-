
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class CertificateService {
  final TokenStorage _tokenStorage = TokenStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Session expired. Please log in again.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  Future<dynamic> _decodeResponse(http.Response response) async {
    dynamic data;

    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      data = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    }

    final message = data is Map
        ? data['message'] ?? data['error']
        : null;

    throw Exception(
      message?.toString() ??
          'Certificate request failed (${response.statusCode}).',
    );
  }

  Future<List<Map<String, dynamic>>> _getList(String path) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}$path'),
      headers: await _headers(),
    );

    final data = await _decodeResponse(response);

    if (data is! List) {
      throw Exception('Unexpected certificates response from server.');
    }

    return data
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> getMyCertificates() {
    return _getList('/api/student/certificates');
  }

  Future<List<Map<String, dynamic>>> getEventCertificates(
    int eventId,
  ) {
    if (eventId <= 0) throw ArgumentError('Invalid event ID.');

    return _getList(
      '/api/organizer/events/$eventId/certificates',
    );
  }

  Future<Map<String, dynamic>> issueCertificate({
    required int eventId,
    required int studentId,
  }) async {
    if (eventId <= 0 || studentId <= 0) {
      throw ArgumentError('Invalid event or student ID.');
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/organizer/events/'
        '$eventId/certificates/$studentId',
      ),
      headers: await _headers(),
    );

    final data = await _decodeResponse(response);

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw Exception('Unexpected response after issuing certificate.');
  }

  Future<Uint8List> downloadCertificate(int certificateId) async {
    if (certificateId <= 0) {
      throw ArgumentError('Invalid certificate ID.');
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/student/certificates/'
        '$certificateId/download',
      ),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      return response.bodyBytes;
    }

    if (response.statusCode == 401) {
      throw Exception('Session expired. Please log in again.');
    }

    if (response.statusCode == 403) {
      throw Exception('You cannot download this certificate.');
    }

    throw Exception(
      'Certificate download failed (${response.statusCode}).',
    );
  }
}
