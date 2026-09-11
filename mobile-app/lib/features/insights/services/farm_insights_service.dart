import 'package:flutter/material.dart';
import '../../profile/services/profile_storage_service.dart';
import '../../tasks/services/reminder_storage_service.dart';
import '../../planner/services/task_storage_service.dart';

enum TimePeriod { allTime, thisMonth, lastMonth, custom }

class FarmInsightsService {
  final ProfileStorageService profileStorage;
  final ReminderStorageService reminderStorage;
  final TaskStorageService? taskStorage;

  FarmInsightsService({
    required this.profileStorage,
    required this.reminderStorage,
    this.taskStorage,
  });

  // Insights Data Models
  Map<String, dynamic> getCropInsights(TimePeriod period, {DateTimeRange? customRange}) {
    final crops = profileStorage.getCrops();
    final healthRecords = profileStorage.healthRecordsNotifier.value;
    final growthUpdates = profileStorage.getGrowthUpdates();

    int totalCrops = 0;
    int activeCrops = 0;
    int harvestedCrops = 0;

    for (var crop in crops) {
      if (_isWithinPeriod(DateTime.tryParse(crop.createdAt ?? '') ?? DateTime.now(), period, customRange)) {
        totalCrops++;
        if (crop.status == 'harvested') {
          harvestedCrops++;
        } else {
          activeCrops++;
        }
      }
    }

    final filteredHealth = healthRecords.where((r) => _isWithinPeriod(DateTime.tryParse(r.initialScan.date) ?? DateTime.now(), period, customRange)).length;
    final filteredGrowth = growthUpdates.where((r) => _isWithinPeriod(r.date, period, customRange)).length;

    return {
      'totalCrops': totalCrops,
      'activeCrops': activeCrops,
      'harvestedCrops': harvestedCrops,
      'healthRecords': filteredHealth,
      'growthRecords': filteredGrowth,
    };
  }

  Map<String, dynamic> getFinancialInsights(TimePeriod period, {DateTimeRange? customRange}) {
    final expenses = profileStorage.getExpenses();
    final sales = profileStorage.getSales();

    double totalIncome = 0;
    double totalExpenses = 0;

    for (var expense in expenses) {
      if (_isWithinPeriod(DateTime.tryParse(expense.date) ?? DateTime.now(), period, customRange)) {
        totalExpenses += expense.amount;
      }
    }

    for (var sale in sales) {
      if (_isWithinPeriod(DateTime.tryParse(sale.saleDate) ?? DateTime.now(), period, customRange)) {
        totalIncome += sale.totalSaleValue;
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netBalance': totalIncome - totalExpenses,
    };
  }

  Future<Map<String, dynamic>> getActivityInsights(TimePeriod period, {DateTimeRange? customRange}) async {
    final activities = profileStorage.getActivities();
    final reminders = await reminderStorage.getReminders();

    int totalActivities = 0;
    int activitiesThisMonth = 0; // Activities specifically in current month regardless of filter, if requested. 
    int completedActivities = 0;
    
    final now = DateTime.now();

    for (var act in activities) {
      if (_isWithinPeriod(act.date, period, customRange)) {
        totalActivities++;
        // We assume all recorded activities are "completed" actions
        completedActivities++;
      }
      if (act.date.month == now.month && act.date.year == now.year) {
        activitiesThisMonth++;
      }
    }

    int upcomingReminders = 0;
    int completedReminders = 0;
    int overdueReminders = 0;

    for (var rem in reminders) {
      if (_isWithinPeriod(rem.date, period, customRange)) {
        if (rem.isCompleted) {
          completedReminders++;
        } else if (rem.date.isBefore(DateTime(now.year, now.month, now.day))) {
          overdueReminders++;
        } else {
          upcomingReminders++;
        }
      }
    }

    int pendingTasks = 0;
    int completedTasks = 0;
    
    if (taskStorage != null) {
      final tasks = await taskStorage!.getTasks();
      for (var task in tasks) {
        if (_isWithinPeriod(task.date, period, customRange)) {
          if (task.isCompleted) {
            completedTasks++;
          } else {
            pendingTasks++;
          }
        }
      }
    }

    return {
      'totalActivities': totalActivities,
      'activitiesThisMonth': activitiesThisMonth,
      'completedActivities': completedActivities,
      'upcomingReminders': upcomingReminders,
      'completedReminders': completedReminders,
      'overdueReminders': overdueReminders,
      'pendingTasks': pendingTasks,
      'completedTasks': completedTasks,
    };
  }

  bool _isWithinPeriod(DateTime date, TimePeriod period, DateTimeRange? customRange) {
    final now = DateTime.now();
    switch (period) {
      case TimePeriod.allTime:
        return true;
      case TimePeriod.thisMonth:
        return date.year == now.year && date.month == now.month;
      case TimePeriod.lastMonth:
        final lastMonth = now.month == 1 ? 12 : now.month - 1;
        final year = now.month == 1 ? now.year - 1 : now.year;
        return date.year == year && date.month == lastMonth;
      case TimePeriod.custom:
        if (customRange != null) {
          // Check if date is within the range, inclusive of start, exclusive of end+1 day
          return date.isAfter(customRange.start.subtract(const Duration(seconds: 1))) && 
                 date.isBefore(customRange.end.add(const Duration(days: 1)));
        }
        return true;
    }
  }
}
