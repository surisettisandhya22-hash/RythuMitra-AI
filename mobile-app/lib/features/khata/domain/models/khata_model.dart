class FarmTransactionItem {
  final String id;
  final String type; // 'expense' or 'income'
  final String category; // 'seeds', 'fertilizer', 'labor_coolie', 'machinery_diesel', 'pesticides', 'crop_sale', 'subsidy', 'other'
  final double amount;
  final String description;
  final String date;
  final String cropName;

  FarmTransactionItem({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.description,
    required this.date,
    required this.cropName,
  });

  factory FarmTransactionItem.fromJson(Map<String, dynamic> json) {
    return FarmTransactionItem(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'expense',
      category: json['category'] as String? ?? 'other',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String? ?? '',
      date: json['date'] as String? ?? '',
      cropName: json['crop_name'] as String? ?? 'General Farm',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'category': category,
      'amount': amount,
      'description': description,
      'date': date,
      'crop_name': cropName,
    };
  }
}

class FarmKhataSummary {
  final double totalIncome;
  final double totalExpense;
  final double netProfitLoss;
  final bool isProfit;
  final List<FarmTransactionItem> transactions;
  final Map<String, double> categoryBreakdown;
  final List<String> insights;

  FarmKhataSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netProfitLoss,
    required this.isProfit,
    required this.transactions,
    required this.categoryBreakdown,
    required this.insights,
  });

  factory FarmKhataSummary.fromJson(Map<String, dynamic> json) {
    final rawTx = json['transactions'] as List<dynamic>? ?? [];
    final rawInsights = json['insights'] as List<dynamic>? ?? [];
    final rawBreakdown = json['category_breakdown'] as Map<String, dynamic>? ?? {};

    final Map<String, double> breakdown = {};
    rawBreakdown.forEach((k, v) {
      breakdown[k] = (v as num).toDouble();
    });

    return FarmKhataSummary(
      totalIncome: (json['total_income'] as num?)?.toDouble() ?? 0.0,
      totalExpense: (json['total_expense'] as num?)?.toDouble() ?? 0.0,
      netProfitLoss: (json['net_profit_loss'] as num?)?.toDouble() ?? 0.0,
      isProfit: json['is_profit'] as bool? ?? false,
      transactions: rawTx.map((t) => FarmTransactionItem.fromJson(t as Map<String, dynamic>)).toList(),
      categoryBreakdown: breakdown,
      insights: rawInsights.map((i) => i.toString()).toList(),
    );
  }
}
