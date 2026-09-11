import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/storage_service.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/farm_expense.dart';
import '../../../voice/services/speech_recognition_service.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final StorageService storageService;
  final FarmExpense? existingExpense;
  final String? initialCropId;

  const AddEditExpenseScreen({
    super.key,
    required this.profileStorageService,
    required this.storageService,
    this.existingExpense,
    this.initialCropId,
  });

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final SpeechRecognitionService _speechService = SpeechRecognitionService();
  
  String? _selectedType;
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCropId;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _notesController = TextEditingController();

  bool _isListening = false;

  final List<String> _expenseTypes = [
    'Seeds',
    'Fertilizer',
    'Pesticides',
    'Labour',
    'Irrigation',
    'Machinery',
    'Transport',
    'Electricity',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _speechService.initialize();

    if (widget.existingExpense != null) {
      final e = widget.existingExpense!;
      _selectedType = e.expenseType;
      _amountController.text = e.amount.toString();
      _selectedCropId = e.cropId;
      try {
        _selectedDate = DateTime.parse(e.date);
      } catch (_) {}
      _notesController.text = e.notes ?? '';
    } else {
      _selectedType = _expenseTypes.first;
      if (widget.initialCropId != null) {
        _selectedCropId = widget.initialCropId;
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _speechService.stopListening();
    super.dispose();
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

  void _saveExpense() {
    if (!_formKey.currentState!.validate()) return;

    final double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).translate('invalid_amount') == 'invalid_amount' 
              ? 'Invalid amount' 
              : AppLocalizations.of(context).translate('invalid_amount')
          ),
          backgroundColor: Colors.red,
        )
      );
      return;
    }

    final expense = FarmExpense(
      id: widget.existingExpense?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      expenseType: _selectedType!,
      amount: amount,
      cropId: _selectedCropId, // if null, it's general
      date: _selectedDate.toIso8601String(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    if (widget.existingExpense != null) {
      widget.profileStorageService.updateExpense(expense);
    } else {
      widget.profileStorageService.addExpense(expense);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isEditing = widget.existingExpense != null;
    
    final title = isEditing 
      ? (t.translate('edit_action') == 'edit_action' ? 'Edit Expense' : t.translate('edit_action'))
      : (t.translate('add_expense') == 'add_expense' ? 'Add Expense' : t.translate('add_expense'));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Expense Type
              Text(
                t.translate('expense_type') == 'expense_type' ? 'Expense Type' : t.translate('expense_type'),
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
                    value: _selectedType,
                    isExpanded: true,
                    items: _expenseTypes.map((type) {
                      String key = type.toLowerCase();
                      if (key == 'other') key = 'expense_other';
                      String label = t.translate(key) == key ? type : t.translate(key);
                      return DropdownMenuItem(
                        value: type,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedType = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Amount
              Text(
                t.translate('amount') == 'amount' ? 'Amount (₹)' : '${t.translate('amount')} (₹)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixText: '₹ ',
                  prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
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
              const SizedBox(height: 24),

              // Crop
              Text(
                t.translate('crop_title') == 'crop_title' ? 'Crop' : t.translate('crop_title'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder(
                valueListenable: widget.profileStorageService.cropsNotifier,
                builder: (context, crops, _) {
                  List<DropdownMenuItem<String?>> items = [
                    DropdownMenuItem(
                      value: null, // null means general farm expense
                      child: Text(t.translate('general_farm_expense') == 'general_farm_expense' ? 'General Farm Expense' : t.translate('general_farm_expense')),
                    )
                  ];
                  
                  items.addAll(crops.map((c) => DropdownMenuItem<String?>(
                    value: c.id,
                    child: Text('🌱 ${c.cropName}'),
                  )));

                  // Validate if selected crop still exists
                  if (_selectedCropId != null && !crops.any((c) => c.id == _selectedCropId)) {
                     _selectedCropId = null; 
                  }

                  return InputDecorator(
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedCropId,
                        isExpanded: true,
                        items: items,
                        onChanged: (val) {
                          setState(() => _selectedCropId = val);
                        },
                      ),
                    ),
                  );
                }
              ),
              const SizedBox(height: 24),

              // Date
              Text(
                t.translate('date') == 'date' ? 'Date' : t.translate('date'),
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
                      const Icon(Icons.calendar_today, color: Colors.orange),
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
                          backgroundColor: _isListening ? Colors.red : Colors.orange.shade100,
                          child: Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color: _isListening ? Colors.white : Colors.orange.shade700,
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
                onPressed: _saveExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
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
}
