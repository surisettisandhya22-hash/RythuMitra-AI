import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/models/farm_task.dart';

class TaskStorageService {
  static const String _keyTasks = 'rythumitra_farm_tasks';
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<FarmTask>> getTasks() async {
    await init();
    final String? tasksJson = _prefs!.getString(_keyTasks);
    if (tasksJson == null) return [];

    try {
      final List<dynamic> decodedList = jsonDecode(tasksJson);
      return decodedList.map((json) => FarmTask.fromJson(json)).toList();
    } catch (e) {
      // Log error in production instead of print
      return [];
    }
  }

  Future<void> saveTask(FarmTask task) async {
    final tasks = await getTasks();
    final index = tasks.indexWhere((t) => t.id == task.id);
    
    if (index >= 0) {
      tasks[index] = task;
    } else {
      tasks.add(task);
    }
    
    await _saveTasksList(tasks);
  }

  Future<void> updateTask(FarmTask task) async {
    await saveTask(task);
  }

  Future<void> deleteTask(String id) async {
    final tasks = await getTasks();
    tasks.removeWhere((t) => t.id == id);
    await _saveTasksList(tasks);
  }

  Future<void> _saveTasksList(List<FarmTask> tasks) async {
    await init();
    final List<Map<String, dynamic>> jsonList = tasks.map((t) => t.toJson()).toList();
    await _prefs!.setString(_keyTasks, jsonEncode(jsonList));
  }
}
