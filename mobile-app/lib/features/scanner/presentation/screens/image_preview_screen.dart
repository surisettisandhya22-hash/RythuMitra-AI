import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../profile/data/models/crop_profile.dart';
import '../../services/scanner_service.dart';
import 'analysis_result_screen.dart';

class ImagePreviewScreen extends StatefulWidget {
  final File imageFile;
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final ScannerService scannerService;
  final NetworkService networkService;
  final CropProfile? initialCropContext;

  const ImagePreviewScreen({
    super.key,
    required this.imageFile,
    required this.storageService,
    required this.profileStorageService,
    required this.scannerService,
    required this.networkService,
    this.initialCropContext,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late TextEditingController _descriptionController;
  String? _selectedCropName;
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
    
    if (widget.initialCropContext != null) {
      _selectedCropName = widget.initialCropContext!.cropName;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _analyzeImage() async {
    if (!widget.networkService.isOnline.value) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('feature_requires_internet') == 'feature_requires_internet' ? 'This feature requires an internet connection.' : AppLocalizations.of(context).translate('feature_requires_internet'))),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
    });

    final languageId = widget.storageService.getSelectedLanguage() ?? 'en';

    final result = await widget.scannerService.analyzeImage(
      imageFile: widget.imageFile,
      languageId: languageId,
      cropName: _selectedCropName,
      description: _descriptionController.text.trim(),
    );

    setState(() {
      _isAnalyzing = false;
    });

    if (result != null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(
            scanResult: result,
            imageFile: widget.imageFile,
            storageService: widget.storageService,
            profileStorageService: widget.profileStorageService,
            scannerService: widget.scannerService,
            associatedCropId: widget.profileStorageService.getCrops().firstWhere(
              (c) => c.cropName == _selectedCropName,
              orElse: () => CropProfile(id: '', cropName: ''), // fallback
            ).id,
          ),
        ));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).translate('analysis_failed'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final crops = widget.profileStorageService.getCrops();
    final cropNames = crops.map((c) => c.cropName).toList();
    if (!cropNames.contains('Other')) {
      cropNames.add('Other');
    }
    
    // Ensure selected crop is in list
    if (_selectedCropName != null && !cropNames.contains(_selectedCropName)) {
      cropNames.insert(0, _selectedCropName!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('crop_photo')),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      widget.imageFile,
                      height: 300,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    AppLocalizations.of(context).translate('which_crop'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCropName,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    items: cropNames.map((name) {
                      return DropdownMenuItem(
                        value: name,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedCropName = val;
                      });
                    },
                    hint: Text(AppLocalizations.of(context).translate('select_crop')),
                  ),
                  const SizedBox(height: 24),
                  
                  Text(
                    AppLocalizations.of(context).translate('optional_notes'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context).translate('describe_problem'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(AppLocalizations.of(context).translate('retake')),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _analyzeImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text(AppLocalizations.of(context).translate('analyze')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
