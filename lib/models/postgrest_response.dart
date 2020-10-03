// To parse this JSON data, do
//
//     final postgrestResponse = postgrestResponseFromJson(jsonString);

import 'dart:convert';

import 'package:postgrest/models/postgrest_error.dart';

class PostgrestResponse {
  PostgrestResponse({
    this.body,
    this.status,
    this.statusText,
    this.error,
  });

  dynamic body;
  int status;
  String statusText;
  PostgrestError error;

  PostgrestResponse copyWith({
    dynamic body,
    int status,
    int statusCode,
    String statusText,
    PostgrestError error,
  }) =>
      PostgrestResponse(
        body: body ?? this.body,
        status: status ?? this.status,
        statusText: statusText ?? this.statusText,
        error: error ?? this.error,
      );

  factory PostgrestResponse.fromRawJson(String str) =>
      PostgrestResponse.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory PostgrestResponse.fromJson(Map<String, dynamic> json) =>
      PostgrestResponse(
        body: json['body'],
        status: json['status'],
        statusText: json['statusText'],
        error: json['error'] == null
            ? null
            : PostgrestError.fromJson(json['error']),
      );

  Map<String, dynamic> toJson() => {
        'body': body,
        'status': status,
        'statusText': statusText,
        'error': error == null ? null : error.toJson(),
      };
}
