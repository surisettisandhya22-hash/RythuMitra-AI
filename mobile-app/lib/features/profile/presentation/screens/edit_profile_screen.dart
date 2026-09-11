import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/farmer_profile.dart';
import '../../data/models/farm_profile.dart';
import '../../data/models/crop_profile.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final FarmerProfile? currentFarmerProfile;
  final FarmProfile? currentFarmProfile;

  const EditProfileScreen({
    super.key,
    required this.profileStorageService,
    this.currentFarmerProfile,
    this.currentFarmProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Farmer fields
  late TextEditingController _nameController;
  late TextEditingController _villageController;
  late TextEditingController _districtController;
  late TextEditingController _stateController;
  double? _latitude;
  double? _longitude;

  bool _isFetchingLocation = false;

  // Farm fields
  late TextEditingController _farmSizeController;
  String _selectedUnit = 'acres'; // Default
  String? _selectedIrrigation;
  String? _selectedFarmingType;

  // Crops
  List<CropProfile> _crops = [];

  final List<String> _irrigationOptions = [
    'rainfed', 'borewell', 'canal', 'drip', 'sprinkler', 'other'
  ];
  
  final List<String> _farmingTypeOptions = [
    'organic', 'conventional', 'mixed', 'other'
  ];

  @override
  void initState() {
    super.initState();
    final fp = widget.currentFarmerProfile;
    _nameController = TextEditingController(text: fp?.name ?? '');
    _villageController = TextEditingController(text: fp?.village ?? '');
    _districtController = TextEditingController(text: fp?.district ?? '');
    _stateController = TextEditingController(text: fp?.state ?? '');
    _latitude = fp?.latitude;
    _longitude = fp?.longitude;

    final farm = widget.currentFarmProfile;
    _farmSizeController = TextEditingController(
      text: farm?.landSize != null && farm!.landSize > 0 
          ? farm.landSize.toString().replaceAll(RegExp(r'\.0$'), '') 
          : '',
    );
    _selectedUnit = farm?.landUnit == 'hectares' ? 'hectares' : 'acres';
    
    if (farm?.irrigationType != null && farm!.irrigationType!.isNotEmpty) {
       _selectedIrrigation = farm.irrigationType;
    }
    
    if (farm?.farmTypes != null && farm!.farmTypes.isNotEmpty) {
      _selectedFarmingType = farm.farmTypes.first;
    }

    _crops = List.from(widget.profileStorageService.getCrops());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _villageController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    _farmSizeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final t = AppLocalizations.of(context);
    setState(() {
      _isFetchingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnackBar(t.translate('location_unavailable'));
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnackBar(t.translate('location_permission_denied'));
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        _showSnackBar(t.translate('location_permission_denied'));
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      List<Placemark> placemarks = await Geocoding().placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          if (place.locality != null && place.locality!.isNotEmpty) {
             _villageController.text = place.locality!;
          } else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
             _villageController.text = place.subLocality!;
          }
          if (place.subAdministrativeArea != null) _districtController.text = place.subAdministrativeArea!;
          if (place.administrativeArea != null) _stateController.text = place.administrativeArea!;
        });
      }
    } catch (e) {
      _showSnackBar(t.translate('location_unavailable'));
    } finally {
      setState(() {
        _isFetchingLocation = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCropDialog([CropProfile? crop]) {
    final t = AppLocalizations.of(context);
    final isEdit = crop != null;
    
    TextEditingController nameCtrl = TextEditingController(text: crop?.cropName ?? '');
    TextEditingController varietyCtrl = TextEditingController(text: crop?.variety ?? '');
    TextEditingController areaCtrl = TextEditingController(
      text: crop?.area != null ? crop?.area.toString().replaceAll(RegExp(r'\.0$'), '') : ''
    );
    String selectedUnit = crop?.unit ?? 'acres';
    DateTime? sowingDate = crop?.plantingDate != null ? DateTime.tryParse(crop!.plantingDate!) : null;
    DateTime? harvestDate = crop?.expectedHarvestDate != null ? DateTime.tryParse(crop!.expectedHarvestDate!) : null;

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(t.translate(isEdit ? 'edit_crop' : 'add_crop')),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(labelText: '${t.translate('crop_name')} *', border: const OutlineInputBorder()),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Please enter crop name.' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: varietyCtrl,
                        decoration: InputDecoration(labelText: t.translate('variety'), border: const OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: areaCtrl,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(labelText: t.translate('farm_area'), border: const OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              initialValue: selectedUnit,
                              decoration: const InputDecoration(border: OutlineInputBorder()),
                              items: ['acres', 'hectares'].map((u) => DropdownMenuItem(value: u, child: Text(t.translate(u)))).toList(),
                              onChanged: (v) => setDialogState(() => selectedUnit = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.translate('sowing_date')),
                        subtitle: Text(sowingDate != null ? "${sowingDate!.year}-${sowingDate!.month.toString().padLeft(2,'0')}-${sowingDate!.day.toString().padLeft(2,'0')}" : ""),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(context: context, initialDate: sowingDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (date != null) setDialogState(() => sowingDate = date);
                        },
                      ),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(t.translate('expected_harvest_date')),
                        subtitle: Text(harvestDate != null ? "${harvestDate!.year}-${harvestDate!.month.toString().padLeft(2,'0')}-${harvestDate!.day.toString().padLeft(2,'0')}" : ""),
                        trailing: const Icon(Icons.calendar_today),
                        onTap: () async {
                          final date = await showDatePicker(context: context, initialDate: harvestDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                          if (date != null) setDialogState(() => harvestDate = date);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      setState(() {
                        final updatedCrop = CropProfile(
                          id: isEdit ? crop.id : DateTime.now().millisecondsSinceEpoch.toString(),
                          cropName: nameCtrl.text.trim(),
                          variety: varietyCtrl.text.trim().isNotEmpty ? varietyCtrl.text.trim() : null,
                          area: double.tryParse(areaCtrl.text.trim()),
                          unit: selectedUnit,
                          plantingDate: sowingDate?.toIso8601String(),
                          expectedHarvestDate: harvestDate?.toIso8601String(),
                        );
                        
                        if (isEdit) {
                          final index = _crops.indexWhere((c) => c.id == crop.id);
                          if (index != -1) _crops[index] = updatedCrop;
                        } else {
                          _crops.add(updatedCrop);
                        }
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: Text(t.translate('save')),
                )
              ],
            );
          }
        );
      },
    );
  }

  void _confirmRemoveCrop(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(AppLocalizations.of(context).translate('remove_crop_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                _removeCrop(id);
                Navigator.pop(context);
              },
              child: Text(AppLocalizations.of(context).translate('remove'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _removeCrop(String id) {
    setState(() {
      _crops.removeWhere((c) => c.id == id);
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final String village = _villageController.text.trim();
      final String district = _districtController.text.trim();
      final String state = _stateController.text.trim();
      
      // Location string for backward compatibility
      final String location = '$village, $district, $state';
      
      final farmerProfile = FarmerProfile(
        name: _nameController.text.trim(),
        location: location,
        village: village,
        district: district,
        state: state,
        preferredLanguage: widget.currentFarmerProfile?.preferredLanguage ?? 'en',
        latitude: _latitude,
        longitude: _longitude,
      );

      final double size = double.tryParse(_farmSizeController.text.trim()) ?? 0.0;
      final farmProfile = FarmProfile(
        landSize: size,
        landUnit: _selectedUnit,
        farmTypes: _selectedFarmingType != null ? [_selectedFarmingType!] : [],
        irrigationType: _selectedIrrigation,
      );

      await widget.profileStorageService.saveFarmerProfile(farmerProfile);
      await widget.profileStorageService.saveFarmProfile(farmProfile);
      await widget.profileStorageService.saveCrops(_crops);

      if (mounted) {
        Navigator.pop(context);
        _showSnackBar(AppLocalizations.of(context).translate('location_saved'));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(t.translate('edit_profile')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(t.translate('farmer_profile')),
                _buildTextField(_nameController, t.translate('farmer_name'), Icons.person, true, t),
                const SizedBox(height: 12),
                
                // Use Current Location Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: OutlinedButton.icon(
                    onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                    icon: _isFetchingLocation 
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location),
                    label: Text(t.translate('use_current_location')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                
                _buildTextField(_villageController, t.translate('village'), Icons.home, true, t),
                const SizedBox(height: 12),
                _buildTextField(_districtController, t.translate('district'), Icons.map, true, t),
                const SizedBox(height: 12),
                _buildTextField(_stateController, t.translate('state'), Icons.location_city, true, t),
                
                const SizedBox(height: 24),
                _buildSectionTitle(t.translate('farm_profile')),
                
                // Farm Size
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _farmSizeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: t.translate('land_size'),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          prefixIcon: const Icon(Icons.straighten),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: ['acres', 'hectares'].map((u) {
                          return DropdownMenuItem(
                            value: u,
                            child: Text(t.translate(u)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedUnit = val!);
                        },
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
                
                // Irrigation Type
                DropdownButtonFormField<String>(
                  initialValue: _selectedIrrigation,
                  decoration: InputDecoration(
                    labelText: t.translate('irrigation_type'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.water_drop),
                  ),
                  items: _irrigationOptions.map((opt) {
                    return DropdownMenuItem(
                      value: opt,
                      child: Text(t.translate(opt)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedIrrigation = val);
                  },
                ),
                const SizedBox(height: 16),
                
                // Farming Type
                DropdownButtonFormField<String>(
                  initialValue: _selectedFarmingType,
                  decoration: InputDecoration(
                    labelText: t.translate('farming_type'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.grass),
                  ),
                  items: _farmingTypeOptions.map((opt) {
                    return DropdownMenuItem(
                      value: opt,
                      child: Text(t.translate(opt)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedFarmingType = val);
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Crops section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle(t.translate('my_crops')),
                    TextButton.icon(
                      onPressed: () => _showCropDialog(),
                      icon: const Icon(Icons.add),
                      label: Text(t.translate('add_crop')),
                    ),
                  ],
                ),
                
                if (_crops.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text(t.translate('no_crops_added_yet'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(t.translate('add_your_crops'), textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade700)),
                      ],
                    ),
                  )
                else
                  Column(
                    children: _crops.map((c) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('🌱 ${c.cropName}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    if (c.variety != null && c.variety!.isNotEmpty) 
                                      Text('${t.translate('variety')}: ${c.variety}', style: TextStyle(color: Colors.grey.shade700)),
                                    if (c.plantingDate != null)
                                      Text('${t.translate('sowing_date')}: ${DateTime.parse(c.plantingDate!).toLocal().toString().split(' ')[0]}', style: TextStyle(color: Colors.grey.shade700)),
                                    if (c.area != null && c.area! > 0)
                                      Text('${t.translate('farm_area')}: ${c.area.toString().replaceAll(RegExp(r'\.0\$'), '')} ${t.translate(c.unit ?? 'acres')}', style: TextStyle(color: Colors.grey.shade700)),
                                  ],
                                ),
                              ),
                              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showCropDialog(c)),
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmRemoveCrop(c.id)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                const SizedBox(height: 40),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(t.translate('cancel'), style: const TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(t.translate('save'), style: const TextStyle(fontSize: 16, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade900),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, bool required, AppLocalizations t) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label + (required ? ' *' : ''),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon),
      ),
      validator: required ? (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter $label';
        }
        return null;
      } : null,
    );
  }
}
