import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../tasks/services/reminder_storage_service.dart';

import '../widgets/crop_report_view.dart';
import '../widgets/financial_report_view.dart';
import '../widgets/activity_report_view.dart';
import '../../../../core/services/storage_service.dart';

class FarmReportsScreen extends StatefulWidget {
  final ProfileStorageService profileStorageService;
  final ReminderStorageService reminderStorageService;
  final StorageService storageService;

  const FarmReportsScreen({
    super.key,
    required this.profileStorageService,
    required this.reminderStorageService,
    required this.storageService,
  });

  @override
  State<FarmReportsScreen> createState() => _FarmReportsScreenState();
}

class _FarmReportsScreenState extends State<FarmReportsScreen> {
  int _selectedTabIndex = 0;
  String _selectedDateFilter = 'all_time';
  DateTime? _fromDate;
  DateTime? _toDate;

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      if (picked.start.isAfter(picked.end)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('From Date must not be after To Date.')),
        );
        return;
      }
      setState(() {
        _selectedDateFilter = 'custom_date_range';
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    } else {
      // Revert if cancelled
      if (_selectedDateFilter == 'custom_date_range' && _fromDate == null) {
        setState(() {
          _selectedDateFilter = 'all_time';
        });
      }
    }
  }

  void _onDateFilterChanged(String? filter) {
    if (filter == null) return;
    
    if (filter == 'custom_date_range') {
      _selectDateRange();
      return;
    }

    setState(() {
      _selectedDateFilter = filter;
      final now = DateTime.now();
      if (filter == 'all_time') {
        _fromDate = null;
        _toDate = null;
      } else if (filter == 'this_month') {
        _fromDate = DateTime(now.year, now.month, 1);
        _toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else if (filter == 'last_month') {
        _fromDate = DateTime(now.year, now.month - 1, 1);
        _toDate = DateTime(now.year, now.month, 0, 23, 59, 59);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    Widget reportView;
    if (_selectedTabIndex == 0) {
      reportView = CropReportView(profileStorageService: widget.profileStorageService);
    } else if (_selectedTabIndex == 1) {
      reportView = FinancialReportView(
        profileStorageService: widget.profileStorageService,
        storageService: widget.storageService,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    } else {
      reportView = ActivityReportView(
        profileStorageService: widget.profileStorageService,
        reminderStorageService: widget.reminderStorageService,
        fromDate: _fromDate,
        toDate: _toDate,
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(t.translate('farm_reports') == 'farm_reports' ? 'Farm Reports' : t.translate('farm_reports')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildTab(0, t.translate('crop_report') == 'crop_report' ? 'Crop Report' : t.translate('crop_report')),
                      _buildTab(1, t.translate('financial_report') == 'financial_report' ? 'Financial Report' : t.translate('financial_report')),
                      _buildTab(2, t.translate('activity_report') == 'activity_report' ? 'Activity Report' : t.translate('activity_report')),
                    ],
                  ),
                  if (_selectedTabIndex != 0) // Hide filter for crop report as per prompt implicit behavior (crops are just totals)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedDateFilter,
                            isExpanded: true,
                            items: [
                              DropdownMenuItem(value: 'all_time', child: Text(t.translate('all_time') == 'all_time' ? 'All Time' : t.translate('all_time'))),
                              DropdownMenuItem(value: 'this_month', child: Text(t.translate('this_month') == 'this_month' ? 'This Month' : t.translate('this_month'))),
                              DropdownMenuItem(value: 'last_month', child: Text(t.translate('last_month') == 'last_month' ? 'Last Month' : t.translate('last_month'))),
                              DropdownMenuItem(value: 'custom_date_range', child: Text(t.translate('custom_date_range') == 'custom_date_range' ? 'Custom Date Range' : t.translate('custom_date_range'))),
                            ],
                            onChanged: _onDateFilterChanged,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: reportView,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Fallback voice feature just reads out generic for now since it triggers AI globally normally
        },
        backgroundColor: Colors.green.shade700,
        child: const Icon(Icons.mic, color: Colors.white),
      ),
    );
  }

  Widget _buildTab(int index, String title) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.green.shade700 : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.green.shade900 : Colors.grey.shade600,
            ),
          ),
        ),
      ),
    );
  }
}
