import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../services/scanner_service.dart';
import '../../data/models/crop_health_record.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../widgets/add_follow_up_sheet.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:io';

class HealthRecordScreen extends StatefulWidget {
  final CropHealthRecord healthRecord;
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final ScannerService scannerService;
  final NetworkService networkService;
  final String? cropName;

  const HealthRecordScreen({
    super.key,
    required this.healthRecord,
    required this.storageService,
    required this.profileStorageService,
    required this.scannerService,
    required this.networkService,
    this.cropName,
  });

  @override
  State<HealthRecordScreen> createState() => _HealthRecordScreenState();
}

class _HealthRecordScreenState extends State<HealthRecordScreen> {
  late CropHealthRecord _record;

  @override
  void initState() {
    super.initState();
    _record = widget.healthRecord;
  }

  String _formatDate(String isoString) {
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return isoString;
    }
  }

  void _addFollowUp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => AddFollowUpSheet(
        scannerService: widget.scannerService,
        languageId: widget.storageService.getSelectedLanguage() ?? 'en',
        onFollowUpAdded: (followUp) async {
          setState(() {
            _record.followUps.add(followUp);
            _record.currentStatus = followUp.statusUpdate;
            _record.updatedAt = DateTime.now().toIso8601String();
          });
          await widget.profileStorageService.saveCropHealthRecord(_record);
        },
      ),
    );
  }
  
  void _deleteRecord() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('delete_record')),
        content: Text(AppLocalizations.of(context).translate('delete_confirm_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () async {
              await widget.profileStorageService.deleteCropHealthRecord(_record.id);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: Text(AppLocalizations.of(context).translate('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('crop_health_history')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteRecord,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Original Scan Header
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.psychology, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context).translate('initial_scan'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(_record.initialScan.date),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text(
                      _record.initialScan.summary,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${AppLocalizations.of(context).translate('possible_issues')}:',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ..._record.initialScan.possibleIssues.map((i) => Text('• $i')),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context).translate('timeline'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Timeline
            if (_record.followUps.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  AppLocalizations.of(context).translate('no_follow_ups'),
                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
              
            ..._record.followUps.map((fu) {
              return Padding(
                padding: const EdgeInsets.only(left: 8.0, bottom: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 80,
                          color: Colors.green.shade200,
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        elevation: 1,
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).translate('farmer_update'),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                  Text(_formatDate(fu.date), style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${AppLocalizations.of(context).translate('status')}: ${AppLocalizations.of(context).translate('status_${fu.statusUpdate.toLowerCase().replaceAll(' ', '_')}')}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              if (fu.note != null && fu.note!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text('"${fu.note}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                                ),
                              if (fu.imagePath != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(File(fu.imagePath!), height: 100, fit: BoxFit.cover),
                                  ),
                                ),
                              if (fu.newScanResult != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
                                          const SizedBox(width: 4),
                                          Text(
                                            AppLocalizations.of(context).translate('ai_analysis'),
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(fu.newScanResult!.summary, style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_circle_outline),
                    label: Text(AppLocalizations.of(context).translate('add_follow_up')),
                    onPressed: _addFollowUp,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.smart_toy, color: Colors.white),
                label: Text(
                  AppLocalizations.of(context).translate('ask_rythumitra_history'),
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => AIAssistantScreen(
                      storageService: widget.storageService,
                      profileStorageService: widget.profileStorageService,
                      networkService: widget.networkService,
                      healthContext: jsonEncode(_record.toJson()),
                      autoStartListening: false,
                    ),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}
