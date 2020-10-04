/// To parse this JSON data, do
///
///     final postgrestResponse = postgrestResponseFromJson(jsonString);

import 'dart:convert';

import 'package:postgrest/models/postgrest_error.dart';

PostgrestResponse postgrestResponseFromJson(String str) => PostgrestResponse.fromJson(json.decode(str));

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
