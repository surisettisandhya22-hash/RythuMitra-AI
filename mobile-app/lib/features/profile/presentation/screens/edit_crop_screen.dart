import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/crop_profile.dart';

class EditCropScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final CropProfile? currentCrop;

  const EditCropScreen({
    super.key, 
    required this.profileStorageService,
    this.currentCrop,
  });

  @override
  State<EditCropScreen> createState() => _EditCropScreenState();
}

class _EditCropScreenState extends State<EditCropScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _cropNameController;
  late TextEditingController _areaController;
  
  late TextEditingController _notesController;
  
  String _selectedUnit = 'Acres';
  final List<String> _units = ['Acres', 'Hectares', 'Sq Meters'];
  
  String? _selectedGrowthStage;
  final List<String> _growthStages = ['seedling', 'vegetative', 'flowering', 'fruiting', 'harvest_ready', 'not_sure'];
  
  String _selectedStatus = 'growing';
  final List<String> _statuses = ['growing', 'needs_attention', 'info_incomplete', 'harvested'];
  
  DateTime? _plantingDate;
  DateTime? _expectedHarvestDate;

  @override
  void initState() {
    super.initState();
    _cropNameController = TextEditingController(text: widget.currentCrop?.cropName ?? '');
    _areaController = TextEditingController(text: widget.currentCrop?.area?.toString() ?? '');
    _notesController = TextEditingController(text: widget.currentCrop?.notes ?? '');
    
    if (widget.currentCrop != null) {
      if (widget.currentCrop!.unit != null && _units.contains(widget.currentCrop!.unit)) {
        _selectedUnit = widget.currentCrop!.unit!;
      }
      if (widget.currentCrop!.growthStage != null && _growthStages.contains(widget.currentCrop!.growthStage)) {
        _selectedGrowthStage = widget.currentCrop!.growthStage!;
      }
      if (widget.currentCrop!.status != null && _statuses.contains(widget.currentCrop!.status)) {
        _selectedStatus = widget.currentCrop!.status!;
      }
      if (widget.currentCrop!.plantingDate != null) {
        _plantingDate = DateTime.tryParse(widget.currentCrop!.plantingDate!);
      }
      if (widget.currentCrop!.expectedHarvestDate != null) {
        _expectedHarvestDate = DateTime.tryParse(widget.currentCrop!.expectedHarvestDate!);
      }
    }
  }

  @override
  void dispose() {
    _cropNameController.dispose();
    _areaController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isPlantingDate) async {
    final initialDate = isPlantingDate ? (_plantingDate ?? DateTime.now()) : (_expectedHarvestDate ?? DateTime.now().add(const Duration(days: 30)));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isPlantingDate) {
          _plantingDate = picked;
        } else {
          _expectedHarvestDate = picked;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      double? area;
      if (_areaController.text.trim().isNotEmpty) {
        area = double.tryParse(_areaController.text.trim());
      }

      if (_expectedHarvestDate != null && _plantingDate != null) {
        if (_expectedHarvestDate!.isBefore(_plantingDate!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Expected Harvest Date cannot be before Planting Date')),
          );
          return;
        }
      }

      final isNew = widget.currentCrop == null;
      final cropId = isNew ? DateTime.now().millisecondsSinceEpoch.toString() : widget.currentCrop!.id;
      final createdAt = isNew ? DateTime.now().toIso8601String() : widget.currentCrop!.createdAt;

      final updatedCrop = CropProfile(
        id: cropId,
        cropName: _cropNameController.text.trim(),
        area: area,
        unit: _selectedUnit,
        growthStage: _selectedGrowthStage,
        status: _selectedStatus,
        plantingDate: _plantingDate?.toIso8601String(),
        expectedHarvestDate: _expectedHarvestDate?.toIso8601String(),
        notes: _notesController.text.trim(),
        createdAt: createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      if (isNew) {
        await widget.profileStorageService.addCrop(updatedCrop);
      } else {
        await widget.profileStorageService.updateCrop(updatedCrop);
      }
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).translate('delete')),
        content: const Text('Are you sure you want to remove this crop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).translate('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              AppLocalizations.of(context).translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.currentCrop != null) {
      await widget.profileStorageService.deleteCrop(widget.currentCrop!.id);
      if (mounted) {
        // Pop back twice to return to dashboard since we might be coming from details screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.currentCrop == null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isNew ? AppLocalizations.of(context).translate('add_crop') : AppLocalizations.of(context).translate('crop_name')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (!isNew)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _handleDelete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _cropNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('crop_name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.eco),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a crop name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _areaController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Area (Optional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.square_foot),
                      ),
                      validator: (value) {
                        if (value != null && value.trim().isNotEmpty) {
                          if (double.tryParse(value.trim()) == null) {
                            return 'Invalid number';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).translate('land_unit'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _units.map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedUnit = value;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).translate('planting_date'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(_plantingDate != null ? _formatDate(_plantingDate!) : 'Select Date'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context).translate('expected_harvest_date'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.event),
                        ),
                        child: Text(_expectedHarvestDate != null ? _formatDate(_expectedHarvestDate!) : 'Select Date'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              DropdownButtonFormField<String>(
                initialValue: _selectedGrowthStage,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('growth_stage'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.trending_up),
                ),
                items: _growthStages.map((stage) {
                  return DropdownMenuItem(
                    value: stage,
                    child: Text(AppLocalizations.of(context).translate(stage)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGrowthStage = value;
                  });
                },
              ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('status'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.info_outline),
                ),
                items: _statuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(AppLocalizations.of(context).translate(status)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('notes'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.note),
                ),
              ),

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppLocalizations.of(context).translate('save'),
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
