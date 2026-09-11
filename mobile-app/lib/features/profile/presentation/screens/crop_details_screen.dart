import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../services/profile_storage_service.dart';
import '../../data/models/crop_profile.dart';
import '../../data/models/crop_growth_update.dart';
import 'add_growth_update_screen.dart';
import 'edit_crop_screen.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../scanner/presentation/widgets/scanner_entry_helper.dart';
import '../../../scanner/services/scanner_service.dart';
import '../../../scanner/data/models/crop_health_record.dart';
import '../../../scanner/presentation/screens/health_record_screen.dart';
import '../../../market/presentation/screens/market_screen.dart';
import '../../../market/services/market_service.dart';
import 'add_crop_photo_screen.dart';
import 'crop_photo_history_screen.dart';
import '../../data/models/crop_photo.dart';
import '../../../../core/services/network_service.dart';
import 'dart:io';
import '../../../../features/voice/presentation/widgets/global_listen_button.dart';
import '../../../planner/services/task_storage_service.dart';
import '../../../tasks/services/reminder_storage_service.dart';
import '../../../planner/domain/models/farm_task.dart';
import '../../../tasks/domain/models/farm_reminder.dart';
import '../../data/models/farm_activity.dart';
import '../../data/models/farm_expense.dart';
import '../../data/models/farm_sale.dart';


class CropDetailsScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final StorageService storageService;
  final NetworkService networkService;
  final String cropId;

  const CropDetailsScreen({
    super.key,
    required this.profileStorageService,
    required this.storageService,
    required this.networkService,
    required this.cropId,
  });

  @override
  State<CropDetailsScreen> createState() => _CropDetailsScreenState();
}

class _CropDetailsScreenState extends State<CropDetailsScreen> {
  late final ScannerService _scannerService;
  late final TaskStorageService _taskStorageService;
  late final ReminderStorageService _reminderStorageService;
  
  bool _isLoading = true;
  List<FarmTask> _cropTasks = [];
  List<FarmReminder> _cropReminders = [];
  List<FarmActivity> _cropActivities = [];
  List<FarmExpense> _cropExpenses = [];
  List<FarmSale> _cropSales = [];
  
  @override
  void initState() {
    super.initState();
    _scannerService = ScannerService(apiService: ApiService());
    _initServices();
  }

  Future<void> _initServices() async {
    _taskStorageService = TaskStorageService();
    await _taskStorageService.init();
    _reminderStorageService = ReminderStorageService();
    await _reminderStorageService.init(onNotificationTap: null);
    await _loadCropData();
  }

  Future<void> _loadCropData() async {
    final tasks = await _taskStorageService.getTasks();
    final reminders = await _reminderStorageService.getReminders();
    final activities = widget.profileStorageService.getActivities();
    final expenses = widget.profileStorageService.getExpenses();
    final sales = widget.profileStorageService.getSales();

    setState(() {
      _cropTasks = tasks.where((t) => t.cropId == widget.cropId).toList();
      _cropReminders = reminders.where((r) => r.cropId == widget.cropId).toList();
      _cropActivities = activities.where((a) => a.cropId == widget.cropId).toList();
      _cropExpenses = expenses.where((e) => e.cropId == widget.cropId).toList();
      _cropSales = sales.where((s) => s.cropId == widget.cropId).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return ValueListenableBuilder<List<CropProfile>>(
      valueListenable: widget.profileStorageService.cropsNotifier,
      builder: (context, crops, _) {
        final crop = crops.cast<CropProfile?>().firstWhere(
              (c) => c?.id == widget.cropId,
              orElse: () => null,
            );

        if (crop == null) {
          return Scaffold(
            appBar: AppBar(title: Text(AppLocalizations.of(context).translate('crop_details'))),
            body: const Center(child: Text('Crop not found')),
          );
        }

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text(t.translate('crop_dashboard') == 'crop_dashboard' ? 'Crop Dashboard' : t.translate('crop_dashboard')),
            backgroundColor: Colors.green.shade700,
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => EditCropScreen(
                      profileStorageService: widget.profileStorageService,
                      currentCrop: crop,
                    ),
                  ));
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusBanner(context, crop),
                const SizedBox(height: 16),
                
                GlobalListenButton(
                  storageService: widget.storageService,
                  textBuilder: () {
                    final String name = crop.cropName;
                    final String statusText = AppLocalizations.of(context).translate(crop.status ?? 'growing');
                    final String area = crop.area != null ? 'Area: ${crop.area} ${crop.unit}. ' : '';
                    
                    double totalExpenses = 0.0;
                    for (var e in _cropExpenses) { totalExpenses += e.amount; }
                    double totalIncome = 0.0;
                    for (var s in _cropSales) { totalIncome += s.totalSaleValue; }
                    double netBalance = totalIncome - totalExpenses;
                    String balanceText = netBalance >= 0 ? 'Net balance is positive ${netBalance.toStringAsFixed(0)} rupees.' : 'Net balance is negative ${netBalance.abs().toStringAsFixed(0)} rupees.';

                    return 'Crop Dashboard: $name. Status: $statusText. $area $balanceText You have ${_cropTasks.length} tasks and ${_cropReminders.length} reminders for this crop.';
                  },
                ),
                
                const SizedBox(height: 16),

                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  _buildDashboardSummary(context, crop),

                const SizedBox(height: 24),
                
                _buildInfoSection(
                  context,
                  title: 'Basic Info',
                  icon: Icons.grass,
                  children: [
                    _buildInfoRow(context, 'Area', (crop.area != null && crop.unit != null) ? '${crop.area} ${crop.unit}' : null),
                    _buildInfoRow(context, 'Season', crop.season),
                    _buildInfoRow(context, 'Growth Stage', crop.growthStage != null ? AppLocalizations.of(context).translate(crop.growthStage!) : null),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                _buildInfoSection(
                  context,
                  title: 'Timeline',
                  icon: Icons.timeline,
                  children: [
                    _buildInfoRow(context, AppLocalizations.of(context).translate('planting_date'), _formatDate(crop.plantingDate)),
                    _buildInfoRow(context, AppLocalizations.of(context).translate('expected_harvest_date'), _formatDate(crop.expectedHarvestDate)),
                  ],
                ),

                if (crop.notes != null && crop.notes!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _buildInfoSection(
                    context,
                    title: AppLocalizations.of(context).translate('notes'),
                    icon: Icons.notes,
                    children: [
                      Text(crop.notes!, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
                
                const SizedBox(height: 32),
                
                
                const SizedBox(height: 16),
                
                _buildRelatedRecords(context, crop),
                
                const SizedBox(height: 32),
                
                // Growth Tracking Section
                ValueListenableBuilder<List<CropGrowthUpdate>>(
                  valueListenable: widget.profileStorageService.growthUpdatesNotifier,
                  builder: (context, allUpdates, _) {
                    final updates = allUpdates.where((u) => u.cropId == crop.id).toList()
                      ..sort((a, b) => b.date.compareTo(a.date)); // newest first

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context).translate('growth_tracking'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => AddGrowthUpdateScreen(
                                    profileStorageService: widget.profileStorageService,
                                    cropId: crop.id,
                                  ),
                                ));
                              },
                              icon: const Icon(Icons.add),
                              label: Text(AppLocalizations.of(context).translate('add_growth_update') == 'add_growth_update' ? 'Add Update' : AppLocalizations.of(context).translate('add_growth_update')),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (updates.isEmpty)
                          Card(
                            elevation: 0,
                            color: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Text('🌱', style: TextStyle(fontSize: 32)),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context).translate('no_growth_updates_yet'),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context).translate('add_an_update_to_keep_track'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...updates.map((u) {
                            final stageText = AppLocalizations.of(context).translate(u.growthStage);
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(color: Colors.green.withValues(alpha: 0.2)),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${u.date.day.toString().padLeft(2, '0')}/${u.date.month.toString().padLeft(2, '0')}/${u.date.year}',
                                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(stageText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          if (u.notes != null && u.notes!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text('"${u.notes!}"', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey.shade800)),
                                          ]
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                          onPressed: () {
                                            Navigator.of(context).push(MaterialPageRoute(
                                              builder: (_) => AddGrowthUpdateScreen(
                                                profileStorageService: widget.profileStorageService,
                                                cropId: crop.id,
                                                existingUpdate: u,
                                              ),
                                            ));
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                        const SizedBox(height: 12),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () => _confirmDeleteGrowthUpdate(u.id),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                      ],
                    );
                  },
                ),

                ValueListenableBuilder<List<CropHealthRecord>>(
                  valueListenable: widget.profileStorageService.healthRecordsNotifier,
                  builder: (context, records, _) {
                    final cropRecords = records.where((s) => s.cropId == crop.id).toList();
                    if (cropRecords.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).translate('crop_health_history'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            elevation: 0,
                            color: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Icon(Icons.psychology, size: 40, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context).translate('no_health_checks_yet'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      );
                    }
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).translate('crop_health_history'),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ...cropRecords.map((record) {
                          IconData statusIcon = Icons.visibility;
                          Color statusColor = Colors.orange;
                          if (record.currentStatus == 'Improved') {
                            statusIcon = Icons.thumb_up;
                            statusColor = Colors.green;
                          } else if (record.currentStatus == 'Still Has Problem') {
                            statusIcon = Icons.warning;
                            statusColor = Colors.red;
                          }

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Icon(statusIcon, color: statusColor),
                              title: Text('Scan — ${_formatDate(record.initialScan.date)}'),
                              subtitle: Text(
                                '${AppLocalizations.of(context).translate('status')}: ${AppLocalizations.of(context).translate('status_${record.currentStatus.toLowerCase().replaceAll(' ', '_')}')}',
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => HealthRecordScreen(
                                    healthRecord: record,
                                    storageService: widget.storageService,
                                    profileStorageService: widget.profileStorageService,
                                    scannerService: _scannerService,
                                    networkService: widget.networkService,
                                    cropName: crop.cropName,
                                  ),
                                ));
                              },
                            ),
                          );
                        }),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 32),

                // Crop Photos Section
                ValueListenableBuilder<List<CropPhoto>>(
                  valueListenable: widget.profileStorageService.cropPhotosNotifier,
                  builder: (context, allPhotos, _) {
                    final photos = allPhotos.where((p) => p.cropId == crop.id).toList()
                      ..sort((a, b) => b.date.compareTo(a.date));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context).translate('crop_photos') == 'crop_photos' ? 'Crop Photos' : AppLocalizations.of(context).translate('crop_photos'),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => AddCropPhotoScreen(
                                    profileStorageService: widget.profileStorageService,
                                    cropId: crop.id,
                                  ),
                                ));
                              },
                              icon: const Icon(Icons.add_a_photo, size: 18),
                              label: Text(AppLocalizations.of(context).translate('add_photo') == 'add_photo' ? 'Add Photo' : AppLocalizations.of(context).translate('add_photo')),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (photos.isEmpty)
                          Card(
                            elevation: 0,
                            color: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: [
                                  const Icon(Icons.photo_library_outlined, size: 40, color: Colors.grey),
                                  const SizedBox(height: 8),
                                  Text(
                                    AppLocalizations.of(context).translate('no_photos_yet') == 'no_photos_yet' ? 'No photos yet' : AppLocalizations.of(context).translate('no_photos_yet'),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              SizedBox(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: photos.length > 5 ? 5 : photos.length,
                                  itemBuilder: (context, index) {
                                    final photo = photos[index];
                                    return Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      width: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: FileImage(File(photo.imagePath)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: () {
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (_) => CropPhotoHistoryScreen(
                                        profileStorageService: widget.profileStorageService,
                                        cropId: crop.id,
                                        cropName: crop.cropName,
                                      ),
                                    ));
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: Text(AppLocalizations.of(context).translate('view_photo_history') == 'view_photo_history' ? 'View Photo History' : AppLocalizations.of(context).translate('view_photo_history')),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: Text(
                          AppLocalizations.of(context).translate('scan_this_crop'),
                        ),
                        onPressed: () {
                          ScannerEntryHelper.showScannerOptions(
                            context,
                            storageService: widget.storageService,
                            profileStorageService: widget.profileStorageService,
                            scannerService: _scannerService,
                            networkService: widget.networkService,
                            initialCropContext: crop,
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.smart_toy, color: Colors.white),
                    label: Text(
                      AppLocalizations.of(context).translate('ask_rythumitra_crop'),
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AIAssistantScreen(
                          storageService: widget.storageService,
                          profileStorageService: widget.profileStorageService,
                          networkService: widget.networkService,
                          focusedCrop: crop,
                          autoStartListening: false,
                        ),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.currency_rupee, color: Colors.white),
                    label: Text(
                      AppLocalizations.of(context).translate('check_market_price') == 'check_market_price' ? 'Check Market Price' : AppLocalizations.of(context).translate('check_market_price'),
                      style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => MarketScreen(
                          marketService: MarketService(),
                          profileStorageService: widget.profileStorageService,
                          networkService: widget.networkService,
                          initialCrop: crop.cropName,
                        ),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteGrowthUpdate(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(AppLocalizations.of(context).translate('delete_update_confirm')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).translate('cancel')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);
                await widget.profileStorageService.deleteGrowthUpdate(id);
              },
              child: Text(AppLocalizations.of(context).translate('delete'), style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusBanner(BuildContext context, CropProfile crop) {
    Color bgColor = Colors.grey.shade100;
    Color textColor = Colors.grey.shade800;
    IconData iconData = Icons.info_outline;

    final status = crop.status ?? 'growing';
    final translatedStatus = AppLocalizations.of(context).translate(status);

    if (status == 'growing') {
      bgColor = Colors.green.shade50;
      textColor = Colors.green.shade800;
      iconData = Icons.trending_up;
    } else if (status == 'needs_attention') {
      bgColor = Colors.orange.shade50;
      textColor = Colors.orange.shade800;
      iconData = Icons.warning_amber_rounded;
    } else if (status == 'harvested') {
      bgColor = Colors.blue.shade50;
      textColor = Colors.blue.shade800;
      iconData = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(iconData, color: textColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              translatedStatus,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, {required String title, required IconData icon, required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildDashboardSummary(BuildContext context, CropProfile crop) {
    final t = AppLocalizations.of(context);
    
    double totalExpenses = 0.0;
    for (var e in _cropExpenses) { totalExpenses += e.amount; }
    double totalIncome = 0.0;
    for (var s in _cropSales) { totalIncome += s.totalSaleValue; }
    double netBalance = totalIncome - totalExpenses;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t.translate('dashboard_summary') == 'dashboard_summary' ? 'Dashboard Summary' : t.translate('dashboard_summary'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: netBalance >= 0 ? Colors.green.shade50 : Colors.red.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: netBalance >= 0 ? Colors.green.shade200 : Colors.red.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.translate('dashboard_income') == 'dashboard_income' ? 'Income' : t.translate('dashboard_income'), style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                    Text('₹ ${totalIncome.toStringAsFixed(2)}', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.translate('dashboard_expenses') == 'dashboard_expenses' ? 'Expenses' : t.translate('dashboard_expenses'), style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                    Text('₹ ${totalExpenses.toStringAsFixed(2)}', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t.translate('net_crop_balance') == 'net_crop_balance' ? 'Net Crop Balance' : t.translate('net_crop_balance'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('₹ ${netBalance.toStringAsFixed(2)}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: netBalance >= 0 ? Colors.green.shade700 : Colors.red.shade700)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryIcon(context, Icons.task_alt, _cropTasks.length, t.translate('dashboard_tasks') == 'dashboard_tasks' ? 'Tasks' : t.translate('dashboard_tasks'), Colors.blue),
            _buildSummaryIcon(context, Icons.notifications_active, _cropReminders.length, t.translate('dashboard_reminders') == 'dashboard_reminders' ? 'Reminders' : t.translate('dashboard_reminders'), Colors.orange),
            _buildSummaryIcon(context, Icons.agriculture, _cropActivities.length, t.translate('dashboard_activities') == 'dashboard_activities' ? 'Activities' : t.translate('dashboard_activities'), Colors.purple),
          ],
        )
      ],
    );
  }

  Widget _buildSummaryIcon(BuildContext context, IconData icon, int count, String label, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          radius: 24,
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(count.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ],
    );
  }

  Widget _buildRelatedRecords(BuildContext context, CropProfile crop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSectionHeader(context, 'Tasks', Icons.task_alt, () {
          // Navigate to tasks
        }),
        if (_cropTasks.isEmpty)
          const Text('No tasks for this crop.')
        else
          ..._cropTasks.take(3).map((t) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.task_alt, color: Colors.blue),
            title: Text(t.title),
            subtitle: Text(t.date.toString().split(' ')[0]),
          )),
        const Divider(),
        
        _buildSectionHeader(context, 'Reminders', Icons.notifications, () {
          // Navigate to reminders
        }),
        if (_cropReminders.isEmpty)
          const Text('No reminders for this crop.')
        else
          ..._cropReminders.take(3).map((r) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications, color: Colors.orange),
            title: Text(r.title),
            subtitle: Text(r.date.toString().split(' ')[0]),
          )),
        const Divider(),

        _buildSectionHeader(context, 'Activities', Icons.agriculture, () {
          // Navigate to activities
        }),
        if (_cropActivities.isEmpty)
          const Text('No activities for this crop.')
        else
          ..._cropActivities.take(3).map((a) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.agriculture, color: Colors.purple),
            title: Text(AppLocalizations.of(context).translate(a.activityType)),
            subtitle: Text(a.date.toString().split(' ')[0]),
          )),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.green.shade700),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '-';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
