import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../tasks/services/reminder_storage_service.dart';
import '../../../weather/data/repositories/weather_repository.dart';
import '../../../voice/services/text_to_speech_service.dart';

import '../../domain/models/farm_alert.dart';
import '../../services/alerts_center_service.dart';

import '../../../tasks/presentation/screens/alerts_screen.dart';
import '../../../profile/presentation/screens/farm_activity_screen.dart';
import '../../../profile/presentation/screens/farm_income_screen.dart';
import '../../../profile/presentation/screens/farm_expenses_screen.dart';
import '../../../profile/presentation/screens/my_farm_dashboard.dart';
import '../../../planner/services/task_storage_service.dart';
import '../../../planner/presentation/screens/daily_planner_screen.dart';

class FarmAlertsCenterScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final StorageService storageService;
  final NetworkService networkService;
  final WeatherRepository weatherRepository;

  const FarmAlertsCenterScreen({
    super.key,
    required this.profileStorageService,
    required this.storageService,
    required this.networkService,
    required this.weatherRepository,
  });

  @override
  State<FarmAlertsCenterScreen> createState() => _FarmAlertsCenterScreenState();
}

class _FarmAlertsCenterScreenState extends State<FarmAlertsCenterScreen> {
  late AlertsCenterService _alertsService;
  final ReminderStorageService _reminderStorageService = ReminderStorageService();
  final TaskStorageService _taskStorageService = TaskStorageService();
  final TextToSpeechService _ttsService = TextToSpeechService();
  
  List<FarmAlert> _alerts = [];
  bool _isLoading = true;
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
        'farm_alerts': 'వ్యవసాయ అలర్ట్‌లు',
        'important': 'ముఖ్యమైనవి',
        'upcoming': 'రాబోయేవి',
        'information': 'సమాచారం',
        'no_alerts': 'ప్రస్తుతం ముఖ్యమైన వ్యవసాయ అలర్ట్‌లు లేవు.',
        'mark_as_read': 'చదివినట్లుగా గుర్తుంచు',
        'dismiss': 'తీసివేయి',
        'overdue_reminder': 'గడువు ముగిసిన రిమైండర్',
        'upcoming_reminder': 'రాబోయే రిమైండర్',
        'todays_activities': 'నేటి వ్యవసాయ పనులు',
        'recent_updates': 'ఇటీవలి అప్‌డేట్‌లు',
        'overdue_task': 'గడువు ముగిసిన పని',
        'pending_task_today': 'నేటి పెండింగ్ పని',
      };
    } else if (lang == 'hi') {
      _localizedStrings = {
        'farm_alerts': 'कृषि अलर्ट',
        'important': 'महत्वपूर्ण',
        'upcoming': 'आगामी',
        'information': 'जानकारी',
        'no_alerts': 'अभी कोई महत्वपूर्ण कृषि अलर्ट नहीं है।',
        'mark_as_read': 'पढ़ा हुआ के रूप में चिह्नित करें',
        'dismiss': 'हटाएं',
        'overdue_reminder': 'अतिदेय अनुस्मारक',
        'upcoming_reminder': 'आगामी अनुस्मारक',
        'todays_activities': 'आज की कृषि गतिविधियां',
        'recent_updates': 'हाल के अपडेट',
        'overdue_task': 'अतिदेय कार्य',
        'pending_task_today': 'आज का लंबित कार्य',
      };
    } else {
      _localizedStrings = {
        'farm_alerts': 'Farm Alerts',
        'important': 'Important',
        'upcoming': 'Upcoming',
        'information': 'Information',
        'no_alerts': 'No important farm alerts right now.',
        'mark_as_read': 'Mark as Read',
        'dismiss': 'Dismiss',
        'overdue_reminder': 'Overdue Reminder',
        'upcoming_reminder': 'Upcoming Reminder',
        'todays_activities': 'Today\'s Farm Activities',
        'recent_updates': 'Recent Updates',
        'overdue_task': 'Overdue Task',
        'pending_task_today': 'Pending Task Today',
      };
    }
  }

  String _t(String key) => _localizedStrings[key] ?? key;
  String _tAlertTitle(String title) {
    if (title == 'Overdue Reminder') return _t('overdue_reminder');
    if (title == 'Upcoming Reminder') return _t('upcoming_reminder');
    if (title == 'Today\'s Farm Activities') return _t('todays_activities');
    if (title == 'Recent Updates') return _t('recent_updates');
    if (title == 'Overdue Task') return _t('overdue_task');
    if (title == 'Pending Task Today') return _t('pending_task_today');
    return title;
  }

  Future<void> _initServices() async {
    await _reminderStorageService.init();
    await _taskStorageService.init();
    _alertsService = AlertsCenterService(
      profileStorage: widget.profileStorageService,
      reminderStorage: _reminderStorageService,
      storageService: widget.storageService,
      taskStorage: _taskStorageService,
    );
    await _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _isLoading = true);
    final alerts = await _alertsService.getAlerts();
    if (mounted) {
      setState(() {
        _alerts = alerts;
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
    
    if (_alerts.isEmpty) return;
    
    setState(() => _isSpeaking = true);
    final lang = widget.storageService.getSelectedLanguage() ?? 'en';
    
    String spokenText = '${_t('farm_alerts')}. ';
    for (var alert in _alerts) {
      spokenText += '${_tAlertTitle(alert.title)}. ${alert.description}. ';
    }
    
    await _ttsService.speak(spokenText, lang);
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isSpeaking) setState(() => _isSpeaking = false);
    });
  }

  void _markAsRead(FarmAlert alert) async {
    await widget.storageService.addReadAlertId(alert.id);
    _loadAlerts();
  }

  void _dismissAlert(FarmAlert alert) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('dismiss')),
        content: Text('Dismissing this alert will hide it locally. The underlying farm data will not be modified.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await widget.storageService.addDismissedAlertId(alert.id);
              _loadAlerts();
            },
            child: Text(_t('dismiss'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateForAlert(FarmAlert alert) {
    if (alert.type == AlertType.reminder) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => AlertsScreen(
          weatherRepository: widget.weatherRepository,
          storageService: widget.storageService,
          profileStorageService: widget.profileStorageService,
          networkService: widget.networkService,
        ),
      )).then((_) => _loadAlerts());
    } else if (alert.type == AlertType.activity) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => FarmActivityScreen(
          profileStorageService: widget.profileStorageService,
        ),
      )).then((_) => _loadAlerts());
    } else if (alert.type == AlertType.financial) {
      // Just route to dashboard for simplicity, or Income/Expense based on title
      if (alert.description.toLowerCase().contains('income')) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FarmIncomeScreen(
            profileStorageService: widget.profileStorageService,
            storageService: widget.storageService,
          ),
        )).then((_) => _loadAlerts());
      } else {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FarmExpensesScreen(
            profileStorageService: widget.profileStorageService,
            storageService: widget.storageService,
          ),
        )).then((_) => _loadAlerts());
      }
    } else if (alert.type == AlertType.task) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DailyPlannerScreen(
          taskService: _taskStorageService,
          profileStorageService: widget.profileStorageService,
          storageService: widget.storageService,
        ),
      )).then((_) => _loadAlerts());
    } else {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => MyFarmDashboard(
          profileStorageService: widget.profileStorageService,
          storageService: widget.storageService,
          networkService: widget.networkService,
          weatherRepository: widget.weatherRepository,
        ),
      )).then((_) => _loadAlerts());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_t('farm_alerts')),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isSpeaking ? Icons.volume_up : Icons.volume_up_outlined),
            onPressed: _alerts.isEmpty ? null : _toggleSpeech,
            tooltip: 'Listen',
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_alerts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _t('no_alerts'),
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAlerts,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _alerts.length,
        itemBuilder: (context, index) {
          return _buildAlertCard(_alerts[index]);
        },
      ),
    );
  }

  Widget _buildAlertCard(FarmAlert alert) {
    IconData icon;
    Color color;
    String priorityText;

    switch (alert.priority) {
      case AlertPriority.important:
        icon = Icons.error_outline;
        color = Colors.red.shade700;
        priorityText = _t('important');
        break;
      case AlertPriority.upcoming:
        icon = Icons.schedule;
        color = Colors.orange.shade700;
        priorityText = _t('upcoming');
        break;
      case AlertPriority.information:
        icon = Icons.info_outline;
        color = Colors.blue.shade700;
        priorityText = _t('information');
        break;
    }

    return Card(
      elevation: alert.isRead ? 0 : 2,
      color: alert.isRead ? Colors.grey.shade100 : Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: alert.isRead ? BorderSide(color: Colors.grey.shade300) : BorderSide.none,
      ),
      child: InkWell(
        onTap: () => _navigateForAlert(alert),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: alert.isRead ? Colors.grey : color, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        priorityText.toUpperCase(),
                        style: TextStyle(
                          color: alert.isRead ? Colors.grey : color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
                    onSelected: (value) {
                      if (value == 'read') _markAsRead(alert);
                      if (value == 'dismiss') _dismissAlert(alert);
                    },
                    itemBuilder: (context) => [
                      if (!alert.isRead) 
                        PopupMenuItem(
                          value: 'read',
                          child: Text(_t('mark_as_read')),
                        ),
                      PopupMenuItem(
                        value: 'dismiss',
                        child: Text(_t('dismiss')),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _tAlertTitle(alert.title),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: alert.isRead ? Colors.grey.shade700 : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                alert.description,
                style: TextStyle(
                  fontSize: 14,
                  color: alert.isRead ? Colors.grey.shade600 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
