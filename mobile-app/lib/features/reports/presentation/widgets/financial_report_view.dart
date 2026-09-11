import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../profile/services/profile_storage_service.dart';
import 'package:intl/intl.dart';
import '../../../profile/presentation/screens/farm_income_screen.dart';
import '../../../profile/presentation/screens/farm_expenses_screen.dart';
import '../../../../core/services/storage_service.dart';

class FinancialReportView extends StatelessWidget {
  final ProfileStorageService profileStorageService;
  final StorageService storageService;
  final DateTime? fromDate;
  final DateTime? toDate;

  const FinancialReportView({
    super.key,
    required this.profileStorageService,
    required this.storageService,
    this.fromDate,
    this.toDate,
  });

  bool _isWithinRange(DateTime date) {
    if (fromDate != null && date.isBefore(fromDate!)) return false;
    if (toDate != null && date.isAfter(toDate!.add(const Duration(days: 1)))) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final allExpenses = profileStorageService.getExpenses();
    final allSales = profileStorageService.getSales();

    final filteredExpenses = allExpenses.where((e) => _isWithinRange(DateTime.parse(e.date))).toList();
    final filteredSales = allSales.where((s) => _isWithinRange(DateTime.parse(s.saleDate))).toList();

    if (filteredExpenses.isEmpty && filteredSales.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            t.translate('no_records_available') == 'no_records_available' ? 'No records available for this period.' : t.translate('no_records_available'),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    double totalExpenses = 0.0;
    for (var e in filteredExpenses) {
      totalExpenses += e.amount;
    }

    double totalIncome = 0.0;
    for (var s in filteredSales) {
      totalIncome += s.totalSaleValue;
    }

    double netBalance = totalIncome - totalExpenses;
    
    String periodText = '';
    if (fromDate != null && toDate != null) {
      periodText = '${DateFormat('dd MMM yyyy').format(fromDate!)} – ${DateFormat('dd MMM yyyy').format(toDate!)}';
    } else {
      periodText = t.translate('all_time') == 'all_time' ? 'All Time' : t.translate('all_time');
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${t.translate('period') == 'period' ? 'Period' : t.translate('period')}: $periodText',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('💵 ', style: TextStyle(fontSize: 22)),
                      Text(
                        t.translate('total_income') == 'total_income' ? 'Total Income' : t.translate('total_income'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('₹${totalIncome.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Text('🧾 ', style: TextStyle(fontSize: 22)),
                      Text(
                        t.translate('total_expenses') == 'total_expenses' ? 'Total Expenses' : t.translate('total_expenses'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('₹${totalExpenses.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, color: Colors.red, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),
                  Row(
                    children: [
                      const Text('📈 ', style: TextStyle(fontSize: 22)),
                      Text(
                        t.translate('net_balance') == 'net_balance' ? 'Net Balance' : t.translate('net_balance'),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${netBalance.toStringAsFixed(2)}', 
                    style: TextStyle(
                      fontSize: 28, 
                      color: netBalance >= 0 ? Colors.green.shade900 : Colors.red.shade900, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FarmIncomeScreen(
                        profileStorageService: profileStorageService,
                        storageService: storageService,
                      ),
                    ));
                  },
                  icon: const Icon(Icons.attach_money, color: Colors.white),
                  label: Text(t.translate('income') == 'income' ? 'Income' : t.translate('income'), style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FarmExpensesScreen(
                        profileStorageService: profileStorageService,
                        storageService: storageService,
                      ),
                    ));
                  },
                  icon: const Icon(Icons.money_off, color: Colors.white),
                  label: Text(t.translate('expenses') == 'expenses' ? 'Expenses' : t.translate('expenses'), style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
