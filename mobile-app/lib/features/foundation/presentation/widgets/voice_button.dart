import 'package:flutter/material.dart';

class VoiceButton extends StatelessWidget {
  final VoidCallback onTap;

  const VoiceButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 32.0),
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.green.shade600,
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade300.withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mic,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap and Speak', // Or localized text based on language
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
