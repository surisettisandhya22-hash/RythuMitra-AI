import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/farmer_profile.dart';
import '../data/models/farm_profile.dart';
import '../data/models/crop_profile.dart';
import '../data/models/crop_growth_update.dart';
import '../data/models/farm_activity.dart';
import '../../scanner/data/models/scan_result.dart';
import '../../scanner/data/models/crop_health_record.dart';
import '../data/models/crop_photo.dart';
import '../data/models/farm_expense.dart';
import '../data/models/farm_sale.dart';

class ProfileStorageService {
  static const String _keyFarmerProfile = 'farmerProfile';
  static const String _keyFarmProfile = 'farmProfile';
  static const String _keyCrops = 'crops';
  static const String _keyGrowthUpdates = 'growthUpdates';
  static const String _keyActivities = 'activities';
  static const String _keyCropPhotos = 'cropPhotos';
  static const String _keyFarmExpenses = 'farmExpenses';
  static const String _keyFarmSales = 'farmSales';

  late SharedPreferences _prefs;

  final ValueNotifier<FarmerProfile?> farmerProfileNotifier = ValueNotifier(null);
  final ValueNotifier<FarmProfile?> farmProfileNotifier = ValueNotifier(null);
  final ValueNotifier<List<CropProfile>> cropsNotifier = ValueNotifier([]);
  final ValueNotifier<List<CropGrowthUpdate>> growthUpdatesNotifier = ValueNotifier([]);
  final ValueNotifier<List<FarmActivity>> activitiesNotifier = ValueNotifier([]);
  final ValueNotifier<List<CropHealthRecord>> healthRecordsNotifier = ValueNotifier([]);
  final ValueNotifier<List<CropPhoto>> cropPhotosNotifier = ValueNotifier([]);
  final ValueNotifier<List<FarmExpense>> expensesNotifier = ValueNotifier([]);
  final ValueNotifier<List<FarmSale>> salesNotifier = ValueNotifier([]);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadAllProfiles();
  }

  void _loadAllProfiles() {
    farmerProfileNotifier.value = getFarmerProfile();
    farmProfileNotifier.value = getFarmProfile();
    cropsNotifier.value = getCrops();

    final growthJson = _prefs.getString(_keyGrowthUpdates);
    if (growthJson != null) {
      final List<dynamic> decodedList = jsonDecode(growthJson);
      growthUpdatesNotifier.value = decodedList.map((json) => CropGrowthUpdate.fromJson(json)).toList();
    }

    final activitiesJson = _prefs.getString(_keyActivities);
    if (activitiesJson != null) {
      final List<dynamic> decodedList = jsonDecode(activitiesJson);
      activitiesNotifier.value = decodedList.map((json) => FarmActivity.fromJson(json)).toList();
    }

    final cropPhotosJson = _prefs.getString(_keyCropPhotos);
    if (cropPhotosJson != null) {
      final List<dynamic> decodedList = jsonDecode(cropPhotosJson);
      cropPhotosNotifier.value = decodedList.map((json) => CropPhoto.fromJson(json)).toList();
    }

    final expensesJson = _prefs.getString(_keyFarmExpenses);
    if (expensesJson != null) {
      final List<dynamic> decodedList = jsonDecode(expensesJson);
      expensesNotifier.value = decodedList.map((json) => FarmExpense.fromJson(json)).toList();
    }
    
    final salesJson = _prefs.getString(_keyFarmSales);
    if (salesJson != null) {
      final List<dynamic> decodedList = jsonDecode(salesJson);
      salesNotifier.value = decodedList.map((json) => FarmSale.fromJson(json)).toList();
    }
    
    try {
      final recordsJson = _prefs.getString('health_history_data');
      if (recordsJson != null) {
        final List<dynamic> decodedList = jsonDecode(recordsJson);
        healthRecordsNotifier.value = decodedList.map((json) => CropHealthRecord.fromJson(json)).toList();
      } else {
        // Migration from old scans_data if needed
        final scansJson = _prefs.getString('scans_data');
        if (scansJson != null) {
          final List<dynamic> decodedList = jsonDecode(scansJson);
          final scans = decodedList.map((json) => ScanResult.fromJson(json)).toList();
          healthRecordsNotifier.value = scans.map((s) => CropHealthRecord(
            id: s.id,
            cropId: s.cropId,
            initialScan: s,
            currentStatus: 'Monitoring',
            createdAt: s.date,
            updatedAt: s.date,
          )).toList();
          _saveHealthRecordsToStorage(); // Save in new format
        }
      }
    } catch (e) {
      debugPrint('Error loading health records data: $e');
    }
  }

  // --- Farmer Profile ---

  Future<void> saveFarmerProfile(FarmerProfile profile) async {
    final String jsonString = jsonEncode(profile.toJson());
    await _prefs.setString(_keyFarmerProfile, jsonString);
    farmerProfileNotifier.value = profile;
  }

  FarmerProfile? getFarmerProfile() {
    final String? jsonString = _prefs.getString(_keyFarmerProfile);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        return FarmerProfile.fromJson(json);
      } catch (e) {
        debugPrint('Error parsing FarmerProfile: $e');
        return null;
      }
    }
    return null;
  }

  // --- Farm Profile ---

  Future<void> saveFarmProfile(FarmProfile profile) async {
    final String jsonString = jsonEncode(profile.toJson());
    await _prefs.setString(_keyFarmProfile, jsonString);
    farmProfileNotifier.value = profile;
  }

  FarmProfile? getFarmProfile() {
    final String? jsonString = _prefs.getString(_keyFarmProfile);
    if (jsonString != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        return FarmProfile.fromJson(json);
      } catch (e) {
        debugPrint('Error parsing FarmProfile: $e');
        return null;
      }
    }
    return null;
  }

  // --- Crops ---

  Future<void> saveCrops(List<CropProfile> crops) async {
    final List<Map<String, dynamic>> jsonList = crops.map((c) => c.toJson()).toList();
    final String jsonString = jsonEncode(jsonList);
    await _prefs.setString(_keyCrops, jsonString);
    cropsNotifier.value = crops;
  }

  List<CropProfile> getCrops() {
    final String? jsonString = _prefs.getString(_keyCrops);
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        return jsonList.map((json) => CropProfile.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        debugPrint('Error parsing crops list: $e');
        return [];
      }
    }
    return [];
  }

  Future<void> addCrop(CropProfile crop) async {
    final List<CropProfile> currentCrops = getCrops();
    currentCrops.add(crop);
    await saveCrops(currentCrops);
  }

  Future<void> updateCrop(CropProfile updatedCrop) async {
    final List<CropProfile> currentCrops = getCrops();
    final int index = currentCrops.indexWhere((c) => c.id == updatedCrop.id);
    if (index != -1) {
      currentCrops[index] = updatedCrop;
      await saveCrops(currentCrops);
    }
  }

  Future<void> deleteCrop(String id) async {
    final List<CropProfile> currentCrops = getCrops();
    currentCrops.removeWhere((c) => c.id == id);
    await saveCrops(currentCrops);
  }

  Future<void> saveCropHealthRecord(CropHealthRecord record) async {
    final updatedRecords = List<CropHealthRecord>.from(healthRecordsNotifier.value);
    final index = updatedRecords.indexWhere((r) => r.id == record.id);
    
    if (index != -1) {
      updatedRecords[index] = record;
    } else {
      updatedRecords.insert(0, record); // Add to beginning
    }
    
    healthRecordsNotifier.value = updatedRecords;
    await _saveHealthRecordsToStorage();
  }
  
  List<CropHealthRecord> getHealthRecordsForCrop(String cropId) {
    return healthRecordsNotifier.value.where((record) => record.cropId == cropId).toList();
  }

  Future<void> deleteCropHealthRecord(String id) async {
    final updatedRecords = List<CropHealthRecord>.from(healthRecordsNotifier.value);
    updatedRecords.removeWhere((r) => r.id == id);
    healthRecordsNotifier.value = updatedRecords;
    await _saveHealthRecordsToStorage();
  }
  
  Future<void> _saveHealthRecordsToStorage() async {
    try {
      final String encodedData = jsonEncode(
        healthRecordsNotifier.value.map((r) => r.toJson()).toList(),
      );
      await _prefs.setString('health_history_data', encodedData);
    } catch (e) {
      debugPrint('Error saving health records data: $e');
    }
  }

  // --- Growth Updates ---
  List<CropGrowthUpdate> getGrowthUpdates() {
    return List.from(growthUpdatesNotifier.value);
  }

  Future<void> addGrowthUpdate(CropGrowthUpdate update) async {
    final updates = getGrowthUpdates();
    updates.add(update);
    growthUpdatesNotifier.value = updates;
    await _saveGrowthUpdatesToStorage();
  }

  Future<void> updateGrowthUpdate(CropGrowthUpdate update) async {
    final updates = getGrowthUpdates();
    final index = updates.indexWhere((u) => u.id == update.id);
    if (index != -1) {
      updates[index] = update;
      growthUpdatesNotifier.value = updates;
      await _saveGrowthUpdatesToStorage();
    }
  }

  Future<void> deleteGrowthUpdate(String id) async {
    final updates = getGrowthUpdates();
    updates.removeWhere((u) => u.id == id);
    growthUpdatesNotifier.value = updates;
    await _saveGrowthUpdatesToStorage();
  }

  Future<void> _saveGrowthUpdatesToStorage() async {
    final encoded = jsonEncode(growthUpdatesNotifier.value.map((u) => u.toJson()).toList());
    await _prefs.setString(_keyGrowthUpdates, encoded);
  }


  // --- Activities ---
  List<FarmActivity> getActivities() {
    return List.from(activitiesNotifier.value);
  }

  Future<void> addActivity(FarmActivity activity) async {
    final acts = getActivities();
    acts.add(activity);
    activitiesNotifier.value = acts;
    await _saveActivitiesToStorage();
  }

  Future<void> updateActivity(FarmActivity activity) async {
    final acts = getActivities();
    final index = acts.indexWhere((a) => a.id == activity.id);
    if (index != -1) {
      acts[index] = activity;
      activitiesNotifier.value = acts;
      await _saveActivitiesToStorage();
    }
  }

  Future<void> deleteActivity(String id) async {
    final acts = getActivities();
    acts.removeWhere((a) => a.id == id);
    activitiesNotifier.value = acts;
    await _saveActivitiesToStorage();
  }

  Future<void> _saveActivitiesToStorage() async {
    final encoded = jsonEncode(activitiesNotifier.value.map((a) => a.toJson()).toList());
    await _prefs.setString(_keyActivities, encoded);
  }

  // --- Crop Photos ---
  List<CropPhoto> getCropPhotosForCrop(String cropId) {
    return cropPhotosNotifier.value.where((p) => p.cropId == cropId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addCropPhoto(CropPhoto photo) async {
    final photos = List<CropPhoto>.from(cropPhotosNotifier.value);
    photos.add(photo);
    cropPhotosNotifier.value = photos;
    await _saveCropPhotosToStorage();
  }

  Future<void> deleteCropPhoto(String id) async {
    final photos = List<CropPhoto>.from(cropPhotosNotifier.value);
    photos.removeWhere((p) => p.id == id);
    cropPhotosNotifier.value = photos;
    await _saveCropPhotosToStorage();
  }

  Future<void> _saveCropPhotosToStorage() async {
    final encoded = jsonEncode(cropPhotosNotifier.value.map((p) => p.toJson()).toList());
    await _prefs.setString(_keyCropPhotos, encoded);
  }

  // --- Farm Expenses ---
  List<FarmExpense> getExpenses() {
    return List.from(expensesNotifier.value)..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<void> addExpense(FarmExpense expense) async {
    final expenses = List<FarmExpense>.from(expensesNotifier.value);
    expenses.add(expense);
    expensesNotifier.value = expenses;
    await _saveExpensesToStorage();
  }

  Future<void> updateExpense(FarmExpense expense) async {
    final expenses = List<FarmExpense>.from(expensesNotifier.value);
    final index = expenses.indexWhere((e) => e.id == expense.id);
    if (index != -1) {
      expenses[index] = expense;
      expensesNotifier.value = expenses;
      await _saveExpensesToStorage();
    }
  }

  Future<void> deleteExpense(String id) async {
    final expenses = List<FarmExpense>.from(expensesNotifier.value);
    expenses.removeWhere((e) => e.id == id);
    expensesNotifier.value = expenses;
    await _saveExpensesToStorage();
  }

  Future<void> _saveExpensesToStorage() async {
    final encoded = jsonEncode(expensesNotifier.value.map((e) => e.toJson()).toList());
    await _prefs.setString(_keyFarmExpenses, encoded);
  }

  // --- Farm Sales ---
  List<FarmSale> getSales() {
    return List.from(salesNotifier.value)..sort((a, b) => b.saleDate.compareTo(a.saleDate));
  }

  Future<void> addSale(FarmSale sale) async {
    final sales = List<FarmSale>.from(salesNotifier.value);
    sales.add(sale);
    salesNotifier.value = sales;
    await _saveSalesToStorage();
  }

  Future<void> updateSale(FarmSale sale) async {
    final sales = List<FarmSale>.from(salesNotifier.value);
    final index = sales.indexWhere((s) => s.id == sale.id);
    if (index != -1) {
      sales[index] = sale;
      salesNotifier.value = sales;
      await _saveSalesToStorage();
    }
  }

  Future<void> deleteSale(String id) async {
    final sales = List<FarmSale>.from(salesNotifier.value);
    sales.removeWhere((s) => s.id == id);
    salesNotifier.value = sales;
    await _saveSalesToStorage();
  }

  Future<void> _saveSalesToStorage() async {
    final encoded = jsonEncode(salesNotifier.value.map((s) => s.toJson()).toList());
    await _prefs.setString(_keyFarmSales, encoded);
  }
}
