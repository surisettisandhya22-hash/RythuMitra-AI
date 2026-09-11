import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../voice/services/text_to_speech_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../services/emergency_storage_service.dart';
import '../../data/models/emergency_contact.dart';
import 'add_edit_contact_screen.dart';

class EmergencyHelpScreen extends StatefulWidget {
  final EmergencyStorageService emergencyStorageService;
  final ProfileStorageService profileStorageService;

  const EmergencyHelpScreen({
    super.key,
    required this.emergencyStorageService,
    required this.profileStorageService,
  });

  @override
  State<EmergencyHelpScreen> createState() => _EmergencyHelpScreenState();
}

class _EmergencyHelpScreenState extends State<EmergencyHelpScreen> {
  final TextToSpeechService _ttsService = TextToSpeechService();
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _ttsService.init();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });
    
    final contacts = await widget.emergencyStorageService.getContacts();
    
    // Sort: Quick Access first
    contacts.sort((a, b) {
      if (a.isQuickAccess && !b.isQuickAccess) return -1;
      if (!a.isQuickAccess && b.isQuickAccess) return 1;
      return a.name.compareTo(b.name);
    });

    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Dialer unavailable for $phoneNumber')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open dialer.')),
        );
      }
    }
  }

  Future<void> _deleteContact(EmergencyContact contact) async {
    final localizations = AppLocalizations.of(context);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.translate('delete_btn')),
        content: Text(localizations.translate('delete_contact_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(localizations.translate('cancel_btn')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(localizations.translate('delete_btn')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await widget.emergencyStorageService.deleteContact(contact.id);
      _loadContacts();
    }
  }

  void _speakContact(EmergencyContact contact) async {
    final prefs = widget.profileStorageService.getFarmerProfile();
    final langId = prefs?.preferredLanguage ?? 'en';
    final String text = '${contact.name}. ${contact.phoneNumber}.';
    await _ttsService.speak(text, langId);
  }

  Widget _getCategoryIcon(String category) {
    switch (category) {
      case 'Agriculture Officer':
      case 'cat_agriculture_officer':
        return const Icon(Icons.agriculture, color: Colors.green);
      case 'Veterinary Help':
      case 'cat_veterinary_help':
        return const Icon(Icons.pets, color: Colors.brown);
      case 'Family':
      case 'cat_family':
        return const Icon(Icons.family_restroom, color: Colors.orange);
      case 'Friend':
      case 'cat_friend':
        return const Icon(Icons.group, color: Colors.blue);
      case 'Medical Help':
      case 'cat_medical_help':
        return const Icon(Icons.local_hospital, color: Colors.red);
      case 'Emergency':
      case 'cat_emergency':
        return const Icon(Icons.warning, color: Colors.redAccent);
      default:
        return const Icon(Icons.person, color: Colors.grey);
    }
  }

  String _getLocalizedCategory(String category) {
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
      final translated = AppLocalizations.of(context).translate(key);
      if (translated != key && translated.isNotEmpty) {
        return translated;
      }
    } catch (_) {}
    return category;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('emergency_help')),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contacts.isEmpty
              ? _buildEmptyState(localizations)
              : _buildContactsList(localizations),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddEditContactScreen(
                emergencyStorageService: widget.emergencyStorageService,
              ),
            ),
          );
          _loadContacts();
        },
        backgroundColor: Colors.red.shade600,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          localizations.translate('add_contact'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations localizations) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.contact_phone_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              localizations.translate('no_contacts_yet'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactsList(AppLocalizations localizations) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _contacts.length,
      itemBuilder: (context, index) {
        final contact = _contacts[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: contact.isQuickAccess 
                ? BorderSide(color: Colors.red.shade300, width: 2) 
                : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          _getCategoryIcon(contact.category),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              contact.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (contact.isQuickAccess)
                      const Icon(Icons.star, color: Colors.orange, size: 28),
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.blue),
                      onPressed: () => _speakContact(contact),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _getLocalizedCategory(contact.category),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  contact.phoneNumber,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                if (contact.notes != null && contact.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    contact.notes!,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => _makePhoneCall(contact.phoneNumber),
                        icon: const Icon(Icons.call, size: 24),
                        label: Text(
                          localizations.translate('call_btn'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AddEditContactScreen(
                                emergencyStorageService: widget.emergencyStorageService,
                                contactToEdit: contact,
                              ),
                            ),
                          );
                          _loadContacts();
                        },
                        child: Text(localizations.translate('edit_btn')),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteContact(contact),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
