class MarketPrice {
  final String state;
  final String district;
  final String marketName;
  final String commodity;
  final String variety;
  final String grade;
  final String arrivalDate;
  final double minPrice;
  final double maxPrice;
  final double modalPrice;
  final String unit;

  MarketPrice({
    required this.state,
    required this.district,
    required this.marketName,
    required this.commodity,
    required this.variety,
    required this.grade,
    required this.arrivalDate,
    required this.minPrice,
    required this.maxPrice,
    required this.modalPrice,
    required this.unit,
  });

  factory MarketPrice.fromJson(Map<String, dynamic> json) {
    return MarketPrice(
      state: json['state'] as String,
      district: json['district'] as String,
      marketName: json['market'] as String,
      commodity: json['commodity'] as String,
      variety: json['variety'] as String,
      grade: json['grade'] as String,
      arrivalDate: json['arrivalDate'] as String,
      minPrice: (json['minPrice'] as num).toDouble(),
      maxPrice: (json['maxPrice'] as num).toDouble(),
      modalPrice: (json['modalPrice'] as num).toDouble(),
      unit: json['unit'] as String? ?? '₹/Quintal',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state,
      'district': district,
      'market': marketName,
      'commodity': commodity,
      'variety': variety,
      'grade': grade,
      'arrivalDate': arrivalDate,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'modalPrice': modalPrice,
      'unit': unit,
    };
  }
}
