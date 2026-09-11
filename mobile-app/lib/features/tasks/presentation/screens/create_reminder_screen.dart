import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/farm_reminder.dart';
import '../../services/reminder_storage_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../profile/data/models/crop_profile.dart';

class CreateReminderScreen extends StatefulWidget {
  final ReminderStorageService reminderService;
  final ProfileStorageService? profileStorageService;
  final FarmReminder? existingReminder;

  const CreateReminderScreen({
    super.key,
    required this.reminderService,
    this.profileStorageService,
    this.existingReminder,
  });

  @override
  State<CreateReminderScreen> createState() => _CreateReminderScreenState();
}

class _CreateReminderScreenState extends State<CreateReminderScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  
  List<CropProfile> _crops = [];
  String? _selectedCropId;
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingReminder != null;
    
    if (widget.profileStorageService != null) {
      _crops = widget.profileStorageService!.getCrops();
    }
    
    if (_isEditing) {
      final r = widget.existingReminder!;
      _titleController.text = r.title;
      _notesController.text = r.description ?? '';
      _selectedCropId = r.cropId;
      _selectedDate = r.date;
      if (r.hasTime) {
        _selectedTime = TimeOfDay.fromDateTime(r.date);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    final t = AppLocalizations.of(context);
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('enter_title_error'))),
      );
      return;
    }

    final scheduledDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime?.hour ?? 0,
      _selectedTime?.minute ?? 0,
    );

    if (scheduledDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.translate('reminder_time_passed') == 'reminder_time_passed' ? 'The selected reminder time has already passed' : t.translate('reminder_time_passed'))),
      );
      return;
    }

    final reminder = FarmReminder(
      id: _isEditing ? widget.existingReminder!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      cropId: _selectedCropId,
      date: scheduledDate,
      hasTime: _selectedTime != null,
      isCompleted: _isEditing ? widget.existingReminder!.isCompleted : false,
      createdAt: _isEditing ? widget.existingReminder!.createdAt : DateTime.now(),
    );

    final hasPermission = await widget.reminderService.requestNotificationPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.translate('notifications_disabled') == 'notifications_disabled' ? 'Notifications are disabled. You can enable them in your phone settings.' : t.translate('notifications_disabled'))),
        );
      }
    }
    
    if (_isEditing) {
      await widget.reminderService.updateReminder(reminder);
    } else {
      await widget.reminderService.addReminder(reminder);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate(_isEditing ? 'edit' : 'add_reminder')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: '${t.translate('reminder_title')} *',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // Crop Selection
            DropdownButtonFormField<String>(
              initialValue: _selectedCropId,
              decoration: InputDecoration(
                labelText: t.translate('crop'),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String>(
                  value: 'general',
                  child: Text(t.translate('general_farm_reminder')),
                ),
                ..._crops.map((c) {
                  return DropdownMenuItem<String>(
                    value: c.id,
                    child: Text(c.cropName),
                  );
                }),
              ],
              onChanged: (val) {
                setState(() => _selectedCropId = val);
              },
            ),
            const SizedBox(height: 16),
            
            // Date Picker (Required)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${t.translate('date')} *'),
              subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            
            // Time Picker (Optional)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.translate('time')),
              subtitle: Text(_selectedTime != null ? _selectedTime!.format(context) : t.translate('add_time')),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_selectedTime != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: () => setState(() => _selectedTime = null),
                      tooltip: t.translate('clear_time'),
                    ),
                  const Icon(Icons.access_time),
                ],
              ),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime ?? TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // Notes
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: t.translate('notes'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
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
