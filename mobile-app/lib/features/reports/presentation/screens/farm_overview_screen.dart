import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../tasks/services/reminder_storage_service.dart';
import '../../../planner/services/task_storage_service.dart';
import '../../../voice/presentation/widgets/global_listen_button.dart';
import '../../../planner/domain/models/farm_task.dart';
import '../../../tasks/domain/models/farm_reminder.dart';

import '../../../profile/presentation/screens/farm_activity_screen.dart';
import '../../../profile/presentation/screens/farm_financial_summary_screen.dart';
import '../../../tasks/presentation/screens/alerts_screen.dart';
import '../../../weather/data/repositories/weather_repository.dart';
import '../../../../core/services/network_service.dart';
import '../../../planner/presentation/screens/daily_planner_screen.dart';

class FarmOverviewScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final StorageService storageService;
  final WeatherRepository? weatherRepository;
  final NetworkService? networkService;

  const FarmOverviewScreen({
    super.key,
    required this.profileStorageService,
    required this.storageService,
    this.weatherRepository,
    this.networkService,
  });

  @override
  State<FarmOverviewScreen> createState() => _FarmOverviewScreenState();
}

class _FarmOverviewScreenState extends State<FarmOverviewScreen> {
  final ReminderStorageService _reminderService = ReminderStorageService();
  final TaskStorageService _taskService = TaskStorageService();

  List<FarmReminder> _reminders = [];
  List<FarmTask> _tasks = [];
  bool _isLoading = true;
  String _dateFilter = 'all_time';

  @override
  void initState() {
    super.initState();
    _loadData();
    widget.profileStorageService.cropsNotifier.addListener(_onDataChanged);
    widget.profileStorageService.activitiesNotifier.addListener(_onDataChanged);
    widget.profileStorageService.expensesNotifier.addListener(_onDataChanged);
    widget.profileStorageService.salesNotifier.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    widget.profileStorageService.cropsNotifier.removeListener(_onDataChanged);
    widget.profileStorageService.activitiesNotifier.removeListener(_onDataChanged);
    widget.profileStorageService.expensesNotifier.removeListener(_onDataChanged);
    widget.profileStorageService.salesNotifier.removeListener(_onDataChanged);
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) {
      _loadData(); // Need to reload tasks and reminders just in case
    }
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    await _reminderService.init();
    await _taskService.init();
    final reminders = await _reminderService.getReminders();
    final tasks = await _taskService.getTasks();
    if (mounted) {
      setState(() {
        _reminders = reminders;
        _tasks = tasks;
        _isLoading = false;
      });
    }
  }
  
  bool _isDateInRange(DateTime date) {
    if (_dateFilter == 'all_time') return true;
    final now = DateTime.now();
    if (_dateFilter == 'this_month') {
      return date.year == now.year && date.month == now.month;
    }
    if (_dateFilter == 'last_month') {
      final lastMonth = now.month == 1 ? 12 : now.month - 1;
      final year = now.month == 1 ? now.year - 1 : now.year;
      return date.year == year && date.month == lastMonth;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('my_farm_overview') == 'my_farm_overview' ? 'My Farm Overview' : t.translate('my_farm_overview')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    // Calculate Data
    final allCrops = widget.profileStorageService.getCrops();
    final activeCrops = allCrops.where((c) => c.status == 'Growing' || c.status == 'Needs Attention').toList();
    final cropsWithGrowth = allCrops.where((c) => c.growthStage != null && c.growthStage!.isNotEmpty).toList();

    final allActivities = widget.profileStorageService.getActivities().where((a) => _isDateInRange(a.date)).toList();
    
    final filteredTasks = _tasks.where((t) => _isDateInRange(t.date)).toList();
    final completedTasks = filteredTasks.where((t) => t.isCompleted).toList();
    final pendingTasks = filteredTasks.where((t) => !t.isCompleted && (t.date.isAfter(DateTime.now().subtract(const Duration(days: 1))) || t.date.day == DateTime.now().day)).toList();
    final overdueTasks = filteredTasks.where((t) => !t.isCompleted && t.date.isBefore(DateTime.now().subtract(const Duration(days: 1))) && t.date.day != DateTime.now().day).toList();

    final filteredReminders = _reminders.where((r) => _isDateInRange(r.date)).toList();
    final completedReminders = filteredReminders.where((r) => r.isCompleted).toList();
    final upcomingReminders = filteredReminders.where((r) => !r.isCompleted).toList();

    final allExpenses = widget.profileStorageService.getExpenses().where((e) => _isDateInRange(DateTime.tryParse(e.date) ?? DateTime.now())).toList();
    final allSales = widget.profileStorageService.getSales().where((s) => _isDateInRange(DateTime.tryParse(s.saleDate) ?? DateTime.now())).toList();

    double totalExpenses = allExpenses.fold(0.0, (sum, e) => sum + e.amount);
    double totalIncome = allSales.fold(0.0, (sum, s) => sum + s.totalSaleValue);
    double netBalance = totalIncome - totalExpenses;

    bool hasAnyData = allCrops.isNotEmpty || allActivities.isNotEmpty || filteredTasks.isNotEmpty || filteredReminders.isNotEmpty || allExpenses.isNotEmpty || allSales.isNotEmpty;

    if (!hasAnyData && _dateFilter == 'all_time') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dashboard_customize, size: 64, color: Colors.green.shade200),
              const SizedBox(height: 16),
              Text(
                t.translate('add_farm_records_overview') == 'add_farm_records_overview' ? 'Add farm records to see your farm overview.' : t.translate('add_farm_records_overview'),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildFilterBar(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: GlobalListenButton(
              storageService: widget.storageService,
              textBuilder: () {
                final cropsMsg = 'You have ${allCrops.length} crops. ';
                final tasksMsg = 'You have ${pendingTasks.length} pending tasks. ';
                final expensesMsg = 'Your total recorded expenses are $totalExpenses rupees. ';
                final incomeMsg = 'Your total income is $totalIncome rupees.';
                return cropsMsg + tasksMsg + expensesMsg + incomeMsg;
              },
            ),
          ),
          _buildCropStats(allCrops.length, activeCrops.length, cropsWithGrowth.length),
          _buildActivityStats(allActivities.length),
          _buildTaskStats(filteredTasks.length, completedTasks.length, pendingTasks.length, overdueTasks.length),
          _buildReminderStats(filteredReminders.length, upcomingReminders.length, completedReminders.length),
          _buildFinancialStats(totalIncome, totalExpenses, netBalance),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.green.shade50,
      child: Wrap(
        spacing: 8.0,
        alignment: WrapAlignment.center,
        children: [
          _buildFilterChip('all_time', t.translate('all_time') == 'all_time' ? 'All Time' : t.translate('all_time')),
          _buildFilterChip('this_month', t.translate('this_month') == 'this_month' ? 'This Month' : t.translate('this_month')),
          _buildFilterChip('last_month', t.translate('last_month') == 'last_month' ? 'Last Month' : t.translate('last_month')),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _dateFilter == value,
      onSelected: (selected) {
        if (selected) setState(() => _dateFilter = value);
      },
      selectedColor: Colors.green.shade200,
    );
  }

  Widget _buildStatCard({required String title, required IconData icon, required Color color, required VoidCallback onTap, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
              const SizedBox(height: 16),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: valueColor ?? Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildCropStats(int total, int active, int withGrowth) {
    final t = AppLocalizations.of(context);
    return _buildStatCard(
      title: t.translate('my_crops') == 'my_crops' ? 'My Crops' : t.translate('my_crops'),
      icon: Icons.grass,
      color: Colors.green.shade700,
      onTap: () {
        Navigator.pop(context); // Fallback to Dashboard which has My Crops
      },
      children: [
        _buildStatRow(t.translate('total_crops') == 'total_crops' ? 'Total Crops' : t.translate('total_crops'), total.toString()),
        _buildStatRow('Active Crops', active.toString(), valueColor: Colors.green.shade700),
        _buildStatRow('Crops with Growth Records', withGrowth.toString()),
      ],
    );
  }

  Widget _buildActivityStats(int total) {
    final t = AppLocalizations.of(context);
    return _buildStatCard(
      title: t.translate('farm_activity_log') == 'farm_activity_log' ? 'Farm Activity Log' : t.translate('farm_activity_log'),
      icon: Icons.agriculture,
      color: Colors.orange.shade700,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => FarmActivityScreen(profileStorageService: widget.profileStorageService)));
      },
      children: [
        _buildStatRow(t.translate('total_activities') == 'total_activities' ? 'Total Activities' : t.translate('total_activities'), total.toString()),
      ],
    );
  }

  Widget _buildTaskStats(int total, int completed, int pending, int overdue) {
    final t = AppLocalizations.of(context);
    return _buildStatCard(
      title: t.translate('planner_title') == 'planner_title' ? 'Daily Farm Planner' : t.translate('planner_title'),
      icon: Icons.task_alt,
      color: Colors.blue.shade700,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => DailyPlannerScreen(
          profileStorageService: widget.profileStorageService,
          taskService: _taskService,
        )));
      },
      children: [
        _buildStatRow(t.translate('total_tasks') == 'total_tasks' ? 'Total Tasks' : t.translate('total_tasks'), total.toString()),
        _buildStatRow(t.translate('completed_tasks') == 'completed_tasks' ? 'Completed Tasks' : t.translate('completed_tasks'), completed.toString(), valueColor: Colors.green),
        _buildStatRow(t.translate('pending_tasks') == 'pending_tasks' ? 'Pending Tasks' : t.translate('pending_tasks'), pending.toString(), valueColor: Colors.orange),
        _buildStatRow(t.translate('overdue_tasks') == 'overdue_tasks' ? 'Overdue Tasks' : t.translate('overdue_tasks'), overdue.toString(), valueColor: Colors.red),
        if (total > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: LinearProgressIndicator(
              value: completed / total,
              backgroundColor: Colors.grey.shade200,
              color: Colors.blue.shade700,
            ),
          )
      ],
    );
  }

  Widget _buildReminderStats(int total, int upcoming, int completed) {
    final t = AppLocalizations.of(context);
    return _buildStatCard(
      title: t.translate('farm_reminders') == 'farm_reminders' ? 'Farm Reminders' : t.translate('farm_reminders'),
      icon: Icons.notifications_active,
      color: Colors.deepPurple.shade700,
      onTap: () {
        if (widget.weatherRepository != null && widget.networkService != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AlertsScreen(
            weatherRepository: widget.weatherRepository!,
            storageService: widget.storageService,
            profileStorageService: widget.profileStorageService,
            networkService: widget.networkService!,
          )));
        }
      },
      children: [
        _buildStatRow('Total Reminders', total.toString()),
        _buildStatRow(t.translate('upcoming_reminders') == 'upcoming_reminders' ? 'Upcoming Reminders' : t.translate('upcoming_reminders'), upcoming.toString(), valueColor: Colors.orange),
        _buildStatRow('Completed Reminders', completed.toString(), valueColor: Colors.green),
      ],
    );
  }

  Widget _buildFinancialStats(double income, double expenses, double netBalance) {
    final t = AppLocalizations.of(context);
    double maxVal = income > expenses ? income : expenses;
    if (maxVal == 0) maxVal = 1;

    return _buildStatCard(
      title: 'Financial Overview',
      icon: Icons.account_balance_wallet,
      color: Colors.teal.shade700,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => FarmFinancialSummaryScreen(
          profileStorageService: widget.profileStorageService, 
          storageService: widget.storageService
        )));
      },
      children: [
        _buildStatRow(t.translate('total_income') == 'total_income' ? 'Total Income' : t.translate('total_income'), '₹${income.toStringAsFixed(2)}', valueColor: Colors.green.shade700),
        _buildStatRow(t.translate('total_expenses') == 'total_expenses' ? 'Total Expenses' : t.translate('total_expenses'), '₹${expenses.toStringAsFixed(2)}', valueColor: Colors.red.shade700),
        const Divider(),
        _buildStatRow(t.translate('net_balance') == 'net_balance' ? 'Net Balance' : t.translate('net_balance'), '₹${netBalance.toStringAsFixed(2)}', valueColor: netBalance >= 0 ? Colors.green.shade900 : Colors.red.shade900),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: (income / maxVal * 100).toInt() + 1,
              child: Container(height: 8, color: Colors.green),
            ),
            Expanded(
              flex: (expenses / maxVal * 100).toInt() + 1,
              child: Container(height: 8, color: Colors.red),
            ),
          ],
        )
      ],
    );
  }
}
