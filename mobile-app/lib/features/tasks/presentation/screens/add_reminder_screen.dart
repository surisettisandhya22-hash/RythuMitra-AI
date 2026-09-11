import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/farm_reminder.dart';
import '../../services/reminder_storage_service.dart';
import '../../../profile/services/profile_storage_service.dart';

class AddReminderScreen extends StatefulWidget {
  final ReminderStorageService reminderService;
  final ProfileStorageService profileStorageService;
  final String? initialCropId;

  const AddReminderScreen({
    super.key, 
    required this.reminderService,
    required this.profileStorageService,
    this.initialCropId,
  });

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  String? _selectedCropId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCropId != null) {
      _selectedCropId = widget.initialCropId;
    }
  }

  void _save() async {
    if (_titleController.text.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('fill_required_fields') == 'fill_required_fields' ? 'Please fill title and date' : AppLocalizations.of(context).translate('fill_required_fields'))),
      );
      return;
    }

    setState(() => _isSaving = true);

    final permissionGranted = await widget.reminderService.requestNotificationPermission();
    if (!permissionGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).translate('notification_permission_denied') == 'notification_permission_denied' ? 'Notifications disabled. Reminders will only appear inside the app.' : AppLocalizations.of(context).translate('notification_permission_denied'))),
      );
    }

    DateTime finalDate = _selectedDate!;
    if (_selectedTime != null) {
      finalDate = DateTime(
        _selectedDate!.year,
        _selectedDate!.month,
        _selectedDate!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
    }

    final reminder = FarmReminder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descController.text.isNotEmpty ? _descController.text : null,
      cropId: _selectedCropId,
      date: finalDate,
      createdAt: DateTime.now(),
    );

    await widget.reminderService.addReminder(reminder);

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('add_reminder')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).translate('reminder_title'),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).translate('description') == 'description' ? 'Description (Optional)' : AppLocalizations.of(context).translate('description'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _selectedCropId,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context).translate('crop'),
                border: const OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(AppLocalizations.of(context).translate('general_farm_activity') == 'general_farm_activity' ? 'General' : AppLocalizations.of(context).translate('general_farm_activity')),
                ),
                ...widget.profileStorageService.getCrops().map((c) {
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
            const SizedBox(height: 16),
            ListTile(
              title: Text(_selectedDate == null 
                  ? (AppLocalizations.of(context).translate('select_date') == 'select_date' ? 'Select Date *' : AppLocalizations.of(context).translate('select_date'))
                  : '${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            ListTile(
              title: Text(_selectedTime == null 
                  ? (AppLocalizations.of(context).translate('select_time') == 'select_time' ? 'Select Time (Optional)' : AppLocalizations.of(context).translate('select_time'))
                  : _selectedTime!.format(context)),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() => _selectedTime = time);
                }
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(AppLocalizations.of(context).translate('save')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

