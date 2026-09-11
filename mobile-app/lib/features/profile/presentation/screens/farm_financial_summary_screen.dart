import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/storage_service.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/farm_expense.dart';
import '../../data/models/farm_sale.dart';
import 'add_edit_expense_screen.dart';
import 'add_edit_sale_screen.dart';
import '../../../../features/voice/presentation/widgets/global_listen_button.dart';

class FarmFinancialSummaryScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final StorageService storageService;

  const FarmFinancialSummaryScreen({
    super.key,
    required this.profileStorageService,
    required this.storageService,
  });

  @override
  State<FarmFinancialSummaryScreen> createState() => _FarmFinancialSummaryScreenState();
}

class _FarmFinancialSummaryScreenState extends State<FarmFinancialSummaryScreen> {
  String _filterType = 'All Time';
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(t.translate('farm_financial_summary') == 'farm_financial_summary' ? 'Farm Financial Summary' : t.translate('farm_financial_summary')),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          widget.profileStorageService.expensesNotifier,
          widget.profileStorageService.salesNotifier,
        ]),
        builder: (context, _) {
          final allExpenses = widget.profileStorageService.expensesNotifier.value;
          final allSales = widget.profileStorageService.salesNotifier.value;

          // Apply Date Filter
          final filteredExpenses = _filterExpenses(allExpenses);
          final filteredSales = _filterSales(allSales);

          final totalExpenses = filteredExpenses.fold(0.0, (sum, e) => sum + e.amount);
          final totalIncome = filteredSales.fold(0.0, (sum, s) => sum + s.totalSaleValue);
          final netBalance = totalIncome - totalExpenses;

          if (filteredExpenses.isEmpty && filteredSales.isEmpty && _filterType == 'All Time') {
            return _buildEmptyState(t);
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildFilterSection(t),
              ),
              SliverToBoxAdapter(
                child: GlobalListenButton(
                  storageService: widget.storageService,
                  textBuilder: () {
                    final String incStr = 'Total Income is ${totalIncome.toInt()} rupees. ';
                    final String expStr = 'Total Expenses are ${totalExpenses.toInt()} rupees. ';
                    final String balStr = 'Net Balance is ${netBalance.toInt()} rupees. ';
                    return incStr + expStr + balStr;
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: _buildOverallSummaryCards(totalIncome, totalExpenses, netBalance, t),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
                  child: Text(
                    t.translate('crop_summary') == 'crop_summary' ? 'Crop Summary' : t.translate('crop_summary'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
              ),
              _buildCropWiseSummary(filteredExpenses, filteredSales, t),
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 80, color: Colors.blue.shade200),
            const SizedBox(height: 24),
            Text(
              t.translate('no_financial_records_yet') == 'no_financial_records_yet' 
                ? 'No financial records yet' 
                : t.translate('no_financial_records_yet'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('add_income_expenses_prompt') == 'add_income_expenses_prompt' 
                ? 'Add your farm income and expenses to see your farm summary' 
                : t.translate('add_income_expenses_prompt'),
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddEditExpenseScreen(
                            profileStorageService: widget.profileStorageService,
                            storageService: widget.storageService,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.remove),
                    label: Text(t.translate('add_expense') == 'add_expense' ? 'Add Expense' : t.translate('add_expense')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AddEditSaleScreen(
                            profileStorageService: widget.profileStorageService,
                            storageService: widget.storageService,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: Text(t.translate('add_income') == 'add_income' ? 'Add Income' : t.translate('add_income')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterSection(AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.date_range, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterType,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem(value: 'All Time', child: Text(t.translate('all_time') == 'all_time' ? 'All Time' : t.translate('all_time'))),
                      DropdownMenuItem(value: 'This Month', child: Text(t.translate('this_month') == 'this_month' ? 'This Month' : t.translate('this_month'))),
                      DropdownMenuItem(value: 'Custom Date Range', child: Text(t.translate('custom_date_range') == 'custom_date_range' ? 'Custom Date Range' : t.translate('custom_date_range'))),
                    ],
                    onChanged: (val) async {
                      if (val == 'Custom Date Range') {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                          helpText: t.translate('select_date_range') == 'select_date_range' ? 'Select Date Range' : t.translate('select_date_range'),
                        );
                        if (picked != null) {
                          setState(() {
                            _filterType = val!;
                            _startDate = picked.start;
                            _endDate = picked.end;
                          });
                        }
                      } else {
                        setState(() {
                          _filterType = val!;
                          _startDate = null;
                          _endDate = null;
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          if (_filterType == 'Custom Date Range' && _startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${DateFormat('dd MMM yyyy').format(_startDate!)} - ${DateFormat('dd MMM yyyy').format(_endDate!)}',
                style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverallSummaryCards(double income, double expenses, double balance, AppLocalizations t) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildSummaryCard(
            title: t.translate('total_income') == 'total_income' ? 'Total Income' : t.translate('total_income'),
            amount: income,
            color: Colors.green,
            icon: Icons.arrow_downward,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            title: t.translate('total_expenses') == 'total_expenses' ? 'Total Expenses' : t.translate('total_expenses'),
            amount: expenses,
            color: Colors.orange,
            icon: Icons.arrow_upward,
          ),
          const SizedBox(height: 12),
          _buildSummaryCard(
            title: t.translate('net_balance') == 'net_balance' ? 'Net Balance' : t.translate('net_balance'),
            amount: balance,
            color: balance >= 0 ? Colors.blue : Colors.red,
            icon: Icons.account_balance,
            isBalance: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required MaterialColor color,
    required IconData icon,
    bool isBalance = false,
  }) {
    String formattedAmount = NumberFormat('#,##,###.##').format(amount.abs());
    String prefix = amount < 0 ? '-₹' : '₹';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color.shade700),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: color.shade800),
                ),
                const SizedBox(height: 4),
                Text(
                  '$prefix$formattedAmount',
                  style: TextStyle(
                    fontSize: isBalance ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: color.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropWiseSummary(List<FarmExpense> expenses, List<FarmSale> sales, AppLocalizations t) {
    // Group by cropId
    final Map<String?, double> cropExpenses = {};
    final Map<String?, double> cropIncome = {};
    
    for (var e in expenses) {
      cropExpenses[e.cropId] = (cropExpenses[e.cropId] ?? 0.0) + e.amount;
    }
    
    for (var s in sales) {
      cropIncome[s.cropId] = (cropIncome[s.cropId] ?? 0.0) + s.totalSaleValue;
    }
    
    final Set<String?> allCropIds = {...cropExpenses.keys, ...cropIncome.keys};
    final crops = widget.profileStorageService.getCrops();

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final cropId = allCropIds.elementAt(index);
          final e = cropExpenses[cropId] ?? 0.0;
          final i = cropIncome[cropId] ?? 0.0;
          final b = i - e;

          String cropName = t.translate('general_farm_expense') == 'general_farm_expense' ? 'General Farm Records' : t.translate('general_farm_expense');
          if (cropId != null) {
            try {
              cropName = crops.firstWhere((c) => c.id == cropId).cropName;
            } catch (_) {}
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(cropId == null ? '🚜 ' : '🌾 ', style: const TextStyle(fontSize: 18)),
                      Text(
                        cropName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.translate('sales') == 'sales' ? 'Income' : t.translate('sales'), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text('₹${NumberFormat('#,##,###.##').format(i)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.translate('total_expenses') == 'total_expenses' ? 'Expenses' : t.translate('total_expenses'), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text('₹${NumberFormat('#,##,###.##').format(e)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(t.translate('net_balance') == 'net_balance' ? 'Net Balance' : t.translate('net_balance'), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          Text(
                            '${b < 0 ? '-' : ''}₹${NumberFormat('#,##,###.##').format(b.abs())}', 
                            style: TextStyle(
                              color: b >= 0 ? Colors.blue.shade700 : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 16
                            )
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        childCount: allCropIds.length,
      ),
    );
  }

  List<FarmExpense> _filterExpenses(List<FarmExpense> expenses) {
    if (_filterType == 'All Time') return expenses;
    
    final now = DateTime.now();
    return expenses.where((e) {
      DateTime d;
      try { d = DateTime.parse(e.date); } catch (_) { return true; }
      
      if (_filterType == 'This Month') {
        return d.year == now.year && d.month == now.month;
      } else if (_filterType == 'Custom Date Range' && _startDate != null && _endDate != null) {
        return d.isAfter(_startDate!.subtract(const Duration(days: 1))) && 
               d.isBefore(_endDate!.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }

  List<FarmSale> _filterSales(List<FarmSale> sales) {
    if (_filterType == 'All Time') return sales;
    
    final now = DateTime.now();
    return sales.where((s) {
      DateTime d;
      try { d = DateTime.parse(s.saleDate); } catch (_) { return true; }
      
      if (_filterType == 'This Month') {
        return d.year == now.year && d.month == now.month;
      } else if (_filterType == 'Custom Date Range' && _startDate != null && _endDate != null) {
        return d.isAfter(_startDate!.subtract(const Duration(days: 1))) && 
               d.isBefore(_endDate!.add(const Duration(days: 1)));
      }
      return true;
    }).toList();
  }
}
