import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../tasks/services/reminder_storage_service.dart';
import '../../services/farm_insights_service.dart';
import '../../../voice/services/text_to_speech_service.dart';

import '../../../weather/data/repositories/weather_repository.dart';
import '../../../profile/presentation/screens/farm_income_screen.dart';
import '../../../profile/presentation/screens/farm_activity_screen.dart';
import '../../../tasks/presentation/screens/alerts_screen.dart';
import '../../../planner/services/task_storage_service.dart';
import '../../../planner/presentation/screens/daily_planner_screen.dart';

class FarmInsightsScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final StorageService storageService;
  final NetworkService networkService;
  final WeatherRepository weatherRepository;

  const FarmInsightsScreen({
    super.key,
    required this.profileStorageService,
    required this.storageService,
    required this.networkService,
    required this.weatherRepository,
  });

  @override
  State<FarmInsightsScreen> createState() => _FarmInsightsScreenState();
}

class _FarmInsightsScreenState extends State<FarmInsightsScreen> {
  late FarmInsightsService _insightsService;
  final TextToSpeechService _ttsService = TextToSpeechService();
  final ReminderStorageService _reminderStorageService = ReminderStorageService();
  final TaskStorageService _taskStorageService = TaskStorageService();

  TimePeriod _selectedPeriod = TimePeriod.allTime;
  DateTimeRange? _customDateRange;

  bool _isLoading = true;
  Map<String, dynamic> _cropInsights = {};
  Map<String, dynamic> _financialInsights = {};
  Map<String, dynamic> _activityInsights = {};

  bool _isSpeaking = false;
  Map<String, String> _localizedStrings = {};

  @override
  void initState() {
    super.initState();
    _initServices();
    _setupLocalization();
  }

  void _setupLocalization() {
    final lang = widget.storageService.getSelectedLanguage() ?? 'en';
    if (lang == 'te') {
      _localizedStrings = {
        'farm_insights': 'వ్యవసాయ అంతర్దృష్టులు',
        'crop_overview': 'పంటల అవలోకనం',
        'financial_overview': 'ఆర్థిక అవలోకనం',
        'activity_overview': 'పనుల అవలోకనం',
        'reminder_overview': 'రిమైండర్ అవలోకనం',
        'farm_progress': 'వ్యవసాయ ప్రగతి',
        'total_crops': 'మొత్తం పంటలు',
        'active_crops': 'క్రియాశీల పంటలు',
        'growth_records': 'పెరుగుదల రికార్డులు',
        'health_records': 'ఆరోగ్య రికార్డులు',
        'total_income': 'మొత్తం ఆదాయం',
        'total_expenses': 'మొత్తం ఖర్చులు',
        'net_balance': 'నికర నిల్వ',
        'upcoming_reminders': 'రాబోయే రిమైండర్‌లు',
        'completed_reminders': 'పూర్తయిన రిమైండర్‌లు',
        'overdue_reminders': 'గడువు ముగిసిన రిమైండర్‌లు',
        'all_time': 'అన్ని సమయాల్లో',
        'this_month': 'ఈ నెల',
        'last_month': 'గత నెల',
        'custom_range': 'అనుకూల తేదీ పరిధి',
        'add_records_msg': 'అంతర్దృష్టులను వీక్షించడానికి వ్యవసాయ రికార్డులను జోడించండి',
        'no_data': 'సరిపోలిన సమాచారం లేదు',
        'income_higher': 'మీ ఆదాయం ఖర్చుల కంటే ఎక్కువగా ఉంది.',
        'expense_higher': 'మీ ఖర్చులు ఆదాయం కంటే ఎక్కువగా ఉన్నాయి.',
        'balanced': 'ఆదాయం మరియు ఖర్చులు సమానంగా ఉన్నాయి.',
        'total_activities': 'మొత్తం పనులు',
        'activities_this_month': 'ఈ నెల పనులు',
        'select_date_range': 'తేదీ పరిధిని ఎంచుకోండి',
        'task_overview': 'ప్రణాళిక అవలోకనం',
        'pending_tasks': 'పెండింగ్ పనులు',
        'completed_tasks': 'పూర్తయిన పనులు',
      };
    } else if (lang == 'hi') {
      _localizedStrings = {
        'farm_insights': 'कृषि अंतर्दृष्टि',
        'crop_overview': 'फसल अवलोकन',
        'financial_overview': 'वित्तीय अवलोकन',
        'activity_overview': 'गतिविधि अवलोकन',
        'reminder_overview': 'अनुस्मारक अवलोकन',
        'farm_progress': 'कृषि प्रगति',
        'total_crops': 'कुल फसलें',
        'active_crops': 'सक्रिय फसलें',
        'growth_records': 'विकास रिकॉर्ड',
        'health_records': 'स्वास्थ्य रिकॉर्ड',
        'total_income': 'कुल आय',
        'total_expenses': 'कुल व्यय',
        'net_balance': 'शुद्ध शेष',
        'upcoming_reminders': 'आगामी अनुस्मारक',
        'completed_reminders': 'पूर्ण अनुस्मारक',
        'overdue_reminders': 'अतिदेय अनुस्मारक',
        'all_time': 'हर समय',
        'this_month': 'इस महीने',
        'last_month': 'पिछले महीने',
        'custom_range': 'कस्टम दिनांक सीमा',
        'add_records_msg': 'अंतर्दृष्टि देखने के लिए कृषि रिकॉर्ड जोड़ें',
        'no_data': 'कोई जानकारी नहीं',
        'income_higher': 'आपकी आय आपके खर्चों से अधिक है।',
        'expense_higher': 'आपके खर्च आपकी आय से अधिक हैं।',
        'balanced': 'आय और व्यय बराबर हैं।',
        'total_activities': 'कुल गतिविधियां',
        'activities_this_month': 'इस महीने की गतिविधियां',
        'select_date_range': 'दिनांक सीमा चुनें',
        'task_overview': 'योजना अवलोकन',
        'pending_tasks': 'लंबित कार्य',
        'completed_tasks': 'पूर्ण कार्य',
      };
    } else {
      _localizedStrings = {
        'farm_insights': 'Farm Insights',
        'crop_overview': 'Crop Overview',
        'financial_overview': 'Financial Overview',
        'activity_overview': 'Activity Overview',
        'reminder_overview': 'Reminder Overview',
        'farm_progress': 'Farm Progress',
        'total_crops': 'Total Crops',
        'active_crops': 'Active Crops',
        'growth_records': 'Growth Records',
        'health_records': 'Health Records',
        'total_income': 'Total Income',
        'total_expenses': 'Total Expenses',
        'net_balance': 'Net Balance',
        'upcoming_reminders': 'Upcoming Reminders',
        'completed_reminders': 'Completed Reminders',
        'overdue_reminders': 'Overdue Reminders',
        'all_time': 'All Time',
        'this_month': 'This Month',
        'last_month': 'Last Month',
        'custom_range': 'Custom Date Range',
        'add_records_msg': 'Add farm records to view insights.',
        'no_data': 'No matching data',
        'income_higher': 'Your recorded income is currently higher than your recorded expenses.',
        'expense_higher': 'Your recorded expenses are currently higher than your recorded income.',
        'balanced': 'Income and expenses are perfectly balanced.',
        'total_activities': 'Total Activities',
        'activities_this_month': 'Activities This Month',
        'select_date_range': 'Select Date Range',
        'task_overview': 'Task Overview',
        'pending_tasks': 'Pending Tasks',
        'completed_tasks': 'Completed Tasks',
      };
    }
  }

  String _t(String key) => _localizedStrings[key] ?? key;

  Future<void> _initServices() async {
    await _reminderStorageService.init();
    await _taskStorageService.init();
    _insightsService = FarmInsightsService(
      profileStorage: widget.profileStorageService,
      reminderStorage: _reminderStorageService,
      taskStorage: _taskStorageService,
    );
    await _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _isLoading = true;
    });

    final cropData = _insightsService.getCropInsights(_selectedPeriod, customRange: _customDateRange);
    final finData = _insightsService.getFinancialInsights(_selectedPeriod, customRange: _customDateRange);
    final actData = await _insightsService.getActivityInsights(_selectedPeriod, customRange: _customDateRange);

    if (mounted) {
      setState(() {
        _cropInsights = cropData;
        _financialInsights = finData;
        _activityInsights = actData;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      await _ttsService.stop();
      setState(() => _isSpeaking = false);
      return;
    }

    setState(() => _isSpeaking = true);
    
    // Generate spoken text
    final lang = widget.storageService.getSelectedLanguage() ?? 'en';
    String spokenText = "";
    
    final income = _financialInsights['totalIncome'] as double? ?? 0.0;
    final expense = _financialInsights['totalExpenses'] as double? ?? 0.0;
    
    if (lang == 'te') {
      spokenText = "వ్యవసాయ అంతర్దృష్టులు. మీ మొత్తం ఆదాయం $income రూపాయలు. మొత్తం ఖర్చులు $expense రూపాయలు.";
      if (income > expense) {
        spokenText += " మీ ఆదాయం ఖర్చుల కంటే ఎక్కువగా ఉంది.";
      } else if (expense > income) {
        spokenText += " మీ ఖర్చులు ఆదాయం కంటే ఎక్కువగా ఉన్నాయి.";
      }
    } else if (lang == 'hi') {
      spokenText = "कृषि अंतर्दृष्टि. आपकी कुल आय $income रुपये है. कुल व्यय $expense रुपये है.";
      if (income > expense) {
        spokenText += " आपकी आय आपके खर्चों से अधिक है.";
      } else if (expense > income) {
        spokenText += " आपके खर्च आपकी आय से अधिक हैं.";
      }
    } else {
      spokenText = "Farm Insights. Your total income is $income rupees. Total expenses are $expense rupees. ";
      if (income > expense) {
        spokenText += "Your income is higher than your expenses.";
      } else if (expense > income) {
        spokenText += "Your expenses are higher than your income.";
      }
    }

    await _ttsService.speak(spokenText, lang);
    
    // Simplistic handling of completion
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted && _isSpeaking) {
        setState(() => _isSpeaking = false);
      }
    });
  }

  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPeriod = TimePeriod.custom;
        _customDateRange = picked;
      });
      _loadInsights();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_t('farm_insights')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_up_outlined),
            onPressed: _toggleSpeech,
            tooltip: 'Listen to Insights',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: _loadInsights,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildTimePeriodFilter(),
          const SizedBox(height: 16),
          _buildFarmProgressCard(),
          const SizedBox(height: 16),
          _buildFinancialOverviewCard(),
          const SizedBox(height: 16),
          _buildCropOverviewCard(),
          const SizedBox(height: 16),
          _buildActivityOverviewCard(),
          const SizedBox(height: 16),
          _buildTaskOverviewCard(),
          const SizedBox(height: 16),
          _buildReminderOverviewCard(),
        ],
      ),
    );
  }

  Widget _buildTimePeriodFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(TimePeriod.allTime, _t('all_time')),
          const SizedBox(width: 8),
          _buildFilterChip(TimePeriod.thisMonth, _t('this_month')),
          const SizedBox(width: 8),
          _buildFilterChip(TimePeriod.lastMonth, _t('last_month')),
          const SizedBox(width: 8),
          _buildFilterChip(TimePeriod.custom, 
              _customDateRange != null && _selectedPeriod == TimePeriod.custom 
                  ? '${_customDateRange!.start.day}/${_customDateRange!.start.month} - ${_customDateRange!.end.day}/${_customDateRange!.end.month}' 
                  : _t('custom_range')),
        ],
      ),
    );
  }

  Widget _buildFilterChip(TimePeriod period, String label) {
    final isSelected = _selectedPeriod == period;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.black87)),
      selected: isSelected,
      selectedColor: Colors.green.shade700,
      onSelected: (selected) {
        if (selected) {
          if (period == TimePeriod.custom) {
            _selectCustomDateRange();
          } else {
            setState(() {
              _selectedPeriod = period;
              _customDateRange = null;
            });
            _loadInsights();
          }
        }
      },
    );
  }

  Widget _buildFarmProgressCard() {
    final totalCrops = _cropInsights['totalCrops'] ?? 0;
    final totalActs = _activityInsights['totalActivities'] ?? 0;
    final totalIncome = _financialInsights['totalIncome'] ?? 0.0;
    
    if (totalCrops == 0 && totalActs == 0 && totalIncome == 0) {
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Icon(Icons.auto_graph, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                _t('add_records_msg'),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      color: Colors.green.shade50,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.green.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.trending_up, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  _t('farm_progress'),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressStat(totalCrops.toString(), _t('total_crops'), Icons.grass),
                _buildProgressStat(totalActs.toString(), _t('total_activities'), Icons.list_alt),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green.shade700, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _buildFinancialOverviewCard() {
    final income = _financialInsights['totalIncome'] as double? ?? 0.0;
    final expenses = _financialInsights['totalExpenses'] as double? ?? 0.0;
    final netBalance = _financialInsights['netBalance'] as double? ?? 0.0;

    String insightText = "";
    if (income == 0 && expenses == 0) {
      insightText = _t('add_records_msg');
    } else if (income > expenses) {
      insightText = _t('income_higher');
    } else if (expenses > income) {
      insightText = _t('expense_higher');
    } else {
      insightText = _t('balanced');
    }

    return GestureDetector(
      onTap: () {
        // Just arbitrarily jump to Income to satisfy "Expense Tracker -> Farm Income"
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FarmIncomeScreen(
            profileStorageService: widget.profileStorageService,
            storageService: widget.storageService,
          ),
        ));
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet, color: Colors.deepPurple.shade700),
                  const SizedBox(width: 8),
                  Text(
                    _t('financial_overview'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_t('total_income'), style: TextStyle(color: Colors.grey.shade600)),
                    Text('₹${income.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(_t('total_expenses'), style: TextStyle(color: Colors.grey.shade600)),
                    Text('₹${expenses.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_t('net_balance'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '₹${netBalance.toStringAsFixed(2)}', 
                  style: TextStyle(
                    color: netBalance >= 0 ? Colors.green.shade800 : Colors.red.shade800, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 18
                  )
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insightText,
                      style: TextStyle(color: Colors.blue.shade900, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildCropOverviewCard() {
    final active = _cropInsights['activeCrops'] ?? 0;
    final growth = _cropInsights['growthRecords'] ?? 0;
    final health = _cropInsights['healthRecords'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop(); // Back to Dashboard which shows My Crops
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.agriculture, color: Colors.brown.shade700),
                  const SizedBox(width: 8),
                  Text(
                    _t('crop_overview'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatRow(_t('active_crops'), active.toString(), Icons.eco),
              const Divider(),
              _buildStatRow(_t('growth_records'), growth.toString(), Icons.show_chart),
              const Divider(),
              _buildStatRow(_t('health_records'), health.toString(), Icons.medical_services),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityOverviewCard() {
    final totalActs = _activityInsights['totalActivities'] ?? 0;
    final monthActs = _activityInsights['activitiesThisMonth'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FarmActivityScreen(
            profileStorageService: widget.profileStorageService,
          ),
        ));
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Text(
                    _t('activity_overview'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatRow(_t('total_activities'), totalActs.toString(), Icons.list),
              const Divider(),
              _buildStatRow(_t('activities_this_month'), monthActs.toString(), Icons.today),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskOverviewCard() {
    final pendingTasks = _activityInsights['pendingTasks'] ?? 0;
    final completedTasks = _activityInsights['completedTasks'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => DailyPlannerScreen(
            taskService: _taskStorageService,
            profileStorageService: widget.profileStorageService,
            storageService: widget.storageService,
          ),
        ));
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_box, color: Colors.teal.shade700),
                  const SizedBox(width: 8),
                  Text(
                    _t('task_overview'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatRow(_t('pending_tasks'), pendingTasks.toString(), Icons.pending_actions),
              const Divider(),
              _buildStatRow(_t('completed_tasks'), completedTasks.toString(), Icons.task_alt),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReminderOverviewCard() {
    final upcoming = _activityInsights['upcomingReminders'] ?? 0;
    final completed = _activityInsights['completedReminders'] ?? 0;
    final overdue = _activityInsights['overdueReminders'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => AlertsScreen(
            weatherRepository: widget.weatherRepository,
            storageService: widget.storageService,
            profileStorageService: widget.profileStorageService,
            networkService: widget.networkService,
          ),
        ));
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_active, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    _t('reminder_overview'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStatRow(_t('upcoming_reminders'), upcoming.toString(), Icons.alarm),
              const Divider(),
              _buildStatRow(_t('completed_reminders'), completed.toString(), Icons.check_circle_outline),
              const Divider(),
              _buildStatRow(_t('overdue_reminders'), overdue.toString(), Icons.warning_amber_rounded),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: Colors.grey.shade800)),
          ],
        ),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
