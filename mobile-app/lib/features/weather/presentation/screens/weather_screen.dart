import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/weather_repository.dart';
import '../../domain/models/weather_data.dart';
import '../../domain/models/weather_forecast.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../profile/presentation/screens/edit_farmer_profile_screen.dart';
import '../../../profile/data/models/farmer_profile.dart';
import '../../../../core/services/network_service.dart';
import '../widgets/smart_climate_advisory_card.dart';
import '../../services/weather_alert_engine.dart';
import '../../services/alert_storage_service.dart';
import '../../domain/models/weather_alert.dart';
import 'alerts_screen.dart';
import 'alert_details_screen.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../../core/services/storage_service.dart';


class WeatherScreen extends StatefulWidget {
  final WeatherRepository weatherRepository;
  final ProfileStorageService profileStorageService;
  final NetworkService networkService;
  final String? defaultLocation;

  const WeatherScreen({
    super.key,
    required this.weatherRepository,
    required this.profileStorageService,
    required this.networkService,
    this.defaultLocation,
  });

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  bool _isLoading = true;
  String? _error;
  bool _isOfflineCached = false;
  WeatherData? _currentWeather;
  List<WeatherForecast>? _forecast;
  List<WeatherAlert> _activeAlerts = [];
  late String _locationPref;
  final WeatherAlertEngine _alertEngine = WeatherAlertEngine();
  final AlertStorageService _alertStorage = AlertStorageService();

  String _getFarmLocationString() {
    final profile = widget.profileStorageService.farmerProfileNotifier.value;
    if (profile == null) return '';
    
    List<String> parts = [];
    if (profile.village != null && profile.village!.trim().isNotEmpty) parts.add(profile.village!.trim());
    if (profile.district != null && profile.district!.trim().isNotEmpty) parts.add(profile.district!.trim());
    if (profile.state != null && profile.state!.trim().isNotEmpty) parts.add(profile.state!.trim());
    
    return parts.join(', ');
  }

  @override
  void initState() {
    super.initState();
    _alertStorage.init();
    _locationPref = _getFarmLocationString();
    if (_locationPref.isNotEmpty) {
      _loadData();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _isOfflineCached = false;
    });

    try {
      final loc = _getFarmLocationString();
      if (loc.isEmpty) {
         setState(() { _isLoading = false; });
         return;
      }

      if (!widget.networkService.isOnline.value) {
        if (widget.weatherRepository.cachedWeather != null) {
          if (mounted) {
            final cachedW = widget.weatherRepository.cachedWeather!;
            final cachedF = widget.weatherRepository.cachedForecast ?? [];
            final generatedAlerts = _alertEngine.generateAlerts(cachedW, cachedF);
            setState(() {
              _currentWeather = cachedW;
              _forecast = cachedF;
              _activeAlerts = generatedAlerts;
              _isOfflineCached = true;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _error = AppLocalizations.of(context).translate('you_are_offline') == 'you_are_offline' ? 'You are offline. Please check your internet connection.' : AppLocalizations.of(context).translate('you_are_offline');
              _isLoading = false;
            });
          }
        }
        return;
      }
      
      final current = await widget.weatherRepository.getWeather(loc, customLocation: loc, forceRefresh: forceRefresh);
      final forecast = await widget.weatherRepository.getForecast(loc, customLocation: loc, forceRefresh: forceRefresh);
      final generatedAlerts = _alertEngine.generateAlerts(current, forecast);
      
      // Save alerts to alert storage for notification consistency
      for (final alert in generatedAlerts) {
        _alertStorage.addOrUpdateAlert(alert);
      }

      if (mounted) {
        setState(() {
          _currentWeather = current;
          _forecast = forecast;
          _activeAlerts = generatedAlerts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (widget.weatherRepository.cachedWeather != null) {
          final cachedW = widget.weatherRepository.cachedWeather!;
          final cachedF = widget.weatherRepository.cachedForecast ?? [];
          setState(() {
            _currentWeather = cachedW;
            _forecast = cachedF;
            _activeAlerts = _alertEngine.generateAlerts(cachedW, cachedF);
            _isOfflineCached = true;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'weather_unavailable';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _askAI() async {
    final storageService = StorageService();
    await storageService.init();

    if (!mounted) return;
    final loc = _getFarmLocationString();
    final tempStr = _currentWeather != null ? '${_currentWeather!.temperature.round()}°C' : '';
    final condStr = _currentWeather?.condition ?? '';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AIAssistantScreen(
          storageService: storageService,
          profileStorageService: widget.profileStorageService,
          networkService: widget.networkService,
          weatherRepository: widget.weatherRepository,
          alertContext: 'Current weather at $loc is $tempStr, $condStr. Please give farm management and irrigation advice for my crops.',
        ),
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain') || c.contains('drizzle') || c.contains('shower')) {
      return Icons.grain;
    } else if (c.contains('thunder')) {
      return Icons.thunderstorm;
    } else if (c.contains('fog') || c.contains('mist')) {
      return Icons.foggy;
    } else if (c.contains('partly') || c.contains('cloud')) {
      return Icons.cloud_outlined;
    } else if (c.contains('snow')) {
      return Icons.ac_unit;
    } else if (c.contains('wind')) {
      return Icons.air;
    }
    return Icons.wb_sunny_rounded;
  }

  Color _getWeatherColor(String condition) {
    final c = condition.toLowerCase();
    if (c.contains('rain') || c.contains('thunder')) {
      return Colors.blue.shade700;
    } else if (c.contains('cloud') || c.contains('fog')) {
      return Colors.blueGrey;
    }
    return Colors.amber.shade800;
  }

  String _getWeatherStateBadge(WeatherData weather) {
    final rain = weather.rain ?? 0.0;
    final wind = weather.windSpeed ?? 0.0;
    final temp = weather.temperature;

    if (rain > 1.0) {
      return '🌧️ Rainy Weather';
    } else if (wind >= 25.0) {
      return '💨 Windy Conditions';
    } else if (temp >= 36.0) {
      return '☀️ Hot Sunny Day';
    } else if (wind < 10.0 && rain <= 0.2) {
      return '🍃 Calm & Pleasant';
    }
    return '⛅ Mild Weather';
  }

  @override
  Widget build(BuildContext context) {
    final farmLoc = _getFarmLocationString();

    if (farmLoc.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context).translate('grid_climate') == 'grid_climate' ? 'Climate & Weather' : AppLocalizations.of(context).translate('grid_climate')),
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).translate('add_farm_location_weather') == 'add_farm_location_weather' 
                      ? 'Add your farm location to view local climate and weather.' 
                      : AppLocalizations.of(context).translate('add_farm_location_weather'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                     final currentProfile = widget.profileStorageService.farmerProfileNotifier.value ?? FarmerProfile(name: '', location: '', preferredLanguage: 'en');
                     Navigator.of(context).push(MaterialPageRoute(
                       builder: (_) => EditFarmerProfileScreen(
                           profileStorageService: widget.profileStorageService,
                           currentProfile: currentProfile,
                       )
                     )).then((_) {
                       setState(() {});
                       if (_getFarmLocationString().isNotEmpty) {
                         _loadData(forceRefresh: true);
                       }
                     });
                  },
                  icon: const Icon(Icons.edit_location_alt),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                  ),
                  label: Text(
                    AppLocalizations.of(context).translate('go_to_farm_location') == 'go_to_farm_location'
                        ? 'Go to Farm Location'
                        : AppLocalizations.of(context).translate('go_to_farm_location'),
                  ),
                )
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).translate('grid_climate') == 'grid_climate' ? 'Climate & Weather' : AppLocalizations.of(context).translate('grid_climate'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Weather Alerts',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AlertsScreen(
                    alertService: _alertStorage,
                    networkService: widget.networkService,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context).translate('refresh') == 'refresh' ? 'Refresh' : AppLocalizations.of(context).translate('refresh'),
            onPressed: () => _loadData(forceRefresh: true),
          )
        ],
      ),
      body: _isLoading
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.green.shade700),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context).translate('getting_weather_info')),
              ],
            ),
          )
        : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      _error == 'weather_unavailable' 
                          ? (AppLocalizations.of(context).translate('weather_unavailable') == 'weather_unavailable' 
                              ? 'Unable to get weather information right now.' 
                              : AppLocalizations.of(context).translate('weather_unavailable'))
                          : _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _loadData(forceRefresh: true),
                      icon: const Icon(Icons.refresh),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                      ),
                      label: Text(AppLocalizations.of(context).translate('try_again') == 'try_again' ? 'Try Again' : AppLocalizations.of(context).translate('try_again')),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_isOfflineCached)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).translate('offline_weather_warning') == 'offline_weather_warning' 
                                  ? 'Showing previously cached data. You are offline.' 
                                  : AppLocalizations.of(context).translate('offline_weather_warning'),
                              style: TextStyle(color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Location Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.location_on, color: Colors.green.shade700, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context).translate('farm_location') == 'farm_location' ? 'Farm Location' : AppLocalizations.of(context).translate('farm_location'),
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                _getFarmLocationString(),
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade900),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Today's Hero Weather Card
                  _buildTodayHeroCard(context),

                  const SizedBox(height: 16),

                  // Climate Alert Messages (Today, Tomorrow, and Severe)
                  if (_activeAlerts.isNotEmpty) ...[
                    _buildAlertsSection(context),
                    const SizedBox(height: 16),
                  ],

                  // Detailed Meteorological Metrics (Precipitation, Wind, Humidity, Air Quality, Feels-like)
                  _buildDetailedMetricsGrid(context),

                  const SizedBox(height: 20),

                  // Smart Farm Climate Advisory Card
                  SmartClimateAdvisoryCard(
                    location: _locationPref.isNotEmpty ? _locationPref : 'Andhra Pradesh',
                  ),

                  const SizedBox(height: 20),
                  
                  // Ask RythuMitra Button
                  ElevatedButton.icon(
                    onPressed: _askAI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.smart_toy, size: 22),
                    label: Text(
                      AppLocalizations.of(context).translate('explain_weather_farm') == 'explain_weather_farm'
                          ? 'Ask RythuMitra AI About Weather & Crops'
                          : AppLocalizations.of(context).translate('explain_weather_farm'),
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ),

                  const SizedBox(height: 24),
                  
                  // 5-Day Weather Forecast
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📅 5-Day Weather Forecast',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                      ),
                      Text(
                        'Day / Night',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_forecast != null) ..._forecast!.take(5).map((f) => _buildForecastDayCard(context, f)),
                  
                  const SizedBox(height: 28),
                  Center(
                    child: Text(
                      '${AppLocalizations.of(context).translate('last_updated')}: ${DateFormat.jm().format(_currentWeather!.lastUpdated)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildTodayHeroCard(BuildContext context) {
    final condition = _currentWeather!.condition;
    final temp = _currentWeather!.temperature.round();
    final feelsLike = _currentWeather!.feelsLike != null ? _currentWeather!.feelsLike!.round() : temp;
    final badge = _getWeatherStateBadge(_currentWeather!);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade900.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(22.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Text(
                'Today, ${DateFormat('d MMMM').format(DateTime.now())}',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$temp',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                      const Text(
                        '°C',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Feels like $feelsLike°C',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).translate('weather_${condition.replaceAll(' ', '_').toLowerCase()}'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getWeatherIcon(condition),
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Climate & Weather Alerts',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade900,
                  ),
                ),
              ],
            ),
            Text(
              '${_activeAlerts.length} Active',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._activeAlerts.take(3).map((alert) {
          final isImp = alert.severity == AlertSeverity.important;
          final title = alert.customTitle ?? (AppLocalizations.of(context).translate(alert.titleKey) == alert.titleKey ? alert.titleKey : AppLocalizations.of(context).translate(alert.titleKey));
          final desc = alert.customDescription ?? (AppLocalizations.of(context).translate(alert.descriptionKey) == alert.descriptionKey ? alert.descriptionKey : AppLocalizations.of(context).translate(alert.descriptionKey));

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isImp ? Colors.red.shade50 : Colors.amber.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isImp ? Colors.red.shade200 : Colors.amber.shade300),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: isImp ? Colors.red.shade100 : Colors.amber.shade100,
                child: Icon(
                  isImp ? Icons.warning_rounded : Icons.info_outline,
                  color: isImp ? Colors.red.shade800 : Colors.amber.shade900,
                  size: 20,
                ),
              ),
              title: Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isImp ? Colors.red.shade900 : Colors.amber.shade900,
                ),
              ),
              subtitle: Text(
                desc,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade800, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => AlertDetailsScreen(
                      alert: alert,
                      networkService: widget.networkService,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetailedMetricsGrid(BuildContext context) {
    final rain = _currentWeather!.rain?.toStringAsFixed(1) ?? '0.0';
    final wind = '${_currentWeather!.windSpeed?.round() ?? 0} km/h';
    final humidity = '${_currentWeather!.humidity?.round() ?? 0}%';
    final aqi = _currentWeather!.airQuality ?? 'Good (AQI 42)';
    final feelsLike = '${_currentWeather!.feelsLike?.round() ?? _currentWeather!.temperature.round()}°C';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '📊 Today\'s Weather Details',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _buildMetricTile(
              icon: Icons.umbrella_outlined,
              color: Colors.blue,
              title: 'Precipitation',
              value: '$rain mm',
              subtitle: _currentWeather!.rain != null && _currentWeather!.rain! > 0.5 ? 'Active Rain' : 'No Rain',
            ),
            _buildMetricTile(
              icon: Icons.air,
              color: Colors.teal,
              title: 'Wind Speed',
              value: wind,
              subtitle: (_currentWeather!.windSpeed ?? 0) > 20 ? 'Breezy' : 'Gentle',
            ),
            _buildMetricTile(
              icon: Icons.water_drop_outlined,
              color: Colors.indigo,
              title: 'Humidity',
              value: humidity,
              subtitle: (_currentWeather!.humidity ?? 0) > 75 ? 'Humid' : 'Moderate',
            ),
            _buildMetricTile(
              icon: Icons.thermostat_outlined,
              color: Colors.orange,
              title: 'Feels Like',
              value: feelsLike,
              subtitle: 'Apparent Temp',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.masks_outlined, color: Colors.green.shade800, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Air Quality (AQI)',
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      aqi,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Healthy',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                Text(
                  value,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastDayCard(BuildContext context, WeatherForecast forecast) {
    final now = DateTime.now();
    final isToday = DateFormat('yyyy-MM-dd').format(forecast.date) == DateFormat('yyyy-MM-dd').format(now);
    final isTomorrow = DateFormat('yyyy-MM-dd').format(forecast.date) == DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
    
    String dayLabel;
    if (isToday) {
      dayLabel = 'Today (${DateFormat('E').format(forecast.date)})';
    } else if (isTomorrow) {
      dayLabel = 'Tomorrow (${DateFormat('E').format(forecast.date)})';
    } else {
      dayLabel = DateFormat('EEEE, d MMM').format(forecast.date);
    }

    final rain = forecast.precipitation ?? 0.0;
    final cond = forecast.condition;
    final iconColor = _getWeatherColor(cond);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isToday ? Colors.green.shade300 : (isTomorrow ? Colors.teal.shade200 : Colors.grey.shade200),
          width: isToday || isTomorrow ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(_getWeatherIcon(cond), color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday || isTomorrow ? FontWeight.bold : FontWeight.w600,
                    color: isToday ? Colors.green.shade900 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).translate('weather_${cond.replaceAll(' ', '_').toLowerCase()}'),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                    if (rain > 0.0) ...[
                      const SizedBox(width: 6),
                      Text(
                        '• 💧 ${rain.toStringAsFixed(1)} mm',
                        style: TextStyle(fontSize: 11, color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${forecast.maxTemperature.round()}°C',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                Text(
                  'Min ${forecast.minTemperature.round()}°C',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
