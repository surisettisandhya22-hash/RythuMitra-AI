import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/farm_profile.dart';

class EditFarmProfileScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final FarmProfile? currentProfile;

  const EditFarmProfileScreen({
    super.key, 
    required this.profileStorageService,
    this.currentProfile,
  });

  @override
  State<EditFarmProfileScreen> createState() => _EditFarmProfileScreenState();
}

class _EditFarmProfileScreenState extends State<EditFarmProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _farmNameController;
  late TextEditingController _landSizeController;
  
  String _selectedUnit = 'Acres';
  final List<String> _units = ['Acres', 'Hectares', 'Sq Meters'];
  
  final List<String> _availableFarmTypes = [
    'Crops', 'Vegetables', 'Fruits', 'Flowers', 'Livestock', 'Poultry', 'Aquaculture', 'Other'
  ];
  final List<String> _selectedFarmTypes = [];

  @override
  void initState() {
    super.initState();
    _farmNameController = TextEditingController(text: widget.currentProfile?.farmName ?? '');
    _landSizeController = TextEditingController(text: widget.currentProfile?.landSize.toString() ?? '');
    
    if (widget.currentProfile != null) {
      if (_units.contains(widget.currentProfile!.landUnit)) {
        _selectedUnit = widget.currentProfile!.landUnit;
      }
      _selectedFarmTypes.addAll(widget.currentProfile!.farmTypes);
    }
  }

  @override
  void dispose() {
    _farmNameController.dispose();
    _landSizeController.dispose();
    super.dispose();
  }

  void _toggleFarmType(String type) {
    setState(() {
      if (_selectedFarmTypes.contains(type)) {
        _selectedFarmTypes.remove(type);
      } else {
        _selectedFarmTypes.add(type);
      }
    });
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final double? size = double.tryParse(_landSizeController.text.trim());
      if (size == null) return; // Basic validation handles empty, this is a fallback

      final updatedProfile = FarmProfile(
        farmName: _farmNameController.text.trim(),
        landSize: size,
        landUnit: _selectedUnit,
        farmTypes: _selectedFarmTypes,
      );
      
      await widget.profileStorageService.saveFarmProfile(updatedProfile);
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).translate('farm_profile')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _farmNameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).translate('farm_name'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.landscape),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _landSizeController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).translate('land_size'),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.square_foot),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Invalid number';
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
              const SizedBox(height: 32),
              
              Text(
                AppLocalizations.of(context).translate('farm_type'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _availableFarmTypes.map((type) {
                  final isSelected = _selectedFarmTypes.contains(type);
                  return FilterChip(
                    label: Text(type),
                    selected: isSelected,
                    onSelected: (_) => _toggleFarmType(type),
                    selectedColor: Colors.green.shade100,
                    checkmarkColor: Colors.green.shade800,
                  );
                }).toList(),
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
