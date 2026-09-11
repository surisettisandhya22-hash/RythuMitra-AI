import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../tasks/services/reminder_storage_service.dart';
import '../../../profile/presentation/screens/farm_activity_screen.dart';
import 'package:intl/intl.dart';

class ActivityReportView extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final ReminderStorageService reminderStorageService;
  final DateTime? fromDate;
  final DateTime? toDate;

  const ActivityReportView({
    super.key,
    required this.profileStorageService,
    required this.reminderStorageService,
    this.fromDate,
    this.toDate,
  });

  @override
  State<ActivityReportView> createState() => _ActivityReportViewState();
}

class _ActivityReportViewState extends State<ActivityReportView> {
  List<Map<String, dynamic>> _allRecords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  @override
  void didUpdateWidget(ActivityReportView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fromDate != widget.fromDate || oldWidget.toDate != widget.toDate) {
      _loadData();
    }
  }

  bool _isWithinRange(DateTime date) {
    if (widget.fromDate != null && date.isBefore(widget.fromDate!)) return false;
    if (widget.toDate != null && date.isAfter(widget.toDate!.add(const Duration(days: 1)))) return false;
    return true;
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final activities = widget.profileStorageService.getActivities();
    final reminders = await widget.reminderStorageService.getReminders();
    final crops = widget.profileStorageService.getCrops();

    List<Map<String, dynamic>> combined = [];

    for (var act in activities) {
      if (_isWithinRange(act.date)) {
        String? cropName;
        if (act.cropId != null) {
          try {
            cropName = crops.firstWhere((c) => c.id == act.cropId).cropName;
          } catch (_) {}
        }
        
        combined.add({
          'type': 'activity',
          'date': act.date,
          'title': act.activityType,
          'crop': cropName,
          'notes': act.notes,
        });
      }
    }

    for (var rem in reminders) {
      if (_isWithinRange(rem.date)) {
        combined.add({
          'type': 'reminder',
          'date': rem.date,
          'title': rem.title,
          'crop': null,
          'notes': rem.description,
        });
      }
    }

    combined.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    if (mounted) {
      setState(() {
        _allRecords = combined;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(24.0), child: CircularProgressIndicator()));
    }

    if (_allRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            t.translate('no_records_available') == 'no_records_available' ? 'No records available for this period.' : t.translate('no_records_available'),
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => FarmActivityScreen(profileStorageService: widget.profileStorageService),
              ));
            },
            icon: const Icon(Icons.list, color: Colors.white),
            label: Text(t.translate('activities') == 'activities' ? 'Activities' : t.translate('activities'), style: const TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            itemCount: _allRecords.length,
            itemBuilder: (context, index) {
              final record = _allRecords[index];
              final isActivity = record['type'] == 'activity';
              final DateTime date = record['date'];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isActivity ? Icons.check_circle_outline : Icons.alarm,
                                color: isActivity ? Colors.green : Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isActivity ? t.translate(record['title']) : record['title'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                          Text(
                            DateFormat('dd MMM yyyy').format(date),
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                        ],
                      ),
                      if (record['crop'] != null || record['notes'] != null)
                        const SizedBox(height: 12),
                      if (record['crop'] != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${t.translate('crop') == 'crop' ? 'Crop' : t.translate('crop')}: ${record['crop']}',
                            style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600),
                          ),
                        ),
                      if (record['notes'] != null && record['notes'].toString().isNotEmpty)
                        Text(
                          record['notes'],
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
