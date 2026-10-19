import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';

class DocumentExplainerScreen extends StatefulWidget {
  final String title;
  final String description;
  final StorageService storageService;
  final NetworkService networkService;

  const DocumentExplainerScreen({
    super.key,
    required this.title,
    required this.description,
    required this.storageService,
    required this.networkService,
  });

  @override
  State<DocumentExplainerScreen> createState() => _DocumentExplainerScreenState();
}

class _DocumentExplainerScreenState extends State<DocumentExplainerScreen> {
  File? _imageFile;
  bool _isAnalyzing = false;
  String? _analysisResult;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _analysisResult = null; // reset
      });
    }
  }

  Future<void> _analyzeDocument() async {
    if (_imageFile == null) return;
    
    if (!widget.networkService.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This feature requires an internet connection.')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    // Simulate backend AI call for document analysis
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isAnalyzing = false;
      _analysisResult = "Based on the image provided, this appears to be an official document.\n\n"
          "Key Takeaways:\n"
          "1. Purpose: This document outlines eligibility criteria for a farming subsidy.\n"
          "2. Important Dates: Applications are due by the 30th of next month.\n"
          "3. Required Actions: Make sure you have your land records and Aadhaar card ready before applying.\n\n"
          "If you have specific questions, you can ask the RythuMitra AI Chatbot!";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.description,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 24),
            
            if (_imageFile == null)
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No Image Selected', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(_imageFile!, height: 300, fit: BoxFit.cover),
              ),
              
            const SizedBox(height: 24),
            
            if (_imageFile == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Gallery'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              )
            else if (_analysisResult == null)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _imageFile = null),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Retake'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isAnalyzing ? null : _analyzeDocument,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isAnalyzing
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Explain This'),
                    ),
                  ),
                ],
              ),
              
            if (_analysisResult != null) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.purple.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: Colors.purple.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'AI Explanation',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.purple.shade900),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      _analysisResult!,
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade900, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _imageFile = null;
                        _analysisResult = null;
                      }),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Analyze Another'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
