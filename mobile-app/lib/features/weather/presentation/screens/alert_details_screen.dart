import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/weather_alert.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../voice/services/text_to_speech_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';

class AlertDetailsScreen extends StatelessWidget {
  final WeatherAlert alert;
  final NetworkService networkService;
  
  const AlertDetailsScreen({super.key, required this.alert, required this.networkService});

  void _askRythuMitra(BuildContext context) async {
    final contextMessage = 'I am looking at a weather alert. Type: ${alert.type.name}. It says: ${alert.titleKey}. Can you explain this simply and tell me what I should do? Please do not guarantee any crop damage.';
    final storageService = StorageService();
    await storageService.init();
    
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIAssistantScreen(
            storageService: storageService,
            networkService: networkService,
            alertContext: contextMessage,
          ),
        ),
      );
    }
  }

  void _listen(BuildContext context) async {
    final title = AppLocalizations.of(context).translate(alert.titleKey);
    final desc = AppLocalizations.of(context).translate(alert.descriptionKey);
    
    final voiceService = TextToSpeechService();
    await voiceService.init();
    
    if (context.mounted) {
      final locale = Localizations.localeOf(context).languageCode;
      await voiceService.speak('$title. $desc', locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = AppLocalizations.of(context).translate(alert.titleKey);
    final desc = AppLocalizations.of(context).translate(alert.descriptionKey);

    IconData icon = Icons.info;
    Color color = Colors.blue;
    if (alert.severity == AlertSeverity.important) {
      color = Colors.red;
      icon = Icons.warning;
    } else if (alert.severity == AlertSeverity.attention) {
      color = Colors.orange;
      icon = Icons.error_outline;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('alert_details') == 'alert_details' ? 'Alert Details' : AppLocalizations.of(context).translate('alert_details')),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 48),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              desc,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Text(
              '${AppLocalizations.of(context).translate('last_updated')}: ${alert.timestamp.toLocal().toString().split('.')[0]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.wb_sunny),
                label: Text(AppLocalizations.of(context).translate('view_weather') == 'view_weather' ? 'View Weather' : AppLocalizations.of(context).translate('view_weather')),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _askRythuMitra(context),
                icon: const Icon(Icons.smart_toy),
                label: Text(AppLocalizations.of(context).translate('ask_rythumitra')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade100,
                  foregroundColor: Colors.green.shade900,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _listen(context),
                icon: const Icon(Icons.volume_up),
                label: Text(AppLocalizations.of(context).translate('listen_audio')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blue.shade900,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

