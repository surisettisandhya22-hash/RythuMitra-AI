import 'package:flutter/material.dart';
import '../../../../shared/models/language.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import 'main_screen.dart';
import '../widgets/language_tile.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../profile/presentation/screens/initial_profile_setup_screen.dart';

class LanguageSelectionScreen extends StatefulWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final NetworkService networkService;
  final bool isFromSettings;

  const LanguageSelectionScreen({
    super.key,
    required this.storageService,
    required this.profileStorageService,
    required this.networkService,
    this.isFromSettings = false,
  });

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  // Common languages for initial list
  final List<Language> _allLanguages = const [
    Language(id: 'en', nativeName: 'English', englishName: 'English'),
    Language(id: 'te', nativeName: 'తెలుగు', englishName: 'Telugu'),
    Language(id: 'hi', nativeName: 'हिन्दी', englishName: 'Hindi'),
    Language(id: 'ta', nativeName: 'தமிழ்', englishName: 'Tamil'),
    Language(id: 'kn', nativeName: 'ಕನ್ನಡ', englishName: 'Kannada'),
    Language(id: 'ml', nativeName: 'മലയാളം', englishName: 'Malayalam'),
    Language(id: 'mr', nativeName: 'मराठी', englishName: 'Marathi'),
    Language(id: 'bn', nativeName: 'বাংলা', englishName: 'Bengali'),
    Language(id: 'gu', nativeName: 'ગુજરાતી', englishName: 'Gujarati'),
    Language(id: 'pa', nativeName: 'ਪੰਜਾਬੀ', englishName: 'Punjabi'),
  ];

  List<Language> _filteredLanguages = [];
  String? _selectedLanguageId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredLanguages = _allLanguages;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterLanguages(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredLanguages = _allLanguages;
      } else {
        _filteredLanguages = _allLanguages.where((lang) {
          return lang.englishName.toLowerCase().contains(query.toLowerCase()) ||
                 lang.nativeName.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  Future<void> _handleContinue() async {
    if (_selectedLanguageId == null) return;

    // Save selected language and mark as not first time
    await widget.storageService.saveSelectedLanguage(_selectedLanguageId!);
    await widget.storageService.setHasCompletedLanguageSelection(true);

    if (mounted) {
      if (widget.isFromSettings) {
        Navigator.of(context).pop();
      } else {
        if (!widget.storageService.isLoggedIn()) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => LoginScreen(
                storageService: widget.storageService,
                profileStorageService: widget.profileStorageService,
                networkService: widget.networkService,
              ),
            ),
          );
        } else {
          final profile = widget.profileStorageService.getFarmerProfile();
          if (profile == null || profile.name.isEmpty || profile.location.isEmpty) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => InitialProfileSetupScreen(
                  storageService: widget.storageService,
                  profileStorageService: widget.profileStorageService,
                  networkService: widget.networkService,
                ),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => MainScreen(
                  storageService: widget.storageService,
                  profileStorageService: widget.profileStorageService,
                  networkService: widget.networkService,
                ),
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Language',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You can change this later in Settings',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: _filterLanguages,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: 'Search Languages',
                      prefixIcon: const Icon(Icons.search, size: 28),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                    ),
                  ),
                ],
              ),
            ),
            
            // Language List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _filteredLanguages.length,
                itemBuilder: (context, index) {
                  final language = _filteredLanguages[index];
                  return LanguageTile(
                    language: language,
                    isSelected: _selectedLanguageId == language.id,
                    onTap: () {
                      setState(() {
                        _selectedLanguageId = language.id;
                      });
                    },
                  );
                },
              ),
            ),
            
            // Continue Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedLanguageId != null ? _handleContinue : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _selectedLanguageId != null ? Colors.white : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
