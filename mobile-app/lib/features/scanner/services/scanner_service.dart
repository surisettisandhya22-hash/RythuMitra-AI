import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/api_service.dart';
import '../data/models/scan_result.dart';

class ScannerService {
  final ImagePicker _picker = ImagePicker();
  final ApiService apiService;
  
  String get _baseUrl => ApiConfig.baseUrl;

  ScannerService({required this.apiService});

  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80, // Compress to save bandwidth
      );
      
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  Future<ScanResult?> analyzeImage({
    required File imageFile,
    required String languageId,
    String? cropName,
    String? description,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/scan/analyze');

    try {
      final request = http.MultipartRequest('POST', uri);
      
      request.fields['languageId'] = languageId;
      if (cropName != null && cropName.isNotEmpty) {
        request.fields['cropName'] = cropName;
      }
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }

      final fileBytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        fileBytes,
        filename: 'crop_image.jpg',
      );
      
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(const Duration(seconds: 180));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        return ScanResult.fromJson({
          ...decoded,
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'date': DateTime.now().toIso8601String(),
        });
      } else if (response.statusCode >= 400 && response.statusCode < 500) {
        debugPrint('Analysis Client Error (4xx): ${response.statusCode} - ${response.body}');
        throw Exception('Analysis request failed: ${response.statusCode}');
      } else if (response.statusCode >= 500) {
        debugPrint('Analysis Server Error (5xx): ${response.statusCode} - ${response.body}');
        throw Exception('Analysis server error. Please try again later.');
      } else {
        debugPrint('Analysis API Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } on TimeoutException {
      debugPrint('Analysis API Timeout Exception');
      throw Exception('Image analysis timed out. Please check your network and try again.');
    } on SocketException catch (e) {
      debugPrint('Analysis SocketException: Connection refused/unreachable. Details: $e');
      throw Exception('Network error: Unable to connect to analysis server. Please check if backend is running.');
    } catch (e) {
      debugPrint('Error uploading image for analysis: $e');
      return null;
    }
  }
}

