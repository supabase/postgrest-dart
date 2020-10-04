import 'dart:convert';

PostgrestError postgrestErrorFromJson(String str) => PostgrestError.fromJson(json.decode(str));

/// A Postgrest response error
class PostgrestError {
  PostgrestError({
    this.message,
    this.details,
    this.hint,
    this.code,
  });

  String message;
  String details;
  String hint;
  String code;

  factory PostgrestError.fromJson(Map<String, dynamic> json) => PostgrestError(
        message: json['message'],
        details: json['details'],
        hint: json['hint'],
        code: json['code'],
      );

  Map<String, dynamic> toJson() => {
        'message': message,
        'details': details,
        'hint': hint,
        'code': code,
      };
}
