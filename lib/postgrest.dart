library postgrest;

import "package:postgrest/builder.dart";
import "package:postgrest/request.dart";
import "package:postgrest/utils/helpers.dart";

class PostgrestClient {
  String restUrl;
  Map<String, String> headers = {};
  String queryString;
  String schema;

  PostgrestClient(String restUrl, [Map<String, dynamic> options]) {
    this.restUrl = restUrl;
    options = options == null ? {} : options;

    if (options.containsKey("headers")) {
      this.headers = options['headers'];
    }
    if (options.containsKey("queryParams")) {
      this.queryString = Helpers.objectToQueryString(options['queryParams']);
    }
    if (options.containsKey("schema")) {
      this.schema = options['schema'];
    }
  }

  Builder from(tableName) {
    var url = "${this.restUrl}/$tableName";

    if (this.queryString != null) {
      url += "?${this.queryString}";
    }

    return new Builder(url, this.headers, this.schema);
  }

  Request rpc(String functionName, [Map functionParameters]) {
    var url = "${this.restUrl}/rpc/$functionName";
    var headers = this.headers;

    if (this.queryString != null) {
      url += "?${this.queryString}";
    }
    if (this.schema != null) {
      headers['Content-Profile'] = this.schema;
    }

    var request = new Request('POST', url, headers);
    if (functionParameters != null) request.body(functionParameters);
    return request;
  }
}
