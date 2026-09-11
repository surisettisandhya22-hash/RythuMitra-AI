import 'package:flutter/material.dart';

class HelpTopic {
  final String id;
  final String title;
  final String description;
  final List<String> steps;
  final IconData icon;
  final bool isFaq;

  const HelpTopic({
    required this.id,
    required this.title,
    required this.description,
    this.steps = const [],
    required this.icon,
    this.isFaq = false,
  });
}
