import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSendMessage;
  final VoidCallback onVoiceTap;
  final bool isThinking;
  final bool isListening;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSendMessage,
    required this.onVoiceTap,
    this.isThinking = false,
    this.isListening = false,
  });

  void _handleSend() {
    final text = controller.text.trim();
    if (text.isNotEmpty && !isThinking) {
      onSendMessage(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        decoration: InputDecoration(
                          hintText: isListening ? 'Listening...' : (AppLocalizations.of(context).translate('ask_placeholder') == 'ask_placeholder' ? 'Ask RythuMitra...' : AppLocalizations.of(context).translate('ask_placeholder')),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.send,
                        color: isThinking ? Colors.grey : Colors.green.shade700,
                      ),
                      onPressed: isThinking ? null : _handleSend,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: isThinking ? null : onVoiceTap,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isThinking 
                      ? Colors.grey 
                      : (isListening ? Colors.red : Colors.green.shade700),
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!isThinking)
                      BoxShadow(
                        color: (isListening ? Colors.red : Colors.green.shade700)
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                  ],
                ),
                child: Icon(
                  isListening ? Icons.stop : Icons.mic,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

