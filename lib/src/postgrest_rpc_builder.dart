import 'package:http/http.dart';
import 'package:postgrest/postgrest.dart';

class PostgrestRpcBuilder extends PostgrestBuilder {
  PostgrestRpcBuilder(
    String url, {
    Map<String, String>? headers,
    String? schema,
    BaseClient? httpClient,
  }) : super(
          url: Uri.parse(url),
          headers: headers ?? {},
          schema: schema,
          httpClient: httpClient,
        );

  /// Performs stored procedures on the database.
  PostgrestFilterBuilder rpc([dynamic params]) {
    method = 'POST';
    body = params;
    return PostgrestFilterBuilder(this);
  }
}
