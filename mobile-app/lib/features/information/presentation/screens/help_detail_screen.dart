import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../voice/services/text_to_speech_service.dart';
import '../../data/models/help_topic.dart';

class HelpDetailScreen extends StatefulWidget {
  final HelpTopic topic;
  final StorageService storageService;

  const HelpDetailScreen({
    super.key,
    required this.topic,
    required this.storageService,
  });

  @override
  State<HelpDetailScreen> createState() => _HelpDetailScreenState();
}

class _HelpDetailScreenState extends State<HelpDetailScreen> {
  final TextToSpeechService _ttsService = TextToSpeechService();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _ttsService.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    if (_isPlaying) {
      await _ttsService.stop();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });
      
      final StringBuffer sb = StringBuffer();
      sb.writeln(widget.topic.title);
      sb.writeln(widget.topic.description);
      for (int i = 0; i < widget.topic.steps.length; i++) {
        sb.writeln('Step ${i + 1}: ${widget.topic.steps[i]}');
      }
      
      final languageId = widget.storageService.getSelectedLanguage() ?? 'en';
      final success = await _ttsService.speak(sb.toString(), languageId);
      
      if (!success && mounted) {
        setState(() {
          _isPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Voice is not currently available for this language on your device.'),
            backgroundColor: Colors.orange.shade800,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Help Details'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.topic.icon, size: 48, color: Colors.green.shade700),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.topic.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toggleAudio,
                icon: Icon(_isPlaying ? Icons.stop : Icons.volume_up, size: 28),
                label: Text(
                  _isPlaying ? 'Stop Listening' : 'Listen to Help',
                  style: const TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isPlaying ? Colors.red.shade50 : Colors.green.shade50,
                  foregroundColor: _isPlaying ? Colors.red.shade900 : Colors.green.shade900,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.topic.description,
              style: const TextStyle(
                fontSize: 18,
                height: 1.5,
              ),
            ),
            
            if (widget.topic.steps.isNotEmpty) ...[
              const SizedBox(height: 32),
              const Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              ...widget.topic.steps.asMap().entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            entry.value,
                            style: const TextStyle(
                              fontSize: 18,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}
