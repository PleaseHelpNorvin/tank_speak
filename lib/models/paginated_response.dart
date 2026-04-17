class PaginatedResponse<T> {
  final int page;
  final int size;
  final int total;
  final List<T> items;

  PaginatedResponse({
    required this.page,
    required this.size,
    required this.total,
    required this.items,
  });

  factory PaginatedResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      String listKey,
      ) {
    final raw = json[listKey];

    final List list;

    if (raw == null) {
      list = [];
    }
    else if (raw is List) {
      list = raw;
    }
    else {
      throw Exception(
          "Expected '$listKey' to be a List but got ${raw.runtimeType}"
      );
    }

    return PaginatedResponse<T>(
      page: json['page'] ?? 1,
      size: json['size'] ?? 10,
      total: json['total'] ?? list.length,

      items: list
          .whereType<Map<String, dynamic>>()
          .map((e) => fromJsonT(e))
          .toList(),
    );
  }
}