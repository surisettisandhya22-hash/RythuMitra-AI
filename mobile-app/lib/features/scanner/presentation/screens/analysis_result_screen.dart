import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/storage_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../services/scanner_service.dart';
import '../../data/models/scan_result.dart';
import '../../data/models/crop_health_record.dart';
import '../../../voice/services/text_to_speech_service.dart';

class AnalysisResultScreen extends StatefulWidget {
  final ScanResult scanResult;
  final File imageFile;
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final ScannerService scannerService;
  final String? associatedCropId;

  const AnalysisResultScreen({
    super.key,
    required this.scanResult,
    required this.imageFile,
    required this.storageService,
    required this.profileStorageService,
    required this.scannerService,
    this.associatedCropId,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  final TextToSpeechService _ttsService = TextToSpeechService();
  bool _isPlaying = false;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    _initTTS();
  }
  
  Future<void> _initTTS() async {
    await _ttsService.init();
    _ttsService.setCompletionHandler(() {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _ttsService.stop();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      if (mounted) setState(() => _isPlaying = true);
      final languageId = widget.storageService.getSelectedLanguage() ?? 'en';
      final textToSpeak = "${widget.scanResult.summary}. ${AppLocalizations.of(context).translate('recommended_next_steps')}: ${widget.scanResult.recommendedNextSteps.join('. ')}";
      await _ttsService.speak(textToSpeak, languageId);
      if (mounted) setState(() => _isPlaying = false);
    }
  }
  
  Future<void> _saveResult() async {
    final resultToSave = CropHealthRecord(
      id: widget.scanResult.id,
      cropId: widget.associatedCropId,
      initialScan: widget.scanResult,
      currentStatus: 'Monitoring',
      createdAt: widget.scanResult.date,
      updatedAt: widget.scanResult.date,
    );
    
    await widget.profileStorageService.saveCropHealthRecord(resultToSave);
    if (mounted) {
      setState(() {
        _saved = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('scan_saved_successfully'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('analysis_result')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (!_saved && widget.associatedCropId != null && widget.associatedCropId!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveResult,
              tooltip: AppLocalizations.of(context).translate('save_result'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image and basic info
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    widget.imageFile,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.scanResult.cropName != null && widget.scanResult.cropName!.isNotEmpty)
                        Text(
                          '${AppLocalizations.of(context).translate('crop')}: ${widget.scanResult.cropName}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        widget.scanResult.summary,
                        style: TextStyle(fontSize: 15, color: Colors.grey.shade800),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _toggleAudio,
                        icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up, size: 18),
                        label: Text(_isPlaying 
                            ? AppLocalizations.of(context).translate('stop_audio') 
                            : AppLocalizations.of(context).translate('listen_audio')),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Uncertainty warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade800, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).translate('ai_uncertainty_warning'),
                      style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            _buildSection(
              context, 
              title: AppLocalizations.of(context).translate('possible_issues'),
              icon: Icons.warning_amber_rounded,
              color: Colors.orange,
              items: widget.scanResult.possibleIssues,
            ),
            
            _buildSection(
              context, 
              title: AppLocalizations.of(context).translate('visible_symptoms'),
              icon: Icons.visibility,
              color: Colors.blue,
              items: widget.scanResult.visibleSymptoms,
            ),
            
            _buildSection(
              context, 
              title: AppLocalizations.of(context).translate('recommended_next_steps'),
              icon: Icons.check_circle_outline,
              color: Colors.green,
              items: widget.scanResult.recommendedNextSteps,
            ),
            
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.red.shade200),
              ),
              color: Colors.red.shade50,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.support_agent, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).translate('when_to_seek_expert'),
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red.shade900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      widget.scanResult.whenToSeekExpertHelp,
                      style: TextStyle(color: Colors.red.shade900, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
              },
              icon: const Icon(Icons.camera_alt),
              label: Text(AppLocalizations.of(context).translate('take_another_photo')),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required IconData icon, required MaterialColor color, required List<String> items}) {
    if (items.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color.shade700),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const Divider(height: 24),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade600, fontSize: 16)),
                  Expanded(child: Text(item, style: const TextStyle(fontSize: 15))),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}
