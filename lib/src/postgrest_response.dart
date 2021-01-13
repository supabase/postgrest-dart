import 'dart:convert';

import 'postgrest_error.dart';

PostgrestResponse postgrestResponseFromJson(String str) =>
    PostgrestResponse.fromJson(json.decode(str) as Map<String, dynamic>);

/// A Postgrest response
class PostgrestResponse {
  PostgrestResponse({
    this.data,
    this.status,
    this.statusText,
    this.error,
  });

  final dynamic data;
  final int status;
  final String statusText;
  final PostgrestError error;

  factory PostgrestResponse.fromJson(Map<String, dynamic> json) => PostgrestResponse(
        data: json['body'],
        status: json['status'] as int,
        statusText: json['statusText'] as String,
        error: json['error'] == null
            ? null
            : PostgrestError.fromJson(json['error'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'data': data,
        'status': status,
        'statusText': statusText,
        'error': error?.toJson(),
      };
}
