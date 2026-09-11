import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/farm_task.dart';
import '../../services/task_storage_service.dart';
import '../../../profile/services/profile_storage_service.dart';
import '../../../profile/data/models/crop_profile.dart';
import 'package:uuid/uuid.dart';

class AddFarmTaskScreen extends StatefulWidget {
  final TaskStorageService taskService;
  final ProfileStorageService? profileStorageService;
  final FarmTask? existingTask;
  final String? initialCropId;

  const AddFarmTaskScreen({
    super.key,
    required this.taskService,
    this.profileStorageService,
    this.existingTask,
    this.initialCropId,
  });

  @override
  State<AddFarmTaskScreen> createState() => _AddFarmTaskScreenState();
}

class _AddFarmTaskScreenState extends State<AddFarmTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _selectedTime;
  String? _selectedCropId;
  List<CropProfile> _crops = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingTask?.title ?? '');
    _notesController = TextEditingController(text: widget.existingTask?.notes ?? '');
    
    if (widget.existingTask != null) {
      _selectedDate = widget.existingTask!.date;
      if (widget.existingTask!.hasTime) {
        _selectedTime = TimeOfDay.fromDateTime(widget.existingTask!.date);
      }
      _selectedCropId = widget.existingTask!.cropId;
    } else if (widget.initialCropId != null) {
      _selectedCropId = widget.initialCropId;
    }
    
    if (widget.profileStorageService != null) {
      _crops = widget.profileStorageService!.getCrops();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.green.shade700,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _saveTask() async {
    if (_formKey.currentState!.validate()) {
      DateTime finalDate = _selectedDate;
      if (_selectedTime != null) {
        finalDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime!.hour,
          _selectedTime!.minute,
        );
      }

      final task = FarmTask(
        id: widget.existingTask?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        date: finalDate,
        hasTime: _selectedTime != null,
        cropId: _selectedCropId,
        notes: _notesController.text.trim(),
        isCompleted: widget.existingTask?.isCompleted ?? false,
        createdAt: widget.existingTask?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await widget.taskService.saveTask(task);
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingTask != null ? t.translate('edit') : t.translate('planner_add_task')),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.translate('planner_task_title'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: t.translate('planner_task_title'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t.translate('enter_title_error');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.translate('date'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.green),
                                const SizedBox(width: 8),
                                Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}"),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.translate('time'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedTime != null 
                                        ? _selectedTime!.format(context) 
                                        : t.translate('add_time'),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              if (_selectedTime != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedTime = null;
                      });
                    },
                    child: Text(t.translate('clear_time'), style: const TextStyle(color: Colors.red)),
                  ),
                )
              else
                const SizedBox(height: 20),
                
              Text(
                t.translate('planner_related_crop'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCropId,
                    hint: Text(t.translate('planner_related_crop')),
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text("None"),
                      ),
                      ..._crops.map((crop) {
                        return DropdownMenuItem<String>(
                          value: crop.id,
                          child: Text(crop.cropName),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCropId = value;
                      });
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              Text(
                t.translate('planner_notes'),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  hintText: t.translate('planner_notes'),
                ),
              ),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveTask,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    t.translate('save'),
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
