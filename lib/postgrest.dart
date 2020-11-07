library postgrest;

import 'src/builder.dart';

/// A PostgREST api client written in Dartlang. The goal of this library is to make an "ORM-like" restful interface.
class PostgrestClient {
  final String url;
  final Map<String, String> headers;
  final String schema;

  /// To create a [PostgrestClient], you need to provide an [url] endpoint.
  ///
  /// You can also provide [options] with `headers` and `schema` key-value if needed
  /// ```dart
  /// new PostgrestClient(REST_URL)
  /// new PostgrestClient(REST_URL, headers: { 'apikey': 'foo' })
  /// ```
  PostgrestClient(this.url, {Map<String, String> headers, this.schema}) : headers = headers ?? {};

  /// Authenticates the request with JWT.
  PostgrestClient auth(String token) {
    headers['Authorization'] = 'Bearer $token';
    return this;
  }

  /// Authenticates the request with JWT.
  PostgrestQueryBuilder from(String table) {
    final url = '${this.url}/$table';
    return PostgrestQueryBuilder(url, headers: headers, schema: schema);
  }

  /// Perform a stored procedure call.
  PostgrestBuilder rpc(String fn, Map params) {
    final url = '${this.url}/rpc/$fn';
    return PostgrestQueryBuilder(url, headers: headers, schema: schema).rpc(params);
  }
}
