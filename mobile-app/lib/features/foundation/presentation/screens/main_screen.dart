import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/localization/app_localizations.dart';
import 'home_screen.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../profile/presentation/screens/my_farm_dashboard.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../planner/presentation/screens/daily_planner_screen.dart';
import '../../../planner/services/task_storage_service.dart';

import 'more_screen.dart';
import '../../../scanner/presentation/widgets/scanner_entry_helper.dart';
import '../../../scanner/services/scanner_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../weather/data/repositories/weather_repository.dart';

import '../../../../core/services/network_service.dart';
import '../../../voice/presentation/screens/voice_command_screen.dart';
import '../../../market/presentation/screens/market_screen.dart';
import '../../../market/services/market_service.dart';
import '../../../scanner/presentation/screens/crop_health_screen.dart';
import '../../../emergency/presentation/screens/emergency_help_screen.dart';
import '../../../emergency/services/emergency_storage_service.dart';
import '../../../profile/presentation/screens/farm_expenses_screen.dart';
import '../../../profile/presentation/screens/farm_income_screen.dart';
import '../../../reports/presentation/screens/farm_reports_screen.dart';
import '../../../calendar/presentation/screens/farm_calendar_screen.dart';
import '../../../search/presentation/screens/smart_search_screen.dart';
import '../../../information/presentation/screens/help_center_screen.dart';
import '../../../tasks/services/reminder_storage_service.dart';
import '../../../alerts_center/presentation/screens/farm_alerts_center_screen.dart';
import '../../../insights/presentation/screens/farm_insights_screen.dart';

class MainScreen extends StatefulWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final NetworkService networkService;

  const MainScreen({
    super.key, 
    required this.storageService,
    required this.profileStorageService,
    required this.networkService,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _autoStartListening = false;
  late final ScannerService _scannerService;
  late final WeatherRepository _weatherRepository;
  late final TaskStorageService _taskService;
  final MarketService _marketService = MarketService();

  @override
  void initState() {
    super.initState();
    _scannerService = ScannerService(apiService: ApiService());
    _weatherRepository = WeatherRepository();
    _taskService = TaskStorageService();
    _taskService.init();
  }
  
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index != 1) {
        _autoStartListening = false;
      }
    });
  }

  void _navigateToAiAssistantWithVoice() {
    setState(() {
      _autoStartListening = true;
      _currentIndex = 1;
    });
  }

  void _navigateToVoiceCommand() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VoiceCommandScreen(
          storageService: widget.storageService,
          networkService: widget.networkService,
          onCommandMatched: (command) {
            Navigator.of(context).pop(); // close voice screen
            _handleVoiceNavigation(command);
          },
        ),
      ),
    );
  }

  void _handleVoiceNavigation(String command) {
    switch (command) {
      case 'home':
        _onTabTapped(0);
        break;
      case 'ai_assistant':
        _onTabTapped(1);
        break;
      case 'my_crops':
      case 'profile':
        _onTabTapped(2);
        break;
      case 'alerts':
        _onTabTapped(3);
        break;
      case 'weather':
        // No direct weather tab, switch to home where weather is visible
        _onTabTapped(0);
        break;
      case 'market_prices':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => MarketScreen(
            marketService: _marketService,
            profileStorageService: widget.profileStorageService,
            networkService: widget.networkService,
          ),
        ));
        break;
      case 'crop_health':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CropHealthScreen(
            storageService: widget.storageService,
            profileStorageService: widget.profileStorageService,
            scannerService: _scannerService,
            networkService: widget.networkService,
          ),
        ));
        break;
      case 'emergency':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => EmergencyHelpScreen(
            emergencyStorageService: EmergencyStorageService(),
            profileStorageService: widget.profileStorageService,
          ),
        ));
        break;
      case 'expenses':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FarmExpensesScreen(
            profileStorageService: widget.profileStorageService,
            storageService: widget.storageService,
          ),
        ));
        break;
      case 'income':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FarmIncomeScreen(
            profileStorageService: widget.profileStorageService,
            storageService: widget.storageService,
          ),
        ));
        break;
      case 'reports':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FarmReportsScreen(
            profileStorageService: widget.profileStorageService,
            reminderStorageService: ReminderStorageService(),
            storageService: widget.storageService,
          ),
        ));
        break;
      case 'knowledge':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => HelpCenterScreen(
            storageService: widget.storageService,
          ),
        ));
        break;
      case 'search':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => SmartSearchScreen(
            storageService: widget.storageService,
            profileStorageService: widget.profileStorageService,
            emergencyStorageService: EmergencyStorageService(),
            reminderStorageService: ReminderStorageService(),
            weatherRepository: _weatherRepository,
            networkService: widget.networkService,
          ),
        ));
        break;
      case 'calendar':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FarmCalendarScreen(
            profileStorageService: widget.profileStorageService,
          ),
        ));
        break;
      case 'insights':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FarmInsightsScreen(
            profileStorageService: widget.profileStorageService,
            storageService: widget.storageService,
            networkService: widget.networkService,
            weatherRepository: _weatherRepository,
          ),
        ));
        break;
      case 'alerts_center':
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FarmAlertsCenterScreen(
            profileStorageService: widget.profileStorageService,
            storageService: widget.storageService,
            networkService: widget.networkService,
            weatherRepository: _weatherRepository,
          ),
        ));
        break;
      default:
        _onTabTapped(4); // More screen for reports, expenses, etc.
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        storageService: widget.storageService,
        profileStorageService: widget.profileStorageService,
        weatherRepository: _weatherRepository,
        networkService: widget.networkService,
        onNavigateToAiAssistant: _navigateToAiAssistantWithVoice,
        onNavigateToVoiceCommand: _navigateToVoiceCommand,
      ),
      AIAssistantScreen(
        storageService: widget.storageService,
        profileStorageService: widget.profileStorageService,
        weatherRepository: _weatherRepository,
        networkService: widget.networkService,
        autoStartListening: _autoStartListening,
      ),
      MyFarmDashboard(
        storageService: widget.storageService,
        profileStorageService: widget.profileStorageService,
        weatherRepository: _weatherRepository,
        networkService: widget.networkService,
        onNavigateToAiAssistant: _navigateToAiAssistantWithVoice,
        onNavigateToVoiceCommand: _navigateToVoiceCommand,
      ),
      DailyPlannerScreen(
        taskService: _taskService,
        profileStorageService: widget.profileStorageService,
        storageService: widget.storageService,
      ),
      MoreScreen(
        storageService: widget.storageService,
        profileStorageService: widget.profileStorageService,
        networkService: widget.networkService,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () {
          ScannerEntryHelper.showScannerOptions(
            context,
            storageService: widget.storageService,
            profileStorageService: widget.profileStorageService,
            scannerService: _scannerService,
            networkService: widget.networkService,
          );
        },
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.camera_alt),
        label: Text(AppLocalizations.of(context).translate('scan_crop_problem')),
      ) : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.green.shade700,
        unselectedItemColor: Colors.grey.shade500,
        showUnselectedLabels: true,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context).translate('nav_home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.smart_toy),
            label: AppLocalizations.of(context).translate('nav_ai'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.agriculture),
            label: AppLocalizations.of(context).translate('nav_farm'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.task_alt),
            label: AppLocalizations.of(context).translate('nav_tasks'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu),
            label: AppLocalizations.of(context).translate('nav_more'),
          ),
        ],
      ),
    );
  }
}
