import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/emergency_storage_service.dart';
import '../../data/models/emergency_contact.dart';

class AddEditContactScreen extends StatefulWidget {
  final EmergencyStorageService emergencyStorageService;
  final EmergencyContact? contactToEdit;

  const AddEditContactScreen({
    super.key,
    required this.emergencyStorageService,
    this.contactToEdit,
  });

  @override
  State<AddEditContactScreen> createState() => _AddEditContactScreenState();
}

class _AddEditContactScreenState extends State<AddEditContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCategory = 'Other';
  bool _isQuickAccess = false;

  final List<String> _categories = [
    'Agriculture Officer',
    'Veterinary Help',
    'Family',
    'Friend',
    'Medical Help',
    'Emergency',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.contactToEdit != null) {
      final contact = widget.contactToEdit!;
      _nameController.text = contact.name;
      _phoneController.text = contact.phoneNumber;
      _notesController.text = contact.notes ?? '';
      _isQuickAccess = contact.isQuickAccess;
      
      if (_categories.contains(contact.category)) {
        _selectedCategory = contact.category;
      } else {
        _selectedCategory = 'Other';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _getLocalizedCategory(String category, AppLocalizations localizations) {
    final Map<String, String> categoryToKey = {
      'Agriculture Officer': 'cat_agriculture_officer',
      'Veterinary Help': 'cat_veterinary_help',
      'Family': 'cat_family',
      'Friend': 'cat_friend',
      'Medical Help': 'cat_medical_help',
      'Emergency': 'cat_emergency',
      'Other': 'cat_other',
    };
    final key = categoryToKey[category] ?? category;
    try {
      final translated = localizations.translate(key);
      if (translated != key && translated.isNotEmpty) {
        return translated;
      }
    } catch (_) {}
    return category;
  }

  Future<void> _saveContact() async {
    if (_formKey.currentState!.validate()) {
      final contact = EmergencyContact(
        id: widget.contactToEdit?.id ?? DateTime.now().toIso8601String(),
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        category: _selectedCategory,
        notes: _notesController.text.trim(),
        isQuickAccess: _isQuickAccess,
      );

      bool success;
      if (widget.contactToEdit != null) {
        success = await widget.emergencyStorageService.updateContact(contact);
      } else {
        success = await widget.emergencyStorageService.addContact(contact);
      }

      if (success && mounted) {
        Navigator.of(context).pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save contact.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isEditing = widget.contactToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate(isEditing ? 'edit_btn' : 'add_contact')),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: localizations.translate('contact_name'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name.'; // simplified fallback, in a real app this might be localized
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: localizations.translate('phone_number'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a valid phone number.';
                    }
                    final phoneRegex = RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]*$');
                    if (!phoneRegex.hasMatch(value)) {
                      return 'Invalid characters in phone number.';
                    }
                    if (value.replaceAll(RegExp(r'\D'), '').length < 3) {
                      return 'Phone number too short.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: localizations.translate('contact_category'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.category),
                  ),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(_getLocalizedCategory(category, localizations)),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    labelText: localizations.translate('contact_notes'),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.note),
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),

                CheckboxListTile(
                  title: Text(
                    localizations.translate('quick_access'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Show this contact at the top of the list.'),
                  value: _isQuickAccess,
                  activeColor: Colors.red.shade700,
                  onChanged: (bool? value) {
                    setState(() {
                      _isQuickAccess = value ?? false;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                
                const SizedBox(height: 32),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _saveContact,
                  child: Text(
                    localizations.translate(isEditing ? 'edit_btn' : 'add_contact'),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
