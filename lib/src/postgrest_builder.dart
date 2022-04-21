import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:postgrest/src/count_option.dart';
import 'package:postgrest/src/postgrest_error.dart';
import 'package:postgrest/src/postgrest_response.dart';

typedef PostgrestConverter<T> = T Function(dynamic data);

/// The base builder class.
class PostgrestBuilder<T> implements Future<T> {
  dynamic body;
  final Map<String, String> headers;
  bool maybeEmpty = false;
  String? method;
  final String? schema;
  Uri url;
  PostgrestConverter? _converter;
  final Client? httpClient;

  PostgrestBuilder({
    required this.url,
    required this.headers,
    this.schema,
    this.method,
    this.body,
    this.httpClient,
  });

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
        response = await (httpClient?.get ?? http.get)(
          url,
          headers: headers,
        );
      } else if (uppercaseMethod == 'POST') {
        response = await (httpClient?.post ?? http.post)(
          url,
          headers: headers,
          body: bodyStr,
        );
      } else if (uppercaseMethod == 'PUT') {
        response = await (httpClient?.put ?? http.put)(
          url,
          headers: headers,
          body: bodyStr,
        );
      } else if (uppercaseMethod == 'PATCH') {
        response = await (httpClient?.patch ?? http.patch)(
          url,
          headers: headers,
          body: bodyStr,
        );
      } else if (uppercaseMethod == 'DELETE') {
        response = await (httpClient?.delete ?? http.delete)(
          url,
          headers: headers,
        );
      } else if (uppercaseMethod == 'HEAD') {
        response = await (httpClient?.head ?? http.head)(
          url,
          headers: headers,
        );
      }

      return _parseResponse(response);
    } catch (error) {
      throw PostgrestError(
        code: '${error.runtimeType}',
        message: '$error',
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
          final errorJson = json.decode(response.body) as Map<String, dynamic>;
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

      throw error;
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
      return PostgrestResponse<T>(
        data: null,
        status: 200,
        count: 0,
      );
    } else {
      throw error;
    }
  }

  /// Update Uri queryParameters with new key:value
  /// Use lists to allow multiple values for the same key
  void appendSearchParams(String key, String value) {
    final searchParams = Map<String, dynamic>.from(url.queryParametersAll);
    searchParams[key] = [...searchParams[key] ?? [], value];
    url = url.replace(queryParameters: searchParams);
  }

  /// Overrides Uri queryParameters with new key:value
  void overrideSearchParams(String key, String value) {
    final searchParams = Map<String, dynamic>.from(url.queryParametersAll);
    searchParams[key] = value;
    url = url.replace(queryParameters: searchParams);
  }

  @override
  Stream<T> asStream() {
    final controller = StreamController<T>.broadcast();

    then((value) {
      controller.add(value);
    }).catchError((Object error, StackTrace stack) {
      controller.addError(error, stack);
    }).whenComplete(() {
      controller.close();
    });

    return controller.stream;
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    throw UnimplementedError('catchError should not be called in this future');
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) async {
    if (onError != null &&
        onError is! Function(Object, StackTrace) &&
        onError is! Function(Object)) {
      throw ArgumentError.value(
        onError,
        "onError",
        "Error handler must accept one Object or one Object and a StackTrace"
            " as arguments, and return a value of the returned future's type",
      );
    }

    try {
      final response = await execute();
      // ignore: null_check_on_nullable_type_parameter
      final data = response.data!;
      onValue(data);
      return data as R;
    } catch (error, stack) {
      if (onError != null) {
        if (onError is Function(Object, StackTrace)) {
          onError(error, stack);
        } else if (onError is Function(Object)) {
          onError(error);
        } else {
          rethrow;
        }
      }
      rethrow;
    }
  }

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
    throw UnimplementedError('timeout should not be called on this future');
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return then(
      (v) {
        final f2 = action();
        if (f2 is Future) return f2.then((_) => v);
        return v;
      },
      onError: (Object e) {
        final f2 = action();
        if (f2 is Future) {
          return f2.then((_) {
            throw e;
          });
        }
        throw e;
      },
    );
  }
}
