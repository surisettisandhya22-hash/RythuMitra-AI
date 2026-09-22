import 'package:flutter/material.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import 'language_selection_screen.dart';
import 'main_screen.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../profile/presentation/screens/initial_profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final NetworkService networkService;

  const SplashScreen({
    super.key, 
    required this.storageService,
    required this.profileStorageService,
    required this.networkService,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkInitialNavigation();
  }

  Future<void> _checkInitialNavigation() async {
    // Add a slight delay so the user can see the splash screen branding
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (!widget.storageService.hasCompletedLanguageSelection()) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LanguageSelectionScreen(
            storageService: widget.storageService,
            profileStorageService: widget.profileStorageService,
            networkService: widget.networkService,
          ),
        ),
      );
    } else if (!widget.storageService.isLoggedIn()) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Agriculture-inspired Logo/Icon
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.energy_savings_leaf,
                size: 80,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 32),
            // Branding
            Text(
              'RythuMitra AI',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            // Tagline
            Text(
              'Smart Farming Companion\nfor Every Farmer',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 64),
            // Loading indicator
            CircularProgressIndicator(
              color: Colors.green.shade600,
            ),
          ],
        ),
      ),
    );
  }
}
