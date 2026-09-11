class FarmSale {
  final String id;
  final String cropId;
  final double quantity;
  final String quantityUnit;
  final double sellingPrice;
  final String priceUnit;
  final double totalSaleValue;
  final String? buyer;
  final String saleDate;
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final String syncStatus;

  FarmSale({
    required this.id,
    required this.cropId,
    required this.quantity,
    required this.quantityUnit,
    required this.sellingPrice,
    required this.priceUnit,
    required this.totalSaleValue,
    this.buyer,
    required this.saleDate,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 'local',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropId': cropId,
      'quantity': quantity,
      'quantityUnit': quantityUnit,
      'sellingPrice': sellingPrice,
      'priceUnit': priceUnit,
      'totalSaleValue': totalSaleValue,
      'buyer': buyer,
      'saleDate': saleDate,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'syncStatus': syncStatus,
    };
  }

  factory FarmSale.fromJson(Map<String, dynamic> json) {
    return FarmSale(
      id: json['id'] as String,
      cropId: json['cropId'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      quantityUnit: json['quantityUnit'] as String,
      sellingPrice: (json['sellingPrice'] as num).toDouble(),
      priceUnit: json['priceUnit'] as String,
      totalSaleValue: (json['totalSaleValue'] as num).toDouble(),
      buyer: json['buyer'] as String?,
      saleDate: json['saleDate'] as String,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      syncStatus: json['syncStatus'] as String? ?? 'local',
    );
  }

  FarmSale copyWith({
    String? id,
    String? cropId,
    double? quantity,
    String? quantityUnit,
    double? sellingPrice,
    String? priceUnit,
    double? totalSaleValue,
    String? buyer,
    String? saleDate,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) {
    return FarmSale(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      quantity: quantity ?? this.quantity,
      quantityUnit: quantityUnit ?? this.quantityUnit,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      priceUnit: priceUnit ?? this.priceUnit,
      totalSaleValue: totalSaleValue ?? this.totalSaleValue,
      buyer: buyer ?? this.buyer,
      saleDate: saleDate ?? this.saleDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
