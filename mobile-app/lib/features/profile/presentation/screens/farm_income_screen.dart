import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/storage_service.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/farm_sale.dart';
import 'add_edit_sale_screen.dart';

class FarmIncomeScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final StorageService storageService;

  const FarmIncomeScreen({
    super.key,
    required this.profileStorageService,
    required this.storageService,
  });

  @override
  State<FarmIncomeScreen> createState() => _FarmIncomeScreenState();
}

class _FarmIncomeScreenState extends State<FarmIncomeScreen> {
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(t.translate('farm_income') == 'farm_income' ? 'Farm Income' : t.translate('farm_income')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<FarmSale>>(
        valueListenable: widget.profileStorageService.salesNotifier,
        builder: (context, sales, _) {
          final sortedSales = List<FarmSale>.from(sales)
            ..sort((a, b) => b.saleDate.compareTo(a.saleDate));
          
          final total = sales.fold(0.0, (sum, s) => sum + s.totalSaleValue);

          return Column(
            children: [
              // Total Income Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.green.shade700,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      t.translate('total_income') == 'total_income' ? 'Total Income' : t.translate('total_income'),
                      style: TextStyle(color: Colors.green.shade100, fontSize: 16),
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
              
              const SizedBox(height: 8),

              // Sales List
              Expanded(
                child: sortedSales.isEmpty
                    ? _buildEmptyState(t)
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: sortedSales.length,
                        itemBuilder: (context, index) {
                          final sale = sortedSales[index];
                          return _buildSaleCard(context, sale, t);
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
              builder: (_) => AddEditSaleScreen(
                profileStorageService: widget.profileStorageService,
                storageService: widget.storageService,
              ),
            ),
          );
        },
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(t.translate('add_sale') == 'add_sale' ? 'Add Sale' : t.translate('add_sale')),
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
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.green.shade200),
            const SizedBox(height: 24),
            Text(
              t.translate('no_sales_recorded_yet') == 'no_sales_recorded_yet' 
                ? 'No sales recorded yet' 
                : t.translate('no_sales_recorded_yet'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              t.translate('record_your_crop_sales') == 'record_your_crop_sales' 
                ? 'Record your crop sales to keep track of your farm income.' 
                : t.translate('record_your_crop_sales'),
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleCard(BuildContext context, FarmSale sale, AppLocalizations t) {
    final dateFormat = DateFormat('dd MMM yyyy');
    DateTime date;
    try {
      date = DateTime.parse(sale.saleDate);
    } catch (_) {
      date = DateTime.now();
    }

    String cropName = 'Crop';
    final crops = widget.profileStorageService.getCrops();
    try {
      cropName = crops.firstWhere((c) => c.id == sale.cropId).cropName;
    } catch (_) {}

    String quantityUnitKey = sale.quantityUnit.toLowerCase();
    String priceUnitKey = sale.priceUnit.toLowerCase() == '₹ / kg' ? 'rs_per_kg'
                          : sale.priceUnit.toLowerCase() == '₹ / quintal' ? 'rs_per_quintal'
                          : sale.priceUnit.toLowerCase() == '₹ / ton' ? 'rs_per_ton' : 'expense_other';
                          
    String qUnit = t.translate(quantityUnitKey) == quantityUnitKey ? sale.quantityUnit : t.translate(quantityUnitKey);
    String pUnit = t.translate(priceUnitKey) == priceUnitKey ? sale.priceUnit : t.translate(priceUnitKey);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Open edit screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddEditSaleScreen(
                profileStorageService: widget.profileStorageService,
                storageService: widget.storageService,
                existingSale: sale,
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
                              builder: (_) => AddEditSaleScreen(
                                profileStorageService: widget.profileStorageService,
                                storageService: widget.storageService,
                                existingSale: sale,
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(4),
                        icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                        onPressed: () => _confirmDelete(context, sale.id, t),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('🌾 ', style: TextStyle(fontSize: 20)),
                  Text(
                    cropName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                      Text(
                        t.translate('quantity') == 'quantity' ? 'Quantity' : t.translate('quantity'),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      Text(
                        '${NumberFormat('#,##,###.##').format(sale.quantity)} $qUnit',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.translate('selling_price') == 'selling_price' ? 'Selling Price' : t.translate('selling_price'),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      Text(
                        '₹${NumberFormat('#,##,###.##').format(sale.sellingPrice)} / $pUnit'.replaceAll(' / ₹ /', ' / '),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (sale.buyer != null && sale.buyer!.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.storefront, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          sale.buyer!,
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        t.translate('total_sale_value') == 'total_sale_value' ? 'Total' : t.translate('total_sale_value'),
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                      Text(
                        '₹${NumberFormat('#,##,###.##').format(sale.totalSaleValue)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (sale.notes != null && sale.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sale.notes!,
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
          t.translate('delete_sale_confirm') == 'delete_sale_confirm'
            ? 'Do you want to delete this sale?'
            : t.translate('delete_sale_confirm')
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.translate('cancel_action') == 'cancel_action' ? 'Cancel' : t.translate('cancel_action')),
          ),
          ElevatedButton(
            onPressed: () {
              widget.profileStorageService.deleteSale(id);
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
