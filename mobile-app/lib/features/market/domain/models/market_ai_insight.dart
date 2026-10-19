import 'market_price.dart';

class MarketAIInsightModel {
  final String headline;
  final String? bestMarket;
  final String priceTrend;
  final String advisory;
  final String? storageTip;

  MarketAIInsightModel({
    required this.headline,
    this.bestMarket,
    required this.priceTrend,
    required this.advisory,
    this.storageTip,
  });

  factory MarketAIInsightModel.fromJson(Map<String, dynamic> json) {
    return MarketAIInsightModel(
      headline: json['headline'] ?? '',
      bestMarket: json['bestMarket'],
      priceTrend: json['priceTrend'] ?? 'Steady',
      advisory: json['advisory'] ?? '',
      storageTip: json['storageTip'],
    );
  }
}

class MarketDataResult {
  final List<MarketPrice> prices;
  final MarketAIInsightModel? insight;

  MarketDataResult({
    required this.prices,
    this.insight,
  });
}
