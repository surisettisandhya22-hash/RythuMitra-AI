import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/scanner_service.dart';
import '../../data/models/crop_health_record.dart';

class AddFollowUpSheet extends StatefulWidget {
  final ScannerService scannerService;
  final String languageId;
  final Function(FollowUpRecord) onFollowUpAdded;

  const AddFollowUpSheet({
    super.key,
    required this.scannerService,
    required this.languageId,
    required this.onFollowUpAdded,
  });

  @override
  State<AddFollowUpSheet> createState() => _AddFollowUpSheetState();
}

class _AddFollowUpSheetState extends State<AddFollowUpSheet> {
  String _selectedStatus = 'Monitoring';
  final TextEditingController _noteController = TextEditingController();
  File? _selectedImage;
  bool _analyzePhoto = false;
  bool _isProcessing = false;

  final List<String> _statuses = [
    'Monitoring',
    'Improved',
    'Still Has Problem',
    'Not Checked Yet',
  ];

  Future<void> _pickImage(ImageSource source) async {
    final image = await widget.scannerService.pickImage(source);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _saveFollowUp() async {
    setState(() => _isProcessing = true);
    
    var followUp = FollowUpRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now().toIso8601String(),
      statusUpdate: _selectedStatus,
      note: _noteController.text.trim(),
      imagePath: _selectedImage?.path,
    );
    
    if (_selectedImage != null && _analyzePhoto) {
      final scanResult = await widget.scannerService.analyzeImage(
        imageFile: _selectedImage!,
        languageId: widget.languageId,
      );
      if (scanResult != null) {
        followUp = FollowUpRecord(
          id: followUp.id,
          date: followUp.date,
          statusUpdate: followUp.statusUpdate,
          note: followUp.note,
          imagePath: followUp.imagePath,
          newScanResult: scanResult,
        );
      }
    }
    
    widget.onFollowUpAdded(followUp);
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppLocalizations.of(context).translate('add_follow_up'),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          
          Text(AppLocalizations.of(context).translate('status')),
          DropdownButtonFormField<String>(
            initialValue: _selectedStatus,
            items: _statuses.map((s) => DropdownMenuItem(
              value: s,
              child: Text(AppLocalizations.of(context).translate('status_${s.toLowerCase().replaceAll(' ', '_')}')),
            )).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedStatus = val);
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).translate('add_note'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          if (_selectedImage == null)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt),
                    label: Text(AppLocalizations.of(context).translate('add_photo')),
                    onPressed: () => _pickImage(ImageSource.camera),
                  ),
                ),
              ],
            )
          else ...[
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_selectedImage!, height: 80, width: 80, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CheckboxListTile(
                    title: Text(AppLocalizations.of(context).translate('analyze_new_photo')),
                    value: _analyzePhoto,
                    onChanged: (val) {
                      setState(() => _analyzePhoto = val ?? false);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _selectedImage = null),
                )
              ],
            )
          ],
          
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isProcessing ? null : _saveFollowUp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isProcessing
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(AppLocalizations.of(context).translate('save_result')),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
