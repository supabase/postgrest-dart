import 'package:http/http.dart';
import 'package:postgrest/src/constants.dart';
import 'package:postgrest/src/postgrest_builder.dart';

/// A PostgREST api client written in Dartlang. The goal of this library is to make an "ORM-like" restful interface.
class PostgrestClient {
  final String url;
  final Map<String, String> headers;
  final String? schema;
  final Client? httpClient;

  /// To create a [PostgrestClient], you need to provide an [url] endpoint.
  ///
  /// You can also provide [options] with `headers` and `schema` key-value if needed
  /// ```dart
  /// PostgrestClient(REST_URL)
  /// PostgrestClient(REST_URL, headers: {'apikey': 'foo'})
  /// ```
  ///
  /// [httpClient] is optional and can be used to provide a custom http client
  PostgrestClient(
    this.url, {
    Map<String, String>? headers,
    this.schema,
    this.httpClient,
  }) : headers = {...defaultHeaders, if (headers != null) ...headers};

  /// Authenticates the request with JWT.
  PostgrestClient auth(String token) {
    headers['Authorization'] = 'Bearer $token';
    return this;
  }

  /// Perform a table operation.
  PostgrestQueryBuilder from(String table) {
    final url = '${this.url}/$table';
    return PostgrestQueryBuilder(
      url,
      headers: headers,
      schema: schema,
      httpClient: httpClient,
    );
  }

  /// Perform a stored procedure call.
  ///
  /// ```dart
  /// postgrest.rpc('get_status', params: {'name_param': 'supabot'})
  /// ```
  PostgrestFilterBuilder rpc(String fn, {Map? params}) {
    final url = '${this.url}/rpc/$fn';
    return PostgrestRpcBuilder(
      url,
      headers: headers,
      schema: schema,
      httpClient: httpClient,
    ).rpc(params);
  }
}
