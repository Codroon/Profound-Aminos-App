class ShippingRate {
  final String id;
  final String carrierId;
  final String carrierName;
  final String serviceName;
  final String serviceCode;
  final double rate;
  final String currency;
  final int? transitDays;
  final DateTime? deliveryDate;
  final bool isResidential;
  final Map<String, dynamic>? metadata;
  final List<String>? features;

  const ShippingRate({
    required this.id,
    required this.carrierId,
    required this.carrierName,
    required this.serviceName,
    required this.serviceCode,
    required this.rate,
    this.currency = 'USD',
    this.transitDays,
    this.deliveryDate,
    this.isResidential = false,
    this.metadata,
    this.features,
  });

  factory ShippingRate.fromJson(Map<String, dynamic> json) {
    return ShippingRate(
      id: json['id'] as String? ?? '',
      carrierId: json['carrier_id'] as String? ?? json['carrier']['id'] as String? ?? '',
      carrierName: json['carrier_name'] as String? ?? json['carrier']['name'] as String? ?? '',
      serviceName: json['service_name'] as String? ?? json['service']['name'] as String? ?? '',
      serviceCode: json['service_code'] as String? ?? json['service']['code'] as String? ?? '',
      rate: (json['rate'] as num?)?.toDouble() ?? (json['amount'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      transitDays: json['transit_days'] as int? ?? json['estimated_days'] as int?,
      deliveryDate: json['delivery_date'] != null 
          ? DateTime.tryParse(json['delivery_date'] as String)
          : null,
      isResidential: json['is_residential'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      features: (json['features'] as List<dynamic>?)?.cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'carrier_id': carrierId,
      'carrier_name': carrierName,
      'service_name': serviceName,
      'service_code': serviceCode,
      'rate': rate,
      'currency': currency,
      if (transitDays != null) 'transit_days': transitDays,
      if (deliveryDate != null) 'delivery_date': deliveryDate!.toIso8601String(),
      'is_residential': isResidential,
      if (metadata != null) 'metadata': metadata,
      if (features != null) 'features': features,
    };
  }

  ShippingRate copyWith({
    String? id,
    String? carrierId,
    String? carrierName,
    String? serviceName,
    String? serviceCode,
    double? rate,
    String? currency,
    int? transitDays,
    DateTime? deliveryDate,
    bool? isResidential,
    Map<String, dynamic>? metadata,
    List<String>? features,
  }) {
    return ShippingRate(
      id: id ?? this.id,
      carrierId: carrierId ?? this.carrierId,
      carrierName: carrierName ?? this.carrierName,
      serviceName: serviceName ?? this.serviceName,
      serviceCode: serviceCode ?? this.serviceCode,
      rate: rate ?? this.rate,
      currency: currency ?? this.currency,
      transitDays: transitDays ?? this.transitDays,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      isResidential: isResidential ?? this.isResidential,
      metadata: metadata ?? this.metadata,
      features: features ?? this.features,
    );
  }

  String get formattedRate => '\$${rate.toStringAsFixed(2)}';
  
  // Getter for backward compatibility
  String get carrier => carrierName;
  
  String get estimatedDelivery {
    if (deliveryDate != null) {
      return '${deliveryDate!.day}/${deliveryDate!.month}/${deliveryDate!.year}';
    } else if (transitDays != null) {
      return '$transitDays business days';
    }
    return 'N/A';
  }

  @override
  String toString() {
    return 'ShippingRate(id: $id, carrierId: $carrierId, carrierName: $carrierName, serviceName: $serviceName, serviceCode: $serviceCode, rate: $rate, currency: $currency, transitDays: $transitDays, deliveryDate: $deliveryDate, isResidential: $isResidential)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ShippingRate &&
        other.id == id &&
        other.carrierId == carrierId &&
        other.carrierName == carrierName &&
        other.serviceName == serviceName &&
        other.serviceCode == serviceCode &&
        other.rate == rate &&
        other.currency == currency &&
        other.transitDays == transitDays &&
        other.deliveryDate == deliveryDate &&
        other.isResidential == isResidential;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      carrierId,
      carrierName,
      serviceName,
      serviceCode,
      rate,
      currency,
      transitDays,
      deliveryDate,
      isResidential,
    );
  }
}