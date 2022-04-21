// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:postgrest/postgrest.dart';
import 'package:postgrest/src/types.dart';

part 'postgrest_filter_builder.dart';
part 'postgrest_query_builder.dart';
part 'postgrest_rpc_builder.dart';
part 'postgrest_transform_builder.dart';

const METHOD_GET = 'GET';
const METHOD_HEAD = 'HEAD';
const METHOD_POST = 'POST';
const METHOD_PUT = 'PUT';
const METHOD_PATCH = 'PATCH';
const METHOD_DELETE = 'DELETE';

/// The base builder class.
class PostgrestBuilder<T> implements Future<T?> {
  dynamic _body;
  late final Headers _headers;
  bool _maybeEmpty = false;
  String? _method;
  late final String? _schema;
  late Uri _url;
  PostgrestConverter? _converter;
  late final Client? _httpClient;
  // ignore: prefer_final_fields
  FetchOptions? _options;

  PostgrestBuilder({
    required Uri url,
    required Headers headers,
    String? schema,
    String? method,
    dynamic body,
    Client? httpClient,
    FetchOptions? options,
  }) {
    _url = url;
    _headers = headers;
    _schema = schema;
    _method = method;
    _body = body;
    _httpClient = httpClient;
    _options = options;
  }

  /// Converts any response that comes from the server into a type-safe response.
  ///
  /// ```dart
  /// final User user = await postgrest
  ///     .from('users')
  ///     .select()
  ///     .withConverter<User>((data) => User.fromJson(json.decode(data)));
  /// ```
  PostgrestBuilder<S> withConverter<S>(PostgrestConverter<S> converter) {
    _converter = converter;
    return PostgrestBuilder<S>(
      url: _url,
      headers: _headers,
      schema: _schema,
      method: _method,
      body: _body,
    )
      .._maybeEmpty = _maybeEmpty
      .._converter = converter;
  }

  /// Sends the request and returns a [PostgrestResponse]
  ///
  /// [head] to trigger a HEAD request
  ///
  /// [count] if you want to returns the count value. Support exact, planned and
  /// estimated count options.
  ///
  /// For more details about switching schemas: https://postgrest.org/en/stable/api.html#switching-schemas
  ///
  /// ```dart
  /// try {
  ///   final client.from('countries').select().execute();
  /// } on PostgrestError catch (error) {
  ///   print(error.code);
  /// }
  /// ```
  @Deprecated('Use async/await or .then instead. Deprecated in 0.2.0')
  Future<PostgrestResponse<T>> execute() async {
    return _execute();
  }

  Future<PostgrestResponse<T>> _execute() async {
    if (_options?.head ?? false) {
      _method = METHOD_HEAD;
    }

    if (_options?.count != null) {
      if (_headers['Prefer'] != null) {
        final oldPreferHeader = _headers['Prefer'];
        _headers['Prefer'] =
            '$oldPreferHeader,count=${_options!.count!.name()}';
      } else {
        _headers['Prefer'] = 'count=${_options!.count!.name()}';
      }
    }

    try {
      if (_method == null) {
        throw "Missing table operation: select, insert, update or delete";
      }

      final uppercaseMethod = _method!.toUpperCase();
      late http.Response response;

      if (_schema == null) {
        // skip
      } else if ([METHOD_GET, METHOD_HEAD].contains(_method)) {
        _headers['Accept-Profile'] = _schema!;
      } else {
        _headers['Content-Profile'] = _schema!;
      }
      if (_method != METHOD_GET && _method != METHOD_HEAD) {
        _headers['Content-Type'] = 'application/json';
      }

      final bodyStr = json.encode(_body);

      if (uppercaseMethod == METHOD_GET) {
        response = await (_httpClient?.get ?? http.get)(
          _url,
          headers: _headers,
        );
      } else if (uppercaseMethod == METHOD_POST) {
        response = await (_httpClient?.post ?? http.post)(
          _url,
          headers: _headers,
          body: bodyStr,
        );
      } else if (uppercaseMethod == METHOD_PUT) {
        response = await (_httpClient?.put ?? http.put)(
          _url,
          headers: _headers,
          body: bodyStr,
        );
      } else if (uppercaseMethod == METHOD_PATCH) {
        response = await (_httpClient?.patch ?? http.patch)(
          _url,
          headers: _headers,
          body: bodyStr,
        );
      } else if (uppercaseMethod == METHOD_DELETE) {
        response = await (_httpClient?.delete ?? http.delete)(
          _url,
          headers: _headers,
        );
      } else if (uppercaseMethod == METHOD_HEAD) {
        response = await (_httpClient?.head ?? http.head)(
          _url,
          headers: _headers,
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

      if (response.request!.method != METHOD_HEAD) {
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
      if (contentRange != null && contentRange.length > 1) {
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
      if (response.request!.method != METHOD_HEAD) {
        try {
          final errorJson = json.decode(response.body) as Map<String, dynamic>;
          error = PostgrestError.fromJson(errorJson);

          if (_maybeEmpty) {
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
        data: '' as T,
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
    final searchParams = Map<String, dynamic>.from(_url.queryParametersAll);
    searchParams[key] = [...searchParams[key] ?? [], value];
    _url = _url.replace(queryParameters: searchParams);
  }

  /// Overrides Uri queryParameters with new key:value
  void overrideSearchParams(String key, String value) {
    final searchParams = Map<String, dynamic>.from(_url.queryParametersAll);
    searchParams[key] = value;
    _url = _url.replace(queryParameters: searchParams);
  }

  @override
  Stream<T?> asStream() {
    final controller = StreamController<T?>.broadcast();

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
    FutureOr<R> Function(T? value) onValue, {
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
      final response = await _execute();
      // ignore: null_check_on_nullable_type_parameter
      final data = response.data;

      if (_converter != null) {
        return onValue(data as T);
      } else {
        if (response.count != null) {
          return onValue(response as T);
        } else {
          return onValue(data as T);
        }
      }
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
  Future<T> timeout(Duration timeLimit, {FutureOr<T?> Function()? onTimeout}) {
    throw UnimplementedError('timeout should not be called on this future');
  }

  @override
  Future<T?> whenComplete(FutureOr<void> Function() action) {
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
