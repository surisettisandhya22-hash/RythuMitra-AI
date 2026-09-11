class FarmProfile {
  final String? farmName;
  final String? location;
  final double landSize;
  final String landUnit;
  final List<String> farmTypes;
  final String? irrigationType;

  FarmProfile({
    this.farmName,
    this.location,
    required this.landSize,
    required this.landUnit,
    required this.farmTypes,
    this.irrigationType,
  });

  Map<String, dynamic> toJson() {
    return {
      'farmName': farmName,
      'location': location,
      'landSize': landSize,
      'landUnit': landUnit,
      'farmTypes': farmTypes,
      'irrigationType': irrigationType,
    };
  }

  factory FarmProfile.fromJson(Map<String, dynamic> json) {
    return FarmProfile(
      farmName: json['farmName'] as String?,
      location: json['location'] as String?,
      landSize: (json['landSize'] as num).toDouble(),
      landUnit: json['landUnit'] as String,
      farmTypes: List<String>.from(json['farmTypes'] ?? []),
      irrigationType: json['irrigationType'] as String?,
    );
  }

  FarmProfile copyWith({
    String? farmName,
    String? location,
    double? landSize,
    String? landUnit,
    List<String>? farmTypes,
    String? irrigationType,
  }) {
    return FarmProfile(
      farmName: farmName ?? this.farmName,
      location: location ?? this.location,
      landSize: landSize ?? this.landSize,
      landUnit: landUnit ?? this.landUnit,
      farmTypes: farmTypes ?? this.farmTypes,
      irrigationType: irrigationType ?? this.irrigationType,
    );
  }
}
