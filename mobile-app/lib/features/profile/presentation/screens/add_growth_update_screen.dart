import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/crop_growth_update.dart';

class AddGrowthUpdateScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final String cropId;
  final CropGrowthUpdate? existingUpdate;

  const AddGrowthUpdateScreen({
    super.key,
    required this.profileStorageService,
    required this.cropId,
    this.existingUpdate,
  });

  @override
  State<AddGrowthUpdateScreen> createState() => _AddGrowthUpdateScreenState();
}

class _AddGrowthUpdateScreenState extends State<AddGrowthUpdateScreen> {
  final _notesController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String? _selectedStage;
  
  bool _isEditing = false;
  
  final List<String> _stages = [
    'seed_sowing',
    'germination',
    'vegetative_growth',
    'flowering',
    'fruit_grain_development',
    'maturity',
    'harvest_ready',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.existingUpdate != null;
    
    if (_isEditing) {
      final u = widget.existingUpdate!;
      _selectedDate = u.date;
      _selectedStage = u.growthStage;
      _notesController.text = u.notes ?? '';
      
      if (!_stages.contains(_selectedStage)) {
        _stages.add(_selectedStage!);
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _save() async {
    final t = AppLocalizations.of(context);
    
    if (_selectedStage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.translate('growth_stage')} is required.')),
      );
      return;
    }

    final update = CropGrowthUpdate(
      id: _isEditing ? widget.existingUpdate!.id : DateTime.now().millisecondsSinceEpoch.toString(),
      cropId: widget.cropId,
      date: _selectedDate,
      growthStage: _selectedStage!,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    if (_isEditing) {
      await widget.profileStorageService.updateGrowthUpdate(update);
    } else {
      await widget.profileStorageService.addGrowthUpdate(update);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate(_isEditing ? 'edit' : 'add_growth_update')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Picker (Required)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${t.translate('date')} *', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365 * 2)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _selectedDate = date);
                }
              },
            ),
            const Divider(),
            const SizedBox(height: 16),
            
            // Growth Stage Selection
            Text('${t.translate('growth_stage')} *', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedStage,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _stages.map((stage) {
                return DropdownMenuItem<String>(
                  value: stage,
                  child: Text(t.translate(stage) == stage ? stage : t.translate(stage)),
                );
              }).toList(),
              onChanged: (val) {
                setState(() => _selectedStage = val);
              },
            ),
            const SizedBox(height: 24),
            
            // Notes
            Text(t.translate('notes'), style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(t.translate('save'), style: const TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
