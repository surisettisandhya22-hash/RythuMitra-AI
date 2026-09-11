import '../../profile/services/profile_storage_service.dart';
import '../../tasks/services/reminder_storage_service.dart';
import '../../../../core/services/storage_service.dart';
import '../domain/models/farm_alert.dart';

import '../../planner/services/task_storage_service.dart';

class AlertsCenterService {
  final ProfileStorageService profileStorage;
  final ReminderStorageService reminderStorage;
  final StorageService storageService;
  final TaskStorageService? taskStorage;

  AlertsCenterService({
    required this.profileStorage,
    required this.reminderStorage,
    required this.storageService,
    this.taskStorage,
  });

  Future<List<FarmAlert>> getAlerts() async {
    List<FarmAlert> generatedAlerts = [];
    final now = DateTime.now();

    // 1. Reminder Alerts
    final reminders = await reminderStorage.getReminders();
    for (var rem in reminders) {
      if (!rem.isCompleted) {
        if (rem.date.isBefore(DateTime(now.year, now.month, now.day))) {
          // Overdue
          generatedAlerts.add(FarmAlert(
            id: 'reminder_overdue_${rem.id}',
            type: AlertType.reminder,
            priority: AlertPriority.important,
            title: 'Overdue Reminder',
            description: rem.title,
            sourceId: rem.id,
            createdAt: rem.date,
          ));
        } else if (rem.date.isBefore(now.add(const Duration(days: 3)))) {
          // Upcoming in next 3 days
          generatedAlerts.add(FarmAlert(
            id: 'reminder_upcoming_${rem.id}',
            type: AlertType.reminder,
            priority: AlertPriority.upcoming,
            title: 'Upcoming Reminder',
            description: rem.title,
            sourceId: rem.id,
            createdAt: rem.date,
          ));
        }
      }
    }

    // 2. Activity Alerts (Today)
    final activities = profileStorage.getActivities();
    bool hasActivityToday = activities.any((act) => 
        act.date.year == now.year && act.date.month == now.month && act.date.day == now.day);
    if (hasActivityToday) {
      generatedAlerts.add(FarmAlert(
        id: 'activity_today_${now.year}${now.month}${now.day}',
        type: AlertType.activity,
        priority: AlertPriority.information,
        title: 'Today\'s Farm Activities',
        description: 'You have farm activities recorded for today.',
        sourceId: 'daily_activity',
        createdAt: now,
      ));
    }

    // 3. Financial Alerts (Recent Income/Expense)
    final expenses = profileStorage.getExpenses();
    final recentExpenses = expenses.where((e) => 
        (DateTime.tryParse(e.date) ?? DateTime(1970)).isAfter(now.subtract(const Duration(days: 1))));
    if (recentExpenses.isNotEmpty) {
      generatedAlerts.add(FarmAlert(
        id: 'expense_recent_${recentExpenses.first.id}',
        type: AlertType.financial,
        priority: AlertPriority.information,
        title: 'Recent Updates',
        description: 'New expense record added.',
        sourceId: recentExpenses.first.id,
        createdAt: DateTime.tryParse(recentExpenses.first.date) ?? now,
      ));
    }

    final income = profileStorage.getSales();
    final recentIncome = income.where((i) => 
        (DateTime.tryParse(i.saleDate) ?? DateTime(1970)).isAfter(now.subtract(const Duration(days: 1))));
    if (recentIncome.isNotEmpty) {
      generatedAlerts.add(FarmAlert(
        id: 'income_recent_${recentIncome.first.id}',
        type: AlertType.financial,
        priority: AlertPriority.information,
        title: 'Recent Updates',
        description: 'New income record added.',
        sourceId: recentIncome.first.id,
        createdAt: DateTime.tryParse(recentIncome.first.saleDate) ?? now,
      ));
    }

    // 4. Planner Tasks (Overdue / Today's Pending)
    if (taskStorage != null) {
      final tasks = await taskStorage!.getTasks();
      for (var task in tasks) {
        if (!task.isCompleted) {
          final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
          final today = DateTime(now.year, now.month, now.day);
          
          if (taskDate.isBefore(today)) {
            generatedAlerts.add(FarmAlert(
              id: 'task_overdue_${task.id}',
              type: AlertType.task,
              priority: AlertPriority.important,
              title: 'Overdue Task',
              description: task.title,
              sourceId: task.id,
              createdAt: task.date,
            ));
          } else if (taskDate.isAtSameMomentAs(today)) {
            generatedAlerts.add(FarmAlert(
              id: 'task_today_${task.id}',
              type: AlertType.task,
              priority: AlertPriority.upcoming,
              title: 'Pending Task Today',
              description: task.title,
              sourceId: task.id,
              createdAt: task.date,
            ));
          }
        }
      }
    }

    // Process read and dismissed state
    final dismissedIds = storageService.getDismissedAlertIds();
    final readIds = storageService.getReadAlertIds();

    final visibleAlerts = generatedAlerts.where((alert) => !dismissedIds.contains(alert.id)).toList();
    for (var alert in visibleAlerts) {
      if (readIds.contains(alert.id)) {
        alert.isRead = true;
      }
    }

    // Sort: Important first, then upcoming, then information
    visibleAlerts.sort((a, b) => a.priority.index.compareTo(b.priority.index));

    return visibleAlerts;
  }
}
