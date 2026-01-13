class Address {
  final int id;
  final String street;
  final String country;
  final String city;
  final String zipCode;

  Address({
    required this.id,
    required this.street,
    required this.country,
    required this.city,
    required this.zipCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id_addresses'] ?? 0,
      street: json['address'] ?? '',
      country: json['country'] ?? '',
      city: json['city'] ?? '',
      zipCode: json['zip_code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_addresses': id, // Correction ici
      'address': street, // Correction ici
      'country': country,
      'city': city,
      'zip_code': zipCode, // Correction ici
    };
  }

  Address copyWith({
    int? id,
    String? street,
    String? country,
    String? city,
    String? zipCode,
  }) {
    return Address(
      id: id ?? this.id,
      street: street ?? this.street,
      country: country ?? this.country,
      city: city ?? this.city,
      zipCode: zipCode ?? this.zipCode,
    );
  }
}