import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/crop_photo.dart';
import 'add_crop_photo_screen.dart';

class CropPhotoHistoryScreen extends StatelessWidget {
  final ProfileStorageService profileStorageService;
  final String cropId;
  final String cropName;

  const CropPhotoHistoryScreen({
    super.key,
    required this.profileStorageService,
    required this.cropId,
    required this.cropName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$cropName ${AppLocalizations.of(context).translate('photos') == 'photos' ? 'Photos' : AppLocalizations.of(context).translate('photos')}'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<CropPhoto>>(
        valueListenable: profileStorageService.cropPhotosNotifier,
        builder: (context, allPhotos, _) {
          final photos = allPhotos.where((p) => p.cropId == cropId).toList()
            ..sort((a, b) => b.date.compareTo(a.date));

          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library_outlined, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).translate('no_photos_yet') == 'no_photos_yet' ? 'No photos yet' : AppLocalizations.of(context).translate('no_photos_yet'),
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Stack(
                      children: [
                        Image.file(
                          File(photo.imagePath),
                          height: 250,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            height: 250,
                            color: Colors.grey.shade300,
                            child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: CircleAvatar(
                            backgroundColor: Colors.black54,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.white),
                              onPressed: () => _confirmDelete(context, photo.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat.yMMMd().format(photo.date),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                          if (photo.note != null && photo.note!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              photo.note!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCropPhotoScreen(
                profileStorageService: profileStorageService,
                cropId: cropId,
              ),
            ),
          );
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.add_a_photo, color: Colors.white),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String photoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('delete_photo') == 'delete_photo' ? 'Delete Photo' : AppLocalizations.of(context).translate('delete_photo')),
        content: Text(AppLocalizations.of(context).translate('delete_photo_confirm') == 'delete_photo_confirm' ? 'Are you sure you want to delete this photo?' : AppLocalizations.of(context).translate('delete_photo_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              profileStorageService.deleteCropPhoto(photoId);
              Navigator.pop(context);
            },
            child: Text(AppLocalizations.of(context).translate('delete'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
