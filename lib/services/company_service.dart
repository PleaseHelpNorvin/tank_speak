import '../core/json_utils.dart';
import '../models/company.dart';
import '../models/member.dart';
import '../models/paginated_response.dart';
import 'api_service.dart';

/// `/api/company/*`.
class CompanyService {
  CompanyService([ApiService? api]) : _api = api ?? ApiService.instance;

  final ApiService _api;

  /// Companies the user belongs to (any membership level).
  Future<PaginatedResponse<Company>> fetchCompanies({
    int page = 1,
    int size = 10,
    String search = '',
  }) async {
    final body = asMap(await _api.get('/company', query: {
      'page': page,
      'size': size,
      'search': search.trim(),
    }));
    return PaginatedResponse<Company>.fromJson(
        body, Company.fromJson, 'companies');
  }

  /// Throws 403 when the user has no membership in the company.
  Future<CompanyDetailResponse?> getCompany(int companyId) async {
    final body = await _api.get('/company/c/$companyId');
    // The backend returns JSON null (200) for a missing/deleted company.
    if (body == null) return null;
    return CompanyDetailResponse.fromJson(asMap(body));
  }

  /// Membership rows of a company (one row per company/station membership).
  Future<PaginatedResponse<CompanyMember>> fetchCompanyMembers(
    int companyId, {
    int page = 1,
    int size = 100,
  }) async {
    final body = asMap(await _api.get(
      '/company/$companyId/company-members',
      query: {'page': page, 'size': size},
    ));
    return PaginatedResponse<CompanyMember>.fromJson(
        body, CompanyMember.fromJson, 'members');
  }

  /// Any signed-in user may create a company and becomes its owner.
  Future<CreateCompanyResponse> createCompany({
    required String name,
    required String address,
    required String phone,
    required String businessHours,
    String? extendedBusinessHours,
  }) async {
    final body = asMap(await _api.post('/company/create', body: {
      'name': name.trim(),
      'address': address.trim(),
      'phone': phone.trim(),
      'business_hours': businessHours.trim(),
      'ex_business_hour': (extendedBusinessHours?.trim().isEmpty ?? true)
          ? null
          : extendedBusinessHours!.trim(),
    }));
    return CreateCompanyResponse.fromJson(body);
  }
}
