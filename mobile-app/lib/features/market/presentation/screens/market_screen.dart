import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/market_price.dart';
import '../../services/market_service.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../voice/services/text_to_speech_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../profile/data/models/farmer_profile.dart';
import '../../../profile/presentation/screens/edit_farmer_profile_screen.dart';
import '../../../profile/presentation/screens/edit_crop_screen.dart';
import '../../../../core/services/network_service.dart';

class MarketScreen extends StatefulWidget {
  final MarketService marketService;
  final ProfileStorageService profileStorageService;
  final NetworkService networkService;
  final String? initialCrop;

  const MarketScreen({super.key, required this.marketService, required this.profileStorageService, required this.networkService, this.initialCrop});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  late TextEditingController _searchController;
  List<MarketPrice> _prices = [];
  bool _isLoading = false;
  String _currentSearch = '';
  String? _errorMessage;
  String? _selectedLocation;
  bool _isOfflineCached = false;

  String _getFarmLocationString() {
    final profile = widget.profileStorageService.farmerProfileNotifier.value;
    if (profile == null) return '';
    List<String> parts = [];
    if (profile.village != null && profile.village!.trim().isNotEmpty) parts.add(profile.village!.trim());
    if (profile.district != null && profile.district!.trim().isNotEmpty) parts.add(profile.district!.trim());
    if (profile.state != null && profile.state!.trim().isNotEmpty) parts.add(profile.state!.trim());
    return parts.join(', ');
  }

  String? _getDistrict() {
    final profile = widget.profileStorageService.farmerProfileNotifier.value;
    if (profile != null && profile.district != null && profile.district!.trim().isNotEmpty) {
       return profile.district!.trim();
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialCrop ?? '');
    if (widget.initialCrop != null && widget.initialCrop!.isNotEmpty) {
      _fetchPrices(widget.initialCrop!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrices(String crop) async {
    if (crop.trim().isEmpty) return;

    if (!widget.networkService.isOnline.value) {
       setState(() {
         _prices = [];
         _errorMessage = AppLocalizations.of(context).translate('feature_requires_internet') == 'feature_requires_internet' ? 'This feature requires an internet connection.' : AppLocalizations.of(context).translate('feature_requires_internet');
         _isLoading = false;
         _isOfflineCached = true;
       });
       return;
    }

    setState(() {
      _isLoading = true;
      _currentSearch = crop;
      _errorMessage = null;
      _isOfflineCached = false;
    });

    try {
      final district = _selectedLocation ?? _getDistrict();
      final prices = await widget.marketService.getMarketPrices(
        crop: crop.trim(),
        district: district,
      );
      
      if (mounted) {
        setState(() {
          _prices = prices;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Fallback to cache if any
        final cached = await _tryGetCachedPrices(crop.trim(), _selectedLocation ?? _getDistrict());
        if (cached.isNotEmpty) {
           setState(() {
              _prices = cached;
              _isOfflineCached = true;
              _isLoading = false;
           });
        } else {
           setState(() {
             final errorStr = e.toString().toLowerCase();
             if (errorStr.contains('invalid crop')) {
               _errorMessage = 'Please select a valid crop.';
             } else {
               _errorMessage = 'market_unavailable';
             }
             _prices = [];
             _isLoading = false;
           });
        }
      }
    }
  }

  Future<List<MarketPrice>> _tryGetCachedPrices(String crop, String? district) async {
    // If the service had a public cache we could access it. Since we can't easily,
    // we'll just check if it throws immediately. But it might throw network errors.
    // For now, if we reach here and there is no cache, we just return empty list.
    // Actually the market service caches internally. If it fails, it throws. So if we caught it, cache missed or expired.
    return [];
  }

  void _onChangeLocation() async {
    // Hidden for STEP 27 to strictly use Farm Location, or just keeping it minimal.
  }

  void _askRythuMitra() async {
    if (_prices.isEmpty) return;
    
    final highest = _prices.reduce((a, b) => a.modalPrice > b.modalPrice ? a : b);
    final contextMessage = 'I am looking at market prices for $_currentSearch. '
        'The highest modal price is ₹${highest.modalPrice} at ${highest.marketName}. '
        'Can you tell me more about selling $_currentSearch? Please do not guarantee future prices.';
    
    final storageService = StorageService();
    await storageService.init();

    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIAssistantScreen(
            storageService: storageService,
            networkService: widget.networkService,
            healthContext: contextMessage, 
          ),
        ),
      );
    }
  }

  void _listenToSummary() async {
    if (_prices.isEmpty) return;
    final highest = _prices.reduce((a, b) => a.modalPrice > b.modalPrice ? a : b);
    
    final msg = '$_currentSearch modal price at ${highest.marketName} is ${highest.modalPrice} Rupees per Quintal, reported on ${highest.arrivalDate}.';
    final voiceService = TextToSpeechService();
    await voiceService.init();
    
    if (mounted) {
      final locale = Localizations.localeOf(context).languageCode;
      await voiceService.speak(msg, locale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farmLoc = _getFarmLocationString();
    
    if (farmLoc.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context).translate('market_prices'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).translate('add_farm_location') == 'add_farm_location'
                    ? 'Add your farm location to view local market information.'
                    : AppLocalizations.of(context).translate('add_farm_location'),
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
                     )).then((_) => setState(() {}));
                  },
                  icon: const Icon(Icons.edit_location_alt),
                  label: Text(
                    AppLocalizations.of(context).translate('go_to_farm_location') == 'go_to_farm_location'
                      ? 'Go to Farm Location'
                      : AppLocalizations.of(context).translate('go_to_farm_location')
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
        title: Text(AppLocalizations.of(context).translate('market_prices')),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              widget.marketService.clearCache();
              if (_searchController.text.isNotEmpty) {
                _fetchPrices(_searchController.text);
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).translate('search_crop'),
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search),
                            onPressed: () => _fetchPrices(_searchController.text),
                          ),
                        ),
                        onSubmitted: _fetchPrices,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder(
                  valueListenable: widget.profileStorageService.cropsNotifier,
                  builder: (context, crops, _) {
                    if (crops.isEmpty) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(AppLocalizations.of(context).translate('no_crops_yet') == 'no_crops_yet' 
                            ? 'No crops added yet.' 
                            : AppLocalizations.of(context).translate('no_crops_yet'), style: const TextStyle(color: Colors.grey)),
                          TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => EditCropScreen(profileStorageService: widget.profileStorageService)
                              )).then((_) => setState((){}));
                            },
                            child: Text(AppLocalizations.of(context).translate('add_crop_market') == 'add_crop_market' ? 'Add Crop' : AppLocalizations.of(context).translate('add_crop_market')),
                          )
                        ],
                      );
                    }
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: crops.map((crop) => Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: Text(crop.cropName),
                            avatar: const CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.grass, size: 16, color: Colors.white)),
                            onPressed: () {
                               _searchController.text = crop.cropName;
                               _fetchPrices(crop.cropName);
                            },
                          )
                        )).toList(),
                      )
                    );
                  }
                ),
              ],
            ),
          ),
          if (_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).translate('getting_market_info') == 'getting_market_info'
                        ? 'Getting market information...'
                        : AppLocalizations.of(context).translate('getting_market_info')
                    ),
                  ],
                ),
              ),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).translate(_errorMessage!) == _errorMessage! 
                          ? _errorMessage! 
                          : AppLocalizations.of(context).translate(_errorMessage!),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => _fetchPrices(_searchController.text),
                        child: Text(AppLocalizations.of(context).translate('retry')),
                      )
                    ],
                  ),
                ),
              ),
            )
          else if (_prices.isEmpty && _currentSearch.isNotEmpty)
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📊', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).translate('no_market_price_found'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context).translate('no_market_price_desc'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            widget.marketService.clearCache();
                            _fetchPrices(_currentSearch);
                          },
                          icon: const Icon(Icons.refresh),
                          label: Text(AppLocalizations.of(context).translate('try_again')),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _onChangeLocation,
                          icon: const Icon(Icons.location_on),
                          label: Text(AppLocalizations.of(context).translate('change_location')),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _prices = [];
                              _currentSearch = '';
                            });
                          },
                          icon: const Icon(Icons.eco),
                          label: Text(AppLocalizations.of(context).translate('search_another_crop')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: Column(
                children: [
                  if (_isOfflineCached)
                    Container(
                      color: Colors.orange.shade100,
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.wifi_off, size: 16, color: Colors.deepOrange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).translate('you_are_offline') == 'you_are_offline'
                                ? 'You are offline. Please check your internet connection.'
                                : AppLocalizations.of(context).translate('you_are_offline'),
                              style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: _prices.length,
                      itemBuilder: (context, index) {
                  final item = _prices[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.marketName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                ),
                              ),
                              Text(
                                item.commodity,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text('${item.district}, ${item.state}', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).translate('minimum_price') == 'minimum_price'
                                      ? 'Minimum'
                                      : AppLocalizations.of(context).translate('minimum_price'),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12)
                                  ),
                                  Text('₹${item.minPrice}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).translate('modal_price') == 'modal_price'
                                      ? 'Modal (Average)'
                                      : AppLocalizations.of(context).translate('modal_price'),
                                    style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)
                                  ),
                                  Text('₹${item.modalPrice}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    AppLocalizations.of(context).translate('maximum_price') == 'maximum_price'
                                      ? 'Maximum'
                                      : AppLocalizations.of(context).translate('maximum_price'),
                                    style: const TextStyle(color: Colors.grey, fontSize: 12)
                                  ),
                                  Text('₹${item.maxPrice}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${AppLocalizations.of(context).translate('reported_on') == 'reported_on' ? 'Reported On:' : AppLocalizations.of(context).translate('reported_on')} ${item.arrivalDate}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              Text(
                                '${AppLocalizations.of(context).translate('unit_label') == 'unit_label' ? 'Unit:' : AppLocalizations.of(context).translate('unit_label')} ${item.unit}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
          
      if (_prices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _askRythuMitra,
                      icon: const Icon(Icons.smart_toy),
                      label: Text(AppLocalizations.of(context).translate('ask_rythumitra')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade100,
                        foregroundColor: Colors.green.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _listenToSummary,
                      icon: const Icon(Icons.volume_up),
                      label: Text(AppLocalizations.of(context).translate('listen_audio')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade100,
                        foregroundColor: Colors.blue.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
