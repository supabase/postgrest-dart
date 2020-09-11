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

  Builder filter(String columnName, String operator, dynamic criteria) {
    this.queryFilters.add({
      'filter': 'filter',
      'columnName': columnName,
      'operator': operator,
      'criteria': criteria
    });

    return this;
  }

  Builder not(String columnName, String operator, dynamic criteria) {
    this.queryFilters.add({
      'filter': 'not',
      'columnName': columnName,
      'operator': operator,
      'criteria': criteria
    });

    return this;
  }

  Builder or(String filters) {
    this.queryFilters.add({
      'filter': 'or',
      'filters': filters,
    });

    return this;
  }

  Builder match(Map query) {
    this.queryFilters.add({
      'filter': 'match',
      'query': query,
    });

    return this;
  }

  Builder order(String columnName,
      [bool ascending = false, bool nullsFirst = false]) {
    this.queryFilters.add({
      'filter': 'order',
      'columnName': columnName,
      'ascending': ascending,
      'nullsFirst': nullsFirst
    });

    return this;
  }

  Builder limit(int criteria, [String columnName]) {
    this.queryFilters.add({
      'filter': 'limit',
      'criteria': criteria,
      'columnName': columnName,
    });

    return this;
  }

  Builder offset(int criteria, [String columnName]) {
    this.queryFilters.add({
      'filter': 'offset',
      'columnName': columnName,
      'criteria': criteria,
    });

    return this;
  }

  Builder range(int from, [int to = -1]) {
    this.queryFilters.add({
      'filter': 'range',
      'from': from,
      'to': to,
    });

    return this;
  }

  Builder single() {
    this.queryFilters.add({
      'filter': 'single',
    });

    return this;
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

    if (data is List) {
      return {
        'body': null,
        'status': 400,
        'statusCode': 400,
        'statusText': 'Data type should be an object or a string.',
      };
    }

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

  Builder eq(String columnName, dynamic criteria) {
    this.filter(columnName, 'eq', criteria);
    return this;
  }

  Builder neq(String columnName, dynamic criteria) {
    this.filter(columnName, 'neq', criteria);
    return this;
  }

  Builder gt(String columnName, dynamic criteria) {
    this.filter(columnName, 'gt', criteria);
    return this;
  }

  Builder lt(String columnName, dynamic criteria) {
    this.filter(columnName, 'lt', criteria);
    return this;
  }

  Builder gte(String columnName, dynamic criteria) {
    this.filter(columnName, 'gte', criteria);
    return this;
  }

  Builder lte(String columnName, dynamic criteria) {
    this.filter(columnName, 'lte', criteria);
    return this;
  }

  Builder like(String columnName, dynamic criteria) {
    this.filter(columnName, 'like', criteria);
    return this;
  }

  Builder ilike(String columnName, dynamic criteria) {
    this.filter(columnName, 'ilike', criteria);
    return this;
  }

  Builder $is(String columnName, dynamic criteria) {
    this.filter(columnName, 'is', criteria);
    return this;
  }

  Builder $in(String columnName, dynamic criteria) {
    this.filter(columnName, 'in', criteria);
    return this;
  }

  Builder fts(String columnName, dynamic criteria) {
    this.filter(columnName, 'fts', criteria);
    return this;
  }

  Builder plfts(String columnName, dynamic criteria) {
    this.filter(columnName, 'plfts', criteria);
    return this;
  }

  Builder phfts(String columnName, dynamic criteria) {
    this.filter(columnName, 'phfts', criteria);
    return this;
  }

  Builder wfts(String columnName, dynamic criteria) {
    this.filter(columnName, 'wfts', criteria);
    return this;
  }

  Builder cs(String columnName, dynamic criteria) {
    this.filter(columnName, 'cs', criteria);
    return this;
  }

  Builder cd(String columnName, dynamic criteria) {
    this.filter(columnName, 'cd', criteria);
    return this;
  }

  Builder ova(String columnName, dynamic criteria) {
    this.filter(columnName, 'ova', criteria);
    return this;
  }

  Builder ovr(String columnName, dynamic criteria) {
    this.filter(columnName, 'ovr', criteria);
    return this;
  }

  Builder sl(String columnName, dynamic criteria) {
    this.filter(columnName, 'sl', criteria);
    return this;
  }

  Builder sr(String columnName, dynamic criteria) {
    this.filter(columnName, 'sr', criteria);
    return this;
  }

  Builder nxr(String columnName, dynamic criteria) {
    this.filter(columnName, 'nxr', criteria);
    return this;
  }

  Builder nxl(String columnName, dynamic criteria) {
    this.filter(columnName, 'nxl', criteria);
    return this;
  }

  Builder adj(String columnName, dynamic criteria) {
    this.filter(columnName, 'adj', criteria);
    return this;
  }
}
