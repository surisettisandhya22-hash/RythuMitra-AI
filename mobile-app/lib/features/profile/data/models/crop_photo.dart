class CropPhoto {
  final String id;
  final String cropId;
  final String imagePath;
  final DateTime date;
  final String? note;
  final DateTime createdAt;

  CropPhoto({
    required this.id,
    required this.cropId,
    required this.imagePath,
    required this.date,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cropId': cropId,
      'imagePath': imagePath,
      'date': date.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CropPhoto.fromJson(Map<String, dynamic> json) {
    return CropPhoto(
      id: json['id'] as String,
      cropId: json['cropId'] as String,
      imagePath: json['imagePath'] as String,
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  CropPhoto copyWith({
    String? id,
    String? cropId,
    String? imagePath,
    DateTime? date,
    String? note,
    DateTime? createdAt,
  }) {
    return CropPhoto(
      id: id ?? this.id,
      cropId: cropId ?? this.cropId,
      imagePath: imagePath ?? this.imagePath,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
