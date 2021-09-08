import 'dart:core';

import 'postgrest_builder.dart';
import 'postgrest_filter_builder.dart';
import 'returning_option.dart';

/// The query builder class provides a convenient interface to creating request queries.
///
/// Allows the user to stack the filter functions before they call any of
/// * select() - "get"
/// * insert() - "post"
/// * update() - "patch"
/// * delete() - "delete"
/// Once any of these are called the filters are passed down to the Request.
class PostgrestQueryBuilder extends PostgrestBuilder {
  PostgrestQueryBuilder(
    String url, {
    Map<String, String>? headers,
    String? schema,
  }) : super(
          url: Uri.parse(url),
          headers: headers ?? {},
          schema: schema,
        );

  /// Performs horizontal filtering with SELECT.
  ///
  /// ```dart
  /// postgrest.from('users').select('id, messages');
  /// ```
  PostgrestFilterBuilder select([String columns = '*']) {
    method = 'GET';

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
    return PostgrestFilterBuilder(this);
  }

  /// Performs an INSERT into the table.
  ///
  /// By default the new record is returned. Set [returning] to minimal if you don't need this value.
  /// ```dart
  /// postgrest.from('messages').insert({'message': 'foo', 'username': 'supabot', 'channel_id': 1})
  /// ```
  PostgrestBuilder insert(
    dynamic values, {
    ReturningOption returning = ReturningOption.representation,
    @Deprecated('Use `upsert()` method instead') bool upsert = false,
    @Deprecated('Use `upsert()` method instead') String? onConflict,
  }) {
    method = 'POST';
    headers['Prefer'] = upsert
        ? 'return=${returning.name()},resolution=merge-duplicates'
        : 'return=${returning.name()}';
    if (onConflict != null) {
      url = url.replace(queryParameters: {
        'on_conflict': onConflict,
        ...url.queryParameters,
      });
    }
    body = values;
    return this;
  }

  /// Performs an UPSERT into the table.
  ///
  /// By default the new record is returned. Set [returning] to minimal if you don't need this value.
  /// By specifying the [onConflict] query parameter, you can make UPSERT work on a column(s) that has a UNIQUE constraint.
  /// [ignoreDuplicates] Specifies if duplicate rows should be ignored and not inserted.
  /// ```dart
  /// postgrest.from('messages').upsert({'id': 3, message: 'foo', 'username': 'supabot', 'channel_id': 2})
  /// ```
  PostgrestBuilder upsert(
    dynamic values, {
    ReturningOption returning = ReturningOption.representation,
    String? onConflict,
    bool ignoreDuplicates = false,
  }) {
    method = 'POST';
    headers['Prefer'] =
        'return=${returning.name()},resolution=${ignoreDuplicates ? 'ignore' : 'merge'}-duplicates';
    if (onConflict != null) {
      url = url.replace(queryParameters: {
        'on_conflict': onConflict,
        ...url.queryParameters,
      });
    }
    body = values;
    return this;
  }

  /// Performs an UPDATE on the table.
  ///
  /// By default the updated record(s) will be returned. Set [returning] to minimal if you don't need this value.
  /// ```dart
  /// postgrest.from('messages').update({'channel_id': 2}).eq('message', 'foo')
  /// ```
  PostgrestFilterBuilder update(
    Map values, {
    ReturningOption returning = ReturningOption.representation,
  }) {
    method = 'PATCH';
    headers['Prefer'] = 'return=${returning.name()}';
    body = values;
    return PostgrestFilterBuilder(this);
  }

  /// Performs a DELETE on the table.
  ///
  /// By default the deleted record(s) will be returned. Set [returning] to minimal if you don't need this value.
  /// ```dart
  /// postgrest.from('messages').delete().eq('message', 'foo')
  /// ```
  PostgrestFilterBuilder delete({
    ReturningOption returning = ReturningOption.representation,
  }) {
    method = 'DELETE';
    headers['Prefer'] = 'return=${returning.name()}';
    return PostgrestFilterBuilder(this);
  }
}
