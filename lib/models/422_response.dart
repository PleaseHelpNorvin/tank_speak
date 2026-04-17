class ValidationErrorResponse {
  final List<ValidationErrorDetail> detail;

  ValidationErrorResponse({required this.detail});

  factory ValidationErrorResponse.fromJson(Map<String, dynamic> json) {
    return ValidationErrorResponse(
      detail: (json['detail'] as List)
          .map((e) => ValidationErrorDetail.fromJson(e))
          .toList(),
    );
  }
}

class ValidationErrorDetail {
  final List<dynamic> loc;
  final String msg;
  final String type;
  final dynamic input;
  final Map<String, dynamic> ctx;

  ValidationErrorDetail({
    required this.loc,
    required this.msg,
    required this.type,
    required this.input,
    required this.ctx,
  });

  factory ValidationErrorDetail.fromJson(Map<String, dynamic> json) {
    return ValidationErrorDetail(
      loc: json['loc'] ?? [],
      msg: json['msg'] ?? '',
      type: json['type'] ?? '',
      input: json['input'],
      ctx: json['ctx'] ?? {},
    );
  }
}