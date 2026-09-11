import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/storage_service.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/farm_sale.dart';
import '../../../voice/services/speech_recognition_service.dart';

class AddEditSaleScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final StorageService storageService;
  final FarmSale? existingSale;
  final String? initialCropId;

  const AddEditSaleScreen({
    super.key,
    required this.profileStorageService,
    required this.storageService,
    this.existingSale,
    this.initialCropId,
  });

  @override
  State<AddEditSaleScreen> createState() => _AddEditSaleScreenState();
}

class _AddEditSaleScreenState extends State<AddEditSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  
  String? _selectedCropId;
  final TextEditingController _quantityController = TextEditingController();
  String _selectedQuantityUnit = 'Kg';
  
  final TextEditingController _priceController = TextEditingController();
  String _selectedPriceUnit = '₹ / Kg';
  
  final TextEditingController _totalController = TextEditingController();
  final TextEditingController _buyerController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  bool _isListening = false;
  
  final List<String> _quantityUnits = ['Kg', 'Quintal', 'Ton', 'Other'];
  final List<String> _priceUnits = ['₹ / Kg', '₹ / Quintal', '₹ / Ton', 'Other'];

  @override
  void initState() {
    super.initState();
    _speechService.initialize();

    if (widget.existingSale != null) {
      final s = widget.existingSale!;
      _selectedCropId = s.cropId;
      _quantityController.text = s.quantity.toString();
      _selectedQuantityUnit = _quantityUnits.contains(s.quantityUnit) ? s.quantityUnit : 'Other';
      _priceController.text = s.sellingPrice.toString();
      _selectedPriceUnit = _priceUnits.contains(s.priceUnit) ? s.priceUnit : 'Other';
      _totalController.text = s.totalSaleValue.toString();
      _buyerController.text = s.buyer ?? '';
      _notesController.text = s.notes ?? '';
      try {
        _selectedDate = DateTime.parse(s.saleDate);
      } catch (_) {}
    } else if (widget.initialCropId != null) {
      _selectedCropId = widget.initialCropId;
    }

    _quantityController.addListener(_calculateTotal);
    _priceController.addListener(_calculateTotal);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _totalController.dispose();
    _buyerController.dispose();
    _notesController.dispose();
    _speechService.stopListening();
    super.dispose();
  }

  void _calculateTotal() {
    // If the units don't align perfectly, do not autocalculate.
    final qUnit = _selectedQuantityUnit.toLowerCase();
    final pUnit = _selectedPriceUnit.toLowerCase();
    
    bool compatible = false;
    if (qUnit == 'kg' && pUnit == '₹ / kg') compatible = true;
    if (qUnit == 'quintal' && pUnit == '₹ / quintal') compatible = true;
    if (qUnit == 'ton' && pUnit == '₹ / ton') compatible = true;

    if (compatible) {
      final q = double.tryParse(_quantityController.text);
      final p = double.tryParse(_priceController.text);
      if (q != null && p != null) {
        _totalController.text = (q * p).toStringAsFixed(2);
      } else {
        _totalController.text = '';
      }
    }
    // if not compatible, we leave it alone so the user can type it manually.
  }

  void _onQuantityUnitChanged(String? val) {
    if (val != null) {
      setState(() => _selectedQuantityUnit = val);
      _calculateTotal();
    }
  }

  void _onPriceUnitChanged(String? val) {
    if (val != null) {
      setState(() => _selectedPriceUnit = val);
      _calculateTotal();
    }
  }

  void _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
    } else {
      final languageId = widget.storageService.getSelectedLanguage() ?? 'en';
      setState(() => _isListening = true);
      
      final started = await _speechService.startListening(
        languageId: languageId,
        onResult: (text) {
          setState(() {
            _notesController.text = text;
          });
        },
      );
      
      if (!started) {
        setState(() => _isListening = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveSale() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCropId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a crop')),
      );
      return;
    }

    final double? quantity = double.tryParse(_quantityController.text);
    final double? price = double.tryParse(_priceController.text);
    final double? total = double.tryParse(_totalController.text);

    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid quantity')),
      );
      return;
    }
    
    if (price == null || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid price')),
      );
      return;
    }

    if (total == null || total < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid total sale value')),
      );
      return;
    }

    final sale = FarmSale(
      id: widget.existingSale?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      cropId: _selectedCropId!,
      quantity: quantity,
      quantityUnit: _selectedQuantityUnit,
      sellingPrice: price,
      priceUnit: _selectedPriceUnit,
      totalSaleValue: total,
      buyer: _buyerController.text.trim().isEmpty ? null : _buyerController.text.trim(),
      saleDate: _selectedDate.toIso8601String(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (widget.existingSale != null) {
      widget.profileStorageService.updateSale(sale);
    } else {
      widget.profileStorageService.addSale(sale);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isEditing = widget.existingSale != null;
    
    final title = isEditing 
      ? (t.translate('edit_action') == 'edit_action' ? 'Edit Sale' : t.translate('edit_action'))
      : (t.translate('add_sale') == 'add_sale' ? 'Add Sale' : t.translate('add_sale'));

    final crops = widget.profileStorageService.getCrops();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: crops.isEmpty 
        ? _buildNoCropsState(t) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Crop
                  Text(
                    t.translate('crop_title') == 'crop_title' ? 'Crop' : t.translate('crop_title'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCropId,
                        isExpanded: true,
                        hint: Text('Select Crop'),
                        items: crops.map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Text('🌱 ${c.cropName}'),
                        )).toList(),
                        onChanged: (val) {
                          setState(() => _selectedCropId = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quantity
                  Text(
                    t.translate('quantity') == 'quantity' ? 'Quantity' : t.translate('quantity'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            final num = double.tryParse(val);
                            if (num == null || num <= 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedQuantityUnit,
                              isExpanded: true,
                              items: _quantityUnits.map((u) {
                                String key = u.toLowerCase();
                                if (key == 'other') key = 'expense_other';
                                String label = t.translate(key) == key ? u : t.translate(key);
                                return DropdownMenuItem(value: u, child: Text(label));
                              }).toList(),
                              onChanged: _onQuantityUnitChanged,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Selling Price
                  Text(
                    t.translate('selling_price') == 'selling_price' ? 'Selling Price' : t.translate('selling_price'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            prefixText: '₹ ',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Required';
                            final num = double.tryParse(val);
                            if (num == null || num < 0) return 'Invalid';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPriceUnit,
                              isExpanded: true,
                              items: _priceUnits.map((u) {
                                String key = u.toLowerCase() == '₹ / kg' ? 'rs_per_kg'
                                  : u.toLowerCase() == '₹ / quintal' ? 'rs_per_quintal'
                                  : u.toLowerCase() == '₹ / ton' ? 'rs_per_ton' : 'expense_other';
                                String label = t.translate(key) == key ? u : t.translate(key);
                                return DropdownMenuItem(value: u, child: Text(label));
                              }).toList(),
                              onChanged: _onPriceUnitChanged,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Total Sale Value
                  Text(
                    t.translate('total_sale_value') == 'total_sale_value' ? 'Total Sale Value' : t.translate('total_sale_value'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _totalController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      prefixStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Required';
                      final num = double.tryParse(val);
                      if (num == null || num < 0) return 'Invalid';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Buyer/Market
                  Text(
                    t.translate('buyer') == 'buyer' ? 'Buyer / Market Name' : '${t.translate('buyer')} / ${t.translate('market_name')}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _buyerController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Local Market, Suresh...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Date
                  Text(
                    t.translate('sale_date') == 'sale_date' ? 'Sale Date' : t.translate('sale_date'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat('dd MMM yyyy').format(_selectedDate),
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Icon(Icons.calendar_today, color: Colors.green),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Notes
                  Text(
                    t.translate('notes') == 'notes' ? 'Notes' : t.translate('notes'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _notesController,
                            maxLines: 4,
                            minLines: 2,
                            decoration: const InputDecoration(
                              hintText: 'Optional details...',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: GestureDetector(
                            onTap: _toggleListening,
                            child: CircleAvatar(
                              backgroundColor: _isListening ? Colors.red : Colors.green.shade100,
                              child: Icon(
                                _isListening ? Icons.stop : Icons.mic,
                                color: _isListening ? Colors.white : Colors.green.shade700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 48),

                  // Save Button
                  ElevatedButton(
                    onPressed: _saveSale,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      t.translate('save_action') == 'save_action' ? 'Save' : t.translate('save_action'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildNoCropsState(AppLocalizations t) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.grass, size: 80, color: Colors.green.shade200),
            const SizedBox(height: 24),
            Text(
              t.translate('no_crops_added_yet') == 'no_crops_added_yet' 
                ? 'No crops added yet' 
                : t.translate('no_crops_added_yet'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
              child: const Text('Go Back', style: TextStyle(color: Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}
