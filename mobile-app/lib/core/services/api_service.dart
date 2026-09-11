import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'backend_config_service.dart';

class ApiService {
  String get baseUrl => BackendConfigService.getBackendUrl(); 

  Future<String> sendChatMessage(String message, String languageId, {Map<String, dynamic>? context}) async {
    try {
      final Map<String, dynamic> body = {
        'message': message,
        'language': languageId,
      };
      
      if (context != null) {
        body['context'] = context;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'];
        if (message == null || message.toString().trim().isEmpty) {
          throw Exception('Empty or invalid response');
        }
        return message;
      } else {
        String errorMessage = 'Server error: ${response.statusCode}. Please try again later.';
        
        if (response.statusCode == 400 || response.statusCode == 404) {
          errorMessage = 'Invalid request. Please try again.';
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          errorMessage = 'Authentication failed. Please verify configuration.';
        } else if (response.statusCode == 500) {
          errorMessage = 'Cloud backend encountered an internal error.';
        } else if (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
          errorMessage = 'AI service is temporarily unavailable. Please try again later.';
        }
        
        try {
          final data = jsonDecode(response.body);
          if (data['detail'] != null) {
            errorMessage = data['detail'];
          }
        } catch (_) {}
        throw Exception(errorMessage);
      }
    } on TimeoutException {
      debugPrint('API Timeout Exception');
      throw Exception('Timeout: Cloud backend unreachable or took too long to respond.');
    } on SocketException catch (e) {
      debugPrint('SocketException: Connection refused or network unreachable. Details: $e');
      throw Exception('No Internet or Cloud backend unreachable.');
    } on FormatException catch (e) {
      debugPrint('FormatException: Invalid JSON response. Details: $e');
      throw Exception('Invalid response from the server.');
    } catch (e) {
      debugPrint('API Service Unexpected Error: $e');
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception('An unexpected error occurred while communicating with the server.');
    }
  }
}
