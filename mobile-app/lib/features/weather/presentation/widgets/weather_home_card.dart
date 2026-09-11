import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/weather_repository.dart';
import '../../domain/models/weather_data.dart';
import '../screens/weather_screen.dart';
import '../../../../core/services/network_service.dart';

import '../../../profile/services/profile_storage_service.dart';

class WeatherHomeCard extends StatefulWidget {
  final WeatherRepository weatherRepository;
  final ProfileStorageService profileStorageService;
  final NetworkService networkService;
  final String? defaultLocation;

  const WeatherHomeCard({
    super.key,
    required this.weatherRepository,
    required this.profileStorageService,
    required this.networkService,
    this.defaultLocation,
  });

  @override
  State<WeatherHomeCard> createState() => _WeatherHomeCardState();
}

class _WeatherHomeCardState extends State<WeatherHomeCard> {
  bool _isLoading = true;
  WeatherData? _weatherData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    if (!widget.networkService.isOnline.value) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).translate('you_are_offline') == 'you_are_offline' ? 'You are offline. Please check your internet connection.' : AppLocalizations.of(context).translate('you_are_offline');
          _isLoading = false;
        });
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final loc = widget.defaultLocation?.isNotEmpty == true ? widget.defaultLocation : 'current';
      final data = await widget.weatherRepository.getWeather(
        loc!,
        customLocation: loc == 'current' ? null : loc,
      );
      if (mounted) {
        setState(() {
          _weatherData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'weather_load_error';
          _isLoading = false;
        });
      }
    }
  }

  void _openWeatherScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => WeatherScreen(
        weatherRepository: widget.weatherRepository,
        profileStorageService: widget.profileStorageService,
        networkService: widget.networkService,
        defaultLocation: widget.defaultLocation,
      ),
    )).then((_) {
      // Refresh on return in case location changed
      _loadWeather();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openWeatherScreen,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _error != null 
              ? Row(
                  children: [
                    const Icon(Icons.cloud_off, color: Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _error == 'weather_load_error' ? AppLocalizations.of(context).translate(_error!) : _error!,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(Icons.cloud_outlined, size: 48, color: Colors.blue),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 14, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(
                                _weatherData!.locationName,
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context).translate('weather_${_weatherData!.condition.replaceAll(' ', '_').toLowerCase()}'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_weatherData!.temperature.round()}°C',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
        ),
      ),
    );
  }
}
