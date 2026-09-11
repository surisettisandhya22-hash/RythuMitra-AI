class FarmerProfile {
  final String name;
  final String? phoneNumber;
  final String location;
  final String? village;
  final String? district;
  final String? state;
  final String? country;
  final String preferredLanguage;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String syncStatus;

  FarmerProfile({
    required this.name,
    this.phoneNumber,
    required this.location,
    this.village,
    this.district,
    this.state,
    this.country,
    required this.preferredLanguage,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.syncStatus = 'local',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phoneNumber': phoneNumber,
      'location': location,
      'village': village,
      'district': district,
      'state': state,
      'country': country,
      'preferredLanguage': preferredLanguage,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'syncStatus': syncStatus,
    };
  }

  factory FarmerProfile.fromJson(Map<String, dynamic> json) {
    return FarmerProfile(
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String?,
      location: json['location'] as String,
      village: json['village'] as String?,
      district: json['district'] as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
      preferredLanguage: json['preferredLanguage'] as String,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      syncStatus: json['syncStatus'] as String? ?? 'local',
    );
  }

  FarmerProfile copyWith({
    String? name,
    String? phoneNumber,
    String? location,
    String? village,
    String? district,
    String? state,
    String? country,
    String? preferredLanguage,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
  }) {
    return FarmerProfile(
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      location: location ?? this.location,
      village: village ?? this.village,
      district: district ?? this.district,
      state: state ?? this.state,
      country: country ?? this.country,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
