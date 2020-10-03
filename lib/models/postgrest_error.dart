// To parse this JSON data, do
//
//     final postgrestError = postgrestErrorFromJson(jsonString);

import 'dart:convert';

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

  PostgrestError copyWith({
    String message,
    String details,
    String hint,
    String code,
  }) =>
      PostgrestError(
        message: message ?? this.message,
        details: details ?? this.details,
        hint: hint ?? this.hint,
        code: code ?? this.code,
      );

  factory PostgrestError.fromRawJson(String str) =>
      PostgrestError.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

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
