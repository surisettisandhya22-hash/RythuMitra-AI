import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/market_service.dart';
import '../screens/market_screen.dart';

import '../../../../core/services/network_service.dart';
import '../../../profile/services/profile_storage_service.dart';

class MarketSummaryCard extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final NetworkService networkService;
  
  const MarketSummaryCard({super.key, required this.profileStorageService, required this.networkService});

  @override
  State<MarketSummaryCard> createState() => _MarketSummaryCardState();
}

class _MarketSummaryCardState extends State<MarketSummaryCard> {
  final MarketService _marketService = MarketService();
  final String _topCrop = 'Tomato'; // Can be fetched from ProfileStorageService
  String _priceSummary = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    final prices = await _marketService.getMarketPrices(crop: _topCrop);
    if (prices.isNotEmpty && mounted) {
      final highest = prices.reduce((a, b) => a.modalPrice > b.modalPrice ? a : b);
      setState(() {
        _priceSummary = '₹${highest.modalPrice} / ${highest.unit}';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink(); // Hide while loading
    if (_priceSummary.isEmpty) return const SizedBox.shrink(); // Hide if no data

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      elevation: 2,
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.currency_rupee, color: Colors.white),
        ),
        title: Text(AppLocalizations.of(context).translate('market_update') == 'market_update' ? 'Market Update: $_topCrop' : '${AppLocalizations.of(context).translate('market_update')}: $_topCrop'),
        subtitle: Text('$_priceSummary\n${AppLocalizations.of(context).translate('last_updated') == 'last_updated' ? 'Last Updated' : AppLocalizations.of(context).translate('last_updated')}: ${DateTime.now().toLocal().toString().split('.')[0]}'),
        isThreeLine: true,
        trailing: TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MarketScreen(
                  marketService: _marketService, 
                  profileStorageService: widget.profileStorageService,
                  networkService: widget.networkService,
                  initialCrop: _topCrop,
              )),
            );
          },
          child: Text(AppLocalizations.of(context).translate('view_market') == 'view_market' ? 'View Market' : AppLocalizations.of(context).translate('view_market')),
        ),
      ),
    );
  }
}
