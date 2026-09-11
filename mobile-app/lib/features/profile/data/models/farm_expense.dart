class FarmExpense {
  final String id;
  final String expenseType;
  final double amount;
  final String? cropId;
  final String date; // ISO 8601 string
  final String? notes;
  final String? createdAt;
  final String? updatedAt;
  final String syncStatus;

  FarmExpense({
    required this.id,
    required this.expenseType,
    required this.amount,
    this.cropId,
    required this.date,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 'local',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'expenseType': expenseType,
      'amount': amount,
      'cropId': cropId,
      'date': date,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'syncStatus': syncStatus,
    };
  }

  factory FarmExpense.fromJson(Map<String, dynamic> json) {
    return FarmExpense(
      id: json['id'] as String,
      expenseType: json['expenseType'] as String,
      amount: (json['amount'] as num).toDouble(),
      cropId: json['cropId'] as String?,
      date: json['date'] as String,
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      syncStatus: json['syncStatus'] as String? ?? 'local',
    );
  }

  FarmExpense copyWith({
    String? id,
    String? expenseType,
    double? amount,
    String? cropId,
    bool clearCropId = false,
    String? date,
    String? notes,
    String? createdAt,
    String? updatedAt,
    String? syncStatus,
  }) {
    return FarmExpense(
      id: id ?? this.id,
      expenseType: expenseType ?? this.expenseType,
      amount: amount ?? this.amount,
      cropId: clearCropId ? null : (cropId ?? this.cropId),
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
