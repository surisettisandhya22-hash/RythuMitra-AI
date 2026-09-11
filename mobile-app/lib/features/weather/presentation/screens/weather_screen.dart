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
  late String _locationPref;

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
            setState(() {
              _currentWeather = widget.weatherRepository.cachedWeather;
              _forecast = widget.weatherRepository.cachedForecast;
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
      
      if (mounted) {
        setState(() {
          _currentWeather = current;
          _forecast = forecast;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        if (widget.weatherRepository.cachedWeather != null) {
          setState(() {
            _currentWeather = widget.weatherRepository.cachedWeather;
            _forecast = widget.weatherRepository.cachedForecast;
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



  void _askAI() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).translate('ai_title'))),
        body: const Center(child: Text("AI Assistant Screen Placeholder")),
      )
    ));
    // We will just return to main screen to use real AI screen, or pass an initial message.
    Navigator.of(context).pop('ask_weather');
  }

  @override
  Widget build(BuildContext context) {
    final farmLoc = _getFarmLocationString();

    if (farmLoc.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).translate('quick_weather'))),
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
                      ? 'Add your farm location to view local weather.' 
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
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('quick_weather')),
        actions: [
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
                const CircularProgressIndicator(),
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
                        borderRadius: BorderRadius.circular(8),
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
                  // Location Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).translate('farm_location') == 'farm_location' ? 'Farm Location' : AppLocalizations.of(context).translate('farm_location'),
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getFarmLocationString(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  // Current Weather
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            AppLocalizations.of(context).translate('current_weather'),
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          const Icon(Icons.wb_sunny_outlined, size: 64, color: Colors.orange), // A placeholder icon
                          const SizedBox(height: 16),
                          Text(
                            '${_currentWeather!.temperature.round()}°C',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            AppLocalizations.of(context).translate('weather_${_currentWeather!.condition.replaceAll(' ', '_').toLowerCase()}'),
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _WeatherDetailItem(
                                icon: Icons.water_drop_outlined,
                                label: AppLocalizations.of(context).translate('humidity'),
                                value: '${_currentWeather!.humidity?.round() ?? 0}%',
                              ),
                              _WeatherDetailItem(
                                icon: Icons.air,
                                label: AppLocalizations.of(context).translate('wind'),
                                value: '${_currentWeather!.windSpeed?.round() ?? 0} km/h',
                              ),
                              _WeatherDetailItem(
                                icon: Icons.umbrella_outlined,
                                label: AppLocalizations.of(context).translate('rain'),
                                value: '${_currentWeather!.rain?.toStringAsFixed(1) ?? "0"} mm',
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Ask RythuMitra Button
                  ElevatedButton.icon(
                    onPressed: _askAI,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade100,
                      foregroundColor: Colors.green.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.smart_toy),
                    label: Text(
                      AppLocalizations.of(context).translate('explain_weather_farm'),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Forecast
                  Text(
                    AppLocalizations.of(context).translate('forecast'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  if (_forecast != null) ..._forecast!.take(5).map((f) => _ForecastRow(forecast: f)),
                  
                  const SizedBox(height: 32),
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
}

class _WeatherDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WeatherDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final WeatherForecast forecast;

  const _ForecastRow({required this.forecast});

  @override
  Widget build(BuildContext context) {
    final isToday = DateFormat('yyyy-MM-dd').format(forecast.date) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dayLabel = isToday ? AppLocalizations.of(context).translate('today') : DateFormat('EEEE').format(forecast.date); // Need translation for days optionally
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(dayLabel, style: const TextStyle(fontSize: 16)),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.cloud_outlined, size: 20, color: Colors.grey), // Placeholder
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).translate('weather_${forecast.condition.replaceAll(' ', '_').toLowerCase()}'),
                    style: const TextStyle(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${forecast.maxTemperature.round()}° / ${forecast.minTemperature.round()}°',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
