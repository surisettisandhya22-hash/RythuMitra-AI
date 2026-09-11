import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/farmer_profile.dart';

import '../../../tasks/domain/models/farm_reminder.dart';
import '../../../tasks/services/reminder_storage_service.dart';
import '../../../weather/presentation/widgets/weather_home_card.dart';
import '../../../../core/services/network_service.dart';

import '../../../../features/foundation/presentation/widgets/app_header.dart';
import '../../../../features/foundation/presentation/widgets/voice_button.dart';
import '../../../../features/voice/presentation/widgets/global_listen_button.dart';

import 'edit_profile_screen.dart';
import 'farm_activity_screen.dart';

import 'farm_financial_summary_screen.dart';
 
import 'edit_crop_screen.dart';
import 'crop_details_screen.dart';
import '../../../tasks/presentation/screens/create_reminder_screen.dart';
import '../../../tasks/presentation/screens/alerts_screen.dart';
import 'add_activity_screen.dart';
import 'add_edit_expense_screen.dart';
import 'add_edit_sale_screen.dart';

import '../../../reports/presentation/screens/farm_reports_screen.dart';
import '../../../../features/insights/presentation/screens/farm_insights_screen.dart';
import '../../../../features/alerts_center/presentation/screens/farm_alerts_center_screen.dart';
import '../../../reports/presentation/screens/farm_overview_screen.dart';
import '../../../weather/data/repositories/weather_repository.dart';

class MyFarmDashboard extends StatefulWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;
  final WeatherRepository weatherRepository;
  final NetworkService networkService;
  final VoidCallback? onNavigateToAiAssistant;
  final VoidCallback? onNavigateToVoiceCommand;

  const MyFarmDashboard({
    super.key,
    required this.storageService,
    required this.profileStorageService,
    required this.weatherRepository,
    required this.networkService,
    this.onNavigateToAiAssistant,
    this.onNavigateToVoiceCommand,
  });

  @override
  State<MyFarmDashboard> createState() => _MyFarmDashboardState();
}

class _MyFarmDashboardState extends State<MyFarmDashboard> with RouteAware {
  final ReminderStorageService _reminderService = ReminderStorageService();
  List<FarmReminder> _upcomingReminders = [];
  bool _isLoadingReminders = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
    // Add listeners to rebuild when data changes
    widget.profileStorageService.farmerProfileNotifier.addListener(_onProfileChanged);
    widget.profileStorageService.farmProfileNotifier.addListener(_onProfileChanged);
    widget.profileStorageService.cropsNotifier.addListener(_onProfileChanged);
    widget.profileStorageService.activitiesNotifier.addListener(_onProfileChanged);
    widget.profileStorageService.expensesNotifier.addListener(_onProfileChanged);
    widget.profileStorageService.salesNotifier.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    widget.profileStorageService.farmerProfileNotifier.removeListener(_onProfileChanged);
    widget.profileStorageService.farmProfileNotifier.removeListener(_onProfileChanged);
    widget.profileStorageService.cropsNotifier.removeListener(_onProfileChanged);
    widget.profileStorageService.activitiesNotifier.removeListener(_onProfileChanged);
    widget.profileStorageService.expensesNotifier.removeListener(_onProfileChanged);
    widget.profileStorageService.salesNotifier.removeListener(_onProfileChanged);
    super.dispose();
  }
  
  void _onProfileChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadReminders() async {
    await _reminderService.init();
    final allReminders = await _reminderService.getReminders();
    final now = DateTime.now();
    
    // Filter for upcoming/today's reminders and sort
    final upcoming = allReminders.where((r) => 
      !r.isCompleted && 
      (r.date.isAfter(now.subtract(const Duration(days: 1)))) // Not more than a day overdue
    ).toList();
    
    upcoming.sort((a, b) => a.date.compareTo(b.date));
    
    if (mounted) {
      setState(() {
        _upcomingReminders = upcoming.take(3).toList(); // Show top 3
        _isLoadingReminders = false;
      });
    }
  }

  void _refreshData() {
    _loadReminders();
    setState(() {}); // Triggers a rebuild for other ValueListenableBuilders
  }
  
  // Refresh when route is popped back to this screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshData();
  }

  void _onVoiceButtonTap() {
    if (widget.onNavigateToVoiceCommand != null) {
      widget.onNavigateToVoiceCommand!();
    } else if (widget.onNavigateToAiAssistant != null) {
      widget.onNavigateToAiAssistant!();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: ValueListenableBuilder<FarmerProfile?>(
          valueListenable: widget.profileStorageService.farmerProfileNotifier,
          builder: (context, farmerProfile, _) {
            if (farmerProfile == null) {
              return _buildEmptyState(context);
            }
            return _buildDashboard(context, farmerProfile);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_alt_1,
                size: 64,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              AppLocalizations.of(context).translate('complete_profile_prompt'),
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(
                      profileStorageService: widget.profileStorageService,
                      currentFarmerProfile: null,
                      currentFarmProfile: null,
                    ),
                  ),
                );
                _refreshData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                AppLocalizations.of(context).translate('complete_profile'),
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, FarmerProfile farmerProfile) {
    final t = AppLocalizations.of(context);
    final String greetingText = '${t.translate('home_greeting')} ${farmerProfile.name}!';

    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppHeader(),
            
            // Farmer Greeting
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Text(
                greetingText,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade900,
                ),
              ),
            ),
            
            // Global Voice Experience
            Center(
              child: VoiceButton(onTap: _onVoiceButtonTap),
            ),
            
            const SizedBox(height: 8),

            // Listen Page Button
            GlobalListenButton(
              storageService: widget.storageService,
              textBuilder: () {
                final t = AppLocalizations.of(context);
                final String greeting = '${t.translate('home_greeting')} ${farmerProfile.name}. ';
                
                final cropsCount = widget.profileStorageService.getCrops().length;
                final String cropsSummary = cropsCount > 0 
                    ? '$cropsCount ${t.translate('crops_added') == 'crops_added' ? 'Crops Added' : t.translate('crops_added')}. ' 
                    : '${t.translate('no_crops_added_yet') == 'no_crops_added_yet' ? 'No crops added yet' : t.translate('no_crops_added_yet')}. ';
                
                final remindersCount = _upcomingReminders.length;
                final String remindersSummary = remindersCount > 0 
                    ? '$remindersCount ${t.translate('upcoming_reminders') == 'upcoming_reminders' ? 'Upcoming Reminders' : t.translate('upcoming_reminders')}. ' 
                    : '${t.translate('no_upcoming_reminders') == 'no_upcoming_reminders' ? 'No upcoming reminders' : t.translate('no_upcoming_reminders')}. ';
                
                return greeting + cropsSummary + remindersSummary;
              },
            ),

            const SizedBox(height: 8),

            // Farm Location Card
            _buildFarmLocationCard(context, farmerProfile),

            // Weather Summary
            WeatherHomeCard(
              weatherRepository: widget.weatherRepository,
              profileStorageService: widget.profileStorageService,
              networkService: widget.networkService,
            ),

            // My Crops Summary
            _buildMyCropsSummary(context),

            // Today's Activities
            _buildTodaysActivities(context),

            // Upcoming Reminders
            _buildUpcomingReminders(context),

            // Financial Summary
            _buildFinancialSummary(context),

            // Quick Actions
            _buildQuickActions(context),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // 1. Farm Location Card
  Widget _buildFarmLocationCard(BuildContext context, FarmerProfile profile) {
    final t = AppLocalizations.of(context);
    final String locationText = [profile.village, profile.district, profile.state]
        .where((s) => s != null && s.isNotEmpty)
        .join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.green.shade700),
                const SizedBox(width: 8),
                Text(
                  t.translate('farm_location') == 'farm_location' ? 'Farm Location' : t.translate('farm_location'),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (locationText.isNotEmpty)
              Text(
                locationText,
                style: const TextStyle(fontSize: 16),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.translate('farm_location_not_added') == 'farm_location_not_added' ? '📍 Farm location not added' : t.translate('farm_location_not_added'),
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () async {
                       await Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => EditProfileScreen(
                            profileStorageService: widget.profileStorageService,
                            currentFarmerProfile: profile,
                            currentFarmProfile: widget.profileStorageService.farmProfileNotifier.value,
                          ),
                        ));
                       _refreshData();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    child: Text(t.translate('add_location') == 'add_location' ? 'Add Location' : t.translate('add_location'), style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                  )
                ],
              )
          ],
        ),
      ),
    );
  }

  // 2. My Crops Summary
  Widget _buildMyCropsSummary(BuildContext context) {
    final t = AppLocalizations.of(context);
    final crops = widget.profileStorageService.getCrops();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Icon(Icons.grass, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      t.translate('my_crops'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                  },
                  child: Text(t.translate('view_all') == 'view_all' ? 'View All' : t.translate('view_all')),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (crops.isEmpty)
              Text(
                t.translate('no_crops_added_yet') == 'no_crops_added_yet' ? 'No crops added yet.' : t.translate('no_crops_added_yet'),
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${crops.length} ${t.translate('crops_added') == 'crops_added' ? 'Crops Added' : t.translate('crops_added')}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: crops.take(4).map((c) => ActionChip(
                      label: Text(c.cropName, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                      backgroundColor: Colors.green.shade100,
                      onPressed: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => CropDetailsScreen(
                            profileStorageService: widget.profileStorageService,
                            storageService: widget.storageService,
                            networkService: widget.networkService,
                            cropId: c.id,
                          ),
                        ));
                      },
                    )).toList(),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }

  // 3. Upcoming Reminders
  Widget _buildUpcomingReminders(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Icon(Icons.notifications_active, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      t.translate('upcoming_reminders') == 'upcoming_reminders' ? 'Upcoming Reminders' : t.translate('upcoming_reminders'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AlertsScreen(
                        weatherRepository: widget.weatherRepository,
                        storageService: widget.storageService,
                        profileStorageService: widget.profileStorageService,
                        networkService: widget.networkService,
                      ),
                    ));
                    _refreshData();
                  },
                  child: Text(t.translate('view_all') == 'view_all' ? 'View All' : t.translate('view_all')),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (_isLoadingReminders)
               const Center(child: CircularProgressIndicator())
            else if (_upcomingReminders.isEmpty)
              Text(
                t.translate('no_upcoming_reminders') == 'no_upcoming_reminders' ? 'No upcoming reminders' : t.translate('no_upcoming_reminders'),
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              Column(
                children: _upcomingReminders.map((r) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.alarm, color: Colors.blue),
                    title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      r.date.day == DateTime.now().day && r.date.month == DateTime.now().month && r.date.year == DateTime.now().year
                          ? (t.translate('today') == 'today' ? 'Today' : t.translate('today'))
                          : DateFormat('MMM dd').format(r.date),
                    ),
                  );
                }).toList(),
              )
          ],
        ),
      ),
    );
  }

  // 4. Today's Activities
  Widget _buildTodaysActivities(BuildContext context) {
    final t = AppLocalizations.of(context);
    final activities = widget.profileStorageService.getActivities();
    final now = DateTime.now();
    final todayActivities = activities.where((a) => 
      a.date.day == now.day && a.date.month == now.month && a.date.year == now.year
    ).toList();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Icon(Icons.today, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      t.translate('todays_activities') == 'todays_activities' ? "Today's Activities" : t.translate('todays_activities'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FarmActivityScreen(
                        profileStorageService: widget.profileStorageService,
                      ),
                    ));
                    _refreshData();
                  },
                  child: Text(t.translate('view_all') == 'view_all' ? 'View All' : t.translate('view_all')),
                )
              ],
            ),
            const SizedBox(height: 8),
            if (todayActivities.isEmpty)
              Text(
                t.translate('no_farm_activities_today') == 'no_farm_activities_today' ? 'No farm activities today' : t.translate('no_farm_activities_today'),
                style: TextStyle(color: Colors.grey.shade600),
              )
            else
              Column(
                children: todayActivities.map((a) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.check_circle_outline, color: Colors.green),
                    title: Text(AppLocalizations.of(context).translate(a.activityType), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(a.notes ?? ''),
                  );
                }).toList(),
              )
          ],
        ),
      ),
    );
  }

  // 5. Financial Summary
  Widget _buildFinancialSummary(BuildContext context) {
    final t = AppLocalizations.of(context);
    final expenses = widget.profileStorageService.getExpenses();
    final sales = widget.profileStorageService.getSales();
    
    double totalExpenses = 0.0;
    for (var e in expenses) {
      totalExpenses += e.amount;
    }
    
    double totalIncome = 0.0;
    for (var s in sales) {
      totalIncome += s.totalSaleValue;
    }
    
    double netBalance = totalIncome - totalExpenses;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Icon(Icons.account_balance_wallet, color: Colors.deepPurple.shade700),
                    const SizedBox(width: 8),
                    Text(
                      t.translate('financial_summary') == 'financial_summary' ? 'Financial Summary' : t.translate('financial_summary'),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FarmFinancialSummaryScreen(
                        profileStorageService: widget.profileStorageService,
                        storageService: widget.storageService,
                      ),
                    ));
                    _refreshData();
                  },
                  child: Text(t.translate('view_more') == 'view_more' ? 'View More' : t.translate('view_more')),
                )
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.translate('total_income') == 'total_income' ? 'Total Income' : t.translate('total_income'), style: TextStyle(color: Colors.grey.shade600)),
                    Text('₹${totalIncome.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(t.translate('total_expenses') == 'total_expenses' ? 'Total Expenses' : t.translate('total_expenses'), style: TextStyle(color: Colors.grey.shade600)),
                    Text('₹${totalExpenses.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t.translate('net_balance') == 'net_balance' ? 'Net Balance' : t.translate('net_balance'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Text(
                  '₹${netBalance.toStringAsFixed(2)}', 
                  style: TextStyle(
                    color: netBalance >= 0 ? Colors.green.shade800 : Colors.red.shade800, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 18
                  )
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 6. Quick Actions
  Widget _buildQuickActions(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.translate('quick_actions'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildActionChip(
                  icon: Icons.grass, 
                  label: t.translate('add_crop') == 'add_crop' ? 'Add Crop' : t.translate('add_crop'), 
                  color: Colors.green,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => EditCropScreen(
                        profileStorageService: widget.profileStorageService,
                        currentCrop: null,
                      ),
                    ));
                    _refreshData();
                  }
                ),
                _buildActionChip(
                  icon: Icons.notification_important, 
                  label: t.translate('farm_alerts') == 'farm_alerts' ? 'Farm Alerts' : t.translate('farm_alerts'), 
                  color: Colors.red.shade700,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FarmAlertsCenterScreen(
                        profileStorageService: widget.profileStorageService,
                        storageService: widget.storageService,
                        networkService: widget.networkService,
                        weatherRepository: widget.weatherRepository,
                      ),
                    ));
                    _refreshData();
                  }
                ),
                _buildActionChip(
                  icon: Icons.insights, 
                  label: t.translate('farm_insights') == 'farm_insights' ? 'Farm Insights' : t.translate('farm_insights'), 
                  color: Colors.teal,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FarmInsightsScreen(
                        profileStorageService: widget.profileStorageService,
                        storageService: widget.storageService,
                        networkService: widget.networkService,
                        weatherRepository: widget.weatherRepository,
                      ),
                    ));
                    _refreshData();
                  }
                ),
                _buildActionChip(
                  icon: Icons.dashboard_customize, 
                  label: t.translate('my_farm_overview') == 'my_farm_overview' ? 'Farm Overview' : t.translate('my_farm_overview'), 
                  color: Colors.indigo,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FarmOverviewScreen(
                        profileStorageService: widget.profileStorageService,
                        storageService: widget.storageService,
                        weatherRepository: widget.weatherRepository,
                        networkService: widget.networkService,
                      ),
                    ));
                    _refreshData();
                  }
                ),
                _buildActionChip(
                  icon: Icons.bar_chart, 
                  label: t.translate('farm_reports') == 'farm_reports' ? 'Farm Reports' : t.translate('farm_reports'), 
                  color: Colors.deepPurple,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => FarmReportsScreen(
                        profileStorageService: widget.profileStorageService,
                        reminderStorageService: _reminderService,
                        storageService: widget.storageService,
                      ),
                    ));
                    _refreshData();
                  }
                ),
                _buildActionChip(
                  icon: Icons.alarm_add, 
                  label: t.translate('add_reminder') == 'add_reminder' ? 'Add Reminder' : t.translate('add_reminder'), 
                  color: Colors.blue,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => CreateReminderScreen(
                        reminderService: _reminderService,
                        profileStorageService: widget.profileStorageService,
                      ),
                    ));
                    _refreshData();
                  }
                ),
                _buildActionChip(
                  icon: Icons.post_add, 
                  label: t.translate('add_activity') == 'add_activity' ? 'Add Activity' : t.translate('add_activity'), 
                  color: Colors.orange,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddActivityScreen(
                        profileStorageService: widget.profileStorageService,
                      ),
                    ));
                    _refreshData();
                  }
                ),
                _buildActionChip(
                  icon: Icons.money_off, 
                  label: t.translate('add_expense') == 'add_expense' ? 'Add Expense' : t.translate('add_expense'), 
                  color: Colors.red,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddEditExpenseScreen(
                        profileStorageService: widget.profileStorageService,
                        storageService: widget.storageService,
                      ),
                    ));
                    _refreshData();
                  }
                ),
                _buildActionChip(
                  icon: Icons.attach_money, 
                  label: t.translate('add_income') == 'add_income' ? 'Add Income' : t.translate('add_income'), 
                  color: Colors.green.shade800,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddEditSaleScreen(
                        profileStorageService: widget.profileStorageService,
                        storageService: widget.storageService,
                      ),
                    ));
                    _refreshData();
                  }
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildActionChip({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
