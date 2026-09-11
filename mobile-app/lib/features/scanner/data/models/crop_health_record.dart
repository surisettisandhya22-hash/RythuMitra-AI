import 'scan_result.dart';

class FollowUpRecord {
  final String id;
  final String date;
  final String statusUpdate;
  final String? note;
  final String? imagePath;
  final ScanResult? newScanResult;

  FollowUpRecord({
    required this.id,
    required this.date,
    required this.statusUpdate,
    this.note,
    this.imagePath,
    this.newScanResult,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'statusUpdate': statusUpdate,
      'note': note,
      'imagePath': imagePath,
      'newScanResult': newScanResult?.toJson(),
    };
  }

  factory FollowUpRecord.fromJson(Map<String, dynamic> json) {
    return FollowUpRecord(
      id: json['id'] as String,
      date: json['date'] as String,
      statusUpdate: json['statusUpdate'] as String,
      note: json['note'] as String?,
      imagePath: json['imagePath'] as String?,
      newScanResult: json['newScanResult'] != null
          ? ScanResult.fromJson(json['newScanResult'])
          : null,
    );
  }
}

class CropHealthRecord {
  final String id;
  final String? cropId;
  final ScanResult initialScan;
  String currentStatus;
  List<FollowUpRecord> followUps;
  final String createdAt;
  String updatedAt;
  final String syncStatus;

  CropHealthRecord({
    required this.id,
    this.cropId,
    required this.initialScan,
    required this.currentStatus,
    this.followUps = const [],
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 'local',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropId': cropId,
      'initialScan': initialScan.toJson(),
      'currentStatus': currentStatus,
      'followUps': followUps.map((f) => f.toJson()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'syncStatus': syncStatus,
    };
  }

  factory CropHealthRecord.fromJson(Map<String, dynamic> json) {
    return CropHealthRecord(
      id: json['id'] as String,
      cropId: json['cropId'] as String?,
      initialScan: ScanResult.fromJson(json['initialScan']),
      currentStatus: json['currentStatus'] as String,
      followUps: (json['followUps'] as List<dynamic>?)
              ?.map((f) => FollowUpRecord.fromJson(f))
              .toList() ??
          [],
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      syncStatus: json['syncStatus'] as String? ?? 'local',
    );
  }
}
