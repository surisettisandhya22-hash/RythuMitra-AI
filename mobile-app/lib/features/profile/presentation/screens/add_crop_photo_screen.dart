import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/crop_photo.dart';

class AddCropPhotoScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final String cropId;

  const AddCropPhotoScreen({
    super.key,
    required this.profileStorageService,
    required this.cropId,
  });

  @override
  State<AddCropPhotoScreen> createState() => _AddCropPhotoScreenState();
}

class _AddCropPhotoScreenState extends State<AddCropPhotoScreen> {
  String? _imagePath;
  DateTime _date = DateTime.now();
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
      });
    }
  }

  void _savePhoto() async {
    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('please_select_image') == 'please_select_image' ? 'Please select an image' : AppLocalizations.of(context).translate('please_select_image'))),
      );
      return;
    }

    setState(() => _isLoading = true);

    final photo = CropPhoto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      cropId: widget.cropId,
      imagePath: _imagePath!,
      date: _date,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
      createdAt: DateTime.now(),
    );

    await widget.profileStorageService.addCropPhoto(photo);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('add_crop_photo') == 'add_crop_photo' ? 'Add Crop Photo' : AppLocalizations.of(context).translate('add_crop_photo')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: () {
                _showImageSourceDialog(context);
              },
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade400, width: 2, style: BorderStyle.solid),
                ),
                child: _imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 64, color: Colors.grey.shade500),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context).translate('tap_to_add_photo') == 'tap_to_add_photo' ? 'Tap to add photo' : AppLocalizations.of(context).translate('tap_to_add_photo'),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Date Picker
            InkWell(
              onTap: () => _selectDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('date') == 'date' ? 'Date' : AppLocalizations.of(context).translate('date'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                child: Text(
                  DateFormat.yMMMd().format(_date),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Note
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).translate('note_optional') == 'note_optional' ? 'Note (Optional)' : AppLocalizations.of(context).translate('note_optional'),
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.note),
              ),
            ),
            const SizedBox(height: 32),

            ElevatedButton(
              onPressed: _isLoading ? null : _savePhoto,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      AppLocalizations.of(context).translate('save') == 'save' ? 'Save' : AppLocalizations.of(context).translate('save'),
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(AppLocalizations.of(context).translate('take_photo') == 'take_photo' ? 'Take Photo' : AppLocalizations.of(context).translate('take_photo')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(AppLocalizations.of(context).translate('choose_from_gallery') == 'choose_from_gallery' ? 'Choose from Gallery' : AppLocalizations.of(context).translate('choose_from_gallery')),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
