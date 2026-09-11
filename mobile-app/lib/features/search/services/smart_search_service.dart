import 'package:flutter/material.dart';
import '../../profile/services/profile_storage_service.dart';
import '../../emergency/services/emergency_storage_service.dart';
import '../../tasks/services/reminder_storage_service.dart';
import '../../information/services/help_service.dart';
import '../data/models/search_result.dart';

import '../../planner/services/task_storage_service.dart';

class SmartSearchService {
  final ProfileStorageService profileStorage;
  final EmergencyStorageService emergencyStorage;
  final ReminderStorageService reminderStorage;
  final TaskStorageService? taskStorage;

  SmartSearchService({
    required this.profileStorage,
    required this.emergencyStorage,
    required this.reminderStorage,
    this.taskStorage,
  });

  Future<List<SearchResult>> searchAll(String query, {String languageCode = 'en'}) async {
    final lowerQuery = query.toLowerCase();
    List<SearchResult> results = [];

    // 1. Crops
    final crops = profileStorage.getCrops();
    for (var crop in crops) {
      if (crop.cropName.toLowerCase().contains(lowerQuery) || 
          (crop.variety?.toLowerCase().contains(lowerQuery) ?? false) ||
          (crop.notes?.toLowerCase().contains(lowerQuery) ?? false)) {
        results.add(SearchResult(
          id: 'crop_${crop.id}',
          title: crop.cropName,
          subtitle: crop.variety ?? 'Crop Profile',
          category: SearchResultCategory.crops,
          icon: Icons.agriculture,
          originalData: crop,
        ));
      }
    }

    // 2. Activities
    final activities = profileStorage.getActivities();
    for (var act in activities) {
      if (act.activityType.toLowerCase().contains(lowerQuery) ||
          (act.notes?.toLowerCase().contains(lowerQuery) ?? false)) {
        results.add(SearchResult(
          id: 'act_${act.id}',
          title: act.activityType,
          subtitle: _formatDate(act.date),
          category: SearchResultCategory.activities,
          icon: Icons.list_alt,
          originalData: act,
        ));
      }
    }

    // 3. Expenses
    final expenses = profileStorage.getExpenses();
    for (var exp in expenses) {
      if (exp.expenseType.toLowerCase().contains(lowerQuery) ||
          (exp.notes?.toLowerCase().contains(lowerQuery) ?? false)) {
        results.add(SearchResult(
          id: 'exp_${exp.id}',
          title: exp.expenseType,
          subtitle: '₹${exp.amount}',
          category: SearchResultCategory.expenses,
          icon: Icons.receipt_long,
          originalData: exp,
        ));
      }
    }

    // 4. Sales/Income
    final sales = profileStorage.getSales();
    for (var sale in sales) {
      // Find crop name for better matching
      final crop = profileStorage.getCrops().where((c) => c.id == sale.cropId).firstOrNull;
      final cropName = crop?.cropName ?? 'Unknown Crop';
      
      if (cropName.toLowerCase().contains(lowerQuery) ||
          (sale.buyer?.toLowerCase().contains(lowerQuery) ?? false) ||
          (sale.notes?.toLowerCase().contains(lowerQuery) ?? false)) {
        results.add(SearchResult(
          id: 'sale_${sale.id}',
          title: 'Sale: $cropName',
          subtitle: '₹${sale.totalSaleValue} from ${sale.buyer ?? 'Unknown'}',
          category: SearchResultCategory.income,
          icon: Icons.payments,
          originalData: sale,
        ));
      }
    }

    // 5. Reminders
    final reminders = await reminderStorage.getReminders();
    for (var rem in reminders) {
      if (rem.title.toLowerCase().contains(lowerQuery) ||
          (rem.description?.toLowerCase().contains(lowerQuery) ?? false)) {
        results.add(SearchResult(
          id: 'rem_${rem.id}',
          title: rem.title,
          subtitle: _formatDate(rem.date),
          category: SearchResultCategory.reminders,
          icon: Icons.notifications,
          originalData: rem,
        ));
      }
    }

    // 6. Contacts
    final contacts = await emergencyStorage.getContacts();
    for (var c in contacts) {
      if (c.name.toLowerCase().contains(lowerQuery) ||
          c.category.toLowerCase().contains(lowerQuery) ||
          c.phoneNumber.contains(lowerQuery)) {
        results.add(SearchResult(
          id: 'contact_${c.id}',
          title: c.name,
          subtitle: c.category,
          category: SearchResultCategory.contacts,
          icon: Icons.contact_phone,
          originalData: c,
        ));
      }
    }

    // 7. Growth Updates
    final growthUpdates = profileStorage.getGrowthUpdates();
    for (var update in growthUpdates) {
      if (update.growthStage.toLowerCase().contains(lowerQuery) ||
          (update.notes?.toLowerCase().contains(lowerQuery) ?? false)) {
        final crop = profileStorage.getCrops().where((c) => c.id == update.cropId).firstOrNull;
        final cropName = crop?.cropName ?? 'Unknown Crop';
        results.add(SearchResult(
          id: 'growth_${update.id}',
          title: 'Growth: $cropName',
          subtitle: update.growthStage,
          category: SearchResultCategory.growth,
          icon: Icons.eco,
          originalData: update,
        ));
      }
    }

    // 8. Crop Photos
    for (var crop in profileStorage.getCrops()) {
      final photos = profileStorage.getCropPhotosForCrop(crop.id);
      for (var photo in photos) {
        if (photo.note?.toLowerCase().contains(lowerQuery) ?? false) {
          results.add(SearchResult(
            id: 'photo_${photo.id}',
            title: 'Photo: ${crop.cropName}',
            subtitle: photo.note!,
            category: SearchResultCategory.photos,
            icon: Icons.photo_camera,
            originalData: { 'photo': photo, 'cropName': crop.cropName },
          ));
        }
      }
    }

    // 9. Health Records
    for (var crop in profileStorage.getCrops()) {
      final healthRecords = profileStorage.getHealthRecordsForCrop(crop.id);
      for (var record in healthRecords) {
        final scan = record.initialScan;
        if ((scan.summary.toLowerCase().contains(lowerQuery)) ||
            (scan.possibleIssues.any((issue) => issue.toLowerCase().contains(lowerQuery))) ||
            (record.currentStatus.toLowerCase().contains(lowerQuery))) {
          results.add(SearchResult(
            id: 'health_${record.id}',
            title: 'Health: ${crop.cropName}',
            subtitle: record.currentStatus,
            category: SearchResultCategory.health,
            icon: Icons.healing,
            originalData: record,
          ));
        }
      }
    }

    // 10. Knowledge
    final topics = HelpService.searchTopics(query, languageCode);
    for (var topic in topics) {
      results.add(SearchResult(
        id: 'knowledge_${topic.id}',
        title: topic.title,
        subtitle: 'Farm Knowledge',
        category: SearchResultCategory.knowledge,
        icon: Icons.book,
        originalData: topic,
      ));
    }

    // 11. Tasks (Planner)
    if (taskStorage != null) {
      final tasks = await taskStorage!.getTasks();
      for (var task in tasks) {
        if (task.title.toLowerCase().contains(lowerQuery) ||
            (task.notes?.toLowerCase().contains(lowerQuery) ?? false)) {
          results.add(SearchResult(
            id: 'task_${task.id}',
            title: task.title,
            subtitle: _formatDate(task.date),
            category: SearchResultCategory.tasks,
            icon: Icons.check_circle_outline,
            originalData: task,
          ));
        }
      }
    }

    return results;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
