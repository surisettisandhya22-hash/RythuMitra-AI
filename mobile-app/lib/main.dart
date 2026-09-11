import 'package:flutter/material.dart';
import 'core/services/storage_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'features/foundation/presentation/screens/splash_screen.dart';
import 'features/profile/services/profile_storage_service.dart';
import 'core/services/network_service.dart';
import 'features/tasks/services/reminder_storage_service.dart';
import 'features/weather/data/repositories/weather_repository.dart';
import 'features/tasks/presentation/screens/alerts_screen.dart';
import 'core/services/backend_config_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Storage Service
  final storageService = StorageService();
  await storageService.init();

  final networkService = NetworkService();
  await networkService.init();

  // Initialize Profile Storage Service
  final profileStorageService = ProfileStorageService();
  await profileStorageService.init();

  // Initialize Backend Config Service
  await BackendConfigService.init();

  final weatherRepository = WeatherRepository();
  
  final reminderStorageService = ReminderStorageService();
  await reminderStorageService.init(
    onNotificationTap: (payload) {
      if (payload != null && navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => AlertsScreen(
              weatherRepository: weatherRepository,
              storageService: storageService,
              profileStorageService: profileStorageService,
              networkService: networkService,
            ),
          ),
        );
      }
    },
  );

  runApp(RythuMitraApp(
    storageService: storageService,
    profileStorageService: profileStorageService,
    networkService: networkService,
  ));
}

class RythuMitraApp extends StatelessWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final NetworkService networkService;

  const RythuMitraApp({
    super.key, 
    required this.storageService,
    required this.profileStorageService,
    required this.networkService,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: storageService.languageNotifier,
      builder: (context, languageCode, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'RythuMitra AI',
          debugShowCheckedModeBanner: false,
          locale: Locale(languageCode), // Force the locale to match the user's selection
          supportedLocales: const [
            Locale('en'),
            Locale('te'),
            Locale('hi'),
            Locale('ta'),
            Locale('kn'),
            Locale('ml'),
            Locale('mr'),
            Locale('bn'),
            Locale('gu'),
            Locale('pa'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade700),
            useMaterial3: true,
            fontFamily: 'Roboto', // Professional font default
          ),
          home: SplashScreen(
            storageService: storageService,
            profileStorageService: profileStorageService,
            networkService: networkService,
          ),
        );
      },
    );
  }
}






 
