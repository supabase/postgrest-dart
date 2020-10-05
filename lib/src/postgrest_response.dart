import 'dart:convert';

import 'postgrest_error.dart';

PostgrestResponse postgrestResponseFromJson(String str) =>
    PostgrestResponse.fromJson(json.decode(str));

/// A Postgrest response
class PostgrestResponse {
  PostgrestResponse({
    this.data,
    this.status,
    this.statusText,
    this.error,
  });

  dynamic data;
  int status;
  String statusText;
  PostgrestError error;

  factory PostgrestResponse.fromJson(Map<String, dynamic> json) => PostgrestResponse(
        data: json['body'],
        status: json['status'],
        statusText: json['statusText'],
        error: json['error'] == null ? null : PostgrestError.fromJson(json['error']),
      );

  Map<String, dynamic> toJson() => {
        'data': data,
        'status': status,
        'statusText': statusText,
        'error': error == null ? null : error.toJson(),
      };
}
