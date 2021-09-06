/// A Postgrest response error
class PostgrestError {
  PostgrestError({
    required this.message,
    this.code,
    this.details,
    this.hint,
  });

  final String message;
  final String? code;
  final dynamic details;
  final String? hint;

  factory PostgrestError.fromJson(Map<String, dynamic> json) => PostgrestError(
        message: json['message'] as String,
        code: json['code'] as String?,
        details: json['details'] as dynamic,
        hint: json['hint'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'message': message,
        'code': code,
        'details': details,
        'hint': hint,
      };

  @override
  String toString() {
    return 'PostgrestError(message: $message, '
        'code: $code, details: ${details?.toString()}, hint: $hint)';
  }
}
