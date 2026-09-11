import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../emergency/services/emergency_storage_service.dart';
import '../../../tasks/services/reminder_storage_service.dart';
import '../../../weather/data/repositories/weather_repository.dart';
import '../../../voice/services/speech_recognition_service.dart';
import '../../services/smart_search_service.dart';
import '../../data/models/search_result.dart';
import '../../../planner/services/task_storage_service.dart';
import '../../../planner/presentation/screens/daily_planner_screen.dart';

// Navigation Destinations
import '../../../profile/presentation/screens/crop_details_screen.dart';
import '../../../profile/presentation/screens/farm_activity_screen.dart';
import '../../../profile/presentation/screens/farm_expenses_screen.dart';
import '../../../profile/presentation/screens/farm_income_screen.dart';
import '../../../tasks/presentation/screens/alerts_screen.dart';
import '../../../emergency/presentation/screens/emergency_help_screen.dart';
import '../../../information/presentation/screens/help_detail_screen.dart';

class SmartSearchScreen extends StatefulWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final EmergencyStorageService emergencyStorageService;
  final ReminderStorageService reminderStorageService;
  final WeatherRepository weatherRepository;
  final NetworkService networkService;

  const SmartSearchScreen({
    super.key,
    required this.storageService,
    required this.profileStorageService,
    required this.emergencyStorageService,
    required this.reminderStorageService,
    required this.weatherRepository,
    required this.networkService,
  });

  @override
  State<SmartSearchScreen> createState() => _SmartSearchScreenState();
}

class _SmartSearchScreenState extends State<SmartSearchScreen> {
  late SmartSearchService _searchService;
  late TaskStorageService _taskStorageService;
  final TextEditingController _searchController = TextEditingController();
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  
  bool _isListening = false;
  bool _isSearching = false;
  List<SearchResult> _results = [];
  Map<String, String> _localizedStrings = {};

  @override
  void initState() {
    super.initState();
    _taskStorageService = TaskStorageService();
    _taskStorageService.init().then((_) {
      _searchService = SmartSearchService(
        profileStorage: widget.profileStorageService,
        emergencyStorage: widget.emergencyStorageService,
        reminderStorage: widget.reminderStorageService,
        taskStorage: _taskStorageService,
      );
    });
    _setupLocalization();
    _speechService.initialize();
  }
  
  void _setupLocalization() {
    final lang = widget.storageService.getSelectedLanguage() ?? 'en';
    if (lang == 'te') {
      _localizedStrings = {
        'search_rythumitra': 'రైతుమిత్ర శోధించండి',
        'search_placeholder': 'పంటలు, పనులు, ఖర్చుల కోసం వెతకండి...',
        'search_crops': '🌱 నా పంటలను శోధించండి',
        'search_activities': '📋 పనులను శోధించండి',
        'search_expenses': '🧾 ఖర్చులను శోధించండి',
        'search_reminders': '🔔 రిమైండర్‌లను శోధించండి',
        'search_contacts': '🆘 పరిచయాలను శోధించండి',
        'search_growth': '🌿 పంట పెరుగుదలను శోధించండి',
        'search_photos': '📸 ఫోటోలను శోధించండి',
        'search_health': '🌿 పంట ఆరోగ్యాన్ని శోధించండి',
        'search_knowledge': '📚 వ్యవసాయ జ్ఞానాన్ని శోధించండి',
        'no_results': 'సరిపోలే వ్యవసాయ సమాచారం కనుగొనబడలేదు.',
        'clear_search': 'శోధనను క్లియర్ చేయండి',
        'listening': 'వింటున్నాము...'
      };
    } else if (lang == 'hi') {
      _localizedStrings = {
        'search_rythumitra': 'रायुतुमित्रा खोजें',
        'search_placeholder': 'फसलें, गतिविधियां, खर्च खोजें...',
        'search_crops': '🌱 मेरी फसलें खोजें',
        'search_activities': '📋 गतिविधियां खोजें',
        'search_expenses': '🧾 खर्च खोजें',
        'search_reminders': '🔔 रिमाइंडर खोजें',
        'search_contacts': '🆘 संपर्क खोजें',
        'search_growth': '🌿 फसल विकास खोजें',
        'search_photos': '📸 तस्वीरें खोजें',
        'search_health': '🌿 फसल स्वास्थ्य खोजें',
        'search_knowledge': '📚 कृषि ज्ञान खोजें',
        'no_results': 'कोई मेल खाने वाली जानकारी नहीं मिली।',
        'clear_search': 'खोज साफ़ करें',
        'listening': 'सुन रहे हैं...'
      };
    } else {
      _localizedStrings = {
        'search_rythumitra': 'Search RythuMitra',
        'search_placeholder': 'Search crops, activities, expenses...',
        'search_crops': '🌱 Search My Crops',
        'search_activities': '📋 Search Activities',
        'search_expenses': '🧾 Search Expenses',
        'search_reminders': '🔔 Search Reminders',
        'search_contacts': '🆘 Search Contacts',
        'search_growth': '🌿 Search Crop Growth',
        'search_photos': '📸 Search Photos',
        'search_health': '🌿 Search Crop Health',
        'search_knowledge': '📚 Search Farm Knowledge',
        'no_results': 'No matching farm information found.',
        'clear_search': 'Clear Search',
        'listening': 'Listening...'
      };
    }
  }

  String _t(String key) => _localizedStrings[key] ?? key;

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _results = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final lang = widget.storageService.getSelectedLanguage() ?? 'en';
    final results = await _searchService.searchAll(query, languageCode: lang);
    
    if (mounted) {
      setState(() {
        _results = results;
      });
    }
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      _speechService.stopListening();
      setState(() {
        _isListening = false;
      });
    } else {
      final available = await _speechService.initialize();
      if (!mounted) return;
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required for voice search.')),
        );
        return;
      }
      
      setState(() {
        _isListening = true;
        _searchController.text = ''; // clear for new voice input
      });

      _speechService.startListening(
        languageId: widget.storageService.getSelectedLanguage() ?? 'en',
        onResult: (text) {
          _searchController.text = text;
          _performSearch(text);
        },
      );

      // Auto stop after 5 seconds to prevent hanging
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted && _isListening) {
          _speechService.stopListening();
          setState(() {
            _isListening = false;
          });
        }
      });
    }
  }

  void _navigateToResult(SearchResult result) {
    Widget destination = const Scaffold(body: Center(child: Text('Unknown')));
    
    switch (result.category) {
      case SearchResultCategory.crops:
        destination = CropDetailsScreen(
          cropId: result.originalData.id,
          profileStorageService: widget.profileStorageService,
          storageService: widget.storageService,
          networkService: widget.networkService,
        );
        break;
      case SearchResultCategory.activities:
        destination = FarmActivityScreen(
          profileStorageService: widget.profileStorageService,
        );
        break;
      case SearchResultCategory.expenses:
        destination = FarmExpensesScreen(
          profileStorageService: widget.profileStorageService,
          storageService: widget.storageService,
        );
        break;
      case SearchResultCategory.income:
        destination = FarmIncomeScreen(
          profileStorageService: widget.profileStorageService,
          storageService: widget.storageService,
        );
        break;
      case SearchResultCategory.reminders:
        destination = AlertsScreen(
          weatherRepository: widget.weatherRepository,
          storageService: widget.storageService,
          profileStorageService: widget.profileStorageService,
          networkService: widget.networkService,
        );
        break;
      case SearchResultCategory.contacts:
        destination = EmergencyHelpScreen(
          emergencyStorageService: widget.emergencyStorageService,
          profileStorageService: widget.profileStorageService,
        );
        break;
      case SearchResultCategory.growth:
      case SearchResultCategory.photos:
      case SearchResultCategory.health:
        final cropId = result.category == SearchResultCategory.photos
            ? result.originalData['photo'].cropId
            : result.originalData.cropId;
        destination = CropDetailsScreen(
          cropId: cropId,
          profileStorageService: widget.profileStorageService,
          storageService: widget.storageService,
          networkService: widget.networkService,
        );
        break;
      case SearchResultCategory.knowledge:
        destination = HelpDetailScreen(
          topic: result.originalData,
          storageService: widget.storageService,
        );
        break;
      case SearchResultCategory.tasks:
        destination = DailyPlannerScreen(
          taskService: _taskStorageService,
          profileStorageService: widget.profileStorageService,
          storageService: widget.storageService,
        );
        break;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(_t('search_rythumitra')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.green.shade700,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _performSearch,
                    decoration: InputDecoration(
                      hintText: _isListening ? _t('listening') : _t('search_placeholder'),
                      prefixIcon: const Icon(Icons.search, color: Colors.green),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _toggleVoiceSearch,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _isListening ? Colors.red.shade400 : Colors.green.shade600,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _isListening ? Icons.mic_off : Icons.mic,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _buildSuggestionTile(_t('search_crops')),
        _buildSuggestionTile(_t('search_activities')),
        _buildSuggestionTile(_t('search_expenses')),
        _buildSuggestionTile(_t('search_reminders')),
        _buildSuggestionTile(_t('search_contacts')),
        _buildSuggestionTile(_t('search_growth')),
        _buildSuggestionTile(_t('search_photos')),
        _buildSuggestionTile(_t('search_health')),
        _buildSuggestionTile(_t('search_knowledge')),
      ],
    );
  }

  Widget _buildSuggestionTile(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_results.isEmpty && _searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _t('no_results'),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _performSearch('');
                FocusScope.of(context).unfocus();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade50,
                foregroundColor: Colors.green.shade900,
              ),
              child: Text(_t('clear_search')),
            ),
          ],
        ),
      );
    }

    // Group results by category
    final Map<SearchResultCategory, List<SearchResult>> grouped = {};
    for (var r in _results) {
      grouped.putIfAbsent(r.category, () => []).add(r);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.keys.length,
      itemBuilder: (context, index) {
        final category = grouped.keys.elementAt(index);
        final items = grouped[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                _getCategoryTitle(category),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            ...items.map((item) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, color: Colors.green.shade700),
                ),
                title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(item.subtitle),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                onTap: () => _navigateToResult(item),
              ),
            )),
            const Divider(height: 32),
          ],
        );
      },
    );
  }

  String _getCategoryTitle(SearchResultCategory cat) {
    switch (cat) {
      case SearchResultCategory.crops: return '🌱 CROPS';
      case SearchResultCategory.activities: return '📋 ACTIVITIES';
      case SearchResultCategory.expenses: return '🧾 EXPENSES';
      case SearchResultCategory.income: return '💵 INCOME / SALES';
      case SearchResultCategory.reminders: return '🔔 REMINDERS';
      case SearchResultCategory.contacts: return '🆘 CONTACTS';
      case SearchResultCategory.growth: return '🌿 CROP GROWTH';
      case SearchResultCategory.photos: return '📸 PHOTOS';
      case SearchResultCategory.health: return '🌿 CROP HEALTH';
      case SearchResultCategory.knowledge: return '📚 KNOWLEDGE';
      case SearchResultCategory.tasks: return '📋 TASKS (PLANNER)';
    }
  }
}
