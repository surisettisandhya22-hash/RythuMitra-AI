class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String category;
  final String? notes;
  final bool isQuickAccess;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.category,
    this.notes,
    this.isQuickAccess = false,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      category: json['category'] as String,
      notes: json['notes'] as String?,
      isQuickAccess: json['isQuickAccess'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'category': category,
      'notes': notes,
      'isQuickAccess': isQuickAccess,
    };
  }

  EmergencyContact copyWith({
    String? name,
    String? phoneNumber,
    String? category,
    String? notes,
    bool? isQuickAccess,
  }) {
    return EmergencyContact(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isQuickAccess: isQuickAccess ?? this.isQuickAccess,
    );
  }
}
