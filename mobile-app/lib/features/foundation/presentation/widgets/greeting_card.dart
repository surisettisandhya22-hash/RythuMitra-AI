import 'package:flutter/material.dart';

class GreetingCard extends StatelessWidget {
  final String greeting;

  const GreetingCard({super.key, required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
        border: Border.all(color: Colors.green.shade100),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              greeting,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.green.shade900,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
