import 'package:postgrest/request.dart';

/// Allows the user to stack the filter functions before they call any of
///
/// select() - "get"
///
/// insert() - "post"
///
/// update() - "patch"
///
/// delete() - "delete"
///
/// Once any of these are called the filters are passed down to the Request
///
/// @class
/// @param {string} url The full URL
class Builder {
  String url;
  Map headers;
  String schema;
  List queryFilters = [];

  Builder(String url, [Map headers, String schema]) {
    this.url = url;
    this.headers = headers == null ? {} : headers;
    this.schema = schema;
  }

  Request request(String method) {
    if (this.schema != null) {
      if (method == 'GET')
        this.headers['Accept-Profile'] = this.schema;
      else
        this.headers['Content-Profile'] = this.schema;
    }
    return new Request(method, this.url, this.headers);
  }

  addFilters(Request request) {
    // loop through this.queryFilters
    this.queryFilters.forEach((queryFilter) {
      switch (queryFilter['filter']) {
        case 'filter':
          request.filter(queryFilter['columnName'], queryFilter['operator'],
              queryFilter['criteria']);
          break;

        case 'not':
          request.not(queryFilter['columnName'], queryFilter['operator'],
              queryFilter['criteria']);
          break;

        case 'or':
          request.or(queryFilter['filters']);
          break;

        case 'match':
          request.match(queryFilter['query']);
          break;

        case 'order':
          request.order(queryFilter['columnName'], queryFilter['ascending'],
              queryFilter['nullsFirst']);
          break;

        case 'limit':
          request.limit(queryFilter['criteria'], queryFilter['columnName']);
          break;

        case 'offset':
          request.offset(queryFilter['criteria'], queryFilter['columnName']);
          break;

        case 'range':
          request.range(queryFilter['from'], queryFilter['to']);
          break;

        case 'single':
          request.single();
          break;

        default:
          break;
      }
    });
  }

  ///
  /// Start a "GET" request
  ///
  select(String columnQuery) {
    if (columnQuery == null) columnQuery = '*';

    var method = 'GET';
    var request = this.request(method);

    request.select(columnQuery);
    this.addFilters(request);

    return request;
  }

  ///
  /// Start a "POST" request
  ///
  insert(data, [Map options]) {
    if (options == null) options = {'upsert': false};

    var method = 'POST';
    var request = this.request(method);
    var header = options['upsert']
        ? 'return=representation,resolution=merge-duplicates'
        : 'return=representation';

    request.headers['Prefer'] = header;
    request.body(data);

    this.addFilters(request);

    return request;
  }

  ///
  /// Start a "PATCH" request
  ///
  update(dynamic data) {
    var method = 'PATCH';
    var request = this.request(method);

    request.headers['Prefer'] = 'return=representation';
    request.body(data);

    this.addFilters(request);

    return request;
  }

  ///
  /// Start a "DELETE" request
  ///
  delete() {
    var method = 'DELETE';
    var request = this.request(method);

    this.addFilters(request);

    return request;
  }
}
