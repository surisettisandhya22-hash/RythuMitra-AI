import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/farm_reminder.dart';
import '../../services/reminder_storage_service.dart';
import 'add_reminder_screen.dart';

import '../../../profile/services/profile_storage_service.dart';

class RemindersScreen extends StatefulWidget {
  final ReminderStorageService reminderService;
  final ProfileStorageService profileStorageService;

  const RemindersScreen({super.key, required this.reminderService, required this.profileStorageService});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<FarmReminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoading = true);
    _reminders = await widget.reminderService.getReminders();
    setState(() => _isLoading = false);
  }

  void _markComplete(FarmReminder reminder) async {
    final updated = FarmReminder(
      id: reminder.id,
      title: reminder.title,
      description: reminder.description,
      cropId: reminder.cropId,
      date: reminder.date,
      isCompleted: true,
      createdAt: reminder.createdAt,
    );
    await widget.reminderService.updateReminder(updated);
    _loadReminders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('reminders')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddReminderScreen(
                reminderService: widget.reminderService,
                profileStorageService: widget.profileStorageService,
              ),
            ),
          );
          if (result == true) {
            _loadReminders();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(AppLocalizations.of(context).translate('add_reminder')),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reminders.isEmpty
              ? Center(
                  child: Text(
                    AppLocalizations.of(context).translate('no_reminders'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _reminders.length,
                  itemBuilder: (context, index) {
                    final reminder = _reminders[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: Icon(
                          reminder.isCompleted ? Icons.check_circle : Icons.calendar_today,
                          color: reminder.isCompleted ? Colors.green : Colors.blue,
                        ),
                        title: Text(
                          reminder.title,
                          style: TextStyle(
                            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        subtitle: Text(
                          '${reminder.date.toLocal().toString().split(' ')[0]} - ${reminder.description ?? ''}',
                        ),
                        trailing: reminder.isCompleted
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () => _markComplete(reminder),
                              ),
                      ),
                    );
                  },
                ),
    );
  }
}
