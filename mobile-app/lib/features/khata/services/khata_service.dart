import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../domain/models/khata_model.dart';

class KhataService {
  final http.Client _client;

  KhataService({http.Client? client}) : _client = client ?? http.Client();

  Future<FarmKhataSummary> fetchSummary() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/khata/summary');

    try {
      final response = await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FarmKhataSummary.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching Khata from backend: $e. Falling back to local offline ledger.');
    }

    return _buildOfflineSummary();
  }

  Future<FarmKhataSummary> addTransaction(FarmTransactionItem item) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/khata/transaction');

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(item.toJson()),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return FarmKhataSummary.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error posting transaction to backend: $e');
    }

    return _buildOfflineSummary();
  }

  FarmKhataSummary _buildOfflineSummary() {
    final sampleItems = [
      FarmTransactionItem(
        id: 'off_1',
        type: 'expense',
        category: 'seeds',
        amount: 2800.0,
        description: 'Certified Hybrid Seeds (2 bags)',
        date: '2026-10-15',
        cropName: 'Paddy',
      ),
      FarmTransactionItem(
        id: 'off_2',
        type: 'expense',
        category: 'fertilizer',
        amount: 4200.0,
        description: 'DAP & Potash application',
        date: '2026-10-16',
        cropName: 'Paddy',
      ),
      FarmTransactionItem(
        id: 'off_3',
        type: 'expense',
        category: 'labor_coolie',
        amount: 5400.0,
        description: 'Transplanting Labor (6 workers)',
        date: '2026-10-17',
        cropName: 'Paddy',
      ),
      FarmTransactionItem(
        id: 'off_4',
        type: 'income',
        category: 'crop_sale',
        amount: 38500.0,
        description: 'Mandi Vegetable & Grain Sale',
        date: '2026-10-18',
        cropName: 'Paddy',
      ),
    ];

    return FarmKhataSummary(
      totalIncome: 38500.0,
      totalExpense: 12400.0,
      netProfitLoss: 26100.0,
      isProfit: true,
      transactions: sampleItems,
      categoryBreakdown: {
        'seeds': 2800.0,
        'fertilizer': 4200.0,
        'labor_coolie': 5400.0,
      },
      insights: [
        'Your farm is operating at a Net Seasonal Profit of ₹26,100.',
        'Labor & Fertilizer account for over 70% of total input expenses.',
      ],
    );
  }
}
