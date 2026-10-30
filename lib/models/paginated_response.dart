import '../core/json_utils.dart';

/// Page of items from the backend.
///
/// The backend uses two shapes:
/// * `{"page": 1, "size": 10, "total": 3, "<items>": [...]}`
/// * `{"<items>": [...], "pagination": {"page", "size", "total", "total_pages"}}`
/// Both are accepted.
class PaginatedResponse<T> {
  PaginatedResponse({
    required this.page,
    required this.size,
    required this.total,
    required this.items,
  });

  final int page;
  final int size;
  final int total;
  final List<T> items;

  int get totalPages => size <= 0 ? 1 : ((total + size - 1) ~/ size);
  bool get hasNext => page < totalPages;
  bool get hasPrevious => page > 1;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
    String listKey,
  ) {
    final list = asMapList(json[listKey]);
    final pagination = asMap(json['pagination']);
    final source = pagination.isNotEmpty ? pagination : json;

    return PaginatedResponse<T>(
      page: asInt(source['page']) ?? 1,
      size: asInt(source['size']) ?? (list.isEmpty ? 10 : list.length),
      total: asInt(source['total']) ?? list.length,
      items: list.map(fromJsonT).toList(),
    );
  }
}
