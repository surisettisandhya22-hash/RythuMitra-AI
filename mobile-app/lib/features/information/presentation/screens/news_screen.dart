import 'package:flutter/material.dart';

class NewsScreen extends StatelessWidget {
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agriculture News'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildNewsCard(
            'Government announces new MSP for Kharif crops',
            'The government has increased the Minimum Support Price for paddy and other major crops...',
            '2 hours ago',
          ),
          _buildNewsCard(
            'New pest-resistant cotton variety approved',
            'Scientists have developed a new variety of cotton that is highly resistant to pink bollworm...',
            '5 hours ago',
          ),
          _buildNewsCard(
            'Monsoon expected to be normal this year',
            'The meteorological department predicts a normal monsoon, bringing relief to farmers across the country...',
            '1 day ago',
          ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(String title, String summary, String time) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Text(summary, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 12),
            Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
