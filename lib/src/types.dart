typedef Headers = Map<String, String>;
typedef PostgrestConverter<S> = S Function(dynamic data);

/// A Postgrest response error
class PostgrestError {
  final String message;
  final String? code;
  final dynamic details;
  final String? hint;

  const PostgrestError({
    required this.message,
    this.code,
    this.details,
    this.hint,
  });

  factory PostgrestError.fromJson(Map<String, dynamic> json) => PostgrestError(
        message: json['message'] as String,
        code: json['code'] as String,
        details: json['details'] as dynamic,
        hint: json['hint'] as String,
      );

  @override
  String toString() {
    return 'PostgrestError(message: $message, code: $code, details: $details, hint: $hint)';
  }
}

/// A Postgrest response
class PostgrestResponse<T> {
  const PostgrestResponse({
    required this.data,
    required this.status,
    this.count,
  });

  final T? data;

  final int status;

  final int? count;

  factory PostgrestResponse.fromJson(Map<String, dynamic> json) =>
      PostgrestResponse<T>(
        data: json['data'] as T,
        status: json['status'] as int,
        count: json['count'] as int?,
      );
}

/// Returns count as part of the response when specified.
enum CountOption {
  exact,
  planned,
  estimated,
}

extension CountOptionName on CountOption {
  String name() {
    return toString().split('.').last;
  }
}

/// Returns count as part of the response when specified.
enum ReturningOption {
  minimal,
  representation,
}

extension ReturningOptionName on ReturningOption {
  String name() {
    return toString().split('.').last;
  }
}

/// The type of tsquery conversion to use on [query].
enum TextSearchType {
  /// Uses PostgreSQL's plainto_tsquery function.
  plain,

  /// Uses PostgreSQL's phraseto_tsquery function.
  phrase,

  /// Uses PostgreSQL's websearch_to_tsquery function.
  /// This function will never raise syntax errors, which makes it possible to use raw user-supplied input for search, and can be used with advanced operators.
  websearch,
}

extension TextSearchTypeName on TextSearchType {
  String name() {
    return toString().split('.').last;
  }
}

class FetchOptions {
  final bool head;
  final CountOption? count;

  const FetchOptions({
    this.head = false,
    this.count,
  });

  FetchOptions ensureNotHead() {
    return FetchOptions(
      head: false,
      count: count,
    );
  }
}
