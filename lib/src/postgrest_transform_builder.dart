part of 'postgrest_builder.dart';

class PostgrestTransformBuilder<T> extends PostgrestBuilder<T, T> {
  PostgrestTransformBuilder(PostgrestBuilder<T, T> builder)
      : super(
          url: builder._url,
          method: builder._method,
          headers: builder._headers,
          schema: builder._schema,
          body: builder._body,
          httpClient: builder._httpClient,
          options: builder._options,
        );

  /// Performs horizontal filtering with SELECT.
  ///
  /// ```dart
  /// postgrest.from('users').select('id, messages');
  /// ```
  PostgrestTransformBuilder<T> select([String columns = '*']) {
    // Remove whitespaces except when quoted
    var quoted = false;
    final re = RegExp(r'\s');
    final cleanedColumns = columns.split('').map((c) {
      if (re.hasMatch(c) && !quoted) {
        return '';
      }
      if (c == '"') {
        quoted = !quoted;
      }
      return c;
    }).join();

    appendSearchParams('select', cleanedColumns);
    if (_headers['Prefer'] != null) {
      _headers['Prefer'] = '${_headers['Prefer']},';
    }
    _headers['Prefer'] = '${_headers['Prefer']}return=representation';
    return this;
  }

  /// Orders the result with the specified [column].
  ///
  /// When [options] has `ascending` value true, the result will be in ascending order.
  /// When [options] has `nullsFirst` value true, `null`s appear first.
  /// If [column] is a foreign column, the [options] need to have `foreignTable` value provided
  /// ```dart
  /// postgrest.from('users').select().order('username', ascending: false)
  /// postgrest.from('users').select('messages(*)').order('channel_id', foreignTable: 'messages', ascending: false)
  /// ```
  PostgrestTransformBuilder<T> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? foreignTable,
  }) {
    final key = foreignTable == null ? 'order' : '$foreignTable.order';
    final existingOrder = _url.queryParameters[key];
    final value = '${existingOrder == null ? '' : '$existingOrder,'}'
        '$column.${ascending ? 'asc' : 'desc'}.${nullsFirst ? 'nullsfirst' : 'nullslast'}';

    overrideSearchParams(key, value);
    return this;
  }

  /// Limits the result with the specified `count`.
  ///
  /// If we want to limit a foreign column, the [options] need to have `foreignTable` value provided
  /// ```dart
  /// postgrest.from('users').select().limit(1)
  /// postgrest.from('users').select('messages(*)').limit(1, foreignTable: 'messages')
  /// ```
  PostgrestTransformBuilder<T> limit(int count, {String? foreignTable}) {
    final key = foreignTable == null ? 'limit' : '$foreignTable.limit';

    appendSearchParams(key, '$count');
    return this;
  }

  /// Limits the result to rows within the specified range, inclusive.
  ///
  /// If we want to limit a foreign column, the [options] need to have `foreignTable` value provided
  /// ```dart
  /// postgrest.from('users').select('messages(*)').range(1, 1, foreignTable: 'messages')
  /// ```
  PostgrestTransformBuilder<T> range(int from, int to, {String? foreignTable}) {
    final keyOffset = foreignTable == null ? 'offset' : '$foreignTable.offset';
    final keyLimit = foreignTable == null ? 'limit' : '$foreignTable.limit';

    appendSearchParams(keyOffset, '$from');
    appendSearchParams(keyLimit, '${to - from + 1}');
    return this;
  }

  /// Retrieves only one row from the result.
  ///
  /// Result must be one row (e.g. using `limit`), otherwise this will result in an error.
  /// ```dart
  /// postgrest.from('users').select().limit(1).single()
  /// ```
  PostgrestTransformBuilder<T> single() {
    _headers['Accept'] = 'application/vnd.pgrst.object+json';
    return this;
  }

  /// Retrieves at most one row from the result.
  ///
  /// Result must be at most one row or nullable
  /// (e.g. using `eq` on a UNIQUE column), otherwise this will result in an error.
  PostgrestTransformBuilder<T> maybeSingle() {
    _headers['Accept'] = 'application/vnd.pgrst.object+json';
    _maybeEmpty = true;
    return this;
  }

  /// Retrieves the response as CSV.
  /// This will skip object parsing.
  ///
  /// ```dart
  /// postgrest.from('users').select().csv()
  /// ```
  PostgrestTransformBuilder<T> csv() {
    _headers['Accept'] = 'text/csv';
    return this;
  }
}
