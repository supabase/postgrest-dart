import 'dart:async';
import 'dart:convert';
import 'dart:core';

import 'package:http/http.dart' as http;

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
  Future<Map<String, dynamic>> end() async {
    try {
      var uppercaseMethod = this.method.toUpperCase();
      var response;

      if (this.schema == null) {
        // skip
      } else if (['GET', 'HEAD'].contains(this.method)) {
        this.headers['Accept-Profile'] = this.schema;
      } else {
        this.headers['Content-Profile'] = this.schema;
      }
      if (this.method != 'GET' && this.method != 'HEAD') {
        this.headers['Content-Type'] = 'application/json';
      }

      var client = http.Client();

      if (uppercaseMethod == "GET") {
        response = await client.get(this.url, headers: this.headers ?? {});
      } else if (uppercaseMethod == "POST") {
        response = await client.post(this.url, headers: this.headers ?? {}, body: this.body);
      } else if (uppercaseMethod == "PUT") {
        response = await client.put(this.url, headers: this.headers ?? {}, body: this.body);
      } else if (uppercaseMethod == "PATCH") {
        var bodyStr = json.encode(this.body);
        response = await client.patch(this.url, headers: this.headers ?? {}, body: bodyStr);
      } else if (uppercaseMethod == "DELETE") {
        response = await client.delete(this.url, headers: this.headers ?? {});
      }

      return parseJsonResponse(response);
    } catch (e) {
      return {
        'body': null,
        'status': 500,
        'statusCode': e.runtimeType.toString(),
        'statusText': e.toString()
      };
    }
  }

  /// Parse request response to json object if possible
  Map<String, dynamic> parseJsonResponse(dynamic response) {
    if (response.statusCode >= 400) {
      // error handling
      return {
        'body': null,
        'status': response.statusCode,
        'statusCode': response.statusCode,
        'statusText': response.body.toString(),
      };
    } else {
      var body;
      try {
        body = json.decode(response.body);
      } on FormatException catch (_) {
        body = response.body;
      }

      return {
        'body': body,
        'status': response.statusCode,
        'statusCode': response.statusCode,
        'statusText': null,
      };
    }
  }

  /// Update Uri queryParameters with new key:value
  appendSearchParams(String key, String value) {
    Map<String, dynamic> searchParams = new Map.from(this.url.queryParameters);
    searchParams[key] = value;
    this.url = this.url.replace(queryParameters: searchParams);
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
  PostgrestQueryBuilder(String url, [Map<String, String> headers, String schema]) {
    this.url = Uri.parse(url);
    this.headers = headers == null ? {} : headers;
    this.schema = schema;
  }

  /// Performs horizontal filtering with SELECT.
  ///
  /// ```dart
  /// postgrest.from('users').select('id, messages');
  /// ```
  PostgrestFilterBuilder select([String columns = '*']) {
    this.method = 'GET';

    // Remove whitespaces except when quoted
    var quoted = false;
    var re = new RegExp(r'\s');
    var cleanedColumns = columns.split('').map((c) {
      if (re.hasMatch(c) && !quoted) {
        return '';
      }
      if (c == '"') {
        quoted = !quoted;
      }
      return c;
    }).join('');

    appendSearchParams('select', cleanedColumns);
    return new PostgrestFilterBuilder(this);
  }

  /// Performs an INSERT into the table.
  ///
  /// When [options] has `upsert` is true, performs an UPSERT.
  /// ```dart
  /// postgrest.from('messages').insert({ message: 'foo', username: 'supabot', channel_id: 1 })
  /// postgrest.from('messages').insert({ id: 3, message: 'foo', username: 'supabot', channel_id: 2 }, { upsert: true })
  /// ```
  PostgrestBuilder insert(dynamic values, [Map options = const {'upsert': false}]) {
    this.method = 'POST';
    this.headers['Prefer'] = options['upsert']
        ? 'return=representation,resolution=merge-duplicates'
        : 'return=representation';
    this.body = values;
    return this;
  }

  /// Performs an UPDATE on the table.
  ///
  /// ```dart
  /// postgrest.from('messages').update({ channel_id: 2 }).eq('message', 'foo')
  /// ```
  PostgrestFilterBuilder update(Map values) {
    this.method = 'PATCH';
    this.headers['Prefer'] = 'return=representation';
    this.body = values;
    return new PostgrestFilterBuilder(this);
  }

  /// Performs a DELETE on the table.
  ///
  /// ```dart
  /// postgrest.from('messages').delete().eq('message', 'foo')
  /// ```
  PostgrestFilterBuilder delete() {
    this.method = 'DELETE';
    this.headers['Prefer'] = 'return=representation';
    return new PostgrestFilterBuilder(this);
  }

  /// Performs stored procedures on the database.
  ///
  /// ```dart
  /// postgrest.rpc('get_status', { name_param: 'supabot' })
  /// ```
  PostgrestBuilder rpc(dynamic params) {
    this.method = 'POST';
    this.body = params;
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
      [Map options = const {'ascending': false, 'nullsFirst': false, 'foreignTable': null}]) {
    var ascending = options != null ? options['ascending'] ?? false : false;
    var nullsFirst = options != null ? options['nullsFirst'] ?? false : false;
    var foreignTable = options != null ? options['foreignTable'] : null;

    var key = foreignTable == null ? 'order' : '"${foreignTable}".order';
    var value =
        '"${column}".${ascending ? 'asc' : 'desc'}.${nullsFirst ? 'nullsfirst' : 'nullslast'}';

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
  PostgrestTransformBuilder limit(int count, [Map options = const {'foreignTable': null}]) {
    var foreignTable = options != null ? options['foreignTable'] : null;
    var key = foreignTable == null ? 'limit' : '"${foreignTable}".limit';

    appendSearchParams(key, '${count}');
    return this;
  }

  /// Limits the result to rows within the specified range, inclusive.
  ///
  /// If we want to limit a foreign column, the [options] need to have `foreignTable` value provided
  /// ```dart
  /// postgrest.from('users').select('messages(*)').range(1, 1, { foreignTable: 'messages' })
  /// ```
  PostgrestTransformBuilder range(int from, int to, [Map options = const {'foreignTable': null}]) {
    var foreignTable = options != null ? options['foreignTable'] : null;
    var keyOffset = foreignTable == null ? 'offset' : '"${foreignTable}".offset';
    var keyLimit = foreignTable == null ? 'limit' : '"${foreignTable}".limit';

    appendSearchParams(keyOffset, '${from}');
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
    this.headers['Accept'] = 'application/vnd.pgrst.object+json';
    return this;
  }
}

class PostgrestFilterBuilder extends PostgrestTransformBuilder {
  PostgrestFilterBuilder(PostgrestBuilder builder) {
    this.url = builder.url;
    this.method = builder.method;
    this.headers = builder.headers;
    this.schema = builder.schema;
    this.body = builder.body;
  }

  /// Convert list filter to query params string
  String _cleanFilterArray(List filter) {
    return filter.map((s) => '"${s}"').join(',');
  }

  /// Finds all rows which doesn't satisfy the filter.
  ///
  /// ```dart
  /// postgrest.from('users').select().not('status', 'eq', 'OFFLINE')
  /// ```
  PostgrestFilterBuilder not(String column, String operator, dynamic value) {
    appendSearchParams('${column}', 'not.${operator}.${value}');
    return this;
  }

  /// Finds all rows satisfying at least one of the filters.
  ///
  /// ```dart
  /// postgrest.from('users').select().or('status.eq.OFFLINE,username.eq.supabot')
  /// ```
  PostgrestFilterBuilder or(String filters) {
    appendSearchParams('or', '(${filters})');
    return this;
  }

  /// Finds all rows whose value on the stated [column] exactly matches the specified [value].
  ///
  /// ```dart
  /// postgrest.from('users').select().eq('username', 'supabot')
  /// ```
  PostgrestFilterBuilder eq(String column, dynamic value) {
    appendSearchParams('${column}', 'eq.${value}');
    return this;
  }

  /// Finds all rows whose value on the stated [column] doesn't match the specified [value].
  ///
  /// ```dart
  /// postgrest.from('users').select().neq('username', 'supabot')
  /// ```
  PostgrestFilterBuilder neq(String column, dynamic value) {
    appendSearchParams('${column}', 'neq.${value}');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is greater than the specified [value].
  ///
  /// ```dart
  /// postgrest.from('messages').select().gt('id', 1)
  /// ```
  PostgrestFilterBuilder gt(String column, dynamic value) {
    appendSearchParams('${column}', 'gt.${value}');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is greater than or equal to the specified [value].
  ///
  /// ```dart
  /// postgrest.from('messages').select().gte('id', 1)
  /// ```
  PostgrestFilterBuilder gte(String column, dynamic value) {
    appendSearchParams('${column}', 'gte.${value}');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is less than the specified [value].
  ///
  /// ```dart
  /// postgrest.from('messages').select().lt('id', 2)
  /// ```
  PostgrestFilterBuilder lt(String column, dynamic value) {
    appendSearchParams('${column}', 'lt.${value}');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is less than or equal to the specified [value].
  ///
  /// ```dart
  /// postgrest.from('messages').select().lte('id', 2)
  /// ```
  PostgrestFilterBuilder lte(String column, dynamic value) {
    appendSearchParams('${column}', 'lte.${value}');
    return this;
  }

  /// Finds all rows whose value in the stated [column] matches the supplied [pattern] (case sensitive).
  ///
  /// ```dart
  /// postgrest.from('users').select().like('username', '%supa%')
  /// ```
  PostgrestFilterBuilder like(String column, String pattern) {
    appendSearchParams('${column}', 'like.${pattern}');
    return this;
  }

  /// Finds all rows whose value in the stated [column] matches the supplied [pattern] (case insensitive).
  ///
  /// ```dart
  /// postgrest.from('users').select().ilike('username', '%SUPA%')
  /// ```
  PostgrestFilterBuilder ilike(String column, String pattern) {
    appendSearchParams('${column}', 'ilike.${pattern}');
    return this;
  }

  /// A check for exact equality (null, true, false)
  ///
  /// Finds all rows whose value on the stated [column] exactly match the specified [value].
  /// ```dart
  /// postgrest.from('users').select().$is('data', null)
  /// ```
  PostgrestFilterBuilder is_(String column, dynamic value) {
    appendSearchParams('${column}', 'is.${value}');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is found on the specified [values].
  ///
  /// ```dart
  /// postgrest.from('users').select().in('status', ['ONLINE', 'OFFLINE'])
  /// ```
  PostgrestFilterBuilder in_(String column, List values) {
    appendSearchParams('${column}', 'in.(${_cleanFilterArray(values)})');
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
      appendSearchParams('${column}', 'cs.${value}');
    } else if (value is List) {
      // array
      appendSearchParams('${column}', 'cs.{${_cleanFilterArray(value)}}');
    } else {
      // json
      appendSearchParams('${column}', 'cs.${json.encode(value)}');
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
      appendSearchParams('${column}', 'cd.${value}');
    } else if (value is List) {
      // array
      appendSearchParams('${column}', 'cd.{${_cleanFilterArray(value)}}');
    } else {
      // json
      appendSearchParams('${column}', 'cd.${json.encode(value)}');
    }
    return this;
  }

  /// Finds all rows whose range value on the stated [column] is strictly to the left of the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().sl('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder sl(String column, String range) {
    appendSearchParams('${column}', 'sl.${range}');
    return this;
  }

  /// Finds all rows whose range value on the stated [column] is strictly to the right of the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().sr('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder sr(String column, String range) {
    appendSearchParams('${column}', 'sr.${range}');
    return this;
  }

  /// Finds all rows whose range value on the stated [column] does not extend to the left of the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().nxl('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder nxl(String column, String range) {
    appendSearchParams('${column}', 'nxl.${range}');
    return this;
  }

  /// Finds all rows whose range value on the stated [column] does not extend to the right of the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().nxr('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder nxr(String column, String range) {
    appendSearchParams('${column}', 'nxr.${range}');
    return this;
  }

  /// Finds all rows whose range value on the stated [column] is adjacent to the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().adj('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder adj(String column, String range) {
    appendSearchParams('${column}', 'adj.${range}');
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
      appendSearchParams('${column}', 'ov.${value}');
    } else if (value is List) {
      // array
      appendSearchParams('${column}', 'ov.{${_cleanFilterArray(value)}}');
    }
    return this;
  }

  /// Finds all rows whose tsvector value on the stated [column] matches to_tsquery([query]).
  ///
  /// [options] can contains `config` key which is text search configuration to use.
  /// ```dart
  /// postgrest.from('users').select().fts('catchphrase', "'fat' & 'cat'", { config: 'english' })
  /// ```
  PostgrestFilterBuilder fts(String column, String query, [Map options = const {'config': null}]) {
    var config = options != null ? options['config'] : null;
    var configPart = config == null ? '' : '(${config})';
    appendSearchParams('${column}', 'fts${configPart}.${query}');
    return this;
  }

  /// Finds all rows whose tsvector value on the stated [column] matches plainto_tsquery([query]).
  ///
  /// [options] can contains `config` key which is text search configuration to use.
  /// ```dart
  /// postgrest.from('users').select().plfts('catchphrase', "'fat' & 'cat'", { config: 'english' })
  /// ```
  PostgrestFilterBuilder plfts(String column, String query,
      [Map options = const {'config': null}]) {
    var config = options != null ? options['config'] : null;
    var configPart = config == null ? '' : '(${config})';
    appendSearchParams('${column}', 'plfts${configPart}.${query}');
    return this;
  }

  /// Finds all rows whose tsvector value on the stated [column] matches phraseto_tsquery([query]).
  ///
  /// [options] can contains `config` key which is text search configuration to use.
  /// ```dart
  /// postgrest.from('users').select().phfts('catchphrase', 'cat', { config: 'english' })
  /// ```
  PostgrestFilterBuilder phfts(String column, String query,
      [Map options = const {'config': null}]) {
    var config = options != null ? options['config'] : null;
    var configPart = config == null ? '' : '(${config})';
    appendSearchParams('${column}', 'phfts${configPart}.${query}');
    return this;
  }

  /// Finds all rows whose tsvector value on the stated [column] matches websearch_to_tsquery([query]).
  ///
  /// [options] can contains `config` key which is text search configuration to use.
  /// ```dart
  /// postgrest.from('users').select().wfts('catchphrase', "'fat' & 'cat'", { config: 'english' })
  /// ```
  PostgrestFilterBuilder wfts(String column, String query, [Map options = const {'config': null}]) {
    var config = options != null ? options['config'] : null;
    var configPart = config == null ? '' : '(${config})';
    appendSearchParams('${column}', 'wfts${configPart}.${query}');
    return this;
  }

  /// Finds all rows whose [column] satisfies the filter.
  ///
  /// ```dart
  /// postgrest.from('users').select().filter('username', 'eq', 'supabot')
  /// ```
  PostgrestFilterBuilder filter(String column, String operator, dynamic value) {
    appendSearchParams('${column}', '${operator}.${value}');
    return this;
  }

  /// Finds all rows whose columns match the specified [query] object.
  ///
  /// [query] contains column names as keys mapped to their filter values.
  /// ```dart
  /// postgrest.from('users').select().match({ 'username': 'supabot', 'status': 'ONLINE' })
  /// ```
  PostgrestFilterBuilder match(Map query) {
    query.forEach((k, v) => appendSearchParams('${k}', 'eq.${v}'));
    return this;
  }
}
