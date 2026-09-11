import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/farm_reminder.dart';
import '../../../weather/domain/models/weather_alert.dart';
import '../../../weather/data/repositories/weather_repository.dart';
import '../../../weather/services/weather_alert_engine.dart';
import '../../services/reminder_storage_service.dart';
import 'create_reminder_screen.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../../core/services/storage_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/data/models/crop_profile.dart';
import '../../../../features/voice/presentation/widgets/global_listen_button.dart';

class AlertsScreen extends StatefulWidget {
  final WeatherRepository weatherRepository;
  final StorageService storageService;
  final ProfileStorageService? profileStorageService;
  final NetworkService networkService;
  
  const AlertsScreen({
    super.key,
    required this.weatherRepository,
    required this.storageService,
    required this.networkService,
    this.profileStorageService,
  });

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final ReminderStorageService _reminderService = ReminderStorageService();
  final WeatherAlertEngine _alertEngine = WeatherAlertEngine();
  
  List<FarmReminder> _reminders = [];
  List<CropProfile> _crops = [];
  List<WeatherAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await _reminderService.init();
        final reminders = await _reminderService.getReminders();
    
    if (widget.profileStorageService != null) {
      _crops = widget.profileStorageService!.getCrops();
    }
    
    // Load weather alerts
    List<WeatherAlert> activeAlerts = [];
    final current = widget.weatherRepository.cachedWeather;
    final forecast = widget.weatherRepository.cachedForecast;
    
    if (current != null && forecast != null) {
      activeAlerts = _alertEngine.generateAlerts(current, forecast);
    }
    
    // In a real app we'd filter dismissed alerts here
    
    if (mounted) {
      setState(() {
        _reminders = reminders;
        _alerts = activeAlerts.where((a) => !a.isDismissed).toList();
        _isLoading = false;
      });
    }
  }

  void _dismissAlert(WeatherAlert alert) {
    setState(() {
      alert.isDismissed = true;
      _alerts.remove(alert);
    });
  }

  void _toggleReminder(FarmReminder reminder, bool? value) async {
    reminder.isCompleted = value ?? false;
    await _reminderService.updateReminder(reminder);
    _loadData();
  }

  void _confirmDeleteReminder(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(AppLocalizations.of(context).translate('delete_reminder_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await _reminderService.deleteReminder(id);
                _loadData();
              },
              child: Text(AppLocalizations.of(context).translate('delete'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _askAIAboutAlert(WeatherAlert alert) {
    final alertDesc = AppLocalizations.of(context).translate(alert.descriptionKey);
    final alertTitle = AppLocalizations.of(context).translate(alert.titleKey);
    
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AIAssistantScreen(
        storageService: widget.storageService,
        profileStorageService: widget.profileStorageService,
        networkService: widget.networkService,
        weatherRepository: widget.weatherRepository,
        alertContext: '$alertTitle: $alertDesc',
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('nav_tasks')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlobalListenButton(
                storageService: widget.storageService,
                textBuilder: () {
                  final activeReminders = _reminders.where((r) => !r.isCompleted).length;
                  final String reminderStr = activeReminders > 0 ? 'You have $activeReminders upcoming reminders. ' : 'You have no upcoming reminders. ';
                  
                  final activeAlerts = _alerts.length;
                  final String alertStr = activeAlerts > 0 ? 'There are $activeAlerts active weather alerts. ' : 'There are no active weather alerts. ';
                  
                  return reminderStr + alertStr;
                },
              ),
              const SizedBox(height: 16),
              _buildSectionHeader(AppLocalizations.of(context).translate('weather_alerts'), Icons.warning_amber),
              if (_alerts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(AppLocalizations.of(context).translate('no_alerts'), style: const TextStyle(color: Colors.grey)),
                )
              else
                ..._alerts.map((a) => _buildAlertCard(a)),
                
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionHeader(AppLocalizations.of(context).translate('farm_reminders'), Icons.checklist),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateReminderScreen(reminderService: _reminderService, profileStorageService: widget.profileStorageService)));
                      _loadData();
                    },
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context).translate('add_reminder')),
                  )
                ],
              ),
              
              if (_reminders.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text(AppLocalizations.of(context).translate('no_reminders_yet'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(AppLocalizations.of(context).translate('create_a_reminder'), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateReminderScreen(reminderService: _reminderService, profileStorageService: widget.profileStorageService)));
                          _loadData();
                        },
                        icon: const Icon(Icons.add),
                        label: Text(AppLocalizations.of(context).translate('add_reminder')),
                      )
                    ],
                  ),
                )
              else
                ..._reminders.map((r) => _buildReminderCard(r)),
            ],
          ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.green.shade700),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAlertCard(WeatherAlert alert) {
    Color color;
    IconData icon;
    
    switch (alert.severity) {
      case AlertSeverity.information:
        color = Colors.blue;
        icon = Icons.info_outline;
        break;
      case AlertSeverity.attention:
        color = Colors.orange;
        icon = Icons.warning_amber;
        break;
      case AlertSeverity.important:
        color = Colors.red;
        icon = Icons.error_outline;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).translate(alert.titleKey),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                  onPressed: () => _dismissAlert(alert),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context).translate(alert.descriptionKey)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _askAIAboutAlert(alert),
                  icon: const Icon(Icons.smart_toy, size: 16),
                  label: Text(AppLocalizations.of(context).translate('ask_rythumitra')),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(FarmReminder reminder) {
    final t = AppLocalizations.of(context);
    final isOverdue = !reminder.isCompleted && reminder.date.isBefore(DateTime.now());
    
    String statusText = t.translate('upcoming');
    Color statusColor = Colors.blue;
    if (reminder.isCompleted) {
      statusText = t.translate('completed');
      statusColor = Colors.grey;
    } else if (isOverdue) {
      statusText = t.translate('overdue');
      statusColor = Colors.red;
    }

    String cropName = '';
    if (reminder.cropId == 'general') {
      cropName = t.translate('general_farm_reminder');
    } else if (reminder.cropId != null) {
      cropName = _crops.firstWhere((c) => c.id == reminder.cropId, orElse: () => CropProfile(id: '', cropName: '')).cropName;
    }

    String timeStr = "";
    if (reminder.hasTime) {
      timeStr = " ${TimeOfDay.fromDateTime(reminder.date).format(context)}";
    }
    String dateStr = "${reminder.date.day}/${reminder.date.month}/${reminder.date.year}$timeStr";

    return Card(
      margin: const EdgeInsets.only(top: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: reminder.isCompleted,
              onChanged: (val) => _toggleReminder(reminder, val),
              activeColor: Colors.green,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          reminder.title,
                          style: TextStyle(
                            fontSize: 16,
                            decoration: reminder.isCompleted ? TextDecoration.lineThrough : null,
                            fontWeight: FontWeight.bold,
                            color: reminder.isCompleted ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (cropName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('🌱 $cropName', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                  ],
                  if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(reminder.description!, style: TextStyle(color: Colors.grey.shade700)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: isOverdue ? Colors.red : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 13, color: isOverdue ? Colors.red : Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreateReminderScreen(
                      reminderService: _reminderService, 
                      profileStorageService: widget.profileStorageService,
                      existingReminder: reminder,
                    )));
                    _loadData();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDeleteReminder(reminder.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
