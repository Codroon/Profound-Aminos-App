class Address {
  final String? name;
  final String? company;
  final String street1;
  final String? street2;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? phone;
  final String? email;

  const Address({
    this.name,
    this.company,
    required this.street1,
    this.street2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.phone,
    this.email,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      name: json['name'] as String?,
      company: json['company'] as String?,
      street1: json['street1'] as String? ?? json['address1'] as String? ?? '',
      street2: json['street2'] as String? ?? json['address2'] as String?,
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? json['province'] as String? ?? '',
      postalCode: json['postal_code'] as String? ?? json['zip'] as String? ?? '',
      country: json['country'] as String? ?? json['country_code'] as String? ?? '',
      phone: json['phone'] as String?,
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (company != null) 'company': company,
      'street1': street1,
      if (street2 != null) 'street2': street2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
    };
  }

  Address copyWith({
    String? name,
    String? company,
    String? street1,
    String? street2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? phone,
    String? email,
  }) {
    return Address(
      name: name ?? this.name,
      company: company ?? this.company,
      street1: street1 ?? this.street1,
      street2: street2 ?? this.street2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }

  @override
  String toString() {
    return 'Address(name: $name, company: $company, street1: $street1, street2: $street2, city: $city, state: $state, postalCode: $postalCode, country: $country, phone: $phone, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.name == name &&
        other.company == company &&
        other.street1 == street1 &&
        other.street2 == street2 &&
        other.city == city &&
        other.state == state &&
        other.postalCode == postalCode &&
        other.country == country &&
        other.phone == phone &&
        other.email == email;
  }

  @override
  int get hashCode {
    return Object.hash(
      name,
      company,
      street1,
      street2,
      city,
      state,
      postalCode,
      country,
      phone,
      email,
    );
  }
}