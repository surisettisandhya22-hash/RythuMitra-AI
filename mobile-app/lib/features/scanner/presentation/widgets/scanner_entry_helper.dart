import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../profile/data/models/crop_profile.dart';
import '../../services/scanner_service.dart';
import '../screens/image_preview_screen.dart';

class ScannerEntryHelper {
  static Future<void> showScannerOptions(
    BuildContext context, {
    required StorageService storageService,
    required ProfileStorageService profileStorageService,
    required ScannerService scannerService,
    required NetworkService networkService,
    CropProfile? initialCropContext,
  }) async {
    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).translate('scan_crop_problem'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.camera_alt, color: Colors.white),
                ),
                title: Text(AppLocalizations.of(context).translate('take_photo')),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: Text(AppLocalizations.of(context).translate('choose_from_gallery')),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source != null && context.mounted) {
      final imageFile = await scannerService.pickImage(source);
      if (imageFile != null && context.mounted) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ImagePreviewScreen(
            imageFile: imageFile,
            storageService: storageService,
            profileStorageService: profileStorageService,
            scannerService: scannerService,
            networkService: networkService,
            initialCropContext: initialCropContext,
          ),
        ));
      }
    }
  }
}
