import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;

import 'count_option.dart';
import 'postgrest_error.dart';
import 'postgrest_response.dart';

typedef PostgrestConverter<T> = T Function(dynamic data);

/// The base builder class.
class PostgrestBuilder<T> {
  PostgrestBuilder({
    required this.url,
    required this.headers,
    this.schema,
    this.method,
    this.body,
  });

  dynamic body;
  final Map<String, String> headers;
  bool maybeEmpty = false;
  String? method;
  final String? schema;
  Uri url;
  PostgrestConverter? _converter;

  /// Converts any response that comes from the server into a type-safe response.
  ///
  /// ```dart
  /// postgrest.from('users').select().withConverter((data) => User.fromJson(json.decode(data))).execute();
  /// ```
  PostgrestBuilder<S> withConverter<S>(PostgrestConverter<S> converter) {
    _converter = converter;
    return PostgrestBuilder<S>(
      url: url,
      headers: headers,
      schema: schema,
      method: method,
      body: body,
    )
      ..maybeEmpty = maybeEmpty
      .._converter = converter;
  }

  /// Sends the request and returns a Future.
  /// catch any error and returns with status 500
  ///
  /// [head] to trigger a HEAD request
  ///
  /// [count] if you want to returns the count value. Support exact, planned and estimated count options.
  ///
  /// For more details about switching schemas: https://postgrest.org/en/stable/api.html#switching-schemas
  /// Returns {Future} Resolves when the request has completed.
  Future<PostgrestResponse<T>> execute({
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

      final bodyStr = json.encode(body);

      if (uppercaseMethod == 'GET') {
        response = await http.get(url, headers: headers);
      } else if (uppercaseMethod == 'POST') {
        response = await http.post(url, headers: headers, body: bodyStr);
      } else if (uppercaseMethod == 'PUT') {
        response = await http.put(url, headers: headers, body: bodyStr);
      } else if (uppercaseMethod == 'PATCH') {
        response = await http.patch(url, headers: headers, body: bodyStr);
      } else if (uppercaseMethod == 'DELETE') {
        response = await http.delete(url, headers: headers);
      } else if (uppercaseMethod == 'HEAD') {
        response = await http.head(url, headers: headers);
      }

      return _parseResponse(response);
    } catch (e) {
      final error =
          PostgrestError(code: e.runtimeType.toString(), message: e.toString());
      return PostgrestResponse(
        status: 500,
        error: error,
      );
    }
  }

  /// Parse request response to json object if possible
  PostgrestResponse<T> _parseResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode <= 299) {
      dynamic body;
      int? count;

      if (response.request!.method != 'HEAD') {
        if (response.request!.headers['Accept'] == 'text/csv') {
          body = response.body;
        } else {
          try {
            body = json.decode(response.body);
          } on FormatException catch (_) {
            body = null;
          }
        }
      }

      final contentRange = response.headers['content-range'];
      if (contentRange != null) {
        count = contentRange.split('/').last == '*'
            ? null
            : int.parse(contentRange.split('/').last);
      }

      if (_converter != null) {
        body = _converter!(body);
      }

      return PostgrestResponse<T>(
        data: body as T,
        status: response.statusCode,
        count: count,
      );
    } else {
      PostgrestError error;
      if (response.request!.method != 'HEAD') {
        try {
          final Map<String, dynamic> errorJson =
              json.decode(response.body) as Map<String, dynamic>;
          error = PostgrestError.fromJson(errorJson);

          if (maybeEmpty) {
            return _handleMaybeEmptyError(response, error);
          }
        } catch (_) {
          error = PostgrestError(message: response.body);
        }
      } else {
        error = PostgrestError(
          code: response.statusCode.toString(),
          message: 'Error in Postgrest response for method HEAD',
        );
      }

      return PostgrestResponse(
        status: response.statusCode,
        error: error,
      );
    }
  }

  /// on maybeEmpty enable, check for error details contains
  /// 'Results contain 0 rows' then
  /// return PostgrestResponse with null data
  PostgrestResponse<T> _handleMaybeEmptyError(
    http.Response response,
    PostgrestError error,
  ) {
    if (error.details is String &&
        error.details.toString().contains('Results contain 0 rows')) {
      return const PostgrestResponse(
        status: 200,
        count: 0,
      );
    } else {
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
