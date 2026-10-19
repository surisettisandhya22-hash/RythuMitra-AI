import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/storage_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../voice/services/text_to_speech_service.dart';
import 'package:mobile_app/features/khata/domain/models/khata_model.dart';
import 'package:mobile_app/features/khata/services/khata_service.dart';

class FarmerKhataScreen extends StatefulWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;

  const FarmerKhataScreen({
    super.key,
    required this.storageService,
    required this.profileStorageService,
  });

  @override
  State<FarmerKhataScreen> createState() => _FarmerKhataScreenState();
}

class _FarmerKhataScreenState extends State<FarmerKhataScreen> {
  final KhataService _khataService = KhataService();
  final TextToSpeechService _ttsService = TextToSpeechService();

  bool _isLoading = true;
  FarmKhataSummary? _summary;

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() => _isLoading = true);
    final summary = await _khataService.fetchSummary();
    if (mounted) {
      setState(() {
        _summary = summary;
        _isLoading = false;
      });
    }
  }

  void _speakFinancialHealth() {
    if (_summary == null) return;
    final speechText = 'Farm Ledger Report. Total seasonal income is ${_summary!.totalIncome.toInt()} rupees. Total expense is ${_summary!.totalExpense.toInt()} rupees. Your net ${_summary!.isProfit ? "profit" : "investment"} is ${_summary!.netProfitLoss.abs().toInt()} rupees.';
    final lang = widget.storageService.getSelectedLanguage() ?? 'en';
    _ttsService.speak(speechText, lang);
  }

  void _openAddTransactionDialog() {
    final descController = TextEditingController();
    final amountController = TextEditingController();
    String type = 'expense';
    String category = 'fertilizer';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Record Farm Transaction',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('🔴 Expense (ఖర్చు)')),
                          selected: type == 'expense',
                          selectedColor: Colors.red.shade100,
                          onSelected: (val) {
                            if (val) setModalState(() => type = 'expense');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text('🟢 Income (ఆదాయం)')),
                          selected: type == 'income',
                          selectedColor: Colors.green.shade100,
                          onSelected: (val) {
                            if (val) setModalState(() => type = 'income');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Amount (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: InputDecoration(
                      labelText: 'Description (e.g., 2 bags Urea, Tractor hire)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'seeds', child: Text('🌱 Seeds (విత్తనాలు)')),
                      DropdownMenuItem(value: 'fertilizer', child: Text('🧪 Fertilizer (ఎరువులు)')),
                      DropdownMenuItem(value: 'labor_coolie', child: Text('👥 Labor / Coolie (కూలీ)')),
                      DropdownMenuItem(value: 'machinery_diesel', child: Text('🚜 Tractor / Diesel (ట్రాక్టర్)')),
                      DropdownMenuItem(value: 'pesticides', child: Text('🛡️ Pesticides (పురుగు మందులు)')),
                      DropdownMenuItem(value: 'crop_sale', child: Text('💰 Crop Sale (పంట అమ్మకం)')),
                      DropdownMenuItem(value: 'subsidy', child: Text('🏛️ Government Subsidy (రాయితీ)')),
                      DropdownMenuItem(value: 'other', child: Text('📦 Other (ఇతరములు)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
                      if (amt <= 0) return;

                      final newItem = FarmTransactionItem(
                        id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                        type: type,
                        category: category,
                        amount: amt,
                        description: descController.text.trim().isEmpty ? 'Farm entry' : descController.text.trim(),
                        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
                        cropName: 'Active Farm',
                      );

                      Navigator.pop(context);
                      setState(() => _isLoading = true);
                      final updated = await _khataService.addTransaction(newItem);
                      setState(() {
                        _summary = updated;
                        _isLoading = false;
                      });
                    },
                    child: const Text('Save Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FBF8),
      appBar: AppBar(
        title: const Text('Farmer Digital Khata (ఖాతా)'),
        backgroundColor: Colors.teal.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: 'Read Balance',
            onPressed: _speakFinancialHealth,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSummary,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Entry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: _openAddTransactionDialog,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_summary != null) ...[
                    _buildProfitLossCard(_summary!),
                    const SizedBox(height: 16),
                    _buildQuickStatsRow(_summary!),
                    const SizedBox(height: 20),
                    _buildInsightsBanner(_summary!),
                    const SizedBox(height: 20),
                    _buildTransactionsList(_summary!),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildProfitLossCard(FarmKhataSummary summary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: summary.isProfit
              ? [Colors.teal.shade900, Colors.teal.shade700]
              : [Colors.deepOrange.shade900, Colors.deepOrange.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (summary.isProfit ? Colors.teal : Colors.deepOrange).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                summary.isProfit ? 'SEASONAL NET PROFIT' : 'NET FARM INVESTMENT',
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(summary.isProfit ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      summary.isProfit ? 'Profitable' : 'Expense Cycle',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${summary.netProfitLoss.abs().toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Income', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text('₹${summary.totalIncome.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Expenses', style: TextStyle(color: Colors.white60, fontSize: 11)),
                      const SizedBox(height: 2),
                      Text('₹${summary.totalExpense.toStringAsFixed(0)}', style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(FarmKhataSummary summary) {
    return Row(
      children: [
        _buildStatTile('Seeds & Plants', '₹${(summary.categoryBreakdown['seeds'] ?? 0).toStringAsFixed(0)}', Icons.eco, Colors.green),
        const SizedBox(width: 10),
        _buildStatTile('Fertilizers', '₹${(summary.categoryBreakdown['fertilizer'] ?? 0).toStringAsFixed(0)}', Icons.science, Colors.orange),
        const SizedBox(width: 10),
        _buildStatTile('Labor / Coolie', '₹${(summary.categoryBreakdown['labor_coolie'] ?? 0).toStringAsFixed(0)}', Icons.groups, Colors.blue),
      ],
    );
  }

  Widget _buildStatTile(String title, String val, IconData icon, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color.shade700, size: 20),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 10.5, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(val, style: TextStyle(color: color.shade900, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsBanner(FarmKhataSummary summary) {
    if (summary.insights.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates, color: Colors.blue.shade800, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Farm Financial Advisory', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900, fontSize: 13.5)),
                const SizedBox(height: 4),
                Text(summary.insights.first, style: TextStyle(color: Colors.blue.shade900, fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(FarmKhataSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            Text(
              '${summary.transactions.length} Entries',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...summary.transactions.map((tx) => _buildTransactionCard(tx)),
      ],
    );
  }

  Widget _buildTransactionCard(FarmTransactionItem tx) {
    final isExpense = tx.type == 'expense';

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: isExpense ? Colors.red.shade50 : Colors.green.shade50,
          child: Icon(
            isExpense ? Icons.arrow_outward : Icons.arrow_downward,
            color: isExpense ? Colors.red.shade700 : Colors.green.shade700,
          ),
        ),
        title: Text(
          tx.description,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          '${tx.cropName} • ${tx.date}',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Text(
          '${isExpense ? "-" : "+"}₹${tx.amount.toStringAsFixed(0)}',
          style: TextStyle(
            color: isExpense ? Colors.red.shade700 : Colors.green.shade700,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
