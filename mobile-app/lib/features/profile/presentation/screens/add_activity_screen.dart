import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/farm_activity.dart';

class AddActivityScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final FarmActivity? existingActivity;
  final String? initialCropId;

  const AddActivityScreen({
    super.key,
    required this.profileStorageService,
    this.existingActivity,
    this.initialCropId,
  });

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String? _selectedType;
  String? _selectedCropId; // null = General Farm Activity
  
  bool _isEditing = false;
  
  final List<String> _activityTypes = [
    'sowing',
    'irrigation',
    'fertilizer_application',
    'pest_control',
    'weed_control',
    'spraying',
    'field_inspection',
    'harvesting',
    'selling',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingActivity != null;
    
    if (_isEditing) {
      final a = widget.existingActivity!;
      _selectedDate = a.date;
      _selectedType = a.activityType;
      _selectedCropId = a.cropId;
      _notesController.text = a.notes ?? '';
      
      if (!_activityTypes.contains(_selectedType)) {
        _activityTypes.add(_selectedType!);
      }
    } else if (widget.initialCropId != null) {
      _selectedCropId = widget.initialCropId;
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    final t = AppLocalizations.of(context);
    
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.translate('activity_type')} is required.')),
      );
      return;
    }

    final activity = FarmActivity(
      id: _isEditing ? widget.existingActivity!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      activityType: _selectedType!,
      cropId: _selectedCropId,
      date: _selectedDate,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (_isEditing) {
      await widget.profileStorageService.updateActivity(activity);
    } else {
      await widget.profileStorageService.addActivity(activity);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final crops = widget.profileStorageService.getCrops();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate(_isEditing ? 'edit' : 'add_activity')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Activity Type (Required)
            Text('${t.translate('activity_type')} *', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: _activityTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(t.translate(type) == type ? type : t.translate(type)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedType = val);
              },
            ),
            const SizedBox(height: 24),
            
            // Crop Selection (Optional)
            Text(t.translate('crop'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _selectedCropId,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(t.translate('general_farm_activity')),
                ),
                ...crops.map((c) {
                  return DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text(c.cropName),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() => _selectedCropId = val);
              },
            ),
            const SizedBox(height: 24),

            // Date Picker (Required)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${t.translate('date')} *', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // Notes
            Text(t.translate('notes'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(t.translate('save'), style: const TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
