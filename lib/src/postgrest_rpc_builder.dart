import 'package:postgrest/postgrest.dart';

class PostgrestRpcBuilder extends PostgrestBuilder {
  PostgrestRpcBuilder(
    String url, {
    Map<String, String>? headers,
    String? schema,
  }) : super(
          url: Uri.parse(url),
          headers: headers ?? {},
          schema: schema,
        );

  /// Performs stored procedures on the database.
  PostgrestFilterBuilder rpc([dynamic params]) {
    method = 'POST';
    body = params;
    return PostgrestFilterBuilder(this);
  }
}
