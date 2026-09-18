import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/registration.dart';
import '../storage/token_storage.dart';

class StudentRegistrationService {
  final TokenStorage _tokenStorage = TokenStorage();

  // ------------------------------------------------------------
  // FREE EVENT REGISTRATION
  // ------------------------------------------------------------

  Future<Map<String, dynamic>> registerForFreeEvent(
    int eventId,
  ) async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/student/registrations/event/$eventId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return jsonDecode(response.body)
          as Map<String, dynamic>;
    }

    if (response.statusCode == 400) {
      throw Exception(
        _extractMessage(
          response.body,
          'Unable to register for event',
        ),
      );
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Session expired. Please login again.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'You do not have permission to register.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'Event not found.',
      );
    }

    throw Exception(
      _extractMessage(
        response.body,
        'Registration failed (${response.statusCode})',
      ),
    );
  }

  // ------------------------------------------------------------
  // CREATE RAZORPAY PAYMENT ORDER
  // ------------------------------------------------------------

  Future<Map<String, dynamic>> createPaymentOrder(
    int eventId,
  ) async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token not found',
      );
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/student/registrations/event/$eventId/payment',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return jsonDecode(response.body)
          as Map<String, dynamic>;
    }

    if (response.statusCode == 400) {
      throw Exception(
        _extractMessage(
          response.body,
          'Unable to create payment order',
        ),
      );
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Session expired. Please login again.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'You do not have permission to register.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'Event not found.',
      );
    }

    throw Exception(
      _extractMessage(
        response.body,
        'Payment order creation failed (${response.statusCode})',
      ),
    );
  }

  // ------------------------------------------------------------
  // VERIFY RAZORPAY PAYMENT
  // ------------------------------------------------------------

  Future<Map<String, dynamic>> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token not found',
      );
    }

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/student/registrations/payment/verify',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature,
      }),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 201) {
      return jsonDecode(response.body)
          as Map<String, dynamic>;
    }

    if (response.statusCode == 400) {
      throw Exception(
        _extractMessage(
          response.body,
          'Payment verification failed',
        ),
      );
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Session expired. Please login again.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'You do not have permission to verify this payment.',
      );
    }

    throw Exception(
      _extractMessage(
        response.body,
        'Payment verification failed (${response.statusCode})',
      ),
    );
  }

  // ------------------------------------------------------------
  // GET MY REGISTRATIONS
  // ------------------------------------------------------------

  Future<List<Registration>> getMyRegistrations() async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token not found',
      );
    }

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/student/registrations',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data =
          jsonDecode(response.body);

      return data
          .map(
            (json) => Registration.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Session expired. Please login again.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'You do not have access to registrations.',
      );
    }

    throw Exception(
      _extractMessage(
        response.body,
        'Failed to load registrations (${response.statusCode})',
      ),
    );
  }

  // ------------------------------------------------------------
  // CANCEL REGISTRATION
  // ------------------------------------------------------------

  Future<void> cancelRegistration(
    int registrationId,
  ) async {
    final token = await _tokenStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'Authentication token not found',
      );
    }

    final response = await http.put(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/student/registrations/$registrationId/cancel',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 ||
        response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 400) {
      throw Exception(
        _extractMessage(
          response.body,
          'Unable to cancel registration.',
        ),
      );
    }

    if (response.statusCode == 401) {
      throw Exception(
        'Session expired. Please login again.',
      );
    }

    if (response.statusCode == 403) {
      throw Exception(
        'You do not have permission to cancel this registration.',
      );
    }

    if (response.statusCode == 404) {
      throw Exception(
        'Registration not found.',
      );
    }

    throw Exception(
      _extractMessage(
        response.body,
        'Failed to cancel registration (${response.statusCode})',
      ),
    );
  }

  // ------------------------------------------------------------
  // EXTRACT BACKEND ERROR MESSAGE
  // ------------------------------------------------------------

  String _extractMessage(
    String body,
    String fallback,
  ) {
    try {
      final data = jsonDecode(body);

      if (data is Map<String, dynamic>) {
        final message =
            data['message'] ?? data['error'];

        if (message != null &&
            message.toString().isNotEmpty) {
          return message.toString();
        }
      }
    } catch (_) {
      // Response was not JSON.
    }

    return fallback;
  }
}