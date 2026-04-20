class Owner {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String businessHours;
  final String extendedBusinessHours;

  Owner({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.businessHours,
    required this.extendedBusinessHours,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      businessHours: json['business_hours'] ?? '',
      extendedBusinessHours: json['extended_business_hours'] ?? '',
    );
  }
}