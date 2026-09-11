import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/storage_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../profile/presentation/screens/edit_crop_screen.dart';
import '../../services/scanner_service.dart';
import '../../../voice/services/speech_recognition_service.dart';
import 'analysis_result_screen.dart';
import 'crop_health_history_screen.dart';
import '../../../../core/services/network_service.dart';

class CropHealthScreen extends StatefulWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final ScannerService scannerService;
  final NetworkService networkService;
  final String? initialCropId;

  const CropHealthScreen({
    super.key,
    required this.storageService,
    required this.profileStorageService,
    required this.scannerService,
    required this.networkService,
    this.initialCropId,
  });

  @override
  State<CropHealthScreen> createState() => _CropHealthScreenState();
}

class _CropHealthScreenState extends State<CropHealthScreen> {
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  final TextEditingController _descriptionController = TextEditingController();
  
  String? _selectedCropName;
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speechService.initialize();
    
    if (widget.initialCropId != null) {
      final crops = widget.profileStorageService.getCrops();
      try {
        _selectedCropName = crops.firstWhere((c) => c.id == widget.initialCropId).cropName;
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _speechService.stopListening();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final image = await widget.scannerService.pickImage(source);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
    } else {
      final languageId = widget.storageService.getSelectedLanguage() ?? 'en';
      setState(() => _isListening = true);
      
      final started = await _speechService.startListening(
        languageId: languageId,
        onResult: (text) {
          setState(() {
            _descriptionController.text = text;
          });
        },
      );
      
      if (!started) {
        setState(() => _isListening = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context).translate('mic_error'))),
          );
        }
      }
    }
  }
  
  Future<File> _getBlankImage() async {
    // 1x1 transparent PNG
    final bytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/blank_crop_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _analyzeCrop() async {
    if (!widget.networkService.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('feature_requires_internet') == 'feature_requires_internet' ? 'This feature requires an internet connection.' : AppLocalizations.of(context).translate('feature_requires_internet'))),
      );
      return;
    }

    if (_selectedCropName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('select_crop'))),
      );
      return;
    }
    
    setState(() => _isAnalyzing = true);

    try {
      final languageId = widget.storageService.getSelectedLanguage() ?? 'en';
      final imageToAnalyze = _selectedImage ?? await _getBlankImage();

      final result = await widget.scannerService.analyzeImage(
        imageFile: imageToAnalyze,
        languageId: languageId,
        cropName: _selectedCropName,
        description: _descriptionController.text.trim(),
      );

      setState(() => _isAnalyzing = false);

      if (result != null) {
        if (mounted) {
          final crops = widget.profileStorageService.getCrops();
          final associatedCrop = crops.firstWhere(
            (c) => c.cropName == _selectedCropName,
            orElse: () => crops.first,
          );

          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => AnalysisResultScreen(
              scanResult: result,
              imageFile: imageToAnalyze,
              storageService: widget.storageService,
              profileStorageService: widget.profileStorageService,
              scannerService: widget.scannerService,
              associatedCropId: associatedCrop.id,
            ),
          ));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(
              AppLocalizations.of(context).translate('crop_analysis_unavailable') == 'crop_analysis_unavailable'
              ? 'Crop analysis is currently unavailable. Please try again.'
              : AppLocalizations.of(context).translate('crop_analysis_unavailable')
            )),
          );
        }
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            AppLocalizations.of(context).translate('no_crop_analysis') == 'no_crop_analysis'
            ? 'No crop analysis is available right now.'
            : AppLocalizations.of(context).translate('no_crop_analysis')
          )),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('crop_health') == 'crop_health' ? 'Crop Health' : AppLocalizations.of(context).translate('crop_health')),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => CropHealthHistoryScreen(
                  profileStorageService: widget.profileStorageService,
                  storageService: widget.storageService,
                  scannerService: widget.scannerService,
                  networkService: widget.networkService,
                )
              ));
            },
            tooltip: AppLocalizations.of(context).translate('report_history'),
          )
        ],
      ),
      body: _isAnalyzing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Colors.green),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context).translate('analyzing_crop'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- CROP SELECTION ---
                  ValueListenableBuilder(
                    valueListenable: widget.profileStorageService.cropsNotifier,
                    builder: (context, crops, _) {
                      if (crops.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Column(
                            children: [
                              Text(
                                AppLocalizations.of(context).translate('no_crops_yet'),
                                style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (_) => EditCropScreen(profileStorageService: widget.profileStorageService)
                                  ));
                                },
                                child: Text(AppLocalizations.of(context).translate('add_crop_market') == 'add_crop_market' ? 'Add Crop' : AppLocalizations.of(context).translate('add_crop_market')),
                              )
                            ],
                          ),
                        );
                      }
                      
                      final cropNames = crops.map((c) => c.cropName).toList();
                      if (_selectedCropName != null && !cropNames.contains(_selectedCropName)) {
                        cropNames.add(_selectedCropName!);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).translate('which_crop'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          InputDecorator(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCropName,
                                isExpanded: true,
                                items: cropNames.map((name) {
                                  return DropdownMenuItem(
                                    value: name,
                                    child: Row(
                                      children: [
                                        const Text('🌱 '),
                                        Text(name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  setState(() {
                                    _selectedCropName = val;
                                  });
                                },
                                hint: Text(AppLocalizations.of(context).translate('select_crop')),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                  const SizedBox(height: 24),
                  
                  // --- ADD PHOTO ---
                  Text(
                    AppLocalizations.of(context).translate('crop_photo'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedImage != null)
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: () => setState(() => _selectedImage = null),
                            ),
                          ),
                        )
                      ],
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: Text(AppLocalizations.of(context).translate('take_photo')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: Text(AppLocalizations.of(context).translate('choose_from_gallery')),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // --- DESCRIBE PROBLEM ---
                  Text(
                    AppLocalizations.of(context).translate('describe_problem') == 'describe_problem' 
                      ? 'Describe Problem' 
                      : AppLocalizations.of(context).translate('describe_problem'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _descriptionController,
                            maxLines: 4,
                            minLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'e.g. Yellow leaves, spots on leaves, insects...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GestureDetector(
                            onTap: _toggleListening,
                            child: CircleAvatar(
                              backgroundColor: _isListening ? Colors.red : Colors.green.shade100,
                              child: Icon(
                                _isListening ? Icons.stop : Icons.mic,
                                color: _isListening ? Colors.white : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  
                  // --- CHECK CROP ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _analyzeCrop,
                      icon: const Icon(Icons.search, size: 24),
                      label: Text(
                        AppLocalizations.of(context).translate('check_crop') == 'check_crop' 
                          ? 'Check Crop' 
                          : AppLocalizations.of(context).translate('check_crop'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
