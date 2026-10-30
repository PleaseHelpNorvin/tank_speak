/// Error raised by [ApiService] for every failed request.
///
/// [message] is always safe to show to the user: it is either the backend's
/// own `detail` text for client errors (4xx) or a generic sentence. Server
/// stack traces and raw bodies are never exposed.
class ApiException implements Exception {
  ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  /// Field name -> message, filled for 422 validation errors.
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => kind == ApiErrorKind.unauthorized;
  bool get isForbidden => kind == ApiErrorKind.forbidden;
  bool get isNotFound => kind == ApiErrorKind.notFound;
  bool get isNetwork =>
      kind == ApiErrorKind.network || kind == ApiErrorKind.timeout;

  @override
  String toString() => message;

  /// Maps an HTTP status and the decoded body to an [ApiException].
  factory ApiException.fromResponse(int statusCode, Object? body) {
    final detail = _detailText(body);
    final fields = _fieldErrors(body);

    switch (statusCode) {
      case 400:
        return ApiException(
          kind: ApiErrorKind.badRequest,
          statusCode: statusCode,
          message: detail ?? 'The request could not be processed.',
        );
      case 401:
        return ApiException(
          kind: ApiErrorKind.unauthorized,
          statusCode: statusCode,
          message: _sessionMessage(detail),
        );
      case 403:
        return ApiException(
          kind: ApiErrorKind.forbidden,
          statusCode: statusCode,
          message: detail ?? 'You do not have permission to do this.',
        );
      case 404:
        return ApiException(
          kind: ApiErrorKind.notFound,
          statusCode: statusCode,
          message: detail ?? 'The requested item was not found.',
        );
      case 409:
        return ApiException(
          kind: ApiErrorKind.conflict,
          statusCode: statusCode,
          message: detail ?? 'This conflicts with existing data.',
        );
      case 410:
        return ApiException(
          kind: ApiErrorKind.gone,
          statusCode: statusCode,
          message: detail ?? 'This item is no longer available.',
        );
      case 422:
        return ApiException(
          kind: ApiErrorKind.validation,
          statusCode: statusCode,
          fieldErrors: fields,
          message: fields.isNotEmpty
              ? fields.entries
                  .map((e) => '${_humanField(e.key)}: ${e.value}')
                  .join('\n')
              : (detail ?? 'Some fields are missing or invalid.'),
        );
      case 429:
        return ApiException(
          kind: ApiErrorKind.rateLimited,
          statusCode: statusCode,
          message: 'Too many requests. Please wait a moment and try again.',
        );
    }

    if (statusCode >= 500) {
      return ApiException(
        kind: ApiErrorKind.server,
        statusCode: statusCode,
        message: 'The TankSpeak server had a problem. Please try again later.',
      );
    }

    return ApiException(
      kind: ApiErrorKind.unknown,
      statusCode: statusCode,
      message: detail ?? 'Unexpected response from the server ($statusCode).',
    );
  }

  static String _sessionMessage(String? detail) {
    switch (detail) {
      case 'Token expired':
        return 'Your session has expired. Please sign in again.';
      case 'User not found':
        return 'This account is no longer active. Please sign in again.';
      default:
        return 'Your session is no longer valid. Please sign in again.';
    }
  }

  /// FastAPI returns `{"detail": "text"}` for HTTPException and
  /// `{"detail": [{"loc": [...], "msg": "..."}]}` for validation errors.
  static String? _detailText(Object? body) {
    if (body is Map) {
      final detail = body['detail'];
      if (detail is String && detail.trim().isNotEmpty) {
        return _clip(detail.trim());
      }
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) {
          return _clip(first['msg'] as String);
        }
      }
      final msg = body['msg'] ?? body['message'];
      if (msg is String && msg.trim().isNotEmpty) return _clip(msg.trim());
    }
    return null;
  }

  static Map<String, String> _fieldErrors(Object? body) {
    final result = <String, String>{};
    if (body is! Map || body['detail'] is! List) return result;

    for (final item in body['detail'] as List) {
      if (item is! Map) continue;
      final loc = item['loc'];
      final msg = item['msg'];
      if (loc is List && loc.isNotEmpty && msg is String) {
        final field = loc.last.toString();
        result.putIfAbsent(field, () => msg);
      }
    }
    return result;
  }

  static String _humanField(String field) =>
      field.replaceAll('_', ' ').replaceFirstMapped(
            RegExp(r'^[a-z]'),
            (m) => m.group(0)!.toUpperCase(),
          );

  /// Guards against an unexpectedly long server message (e.g. HTML).
  static String _clip(String text) =>
      text.length > 300 ? '${text.substring(0, 300)}…' : text;
}

enum ApiErrorKind {
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  gone,
  validation,
  rateLimited,
  server,
  network,
  timeout,
  invalidResponse,
  configuration,
  unknown,
}
