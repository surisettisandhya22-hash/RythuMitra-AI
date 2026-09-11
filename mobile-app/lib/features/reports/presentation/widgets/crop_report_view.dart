import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../profile/data/models/crop_profile.dart';
import 'package:intl/intl.dart';

class CropReportView extends StatefulWidget {
  final ProfileStorageService profileStorageService;

  const CropReportView({
    super.key,
    required this.profileStorageService,
  });

  @override
  State<CropReportView> createState() => _CropReportViewState();
}

class _CropReportViewState extends State<CropReportView> {
  String? _selectedCropId;

  @override
  void initState() {
    super.initState();
    final crops = widget.profileStorageService.getCrops();
    if (crops.isNotEmpty) {
      _selectedCropId = crops.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final crops = widget.profileStorageService.getCrops();

    if (crops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            t.translate('no_records_available') == 'no_records_available' ? 'No records available for this period.' : t.translate('no_records_available'),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    CropProfile? selectedCrop;
    if (_selectedCropId != null) {
      try {
        selectedCrop = crops.firstWhere((c) => c.id == _selectedCropId);
      } catch (e) {
        selectedCrop = crops.first;
        _selectedCropId = selectedCrop.id;
      }
    } else {
      selectedCrop = crops.first;
      _selectedCropId = selectedCrop.id;
    }

    final growthRecords = widget.profileStorageService.getGrowthUpdates().where((u) => u.cropId == selectedCrop!.id).length;
    final photoRecords = widget.profileStorageService.getCropPhotosForCrop(selectedCrop.id).length;
    final healthReports = widget.profileStorageService.getHealthRecordsForCrop(selectedCrop.id).length;

    String startDateStr = 'N/A';
    if (selectedCrop.plantingDate != null) {
      final dt = DateTime.tryParse(selectedCrop.plantingDate!);
      if (dt != null) {
        startDateStr = DateFormat('dd MMM yyyy').format(dt);
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.translate('select_crop') == 'select_crop' ? 'Select Crop' : t.translate('select_crop'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCropId,
                isExpanded: true,
                items: crops.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.cropName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCropId = val;
                  });
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.grass, color: Colors.green.shade700, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        selectedCrop.cropName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  _buildReportRow(Icons.calendar_today, t.translate('crop_start_date') == 'crop_start_date' ? 'Crop Start Date' : t.translate('crop_start_date'), startDateStr),
                  const SizedBox(height: 16),
                  _buildReportRow(Icons.trending_up, t.translate('growth_records') == 'growth_records' ? 'Growth Records Count' : t.translate('growth_records'), growthRecords.toString()),
                  const SizedBox(height: 16),
                  _buildReportRow(Icons.photo_library, t.translate('photo_records') == 'photo_records' ? 'Photo Records Count' : t.translate('photo_records'), photoRecords.toString()),
                  const SizedBox(height: 16),
                  _buildReportRow(Icons.health_and_safety, t.translate('health_reports') == 'health_reports' ? 'Health Reports Count' : t.translate('health_reports'), healthReports.toString()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(Icons.list, color: Colors.white),
            label: Text(t.translate('my_crops') == 'my_crops' ? 'My Crops' : t.translate('my_crops'), style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(IconData icon, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.grey.shade800, fontSize: 16)),
          ],
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
