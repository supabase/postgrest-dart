import 'postgrest_builder.dart';
import 'postgrest_transform_builder.dart';

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
  PostgrestTransformBuilder rpc([dynamic params]) {
    method = 'POST';
    body = params;
    return PostgrestTransformBuilder(this);
  }
}
