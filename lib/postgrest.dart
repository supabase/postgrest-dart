library postgrest;

import "package:postgrest/builder.dart";

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
  /// new PostgrestClient(REST_URL, { headers: { apikey: 'foo' } })
  /// ```
  PostgrestClient(String url, [Map<String, dynamic> options = const {}]) {
    this.url = url;

    if (options != null && options.containsKey("headers")) {
      this.headers = options['headers'];
    }
    if (options != null && options.containsKey("schema")) {
      this.schema = options['schema'];
    }
  }

  /// Authenticates the request with JWT.
  PostgrestClient auth(String token) {
    this.headers['Authorization'] = 'Bearer ${token}';
    return this;
  }

  /// Authenticates the request with JWT.
  PostgrestQueryBuilder from(String table) {
    var url = '${this.url}/${table}';
    return new PostgrestQueryBuilder(url, {headers: this.headers, schema: this.schema});
  }

  /// Perform a stored procedure call.
  PostgrestQueryBuilder rpc(String fn, Map params) {
    var url = '${this.url}/rpc/${fn}';
    return new PostgrestQueryBuilder(url, {headers: this.headers, schema: this.schema}).rpc(params);
  }
}
