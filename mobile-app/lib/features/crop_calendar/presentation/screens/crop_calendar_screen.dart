import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/services/storage_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../voice/services/text_to_speech_service.dart';
import 'package:mobile_app/features/crop_calendar/domain/models/crop_calendar_model.dart';
import 'package:mobile_app/features/crop_calendar/services/crop_calendar_service.dart';

class CropCalendarScreen extends StatefulWidget {
  final StorageService storageService;
  final ProfileStorageService profileStorageService;

  const CropCalendarScreen({
    super.key,
    required this.storageService,
    required this.profileStorageService,
  });

  @override
  State<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends State<CropCalendarScreen> {
  final CropCalendarService _calendarService = CropCalendarService();
  final TextToSpeechService _ttsService = TextToSpeechService();

  String _selectedCrop = 'paddy';
  DateTime _sowingDate = DateTime.now().subtract(const Duration(days: 35));
  bool _isLoading = true;
  CropCalendarPlan? _plan;
  final Set<String> _completedTaskIds = {};

  final List<Map<String, String>> _availableCrops = [
    {'key': 'paddy', 'name': 'Paddy / వరి', 'icon': '🌾'},
    {'key': 'chilli', 'name': 'Chilli / మిరప', 'icon': '🌶️'},
    {'key': 'cotton', 'name': 'Cotton / ప్రత్తి', 'icon': '☁️'},
    {'key': 'tomato', 'name': 'Tomato / టమోటా', 'icon': '🍅'},
  ];

  @override
  void initState() {
    super.initState();
    _ttsService.init();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_sowingDate);
    final plan = await _calendarService.fetchCropCalendar(
      crop: _selectedCrop,
      sowingDate: dateStr,
    );

    if (mounted) {
      setState(() {
        _plan = plan;
        _isLoading = false;
      });
    }
  }

  void _speakSummary() {
    if (_plan == null) return;
    final speechText = 'Crop Calendar for ${_plan!.cropName}. Current day is ${_plan!.currentDay} of ${_plan!.totalDurationDays} days. Current stage: ${_plan!.currentStage}. Check pending tasks for today.';
    final lang = widget.storageService.getSelectedLanguage() ?? 'en';
    _ttsService.speak(speechText, lang);
  }

  Future<void> _selectSowingDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _sowingDate,
      firstDate: DateTime.now().subtract(const Duration(days: 200)),
      lastDate: DateTime.now(),
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

    if (picked != null && picked != _sowingDate) {
      setState(() => _sowingDate = picked);
      _loadCalendar();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF7),
      appBar: AppBar(
        title: const Text('Smart Crop Calendar & Planner'),
        backgroundColor: Colors.green.shade800,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_outlined),
            tooltip: 'Read Summary',
            onPressed: _speakSummary,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCalendar,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCropSelectorHeader(),
                  const SizedBox(height: 16),
                  if (_plan != null) ...[
                    _buildProgressOverviewCard(_plan!),
                    const SizedBox(height: 20),
                    _buildStagesTimeline(_plan!),
                    const SizedBox(height: 20),
                    _buildSmartTipsCard(_plan!),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCropSelectorHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.eco, color: Colors.green.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Select Crop & Sowing Date',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCrop,
                    decoration: InputDecoration(
                      labelText: 'Crop',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _availableCrops.map((c) {
                      return DropdownMenuItem(
                        value: c['key'],
                        child: Text('${c['icon']} ${c['name']}'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCrop = val);
                        _loadCalendar();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: BorderSide(color: Colors.green.shade600),
                    ),
                    icon: Icon(Icons.calendar_month, color: Colors.green.shade700, size: 20),
                    label: Text(
                      DateFormat('dd MMM yyyy').format(_sowingDate),
                      style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    onPressed: _selectSowingDate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressOverviewCard(CropCalendarPlan plan) {
    final progress = (plan.currentDay / plan.totalDurationDays).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.shade800, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.green.shade900.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.cropName,
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Day ${plan.currentDay} of ${plan.totalDurationDays} Days',
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white38),
                ),
                child: Text(
                  '$percentage% Complete',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.stars, color: Colors.amberAccent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Active Stage: ${plan.currentStage}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStagesTimeline(CropCalendarPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Chronological Crop Stages',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            Text(
              '${_completedTaskIds.length} Done',
              style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...plan.stages.map((stage) => _buildStageCard(stage)),
      ],
    );
  }

  Widget _buildStageCard(CropGrowthStage stage) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(stage.icon, style: const TextStyle(fontSize: 26)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.stageName,
                        style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        stage.dayRange,
                        style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              stage.summary,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.4),
            ),
            const Divider(height: 24),
            const Text(
              'Stage Action Items:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            ...stage.tasks.map((task) => _buildTaskItem(task)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(CropStageTask task) {
    final isDone = _completedTaskIds.contains(task.id);

    return InkWell(
      onTap: () {
        setState(() {
          if (isDone) {
            _completedTaskIds.remove(task.id);
          } else {
            _completedTaskIds.add(task.id);
          }
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: isDone ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDone ? Colors.green.shade300 : Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: isDone,
              activeColor: Colors.green.shade700,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _completedTaskIds.add(task.id);
                  } else {
                    _completedTaskIds.remove(task.id);
                  }
                });
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildCategoryChip(task.category),
                      const SizedBox(width: 6),
                      Text(
                        'Day ${task.dayOffset}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey.shade600 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    task.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDone ? Colors.grey.shade500 : Colors.grey.shade700,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color bg;
    Color fg;
    String label;

    switch (category) {
      case 'fertilizer':
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
        label = 'Fertilizer';
        break;
      case 'irrigation':
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        label = 'Water';
        break;
      case 'pest_control':
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        label = 'Pest Vigil';
        break;
      default:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        label = 'Field Care';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSmartTipsCard(CropCalendarPlan plan) {
    return Card(
      elevation: 2,
      color: Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.amber.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Text(
                  'Expert Agronomy Tips',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...plan.smartTips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Expanded(
                        child: Text(
                          tip,
                          style: TextStyle(fontSize: 13, color: Colors.brown.shade900, height: 1.35),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
