import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/weather_alert.dart';
import '../../services/alert_storage_service.dart';
import 'alert_details_screen.dart';
import '../../../../core/services/network_service.dart';

class AlertsScreen extends StatefulWidget {
  final AlertStorageService alertService;
  final NetworkService networkService;

  const AlertsScreen({super.key, required this.alertService, required this.networkService});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    widget.alertService.alertsNotifier.addListener(_onAlertsChanged);
  }

  @override
  void dispose() {
    widget.alertService.alertsNotifier.removeListener(_onAlertsChanged);
    super.dispose();
  }

  void _onAlertsChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final activeAlerts = widget.alertService.getActiveAlerts();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('weather_alerts')),
      ),
      body: activeAlerts.isEmpty
          ? Center(
              child: Text(
                AppLocalizations.of(context).translate('no_alerts'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: activeAlerts.length,
              itemBuilder: (context, index) {
                final alert = activeAlerts[index];
                return _buildAlertCard(context, alert);
              },
            ),
    );
  }

  Widget _buildAlertCard(BuildContext context, WeatherAlert alert) {
    IconData icon;
    Color color;

    switch (alert.type) {
      case AlertType.rain:
        icon = Icons.water_drop;
        color = Colors.blue;
        break;
      case AlertType.highTemperature:
        icon = Icons.wb_sunny;
        color = Colors.orange;
        break;
      case AlertType.strongWind:
        icon = Icons.air;
        color = Colors.grey;
        break;
      case AlertType.temperatureChange:
        icon = Icons.thermostat;
        color = Colors.purple;
        break;
    }

    if (alert.severity == AlertSeverity.important) {
      color = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          AppLocalizations.of(context).translate(alert.titleKey),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          AppLocalizations.of(context).translate(alert.descriptionKey),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlertDetailsScreen(
                alert: alert,
                networkService: widget.networkService,
              ),
            ),
          );
        },
      ),
    );
  }
}
