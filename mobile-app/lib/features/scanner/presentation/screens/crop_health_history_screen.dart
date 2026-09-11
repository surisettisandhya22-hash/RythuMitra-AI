import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../services/scanner_service.dart';
import 'health_record_screen.dart';
import '../../data/models/crop_health_record.dart';

class CropHealthHistoryScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final StorageService storageService;
  final ScannerService scannerService;
  final NetworkService networkService;

  const CropHealthHistoryScreen({
    super.key,
    required this.profileStorageService,
    required this.storageService,
    required this.scannerService,
    required this.networkService,
  });

  @override
  State<CropHealthHistoryScreen> createState() => _CropHealthHistoryScreenState();
}

class _CropHealthHistoryScreenState extends State<CropHealthHistoryScreen> {
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(AppLocalizations.of(context).translate('delete_confirm_desc') == 'delete_confirm_desc' ? 'Are you sure you want to delete this record?' : AppLocalizations.of(context).translate('delete_confirm_desc')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await widget.profileStorageService.deleteCropHealthRecord(id);
              },
              child: Text(AppLocalizations.of(context).translate('delete'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('report_history')),
      ),
      body: ValueListenableBuilder<List<CropHealthRecord>>(
        valueListenable: widget.profileStorageService.healthRecordsNotifier,
        builder: (context, records, _) {
          if (records.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.history, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).translate('no_health_checks_yet'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              IconData statusIcon = Icons.visibility;
              Color statusColor = Colors.orange;
              
              if (record.currentStatus == 'Improved') {
                statusIcon = Icons.thumb_up;
                statusColor = Colors.green;
              } else if (record.currentStatus == 'Still Has Problem') {
                statusIcon = Icons.warning;
                statusColor = Colors.red;
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.1),
                    child: Icon(statusIcon, color: statusColor),
                  ),
                  title: Text(
                    record.initialScan.cropName ?? AppLocalizations.of(context).translate('crop'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '${AppLocalizations.of(context).translate('date')}: ${_formatDate(record.initialScan.date)}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.initialScan.summary,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade800),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(record.id),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => HealthRecordScreen(
                        healthRecord: record,
                        storageService: widget.storageService,
                        profileStorageService: widget.profileStorageService,
                        scannerService: widget.scannerService,
                        networkService: widget.networkService,
                        cropName: record.initialScan.cropName ?? '',
                      ),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
