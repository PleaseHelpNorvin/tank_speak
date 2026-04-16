class Owner {
  final String id;
  final String name;
  final String contactInfo;

  Owner({
    required this.id,
    required this.name,
    required this.contactInfo,
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'],
      name: json['name'],
      contactInfo: json['contact_info'],
    );
  }
}