import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';

class AuthService {
  /// Sends an OTP to a given phone number or email via the backend.
  Future<bool> sendOtp(String contact) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/send-otp');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contact': contact}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Failed to send OTP: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending OTP: $e');
      return false;
    }
  }

  /// Verifies the OTP via the backend.
  Future<bool> verifyOtp(String contact, String otp) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/api/auth/verify-otp');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contact': contact,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        debugPrint('Failed to verify OTP: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error verifying OTP: $e');
      return false;
    }
  }
}
