import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../weather/data/repositories/weather_repository.dart';
import '../../../weather/services/weather_alert_engine.dart';
import '../../services/reminder_storage_service.dart';
import '../../domain/models/farm_reminder.dart';
import '../../../weather/domain/models/weather_alert.dart';

class AlertsSummaryCard extends StatefulWidget {
  final WeatherRepository weatherRepository;

  const AlertsSummaryCard({super.key, required this.weatherRepository});

  @override
  State<AlertsSummaryCard> createState() => _AlertsSummaryCardState();
}

class _AlertsSummaryCardState extends State<AlertsSummaryCard> {
  final ReminderStorageService _reminderService = ReminderStorageService();
  final WeatherAlertEngine _alertEngine = WeatherAlertEngine();
  
  List<FarmReminder> _reminders = [];
  List<WeatherAlert> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _reminderService.init();
    final reminders = await _reminderService.getReminders();
    
    List<WeatherAlert> activeAlerts = [];
    final current = widget.weatherRepository.cachedWeather;
    final forecast = widget.weatherRepository.cachedForecast;
    
    if (current != null && forecast != null) {
      activeAlerts = _alertEngine.generateAlerts(current, forecast);
    }

    if (mounted) {
      setState(() {
        _reminders = reminders.where((r) => !r.isCompleted).toList();
        _alerts = activeAlerts.where((a) => !a.isDismissed).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    final totalUpdates = _alerts.length + _reminders.length;
    if (totalUpdates == 0) {
      return const SizedBox.shrink(); // Do not show empty space
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  '$totalUpdates ${AppLocalizations.of(context).translate('updates')}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_alerts.isNotEmpty)
              ..._alerts.take(2).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_outlined, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(child: Text(AppLocalizations.of(context).translate(a.titleKey))),
                  ],
                ),
              )),
            if (_reminders.isNotEmpty)
              ..._reminders.take(2).map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.checklist, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(child: Text(r.title)),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}
