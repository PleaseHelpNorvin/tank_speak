import 'gas_station.dart';

class Company {
  final int? id;
  final String name;
  final String address;
  final String phone;
  final String businessHours;
  final String extendedBusinessHours;

  Company({
    this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.businessHours,
    required this.extendedBusinessHours,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'],
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      businessHours: json['business_hours'] ?? '',
      extendedBusinessHours: json['ex_business_hour'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "address": address,
      "phone": phone,
      "business_hours": businessHours,
      "ex_business_hour": extendedBusinessHours,
    };
  }
}

class CompanyDetailResponse {
  final Company company;
  final List<GasStation> stations;


  CompanyDetailResponse({
    required this.company,
    required this.stations,
  });


  factory CompanyDetailResponse.fromJson(Map<String, dynamic> json) {
    return CompanyDetailResponse(
      company: Company.fromJson(json['company']),
      stations: (json['stations'] as List<dynamic>? ?? [])
          .map((e) => GasStation.fromJson(e))
          .toList(),
    );
  }
}

class CreateCompanyResponse {
  final String message;
  final Company company;

  CreateCompanyResponse({
    required this.message,
    required this.company,
  });

  factory CreateCompanyResponse.fromJson(Map<String, dynamic> json) {
    return CreateCompanyResponse(
      message: json['message'] ?? '',
      company: Company.fromJson(json['company']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "message": message,
      "company": company.toJson(),
    };
  }
}