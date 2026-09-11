import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/language_utils.dart';

class VoiceSettingsScreen extends StatefulWidget {
  final StorageService storageService;

  const VoiceSettingsScreen({super.key, required this.storageService});

  @override
  State<VoiceSettingsScreen> createState() => _VoiceSettingsScreenState();
}

class _VoiceSettingsScreenState extends State<VoiceSettingsScreen> {
  late bool _autoSpeakEnabled;
  late String _currentLanguageId;
  late double _speechSpeed;

  @override
  void initState() {
    super.initState();
    _autoSpeakEnabled = widget.storageService.getAutoSpeakEnabled();
    _currentLanguageId = widget.storageService.getSelectedLanguage() ?? 'en';
    _speechSpeed = widget.storageService.getSpeechSpeed();
  }

  void _toggleAutoSpeak(bool value) async {
    await widget.storageService.setAutoSpeakEnabled(value);
    setState(() {
      _autoSpeakEnabled = value;
    });
  }

  void _changeSpeechSpeed(double speed) async {
    await widget.storageService.setSpeechSpeed(speed);
    setState(() {
      _speechSpeed = speed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageName = LanguageUtils.getLanguageName(_currentLanguageId);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Customize how RythuMitra speaks to you.',
            style: TextStyle(fontSize: 16, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: SwitchListTile(
                title: const Text('Auto Speak Responses'),
                subtitle: const Text('Automatically read AI responses aloud when they arrive.'),
                value: _autoSpeakEnabled,
                onChanged: _toggleAutoSpeak,
                activeThumbColor: Colors.green.shade600,
                secondary: const Icon(Icons.record_voice_over, color: Colors.green),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.language, color: Colors.green),
              title: const Text('Voice Language'),
              subtitle: Text(languageName),
              trailing: const Icon(Icons.info_outline, color: Colors.grey),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Change app language to change the voice language.'),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Speech Speed', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  RadioGroup<double>(
                    groupValue: _speechSpeed,
                    onChanged: (val) => _changeSpeechSpeed(val!),
                    child: Column(
                      children: [
                        RadioListTile<double>(
                          title: const Text('Slow'),
                          value: 0.3,
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<double>(
                          title: const Text('Normal'),
                          value: 0.5,
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<double>(
                          title: const Text('Fast'),
                          value: 0.8,
                          activeColor: Colors.green,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
