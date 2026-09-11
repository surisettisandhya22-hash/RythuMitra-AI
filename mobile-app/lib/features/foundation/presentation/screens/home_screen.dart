import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/services/storage_service.dart';
import '../../../../core/config/api_config.dart';
import '../widgets/app_header.dart';
import '../widgets/greeting_card.dart';
import '../widgets/voice_button.dart';
import '../widgets/quick_action_card.dart';
import '../../../../core/localization/app_localizations.dart';
import '../widgets/section_title.dart';
import 'action_placeholder_screen.dart';
import '../../../weather/data/repositories/weather_repository.dart';
import '../../../weather/presentation/widgets/weather_home_card.dart';
import '../../../tasks/presentation/widgets/alerts_summary_card.dart';
import '../../../market/presentation/widgets/market_summary_card.dart';
import '../../../emergency/presentation/screens/emergency_help_screen.dart';
import '../../../emergency/services/emergency_storage_service.dart';
import '../../../tasks/services/reminder_storage_service.dart';
import '../../../market/presentation/screens/market_screen.dart';
import '../../../market/services/market_service.dart';
import '../../../scanner/presentation/screens/crop_health_screen.dart';
import '../../../scanner/services/scanner_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../search/presentation/screens/smart_search_screen.dart';

import '../../../profile/services/profile_storage_service.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final WeatherRepository weatherRepository;
  final NetworkService networkService;
  final VoidCallback? onNavigateToAiAssistant;
  final VoidCallback? onNavigateToVoiceCommand;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.profileStorageService,
    required this.weatherRepository,
    required this.networkService,
    this.onNavigateToAiAssistant,
    this.onNavigateToVoiceCommand,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MarketService _marketService = MarketService();
  final ScannerService _scannerService = ScannerService(apiService: ApiService());
  String? _backendStatus;
  bool _isBackendConnected = false;

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  Future<void> _checkBackendHealth() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/health');
    debugPrint('\n--- TRIGGERING BACKEND HEALTH CHECK ---');
    debugPrint('BACKEND URL:\n${ApiConfig.baseUrl}');
    debugPrint('REQUEST:\nGET /health');
    
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      
      debugPrint('STATUS:\n${response.statusCode}');
      debugPrint('RESPONSE:\n${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _backendStatus = '🟢 Connected: ${data['service']}';
            _isBackendConnected = true;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _backendStatus = '🔴 Backend Error (${response.statusCode})';
            _isBackendConnected = false;
          });
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _backendStatus = '🔴 Connection Timed Out';
          _isBackendConnected = false;
        });
      }
    } on SocketException {
      if (mounted) {
        setState(() {
          _backendStatus = '🔴 No Internet or Backend Offline';
          _isBackendConnected = false;
        });
      }
    } catch (e) {
      debugPrint('ERROR:\n$e');
      if (mounted) {
        setState(() {
          _backendStatus = '🔴 Backend Connection Failed';
          _isBackendConnected = false;
        });
      }
    }
    debugPrint('--- END HEALTH CHECK ---\n');
  }

  void _onVoiceButtonTap() {
    if (widget.onNavigateToVoiceCommand != null) {
      widget.onNavigateToVoiceCommand!();
    } else if (widget.onNavigateToAiAssistant != null) {
      widget.onNavigateToAiAssistant!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Voice Assistant coming soon!'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _navigateToPlaceholder(String title, IconData icon) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ActionPlaceholderScreen(
          title: title,
          icon: icon,
        ),
      ),
    );
  }

  void _navigateToMarket() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MarketScreen(
            marketService: _marketService,
            profileStorageService: widget.profileStorageService,
            networkService: widget.networkService,
        ),
      ),
    );
  }

  void _navigateToCropHealth() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CropHealthScreen(
          storageService: widget.storageService,
          profileStorageService: widget.profileStorageService,
          scannerService: _scannerService,
          networkService: widget.networkService,
        ),
      ),
    );
  }

  void _navigateToEmergencyHelp() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EmergencyHelpScreen(
          emergencyStorageService: EmergencyStorageService(),
          profileStorageService: widget.profileStorageService,
        ),
      ),
    );
  }

  void _navigateToSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SmartSearchScreen(
          storageService: widget.storageService,
          profileStorageService: widget.profileStorageService,
          emergencyStorageService: EmergencyStorageService(),
          reminderStorageService: ReminderStorageService(),
          weatherRepository: widget.weatherRepository,
          networkService: widget.networkService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final greeting = AppLocalizations.of(context).translate('home_greeting');

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_backendStatus != null)
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Re-checking backend connection...'), duration: Duration(seconds: 1)),
                    );
                    _checkBackendHealth();
                  },
                  child: Container(
                    color: _isBackendConnected ? Colors.green.shade100 : Colors.red.shade100,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _backendStatus!,
                          style: TextStyle(
                            fontSize: 13,
                            color: _isBackendConnected ? Colors.green.shade900 : Colors.red.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.refresh,
                          size: 14,
                          color: _isBackendConnected ? Colors.green.shade900 : Colors.red.shade900,
                        )
                      ],
                    ),
                  ),
                ),
              AppHeader(onSearchTap: _navigateToSearch),
              
              GreetingCard(
                greeting: greeting,
              ),
              
              Center(
                child: VoiceButton(onTap: _onVoiceButtonTap),
              ),

              WeatherHomeCard(
                weatherRepository: widget.weatherRepository,
                profileStorageService: widget.profileStorageService,
                networkService: widget.networkService,
              ),
              AlertsSummaryCard(weatherRepository: widget.weatherRepository),
              MarketSummaryCard(
                profileStorageService: widget.profileStorageService,
                networkService: widget.networkService,
              ),
              
              SectionTitle(title: AppLocalizations.of(context).translate('quick_actions')),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    QuickActionCard(
                      title: AppLocalizations.of(context).translate('quick_prices'),
                      icon: Icons.currency_rupee,
                      onTap: _navigateToMarket,
                    ),
                    QuickActionCard(
                      title: AppLocalizations.of(context).translate('quick_diagnosis'),
                      icon: Icons.local_florist_outlined,
                      onTap: _navigateToCropHealth,
                    ),
                    QuickActionCard(
                      title: AppLocalizations.of(context).translate('quick_schemes'),
                      icon: Icons.description_outlined,
                      onTap: () => _navigateToPlaceholder(AppLocalizations.of(context).translate('quick_schemes'), Icons.description_outlined),
                    ),
                    QuickActionCard(
                      title: AppLocalizations.of(context).translate('emergency_help'),
                      icon: Icons.sos,
                      onTap: _navigateToEmergencyHelp,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
