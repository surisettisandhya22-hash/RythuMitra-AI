import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/storage_service.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/farm_expense.dart';
import 'add_edit_expense_screen.dart';
import '../../../../features/voice/presentation/widgets/global_listen_button.dart';

class FarmExpensesScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final StorageService storageService;

  const FarmExpensesScreen({
    super.key,
    required this.profileStorageService,
    required this.storageService,
  });

  @override
  State<FarmExpensesScreen> createState() => _FarmExpensesScreenState();
}

class _FarmExpensesScreenState extends State<FarmExpensesScreen> {
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(t.translate('farm_expenses') == 'farm_expenses' ? 'Farm Expenses' : t.translate('farm_expenses')),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<FarmExpense>>(
        valueListenable: widget.profileStorageService.expensesNotifier,
        builder: (context, expenses, _) {
          final sortedExpenses = List<FarmExpense>.from(expenses)
            ..sort((a, b) => b.date.compareTo(a.date));
          
          List<FarmExpense> filteredExpenses = sortedExpenses;
          if (_filterType != 'all') {
            filteredExpenses = sortedExpenses.where((e) => e.expenseType.toLowerCase() == _filterType.toLowerCase()).toList();
          }

          final total = expenses.fold(0.0, (sum, e) => sum + e.amount);

          return Column(
            children: [
              // Total Expenses Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      t.translate('total_expenses') == 'total_expenses' ? 'Total Expenses' : t.translate('total_expenses'),
                      style: TextStyle(color: Colors.orange.shade100, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${NumberFormat('#,##,###.##').format(total)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Listen Page Button
              GlobalListenButton(
                storageService: widget.storageService,
                textBuilder: () {
                  final String expensesSummary = 'Your total expenses are ${total.toInt()} rupees. ';
                  final String recordsSummary = filteredExpenses.isNotEmpty 
                      ? 'You have ${filteredExpenses.length} expense records.' 
                      : 'No expenses have been recorded yet.';
                  
                  return expensesSummary + recordsSummary;
                },
              ),

              // Filter
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterType,
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(value: 'all', child: Text(t.translate('all') == 'all' ? 'All' : t.translate('all'))),
                            DropdownMenuItem(value: 'Seeds', child: Text(t.translate('seeds'))),
                            DropdownMenuItem(value: 'Fertilizer', child: Text(t.translate('fertilizer'))),
                            DropdownMenuItem(value: 'Pesticides', child: Text(t.translate('pesticides'))),
                            DropdownMenuItem(value: 'Labour', child: Text(t.translate('labour'))),
                            DropdownMenuItem(value: 'Irrigation', child: Text(t.translate('irrigation'))),
                            DropdownMenuItem(value: 'Machinery', child: Text(t.translate('machinery'))),
                            DropdownMenuItem(value: 'Transport', child: Text(t.translate('transport'))),
                            DropdownMenuItem(value: 'Electricity', child: Text(t.translate('electricity'))),
                            DropdownMenuItem(value: 'Other', child: Text(t.translate('expense_other') == 'expense_other' ? 'Other' : t.translate('expense_other'))),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _filterType = val!;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Expense List
              Expanded(
                child: filteredExpenses.isEmpty
                    ? _buildEmptyState(t)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = filteredExpenses[index];
                          return _buildExpenseCard(context, expense, t);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
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
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(t.translate('add_expense') == 'add_expense' ? 'Add Expense' : t.translate('add_expense')),
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
            Icon(Icons.receipt_long, size: 80, color: Colors.orange.shade200),
            const SizedBox(height: 24),
            Text(
              t.translate('no_expenses_recorded_yet') == 'no_expenses_recorded_yet' 
                ? 'No expenses recorded yet' 
                : t.translate('no_expenses_recorded_yet'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('add_your_farm_expenses') == 'add_your_farm_expenses' 
                ? 'Add your farm expenses to keep track of your spending.' 
                : t.translate('add_your_farm_expenses'),
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(BuildContext context, FarmExpense expense, AppLocalizations t) {
    final dateFormat = DateFormat('dd MMM yyyy');
    DateTime date;
    try {
      date = DateTime.parse(expense.date);
    } catch (_) {
      date = DateTime.now();
    }

    String cropName = t.translate('general_farm_expense') == 'general_farm_expense' ? 'General Farm Expense' : t.translate('general_farm_expense');
    if (expense.cropId != null) {
      final crops = widget.profileStorageService.getCrops();
      try {
        cropName = crops.firstWhere((c) => c.id == expense.cropId).cropName;
      } catch (_) {}
    }

    String typeKey = expense.expenseType.toLowerCase();
    if (typeKey == 'other') typeKey = 'expense_other';
    String translatedType = t.translate(typeKey) == typeKey ? expense.expenseType : t.translate(typeKey);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Open edit screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddEditExpenseScreen(
                profileStorageService: widget.profileStorageService,
                storageService: widget.storageService,
                existingExpense: expense,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        dateFormat.format(date),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddEditExpenseScreen(
                                profileStorageService: widget.profileStorageService,
                                storageService: widget.storageService,
                                existingExpense: expense,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _confirmDelete(context, expense.id, t),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          translatedType,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text('🌱 ', style: TextStyle(fontSize: 12)),
                            Text(
                              cropName,
                              style: TextStyle(color: Colors.green.shade800, fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₹${NumberFormat('#,##,###.##').format(expense.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ],
              ),
              if (expense.notes != null && expense.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    expense.notes!,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, AppLocalizations t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.translate('delete_action') == 'delete_action' ? 'Delete' : t.translate('delete_action')),
        content: Text(
          t.translate('delete_expense_confirm') == 'delete_expense_confirm'
            ? 'Do you want to delete this expense?'
            : t.translate('delete_expense_confirm')
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.translate('cancel_action') == 'cancel_action' ? 'Cancel' : t.translate('cancel_action')),
          ),
          ElevatedButton(
            onPressed: () {
              widget.profileStorageService.deleteExpense(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              t.translate('delete_action') == 'delete_action' ? 'Delete' : t.translate('delete_action'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
