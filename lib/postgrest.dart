library postgrest;

import 'src/builder.dart';

/// A PostgREST api client written in Dartlang. The goal of this library is to make an "ORM-like" restful interface.
class PostgrestClient {
  Map<String, String> headers = {};
  String url;
  String schema;

  /// To create a [PostgrestClient], you need to provide an [url] endpoint.
  ///
  /// You can also provide [options] with `headers` and `schema` key-value if needed
  /// ```dart
  /// new PostgrestClient(REST_URL)
  /// new PostgrestClient(REST_URL, headers: { 'apikey': 'foo' })
  /// ```
  PostgrestClient(String url, {Map<String, String> headers, String schema}) {
    this.url = url;
    this.headers = headers ?? {};
    this.schema = schema;
  }

  /// Authenticates the request with JWT.
  PostgrestClient auth(String token) {
    headers['Authorization'] = 'Bearer ${token}';
    return this;
  }

  /// Authenticates the request with JWT.
  PostgrestQueryBuilder from(String table) {
    var url = '${this.url}/${table}';
    return PostgrestQueryBuilder(url, headers: headers, schema: schema);
  }

  /// Perform a stored procedure call.
  PostgrestQueryBuilder rpc(String fn, Map params) {
    var url = '${this.url}/rpc/${fn}';
    return PostgrestQueryBuilder(url, headers: headers, schema: schema).rpc(params);
  }
}
