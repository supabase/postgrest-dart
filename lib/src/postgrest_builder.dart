import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;

import 'count_option.dart';
import 'postgrest_error.dart';
import 'postgrest_response.dart';

/// The base builder class.
abstract class PostgrestBuilder {
  PostgrestBuilder({
    required this.url,
    required this.headers,
    this.schema,
    this.method,
    this.body,
  });
  dynamic body;
  final List query = [];
  final Map<String, String> headers;
  String? method;
  final String? schema;
  Uri url;

  /// Sends the request and returns a Future.
  /// catch any error and returns with status 500
  ///
  /// [head] to trigger a HEAD request
  ///
  /// [count] if you want to returns the count value. Support exact, planned and estimated count options.
  ///
  /// For more details about switching schemas: https://postgrest.org/en/stable/api.html#switching-schemas
  /// Returns {Future} Resolves when the request has completed.
  Future<PostgrestResponse> execute({
    bool head = false,
    CountOption? count,
  }) async {
    if (head) {
      method = 'HEAD';
    }

    if (count != null) {
      if (headers['Prefer'] == null) {
        headers['Prefer'] = 'count=${count.name()}';
      } else {
        headers['Prefer'] = '${headers['Prefer']!},count=${count.name()}';
      }
    }

    try {
      if (method == null) {
        throw "Missing table operation: select, insert, update or delete";
      }

      final uppercaseMethod = method!.toUpperCase();
      late http.Response response;

      if (schema == null) {
        // skip
      } else if (['GET', 'HEAD'].contains(method)) {
        headers['Accept-Profile'] = schema!;
      } else {
        headers['Content-Profile'] = schema!;
      }
      if (method != 'GET' && method != 'HEAD') {
        headers['Content-Type'] = 'application/json';
      }

      final client = http.Client();
      final bodyStr = json.encode(body);

      if (uppercaseMethod == 'GET') {
        response = await client.get(url, headers: headers);
      } else if (uppercaseMethod == 'POST') {
        response = await client.post(url, headers: headers, body: bodyStr);
      } else if (uppercaseMethod == 'PUT') {
        response = await client.put(url, headers: headers, body: bodyStr);
      } else if (uppercaseMethod == 'PATCH') {
        response = await client.patch(url, headers: headers, body: bodyStr);
      } else if (uppercaseMethod == 'DELETE') {
        response = await client.delete(url, headers: headers);
      } else if (uppercaseMethod == 'HEAD') {
        response = await client.head(url, headers: headers);
      }

      return parseJsonResponse(response);
    } catch (e) {
      final error = PostgrestError(code: e.runtimeType.toString(), message: e.toString());
      return PostgrestResponse(
        status: 500,
        error: error,
      );
    }
  }

  /// Parse request response to json object if possible
  PostgrestResponse parseJsonResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      dynamic body;
      int? count;

      if (response.request!.method != 'HEAD') {
        try {
          body = json.decode(response.body);
        } on FormatException catch (_) {
          body = null;
        }
      }

      final contentRange = response.headers['content-range'];
      if (contentRange != null) {
        count =
            contentRange.split('/').last == '*' ? null : int.parse(contentRange.split('/').last);
      }

      return PostgrestResponse(
        data: body,
        status: response.statusCode,
        count: count,
      );
    } else {
      PostgrestError error;
      if (response.request!.method != 'HEAD') {
        try {
          final Map<String, dynamic> errorJson = json.decode(response.body) as Map<String, dynamic>;
          error = PostgrestError.fromJson(errorJson);
        } catch (_) {
          error = PostgrestError(message: response.body);
        }
      } else {
        error = PostgrestError(
            code: response.statusCode.toString(),
            message: 'Error in Postgrest response for method HEAD');
      }

      return PostgrestResponse(
        status: response.statusCode,
        error: error,
      );
    }
  }

  /// Update Uri queryParameters with new key:value
  void appendSearchParams(String key, String value) {
    final searchParams = Map<String, dynamic>.from(url.queryParameters);
    searchParams[key] = value;
    url = url.replace(queryParameters: searchParams);
  }
}
