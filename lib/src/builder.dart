import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;

import 'count_option.dart';
import 'postgrest_error.dart';
import 'postgrest_response.dart';

/// The base builder class.
class PostgrestBuilder {
  dynamic body;
  List query = [];
  Map<String, String> headers;
  String method;
  String schema;
  Uri url;

  /// Sends the request and returns a Future.
  /// catch any error and returns with status 500
  ///
  /// For more details about switching schemas: https://postgrest.org/en/stable/api.html#switching-schemas
  /// Returns {Future} Resolves when the request has completed.
  Future<PostgrestResponse> execute() async {
    try {
      final uppercaseMethod = method.toUpperCase();
      http.Response response;

      if (schema == null) {
        // skip
      } else if (['GET', 'HEAD'].contains(method)) {
        headers['Accept-Profile'] = schema;
      } else {
        headers['Content-Profile'] = schema;
      }
      if (method != 'GET' && method != 'HEAD') {
        headers['Content-Type'] = 'application/json';
      }

      final client = http.Client();
      final bodyStr = json.encode(body);

      if (uppercaseMethod == 'GET') {
        response = await client.get(url, headers: headers ?? {});
      } else if (uppercaseMethod == 'POST') {
        response =
            await client.post(url, headers: headers ?? {}, body: bodyStr);
      } else if (uppercaseMethod == 'PUT') {
        response = await client.put(url, headers: headers ?? {}, body: bodyStr);
      } else if (uppercaseMethod == 'PATCH') {
        response =
            await client.patch(url, headers: headers ?? {}, body: bodyStr);
      } else if (uppercaseMethod == 'DELETE') {
        response = await client.delete(url, headers: headers ?? {});
      } else if (uppercaseMethod == 'HEAD') {
        response = await client.head(url, headers: headers ?? {});
      }

      return parseJsonResponse(response);
    } catch (e) {
      return PostgrestResponse(
        status: 500,
        error: PostgrestError(code: e.runtimeType.toString()),
        statusText: e.toString(),
      );
    }
  }

  /// Parse request response to json object if possible
  PostgrestResponse parseJsonResponse(http.Response response) {
    if (response.statusCode >= 400) {
      // error handling
      return PostgrestResponse(
        status: response.statusCode,
        error: PostgrestError(code: response.statusCode.toString()),
        statusText: response.body.toString(),
      );
    } else {
      dynamic body;
      int count;
      if (response.request.method != 'HEAD') {
        try {
          body = json.decode(response.body);
        } on FormatException catch (_) {
          body = response.body;
        }
      }

      final contentRange = response.headers['content-range'];
      count = contentRange.split('/')[1] == '*'
          ? null
          : int.parse(contentRange.split('/')[1]);

      return PostgrestResponse(
        data: body,
        status: response.statusCode,
        count: count,
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

/// The query builder class provides a convenient interface to creating request queries.
///
/// Allows the user to stack the filter functions before they call any of
/// * select() - "get"
/// * insert() - "post"
/// * update() - "patch"
/// * delete() - "delete"
/// Once any of these are called the filters are passed down to the Request.
class PostgrestQueryBuilder extends PostgrestBuilder {
  PostgrestQueryBuilder(String url,
      {Map<String, String> headers, String schema}) {
    this.url = Uri.parse(url);
    this.headers = headers ?? {};
    this.schema = schema;
  }

  /// Performs horizontal filtering with SELECT.
  ///
  /// ```dart
  /// postgrest.from('users').select('id, messages');
  /// ```
  PostgrestFilterBuilder select({
    String columns = '*',
    bool head = false,
    CountOption count,
  }) {
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
    }).join('');

    if (count != null) {
      headers['Prefer'] = 'count=${count.name()}';
    }
    if (head) {
      method = 'HEAD';
    }

    appendSearchParams('select', cleanedColumns);
    return PostgrestFilterBuilder(this);
  }

  /// Performs an INSERT into the table.
  ///
  /// When [options] has `upsert` is true, performs an UPSERT.
  /// ```dart
  /// postgrest.from('messages').insert({ message: 'foo', username: 'supabot', channel_id: 1 })
  /// postgrest.from('messages').insert({ id: 3, message: 'foo', username: 'supabot', channel_id: 2 }, { upsert: true })
  /// ```
  PostgrestBuilder insert(
    dynamic values, {
    bool upsert = false,
    String onConflict,
    CountOption count,
  }) {
    method = 'POST';
    headers['Prefer'] = upsert
        ? 'return=representation,resolution=merge-duplicates'
        : 'return=representation';
    body = values;
    if (count != null) {
      headers['Prefer'] += ',count=${count.name()}';
    }
    return this;
  }

  /// Performs an UPDATE on the table.
  ///
  /// ```dart
  /// postgrest.from('messages').update({ channel_id: 2 }).eq('message', 'foo')
  /// ```
  PostgrestFilterBuilder update(Map values, {CountOption count}) {
    method = 'PATCH';
    headers['Prefer'] = 'return=representation';
    body = values;
    if (count != null) {
      headers['Prefer'] += ',count=${count.name()}';
    }
    return PostgrestFilterBuilder(this);
  }

  /// Performs a DELETE on the table.
  ///
  /// ```dart
  /// postgrest.from('messages').delete().eq('message', 'foo')
  /// ```
  PostgrestFilterBuilder delete({CountOption count}) {
    method = 'DELETE';
    headers['Prefer'] = 'return=representation';
    if (count != null) {
      headers['Prefer'] += ',count=${count.name()}';
    }
    return PostgrestFilterBuilder(this);
  }

  /// Performs stored procedures on the database.
  ///
  /// ```dart
  /// postgrest.rpc('get_status', { name_param: 'supabot' })
  /// ```
  PostgrestBuilder rpc(
    dynamic params, {
    bool head = false,
    CountOption count,
  }) {
    method = 'POST';
    body = params;
    if (count != null) {
      headers['Prefer'] = 'count=${count.name()}';
    }
    if (head) {
      method = 'HEAD';
    }
    return this;
  }
}

class PostgrestTransformBuilder<T> extends PostgrestBuilder {
  /// Orders the result with the specified [column].
  ///
  /// When [options] has `ascending` value true, the result will be in ascending order.
  /// When [options] has `nullsFirst` value true, `null`s appear first.
  /// If [column] is a foreign column, the [options] need to have `foreignTable` value provided
  /// ```dart
  /// postgrest.from('users').select().order('username', { ascending: false })
  /// postgrest.from('users').select('messages(*)').order('channel_id', { foreignTable: 'messages', ascending: false })
  /// ```
  PostgrestTransformBuilder order(String column,
      {bool ascending = false, bool nullsFirst = false, String foreignTable}) {
    final key = foreignTable == null ? 'order' : '"$foreignTable".order';
    final value =
        '"$column".${ascending ? 'asc' : 'desc'}.${nullsFirst ? 'nullsfirst' : 'nullslast'}';

    appendSearchParams(key, value);
    return this;
  }

  /// Limits the result with the specified `count`.
  ///
  /// If we want to limit a foreign column, the [options] need to have `foreignTable` value provided
  /// ```dart
  /// postgrest.from('users').select().limit(1)
  /// postgrest.from('users').select('messages(*)').limit(1, { foreignTable: 'messages' })
  /// ```
  PostgrestTransformBuilder limit(int count, {String foreignTable}) {
    final key = foreignTable == null ? 'limit' : '"$foreignTable".limit';

    appendSearchParams(key, '$count');
    return this;
  }

  /// Limits the result to rows within the specified range, inclusive.
  ///
  /// If we want to limit a foreign column, the [options] need to have `foreignTable` value provided
  /// ```dart
  /// postgrest.from('users').select('messages(*)').range(1, 1, { foreignTable: 'messages' })
  /// ```
  PostgrestTransformBuilder range(int from, int to, {String foreignTable}) {
    final keyOffset =
        foreignTable == null ? 'offset' : '"$foreignTable".offset';
    final keyLimit = foreignTable == null ? 'limit' : '"$foreignTable".limit';

    appendSearchParams(keyOffset, '$from');
    appendSearchParams(keyLimit, '${to - from + 1}');
    return this;
  }

  /// Retrieves only one row from the result.
  ///
  /// Result must be one row (e.g. using `limit`),otherwise this will result in an error.
  /// ```dart
  /// postgrest.from('users').select().limit(1).single()
  /// ```
  PostgrestTransformBuilder single() {
    headers['Accept'] = 'application/vnd.pgrst.object+json';
    return this;
  }
}

class PostgrestFilterBuilder extends PostgrestTransformBuilder {
  PostgrestFilterBuilder(PostgrestBuilder builder) {
    url = builder.url;
    method = builder.method;
    headers = builder.headers;
    schema = builder.schema;
    body = builder.body;
  }

  /// Convert list filter to query params string
  String _cleanFilterArray(List filter) {
    return filter.map((s) => '"$s"').join(',');
  }

  /// Finds all rows which doesn't satisfy the filter.
  ///
  /// ```dart
  /// postgrest.from('users').select().not('status', 'eq', 'OFFLINE')
  /// ```
  PostgrestFilterBuilder not(String column, String operator, dynamic value) {
    appendSearchParams(column, 'not.$operator.$value');
    return this;
  }

  /// Finds all rows satisfying at least one of the filters.
  ///
  /// ```dart
  /// postgrest.from('users').select().or('status.eq.OFFLINE,username.eq.supabot')
  /// ```
  PostgrestFilterBuilder or(String filters) {
    appendSearchParams('or', '($filters)');
    return this;
  }

  /// Finds all rows whose value on the stated [column] exactly matches the specified [value].
  ///
  /// ```dart
  /// postgrest.from('users').select().eq('username', 'supabot')
  /// ```
  PostgrestFilterBuilder eq(String column, dynamic value) {
    appendSearchParams(column, 'eq.$value');
    return this;
  }

  /// Finds all rows whose value on the stated [column] doesn't match the specified [value].
  ///
  /// ```dart
  /// postgrest.from('users').select().neq('username', 'supabot')
  /// ```
  PostgrestFilterBuilder neq(String column, dynamic value) {
    appendSearchParams(column, 'neq.$value');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is greater than the specified [value].
  ///
  /// ```dart
  /// postgrest.from('messages').select().gt('id', 1)
  /// ```
  PostgrestFilterBuilder gt(String column, dynamic value) {
    appendSearchParams(column, 'gt.$value');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is greater than or equal to the specified [value].
  ///
  /// ```dart
  /// postgrest.from('messages').select().gte('id', 1)
  /// ```
  PostgrestFilterBuilder gte(String column, dynamic value) {
    appendSearchParams(column, 'gte.$value');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is less than the specified [value].
  ///
  /// ```dart
  /// postgrest.from('messages').select().lt('id', 2)
  /// ```
  PostgrestFilterBuilder lt(String column, dynamic value) {
    appendSearchParams(column, 'lt.$value');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is less than or equal to the specified [value].
  ///
  /// ```dart
  /// postgrest.from('messages').select().lte('id', 2)
  /// ```
  PostgrestFilterBuilder lte(String column, dynamic value) {
    appendSearchParams(column, 'lte.$value');
    return this;
  }

  /// Finds all rows whose value in the stated [column] matches the supplied [pattern] (case sensitive).
  ///
  /// ```dart
  /// postgrest.from('users').select().like('username', '%supa%')
  /// ```
  PostgrestFilterBuilder like(String column, String pattern) {
    appendSearchParams(column, 'like.$pattern');
    return this;
  }

  /// Finds all rows whose value in the stated [column] matches the supplied [pattern] (case insensitive).
  ///
  /// ```dart
  /// postgrest.from('users').select().ilike('username', '%SUPA%')
  /// ```
  PostgrestFilterBuilder ilike(String column, String pattern) {
    appendSearchParams(column, 'ilike.$pattern');
    return this;
  }

  /// A check for exact equality (null, true, false)
  ///
  /// Finds all rows whose value on the stated [column] exactly match the specified [value].
  /// ```dart
  /// postgrest.from('users').select().is_('data', null)
  /// ```
  // ignore: non_constant_identifier_names
  PostgrestFilterBuilder is_(String column, dynamic value) {
    appendSearchParams(column, 'is.$value');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is found on the specified [values].
  ///
  /// ```dart
  /// postgrest.from('users').select().in_('status', ['ONLINE', 'OFFLINE'])
  /// ```
  // ignore: non_constant_identifier_names
  PostgrestFilterBuilder in_(String column, List values) {
    appendSearchParams(column, 'in.(${_cleanFilterArray(values)})');
    return this;
  }

  /// Finds all rows whose json, array, or range value on the stated [column] contains the values specified in [value].
  ///
  /// ```dart
  /// postgrest.from('users').select().cs('age_range', '[1,2)')
  /// ```
  PostgrestFilterBuilder cs(String column, dynamic value) {
    if (value is String) {
      // range types can be inclusive '[', ']' or exclusive '(', ')' so just
      // keep it simple and accept a string
      appendSearchParams(column, 'cs.$value');
    } else if (value is List) {
      // array
      appendSearchParams(column, 'cs.{${_cleanFilterArray(value)}}');
    } else {
      // json
      appendSearchParams(column, 'cs.${json.encode(value)}');
    }
    return this;
  }

  /// Finds all rows whose json, array, or range value on the stated [column] is contained by the specified [value].
  ///
  /// ```dart
  /// postgrest.from('users').select().cd('age_range', '[1,2)')
  /// ```
  PostgrestFilterBuilder cd(String column, dynamic value) {
    if (value is String) {
      // range types can be inclusive '[', ']' or exclusive '(', ')' so just
      // keep it simple and accept a string
      appendSearchParams(column, 'cd.$value');
    } else if (value is List) {
      // array
      appendSearchParams(column, 'cd.{${_cleanFilterArray(value)}}');
    } else {
      // json
      appendSearchParams(column, 'cd.${json.encode(value)}');
    }
    return this;
  }

  /// Finds all rows whose range value on the stated [column] is strictly to the left of the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().sl('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder sl(String column, String range) {
    appendSearchParams(column, 'sl.$range');
    return this;
  }

  /// Finds all rows whose range value on the stated [column] is strictly to the right of the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().sr('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder sr(String column, String range) {
    appendSearchParams(column, 'sr.$range');
    return this;
  }

  /// Finds all rows whose range value on the stated [column] does not extend to the left of the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().nxl('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder nxl(String column, String range) {
    appendSearchParams(column, 'nxl.$range');
    return this;
  }

  /// Finds all rows whose range value on the stated [column] does not extend to the right of the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().nxr('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder nxr(String column, String range) {
    appendSearchParams(column, 'nxr.$range');
    return this;
  }

  /// Finds all rows whose range value on the stated [column] is adjacent to the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().adj('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder adj(String column, String range) {
    appendSearchParams(column, 'adj.$range');
    return this;
  }

  /// Finds all rows whose array or range value on the stated [column] iscontained by the specified [value].
  ///
  /// ```dart
  /// postgrest.from('users').select().ov('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder ov(String column, dynamic value) {
    if (value is String) {
      // range types can be inclusive '[', ']' or exclusive '(', ')' so just
      // keep it simple and accept a string
      appendSearchParams(column, 'ov.$value');
    } else if (value is List) {
      // array
      appendSearchParams(column, 'ov.{${_cleanFilterArray(value)}}');
    }
    return this;
  }

  /// Finds all rows whose tsvector value on the stated [column] matches to_tsquery([query]).
  ///
  /// [options] can contains `config` key which is text search configuration to use.
  /// ```dart
  /// postgrest.from('users').select().fts('catchphrase', "'fat' & 'cat'", { config: 'english' })
  /// ```
  PostgrestFilterBuilder fts(String column, String query, {String config}) {
    final configPart = config == null ? '' : '($config)';
    appendSearchParams(column, 'fts$configPart.$query');
    return this;
  }

  /// Finds all rows whose tsvector value on the stated [column] matches plainto_tsquery([query]).
  ///
  /// [options] can contains `config` key which is text search configuration to use.
  /// ```dart
  /// postgrest.from('users').select().plfts('catchphrase', "'fat' & 'cat'", { config: 'english' })
  /// ```
  PostgrestFilterBuilder plfts(String column, String query, {String config}) {
    final configPart = config == null ? '' : '($config)';
    appendSearchParams(column, 'plfts$configPart.$query');
    return this;
  }

  /// Finds all rows whose tsvector value on the stated [column] matches phraseto_tsquery([query]).
  ///
  /// [options] can contains `config` key which is text search configuration to use.
  /// ```dart
  /// postgrest.from('users').select().phfts('catchphrase', 'cat', { config: 'english' })
  /// ```
  PostgrestFilterBuilder phfts(String column, String query, {String config}) {
    final configPart = config == null ? '' : '($config)';
    appendSearchParams(column, 'phfts$configPart.$query');
    return this;
  }

  /// Finds all rows whose tsvector value on the stated [column] matches websearch_to_tsquery([query]).
  ///
  /// [options] can contains `config` key which is text search configuration to use.
  /// ```dart
  /// postgrest.from('users').select().wfts('catchphrase', "'fat' & 'cat'", { config: 'english' })
  /// ```
  PostgrestFilterBuilder wfts(String column, String query, {String config}) {
    final configPart = config == null ? '' : '($config)';
    appendSearchParams(column, 'wfts$configPart.$query');
    return this;
  }

  /// Finds all rows whose [column] satisfies the filter.
  ///
  /// ```dart
  /// postgrest.from('users').select().filter('username', 'eq', 'supabot')
  /// ```
  PostgrestFilterBuilder filter(String column, String operator, dynamic value) {
    appendSearchParams(column, '$operator.$value');
    return this;
  }

  /// Finds all rows whose columns match the specified [query] object.
  ///
  /// [query] contains column names as keys mapped to their filter values.
  /// ```dart
  /// postgrest.from('users').select().match({ 'username': 'supabot', 'status': 'ONLINE' })
  /// ```
  PostgrestFilterBuilder match(Map query) {
    query.forEach((k, v) => appendSearchParams('$k', 'eq.$v'));
    return this;
  }
}
