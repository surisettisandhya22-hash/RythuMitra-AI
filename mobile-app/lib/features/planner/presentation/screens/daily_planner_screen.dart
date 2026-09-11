import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/farm_task.dart';
import '../../services/task_storage_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../profile/data/models/crop_profile.dart';
import '../widgets/farm_task_card.dart';
import 'add_farm_task_screen.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../features/voice/presentation/widgets/global_listen_button.dart';

class DailyPlannerScreen extends StatefulWidget {
  final TaskStorageService taskService;
  final ProfileStorageService? profileStorageService;
  final StorageService? storageService;

  const DailyPlannerScreen({
    super.key,
    required this.taskService,
    this.profileStorageService,
    this.storageService,
  });

  @override
  State<DailyPlannerScreen> createState() => _DailyPlannerScreenState();
}

class _DailyPlannerScreenState extends State<DailyPlannerScreen> {
  List<FarmTask> _allTasks = [];
  List<CropProfile> _crops = [];
  bool _isLoading = true;
  String _currentFilter = 'Today'; // Options: Today, Tomorrow, This Week, Upcoming, Completed, All Tasks

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final tasks = await widget.taskService.getTasks();
    if (widget.profileStorageService != null) {
      _crops = widget.profileStorageService!.getCrops();
    }

    if (mounted) {
      setState(() {
        _allTasks = tasks;
        _isLoading = false;
      });
    }
  }

  CropProfile? _getCrop(String? cropId) {
    if (cropId == null) return null;
    try {
      return _crops.firstWhere((c) => c.id == cropId);
    } catch (e) {
      return null;
    }
  }

  void _toggleTaskCompletion(FarmTask task, bool? value) async {
    task.isCompleted = value ?? false;
    task.completedAt = task.isCompleted ? DateTime.now() : null;
    await widget.taskService.updateTask(task);
    _loadData();

    if (task.isCompleted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).translate('planner_completed')),
          action: SnackBarAction(
            label: "Add to Farm Activity Log",
            onPressed: () {
              // Nav to activity log (Step 23) in a real app
            },
          ),
        ),
      );
    }
  }

  void _confirmDeleteTask(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(AppLocalizations.of(context).translate('planner_delete_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await widget.taskService.deleteTask(id);
                _loadData();
              },
              child: Text(AppLocalizations.of(context).translate('delete'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  List<FarmTask> _getFilteredTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final endOfWeek = today.add(Duration(days: 7 - today.weekday));

    return _allTasks.where((task) {
      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
      
      if (_currentFilter == 'Completed') {
        return task.isCompleted;
      }
      
      if (task.isCompleted && _currentFilter != 'All Tasks') {
        return false;
      }

      switch (_currentFilter) {
        case 'Today':
          return taskDate.isAtSameMomentAs(today) || (taskDate.isBefore(today) && !task.isCompleted);
        case 'Tomorrow':
          return taskDate.isAtSameMomentAs(tomorrow);
        case 'This Week':
          return taskDate.isAfter(today.subtract(const Duration(days: 1))) && taskDate.isBefore(endOfWeek.add(const Duration(days: 1)));
        case 'Upcoming':
          return taskDate.isAfter(today);
        case 'All Tasks':
          return true;
        default:
          return true;
      }
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  double _calculateDailyProgress() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final todaysTasks = _allTasks.where((t) {
      final taskDate = DateTime(t.date.year, t.date.month, t.date.day);
      return taskDate.isAtSameMomentAs(today) || (taskDate.isBefore(today) && !t.isCompleted);
    }).toList();

    if (todaysTasks.isEmpty) return 0.0;

    final completedTasks = todaysTasks.where((t) => t.isCompleted).length;
    return completedTasks / todaysTasks.length;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final filteredTasks = _getFilteredTasks();
    final progress = _calculateDailyProgress();
    
    // Separate into Today/Upcoming/Completed for 'All Tasks' view or general grouping
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todaysTasksList = filteredTasks.where((task) {
      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
      return (taskDate.isAtSameMomentAs(today) || taskDate.isBefore(today)) && !task.isCompleted;
    }).toList();

    final upcomingTasksList = filteredTasks.where((task) {
      final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
      return taskDate.isAfter(today) && !task.isCompleted;
    }).toList();

    final completedTasksList = filteredTasks.where((task) => task.isCompleted).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(t.translate('planner_title')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              _buildProgressHeader(t, progress),
              _buildFilterChips(t),
              Expanded(
                child: filteredTasks.isEmpty
                  ? Center(child: Text("No tasks found.", style: TextStyle(color: Colors.grey.shade600)))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (widget.storageService != null)
                          GlobalListenButton(
                            storageService: widget.storageService!,
                            textBuilder: () {
                              final total = todaysTasksList.length + completedTasksList.where((t) => DateTime(t.date.year, t.date.month, t.date.day).isAtSameMomentAs(today)).length;
                              final comp = completedTasksList.where((t) => DateTime(t.date.year, t.date.month, t.date.day).isAtSameMomentAs(today)).length;
                              final rem = total - comp;
                              return "You have $total tasks today. $comp tasks are completed. $rem tasks are remaining.";
                            },
                          ),
                        const SizedBox(height: 16),
                        if (_currentFilter == 'All Tasks' || _currentFilter == 'Today' || _currentFilter == 'This Week') ...[
                          if (todaysTasksList.isNotEmpty) ...[
                            _buildSectionTitle(t.translate('planner_todays_tasks')),
                            ...todaysTasksList.map((task) => FarmTaskCard(
                              task: task,
                              relatedCrop: _getCrop(task.cropId),
                              onToggleComplete: (val) => _toggleTaskCompletion(task, val),
                              onEdit: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => AddFarmTaskScreen(taskService: widget.taskService, profileStorageService: widget.profileStorageService, existingTask: task)));
                                _loadData();
                              },
                              onDelete: () => _confirmDeleteTask(task.id),
                            )),
                            const SizedBox(height: 16),
                          ],
                        ],
                        
                        if (_currentFilter == 'All Tasks' || _currentFilter == 'Upcoming' || _currentFilter == 'Tomorrow' || _currentFilter == 'This Week') ...[
                          if (upcomingTasksList.isNotEmpty) ...[
                            _buildSectionTitle(t.translate('planner_upcoming_tasks')),
                            ...upcomingTasksList.map((task) => FarmTaskCard(
                              task: task,
                              relatedCrop: _getCrop(task.cropId),
                              onToggleComplete: (val) => _toggleTaskCompletion(task, val),
                              onEdit: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => AddFarmTaskScreen(taskService: widget.taskService, profileStorageService: widget.profileStorageService, existingTask: task)));
                                _loadData();
                              },
                              onDelete: () => _confirmDeleteTask(task.id),
                            )),
                            const SizedBox(height: 16),
                          ],
                        ],
                        
                        if (_currentFilter == 'All Tasks' || _currentFilter == 'Completed') ...[
                          if (completedTasksList.isNotEmpty) ...[
                            _buildSectionTitle(t.translate('planner_completed_tasks')),
                            ...completedTasksList.map((task) => FarmTaskCard(
                              task: task,
                              relatedCrop: _getCrop(task.cropId),
                              onToggleComplete: (val) => _toggleTaskCompletion(task, val),
                              onEdit: () async {
                                await Navigator.push(context, MaterialPageRoute(builder: (_) => AddFarmTaskScreen(taskService: widget.taskService, profileStorageService: widget.profileStorageService, existingTask: task)));
                                _loadData();
                              },
                              onDelete: () => _confirmDeleteTask(task.id),
                            )),
                            const SizedBox(height: 16),
                          ],
                        ]
                      ],
                    ),
              ),
            ],
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => AddFarmTaskScreen(taskService: widget.taskService, profileStorageService: widget.profileStorageService)));
          _loadData();
        },
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(t.translate('planner_add_task')),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade800,
        ),
      ),
    );
  }

  Widget _buildProgressHeader(AppLocalizations t, double progress) {
    final percent = (progress * 100).toInt();
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.translate('planner_daily_progress'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green.shade600,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$percent%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(AppLocalizations t) {
    final filters = ['Today', 'Tomorrow', 'This Week', 'Upcoming', 'Completed', 'All Tasks'];
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          String translated = filter;
          if (filter == 'Today') translated = t.translate('planner_today');
          if (filter == 'Tomorrow') translated = t.translate('planner_tomorrow');
          if (filter == 'This Week') translated = t.translate('planner_this_week');
          if (filter == 'Upcoming') translated = t.translate('upcoming');
          if (filter == 'Completed') translated = t.translate('completed');
          if (filter == 'All Tasks') translated = t.translate('planner_all_tasks');
          
          final isSelected = _currentFilter == filter;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(translated),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _currentFilter = filter;
                  });
                }
              },
              selectedColor: Colors.green.shade600,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }
}
