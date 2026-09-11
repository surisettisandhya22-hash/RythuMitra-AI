import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/farm_activity.dart';
import 'add_activity_screen.dart';

class FarmActivityScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;

  const FarmActivityScreen({
    super.key,
    required this.profileStorageService,
  });

  @override
  State<FarmActivityScreen> createState() => _FarmActivityScreenState();
}

class _FarmActivityScreenState extends State<FarmActivityScreen> {
  void _confirmDeleteActivity(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(AppLocalizations.of(context).translate('delete_activity_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await widget.profileStorageService.deleteActivity(id);
              },
              child: Text(AppLocalizations.of(context).translate('delete'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(t.translate('farm_activity_log')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder<List<FarmActivity>>(
        valueListenable: widget.profileStorageService.activitiesNotifier,
        builder: (context, activities, _) {
          final sortedActivities = List<FarmActivity>.from(activities)
            ..sort((a, b) => b.date.compareTo(a.date));

          if (sortedActivities.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('📋', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      t.translate('no_farm_activities_yet'),
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      t.translate('record_farm_activities_prompt'),
                      style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => AddActivityScreen(
                            profileStorageService: widget.profileStorageService,
                          ),
                        ));
                      },
                      icon: const Icon(Icons.add),
                      label: Text(t.translate('add_activity')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedActivities.length,
            itemBuilder: (context, index) {
              final act = sortedActivities[index];
              final stageText = t.translate(act.activityType);
              
              String cropName = t.translate('general_farm_activity');
              if (act.cropId != null) {
                final crops = widget.profileStorageService.getCrops();
                final matchingCrop = crops.where((c) => c.id == act.cropId).toList();
                if (matchingCrop.isNotEmpty) {
                  cropName = matchingCrop.first.cropName;
                }
              }

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.green.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '${act.date.day.toString().padLeft(2, '0')} ${_getMonthName(act.date.month)} ${act.date.year}',
                                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(act.cropId == null ? Icons.grass : Icons.spa, size: 16, color: Colors.green.shade600),
                                const SizedBox(width: 4),
                                Text(cropName, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.green.shade800)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(stageText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            if (act.notes != null && act.notes!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text('"${act.notes!}"', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade800)),
                            ]
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => AddActivityScreen(
                                  profileStorageService: widget.profileStorageService,
                                  existingActivity: act,
                                ),
                              ));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                            onPressed: () => _confirmDeleteActivity(act.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<List<FarmActivity>>(
        valueListenable: widget.profileStorageService.activitiesNotifier,
        builder: (context, activities, _) {
          if (activities.isEmpty) return const SizedBox.shrink();
          return FloatingActionButton(
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => AddActivityScreen(
                  profileStorageService: widget.profileStorageService,
                ),
              ));
            },
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
