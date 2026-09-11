import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/farm_task.dart';
import '../../../profile/data/models/crop_profile.dart';

class FarmTaskCard extends StatelessWidget {
  final FarmTask task;
  final CropProfile? relatedCrop;
  final Function(bool?) onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTaskTap;

  const FarmTaskCard({
    super.key,
    required this.task,
    this.relatedCrop,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(task.date.year, task.date.month, task.date.day);
    
    final isOverdue = !task.isCompleted && taskDate.isBefore(today);
    
    String statusText = t.translate('planner_pending');
    Color statusColor = Colors.blue;
    
    if (task.isCompleted) {
      statusText = t.translate('planner_completed');
      statusColor = Colors.grey;
    } else if (isOverdue) {
      statusText = t.translate('planner_overdue');
      statusColor = Colors.red;
    }

    String timeStr = "";
    if (task.hasTime) {
      timeStr = " ${TimeOfDay.fromDateTime(task.date).format(context)}";
    }
    String dateStr = "${task.date.day}/${task.date.month}/${task.date.year}$timeStr";

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3), width: 1.5),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTaskTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 1.3,
                child: Checkbox(
                  value: task.isCompleted,
                  onChanged: onToggleComplete,
                  activeColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            task.title,
                            style: TextStyle(
                              fontSize: 18,
                              decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                              fontWeight: FontWeight.bold,
                              color: task.isCompleted ? Colors.grey : Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            statusText, 
                            style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ],
                    ),
                    if (relatedCrop != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.grass, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 4),
                          Text(
                            relatedCrop!.cropName, 
                            style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 14)
                          ),
                        ],
                      ),
                    ],
                    if (task.notes != null && task.notes!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        task.notes!, 
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: isOverdue ? Colors.red : Colors.grey.shade700),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: TextStyle(fontSize: 14, color: isOverdue ? Colors.red : Colors.grey.shade700, fontWeight: FontWeight.w500),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue, size: 22),
                          onPressed: onEdit,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 22),
                          onPressed: onDelete,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
