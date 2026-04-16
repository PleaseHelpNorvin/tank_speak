class AreaManager {
  final String id;
  final String name;
  final String contactInfo;
  final String companyName;

  AreaManager({
    required this.id,
    required this.name,
    required this.contactInfo,
    required this.companyName,
  });

  factory AreaManager.fromJson(Map<String, dynamic> json) {
    return AreaManager(
      id: json['id'],
      name: json['name'],
      contactInfo: json['contact_info'],
      companyName: json['company_name'],
    );
  }
}