class AreaManager {
  final int id;
  final String name;
  final String phone;
  final String address;
  final String businessHours;
  final String extendedBusinessHours;

  AreaManager({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
    required this.businessHours,
    required this.extendedBusinessHours,
  });

  factory AreaManager.fromJson(Map<String, dynamic> json) {
    return AreaManager(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      businessHours: json['business_hours'] ?? '',
      extendedBusinessHours: json['extended_business_hours'] ?? '',
    );
  }
}