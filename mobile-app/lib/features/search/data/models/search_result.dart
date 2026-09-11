import 'package:flutter/material.dart';

enum SearchResultCategory {
  crops,
  activities,
  expenses,
  income,
  reminders,
  contacts,
  growth,
  photos,
  health,
  knowledge,
  tasks
}

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final SearchResultCategory category;
  final IconData icon;
  final dynamic originalData;

  const SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.icon,
    required this.originalData,
  });
}
