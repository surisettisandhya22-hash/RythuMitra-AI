import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../tasks/services/reminder_storage_service.dart';
import '../../../tasks/domain/models/farm_reminder.dart';
import '../../../profile/data/models/farm_activity.dart';
import '../../../profile/data/models/crop_growth_update.dart';
import '../../../profile/data/models/crop_photo.dart';
import '../../../profile/presentation/screens/farm_activity_screen.dart';

class FarmCalendarScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;

  const FarmCalendarScreen({super.key, required this.profileStorageService});

  @override
  State<FarmCalendarScreen> createState() => _FarmCalendarScreenState();
}

class _FarmCalendarScreenState extends State<FarmCalendarScreen> {
  DateTime _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  final ReminderStorageService _reminderService = ReminderStorageService();

  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllEvents();
  }

  Future<void> _loadAllEvents() async {
    setState(() => _isLoading = true);
    
    final events = <DateTime, List<dynamic>>{};

    // 1. Reminders
    try {
      final reminders = await _reminderService.getReminders();
      for (var r in reminders) {
        final d = DateTime(r.date.year, r.date.month, r.date.day);
        events.putIfAbsent(d, () => []).add(r);
      }
    } catch (_) {}

    // 2. Activities
    final activities = widget.profileStorageService.activitiesNotifier.value;
    for (var a in activities) {
      try {
        final ad = a.date;
        final d = DateTime(ad.year, ad.month, ad.day);
        events.putIfAbsent(d, () => []).add(a);
      } catch (_) {}
    }

    // 3. Growth Updates
    final growth = widget.profileStorageService.getGrowthUpdates();
    for (var g in growth) {
      try {
        final gd = g.date;
        final d = DateTime(gd.year, gd.month, gd.day);
        events.putIfAbsent(d, () => []).add(g);
      } catch (_) {}
    }

    // 4. Photos
    final photos = widget.profileStorageService.cropPhotosNotifier.value;
    for (var p in photos) {
      try {
        final pd = p.date;
        final d = DateTime(pd.year, pd.month, pd.day);
        events.putIfAbsent(d, () => []).add(p);
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _events = events;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + delta, 1);
    });
  }

  void _jumpToToday() {
    final now = DateTime.now();
    setState(() {
      _currentMonth = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(t.translate('farm_calendar') == 'farm_calendar' ? 'Farm Calendar' : t.translate('farm_calendar')),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            tooltip: t.translate('today') == 'today' ? 'Today' : t.translate('today'),
            onPressed: _jumpToToday,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendarHeader(t),
                _buildCalendarGrid(),
                Expanded(
                  child: _buildEventDetailsList(t),
                ),
              ],
            ),
    );
  }

  Widget _buildCalendarHeader(AppLocalizations t) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _changeMonth(-1),
            tooltip: t.translate('previous_month') == 'previous_month' ? 'Previous Month' : t.translate('previous_month'),
          ),
          Text(
            DateFormat('MMMM yyyy').format(_currentMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _changeMonth(1),
            tooltip: t.translate('next_month') == 'next_month' ? 'Next Month' : t.translate('next_month'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0).day;
    final firstDayWeekday = DateTime(_currentMonth.year, _currentMonth.month, 1).weekday;
    
    // Weekday labels
    final weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekdays.map((w) => Text(w, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey))).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.0,
            ),
            itemCount: 42, // 6 rows * 7 days
            itemBuilder: (context, index) {
              final dayOffset = index - firstDayWeekday + 2;
              
              if (dayOffset <= 0 || dayOffset > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date = DateTime(_currentMonth.year, _currentMonth.month, dayOffset);
              final isSelected = _selectedDate == date;
              final isToday = DateTime.now().year == date.year && DateTime.now().month == date.month && DateTime.now().day == date.day;
              
              final dayEvents = _events[date] ?? [];
              
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = date;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.deepPurple.shade100 : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: isToday ? Border.all(color: Colors.deepPurple, width: 2) : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayOffset',
                        style: TextStyle(
                          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.deepPurple.shade900 : Colors.black87,
                        ),
                      ),
                      if (dayEvents.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: dayEvents.take(3).map((e) {
                            IconData icon = Icons.circle;
                            Color color = Colors.grey;
                            if (e is FarmReminder) { icon = Icons.notifications; color = Colors.amber.shade700; }
                            else if (e is FarmActivity) { icon = Icons.eco; color = Colors.green.shade700; }
                            else if (e is CropGrowthUpdate) { icon = Icons.trending_up; color = Colors.blue.shade700; }
                            else if (e is CropPhoto) { icon = Icons.camera_alt; color = Colors.pink.shade700; }
                            return Icon(icon, size: 8, color: color);
                          }).toList(),
                        )
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventDetailsList(AppLocalizations t) {
    final dayEvents = _events[_selectedDate] ?? [];

    if (dayEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                t.translate('no_farm_activities_for_this_date') == 'no_farm_activities_for_this_date'
                    ? 'No farm activities for this date'
                    : t.translate('no_farm_activities_for_this_date'),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            t.translate('event_details') == 'event_details' ? 'Event Details' : t.translate('event_details'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: dayEvents.length,
            itemBuilder: (context, index) {
              final event = dayEvents[index];
              return _buildEventCard(event, t);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(dynamic event, AppLocalizations t) {
    IconData icon = Icons.event;
    Color color = Colors.grey;
    String type = 'Event';
    String title = '';
    String? subtitle;
    String? cropName;

    final crops = widget.profileStorageService.getCrops();

    if (event is FarmReminder) {
      icon = Icons.notifications;
      color = Colors.amber.shade700;
      type = t.translate('event_type_reminder') == 'event_type_reminder' ? 'Reminder' : t.translate('event_type_reminder');
      title = event.title;
      if (event.description != null && event.description!.isNotEmpty) subtitle = event.description;
    } else if (event is FarmActivity) {
      icon = Icons.eco;
      color = Colors.green.shade700;
      type = t.translate('event_type_activity') == 'event_type_activity' ? 'Activity' : t.translate('event_type_activity');
      title = event.activityType;
      if (event.notes != null && event.notes!.isNotEmpty) subtitle = event.notes;
      try {
        if (event.cropId != null) cropName = crops.firstWhere((c) => c.id == event.cropId).cropName;
      } catch (_) {}
    } else if (event is CropGrowthUpdate) {
      icon = Icons.trending_up;
      color = Colors.blue.shade700;
      type = t.translate('event_type_growth') == 'event_type_growth' ? 'Crop Growth' : t.translate('event_type_growth');
      title = event.growthStage;
      if (event.notes != null && event.notes!.isNotEmpty) subtitle = event.notes;
      try {
        cropName = crops.firstWhere((c) => c.id == event.cropId).cropName;
      } catch (_) {}
    } else if (event is CropPhoto) {
      icon = Icons.camera_alt;
      color = Colors.pink.shade700;
      type = t.translate('event_type_photo') == 'event_type_photo' ? 'Crop Photo' : t.translate('event_type_photo');
      title = t.translate('event_type_photo') == 'event_type_photo' ? 'Crop Photo' : t.translate('event_type_photo');
      if (event.note != null && event.note!.isNotEmpty) subtitle = event.note;
      try {
        cropName = crops.firstWhere((c) => c.id == event.cropId).cropName;
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () => _navigateToHostScreen(event),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withAlpha(26), shape: BoxShape.circle),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(type, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
            if (cropName != null) Text('${t.translate('crop') == 'crop' ? 'Crop' : t.translate('crop')}: $cropName', style: TextStyle(color: Colors.grey.shade700)),
            if (subtitle != null) Text(subtitle),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  void _navigateToHostScreen(dynamic event) {
    // Navigation to specific screens can be done via MyFarmDashboard or specific route
    // if the direct screen import is not available. To keep it safe:
    if (event is FarmActivity) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => FarmActivityScreen(profileStorageService: widget.profileStorageService)));
    } else {
      Navigator.of(context).pop(); // Fallback to Dashboard
    }
  }
}
