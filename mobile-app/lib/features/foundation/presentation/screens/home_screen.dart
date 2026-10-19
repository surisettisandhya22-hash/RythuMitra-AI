import 'package:flutter/material.dart';
import '../../../emergency/services/emergency_storage_service.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../../../core/services/storage_service.dart';
import '../../../../core/config/api_config.dart';
import '../widgets/app_header.dart';
import '../widgets/greeting_card.dart';
import '../widgets/voice_button.dart';
import '../../../../core/localization/app_localizations.dart';
import '../widgets/section_title.dart';
import '../../../weather/data/repositories/weather_repository.dart';
import '../../../weather/presentation/widgets/weather_home_card.dart';
import '../../../tasks/presentation/widgets/alerts_summary_card.dart';
import '../../../market/presentation/widgets/market_summary_card.dart';
import '../../../tasks/services/reminder_storage_service.dart';
import '../../../market/presentation/screens/market_screen.dart';
import '../../../market/services/market_service.dart';
import '../../../scanner/presentation/screens/crop_health_screen.dart';
import '../../../scanner/services/scanner_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../search/presentation/screens/smart_search_screen.dart';
import '../../../ai_utilities/presentation/screens/soil_health_screen.dart';
import '../../../ai_utilities/presentation/screens/fertilizer_calculator_screen.dart';
import '../../../irrigation/presentation/screens/irrigation_screen.dart';
import '../../../community/presentation/screens/community_screen.dart';

import '../../../profile/services/profile_storage_service.dart';
import '../../../profile/presentation/screens/farmer_profile_details_screen.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../weather/presentation/screens/weather_screen.dart';

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



  void _navigateToClimate() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeatherScreen(
          weatherRepository: widget.weatherRepository,
          profileStorageService: widget.profileStorageService,
          networkService: widget.networkService,
        ),
      ),
    );
  }

  void _navigateToSoilHealth() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SoilHealthScreen()));
  }

  void _navigateToFertilizer() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FertilizerCalculatorScreen()));
  }

  void _navigateToIrrigation() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => IrrigationScreen(
      storageService: widget.storageService,
      profileStorageService: widget.profileStorageService,
      networkService: widget.networkService,
    )));
  }

  void _navigateToCommunity() {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityScreen()));
  }

  void _navigateToAiAssistant() {
    if (widget.onNavigateToAiAssistant != null) {
      widget.onNavigateToAiAssistant!();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => AIAssistantScreen(
            storageService: widget.storageService,
            profileStorageService: widget.profileStorageService,
            networkService: widget.networkService,
            weatherRepository: widget.weatherRepository,
          ),
        ),
      );
    }
  }

  void _navigateToProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FarmerProfileDetailsScreen(
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
              AppHeader(
                onSearchTap: _navigateToSearch,
                onProfileTap: _navigateToProfile,
              ),
              
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
              
              SectionTitle(title: AppLocalizations.of(context).translate('crop_dashboard')),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.8,
                  children: [
                    _buildGridItem(AppLocalizations.of(context).translate('grid_soil'), Icons.landscape, _navigateToSoilHealth),
                    _buildGridItem(AppLocalizations.of(context).translate('grid_climate'), Icons.wb_sunny_outlined, _navigateToClimate),
                    _buildGridItem(AppLocalizations.of(context).translate('grid_fertilizer'), Icons.science, _navigateToFertilizer),
                    _buildGridItem(AppLocalizations.of(context).translate('grid_irrigation'), Icons.water_drop, _navigateToIrrigation),
                    _buildGridItem(AppLocalizations.of(context).translate('grid_disease'), Icons.pest_control, _navigateToCropHealth),
                    _buildGridItem(AppLocalizations.of(context).translate('grid_community'), Icons.people, _navigateToCommunity),
                    _buildGridItem(AppLocalizations.of(context).translate('grid_market'), Icons.currency_rupee, _navigateToMarket),
                    _buildGridItem(AppLocalizations.of(context).translate('grid_assistant'), Icons.auto_awesome, _navigateToAiAssistant),
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

  Widget _buildGridItem(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.green.shade700, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
