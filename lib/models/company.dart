import '../core/json_utils.dart';
import 'gas_station.dart';

class Company {
  Company({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.businessHours,
    this.extendedBusinessHours,
  });

  final int id;
  final String name;
  final String address;
  final String phone;
  final String businessHours;
  final String? extendedBusinessHours;

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      address: asString(json['address']) ?? '',
      phone: asString(json['phone']) ?? '',
      businessHours: asString(json['business_hours']) ?? '',
      extendedBusinessHours: asText(json['extended_business_hours']),
    );
  }
}

class ContactPerson {
  ContactPerson({
    required this.id,
    required this.name,
    this.position,
    this.phone,
    this.email,
  });

  final int id;
  final String name;
  final String? position;
  final String? phone;
  final String? email;

  factory ContactPerson.fromJson(Map<String, dynamic> json) {
    return ContactPerson(
      id: asInt(json['id']) ?? 0,
      name: asString(json['name']) ?? '',
      position: asText(json['position']),
      phone: asText(json['phone']),
      email: asText(json['email']),
    );
  }
}

/// `GET /api/company/c/{company_id}`.
///
/// `stations` is already scoped by the backend: company owners see every
/// station, station-level members only their own.
class CompanyDetailResponse {
  CompanyDetailResponse({
    required this.company,
    required this.stations,
    required this.contacts,
  });

  final Company company;
  final List<GasStation> stations;
  final List<ContactPerson> contacts;

  factory CompanyDetailResponse.fromJson(Map<String, dynamic> json) {
    return CompanyDetailResponse(
      company: Company.fromJson(asMap(json['company'])),
      stations: asMapList(json['stations']).map(GasStation.fromJson).toList(),
      contacts:
          asMapList(json['contacts']).map(ContactPerson.fromJson).toList(),
    );
  }
}

/// `POST /api/company/create` response.
class CreateCompanyResponse {
  CreateCompanyResponse({required this.message, required this.company});

  final String message;
  final Company company;

  factory CreateCompanyResponse.fromJson(Map<String, dynamic> json) {
    return CreateCompanyResponse(
      message: asString(json['message']) ?? 'Company created',
      company: Company.fromJson(asMap(json['company'])),
    );
  }
}
