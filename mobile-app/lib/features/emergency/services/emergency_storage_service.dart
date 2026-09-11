import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/emergency_contact.dart';

class EmergencyStorageService {
  static const String _contactsKey = 'emergency_contacts';

  Future<List<EmergencyContact>> getContacts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? contactsJson = prefs.getString(_contactsKey);
      
      if (contactsJson == null || contactsJson.isEmpty) {
        return [];
      }

      final List<dynamic> decodedList = json.decode(contactsJson);
      return decodedList
          .map((item) => EmergencyContact.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty list on failure, prevent crashing
      return [];
    }
  }

  Future<bool> addContact(EmergencyContact contact) async {
    try {
      final contacts = await getContacts();
      contacts.add(contact);
      return await _saveContacts(contacts);
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateContact(EmergencyContact updatedContact) async {
    try {
      final contacts = await getContacts();
      final index = contacts.indexWhere((c) => c.id == updatedContact.id);
      
      if (index != -1) {
        contacts[index] = updatedContact;
        return await _saveContacts(contacts);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteContact(String contactId) async {
    try {
      final contacts = await getContacts();
      contacts.removeWhere((c) => c.id == contactId);
      return await _saveContacts(contacts);
    } catch (e) {
      return false;
    }
  }

  Future<bool> _saveContacts(List<EmergencyContact> contacts) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(contacts.map((c) => c.toJson()).toList());
    return await prefs.setString(_contactsKey, encodedList);
  }
}
