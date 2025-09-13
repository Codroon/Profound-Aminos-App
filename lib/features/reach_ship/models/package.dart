class Package {
  final double length;
  final double width;
  final double height;
  final double weight;
  final String? description;
  final double? declaredValue;
  final String weightUnit;
  final String dimensionUnit;

  const Package({
    required this.length,
    required this.width,
    required this.height,
    required this.weight,
    this.description,
    this.declaredValue,
    this.weightUnit = 'lb',
    this.dimensionUnit = 'in',
  });

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      length: (json['length'] as num?)?.toDouble() ?? 0.0,
      width: (json['width'] as num?)?.toDouble() ?? 0.0,
      height: (json['height'] as num?)?.toDouble() ?? 0.0,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      description: json['description'] as String?,
      declaredValue: (json['declared_value'] as num?)?.toDouble(),
      weightUnit: json['weight_unit'] as String? ?? 'lb',
      dimensionUnit: json['dimension_unit'] as String? ?? 'in',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'length': length,
      'width': width,
      'height': height,
      'weight': weight,
      if (description != null) 'description': description,
      if (declaredValue != null) 'declared_value': declaredValue,
      'weight_unit': weightUnit,
      'dimension_unit': dimensionUnit,
    };
  }

  Package copyWith({
    double? length,
    double? width,
    double? height,
    double? weight,
    String? description,
    double? declaredValue,
    String? weightUnit,
    String? dimensionUnit,
  }) {
    return Package(
      length: length ?? this.length,
      width: width ?? this.width,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      description: description ?? this.description,
      declaredValue: declaredValue ?? this.declaredValue,
      weightUnit: weightUnit ?? this.weightUnit,
      dimensionUnit: dimensionUnit ?? this.dimensionUnit,
    );
  }

  @override
  String toString() {
    return 'Package(length: $length, width: $width, height: $height, weight: $weight, description: $description, declaredValue: $declaredValue, weightUnit: $weightUnit, dimensionUnit: $dimensionUnit)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Package &&
        other.length == length &&
        other.width == width &&
        other.height == height &&
        other.weight == weight &&
        other.description == description &&
        other.declaredValue == declaredValue &&
        other.weightUnit == weightUnit &&
        other.dimensionUnit == dimensionUnit;
  }

  @override
  int get hashCode {
    return Object.hash(
      length,
      width,
      height,
      weight,
      description,
      declaredValue,
      weightUnit,
      dimensionUnit,
    );
  }
}