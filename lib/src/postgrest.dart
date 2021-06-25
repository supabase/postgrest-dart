import 'postgrest_query_builder.dart';
import 'postgrest_rpc_builder.dart';
import 'postgrest_transform_builder.dart';

/// A PostgREST api client written in Dartlang. The goal of this library is to make an "ORM-like" restful interface.
class PostgrestClient {
  final String url;
  final Map<String, String> headers;
  final String? schema;

  /// To create a [PostgrestClient], you need to provide an [url] endpoint.
  ///
  /// You can also provide [options] with `headers` and `schema` key-value if needed
  /// ```dart
  /// PostgrestClient(REST_URL)
  /// PostgrestClient(REST_URL, headers: {'apikey': 'foo'})
  /// ```
  PostgrestClient(
    this.url, {
    Map<String, String>? headers,
    this.schema,
  }) : headers = headers ?? {};

  /// Authenticates the request with JWT.
  PostgrestClient auth(String token) {
    headers['Authorization'] = 'Bearer $token';
    return this;
  }

  /// Perform a table operation.
  PostgrestQueryBuilder from(String table) {
    final url = '${this.url}/$table';
    return PostgrestQueryBuilder(url, headers: headers, schema: schema);
  }

  /// Perform a stored procedure call.
  ///
  /// ```dart
  /// postgrest.rpc('get_status', params: {'name_param': 'supabot'})
  /// ```
  PostgrestTransformBuilder rpc(String fn, {Map? params}) {
    final url = '${this.url}/rpc/$fn';
    return PostgrestRpcBuilder(url, headers: headers, schema: schema)
        .rpc(params);
  }
}
