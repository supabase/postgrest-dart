import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:postgrest/utils/filters.dart';
import 'package:postgrest/utils/helpers.dart';

class Request extends http.BaseClient {
  String method;
  String url;
  Map<String, String> headers;
  List query = [];
  dynamic _body;

  Request(String method, String url, [Map<String, String> headers]) {
    this.method = method;
    this.url = url;
    this.headers = headers == null ? {} : headers;
    this.headers[HttpHeaders.acceptHeader] = 'application/json';
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(headers);
    return request.send();
  }

  /// Set `data` as the request body.
  /// @param {String|Object|Array} data
  /// @return {Request} The API request object.
  body(dynamic data) {
    _body = data;
  }

  /// Add query-string `val`.
  ///
  /// Examples:
  ///
  ///   request.get('/shoes')
  ///     .query('size=10')
  ///     .query({ color: 'blue' })
  ///
  /// @param {Object|String} val
  /// @return {Request} for chaining
  /// @api public

  _query(dynamic val) {
    if (val is! String) val = _serialize(val);
    if (val is String) this.query.add("$val");
    return this;
  }

  /// Serialize the given `obj`.
  ///
  /// @param {Object} obj
  /// @return {String}
  /// @api private
  _serialize(Map obj) {
    if (obj == null || obj is! Map) return obj;
    var pairs = [];
    obj.forEach((k, v) => _pushEncodedKeyValuePair(pairs, k, v));

    return pairs.join('&');
  }

  /// Helps 'serialize' with serializing arrays.
  /// Mutates the pairs array.
  ///
  /// @param {Array} pairs
  /// @param {String} key
  /// @param {Mixed} val
  _pushEncodedKeyValuePair(List pairs, String key, dynamic val) {
    if (val == null) {
      pairs.add(Uri.encodeFull(key));
      return;
    }

    if (val is List) {
      val.forEach((v) {
        _pushEncodedKeyValuePair(pairs, key, v);
      });
    } else if (val is Map) {
      val.forEach((k, v) => _pushEncodedKeyValuePair(pairs, "$key[$k]", v));
    } else {
      pairs.add(Uri.encodeFull(key) + '=' + Uri.encodeComponent(val));
    }
  }

  /// Set auth using special formats. If only one string parameter is passed, it
  /// is interpreted as a bearer token. If an object and nothing else is passed,
  /// `user` and `pass` keys are extracted from it and used for basic auth.
  ///
  /// @param {string|object} user The user, bearer token, or user/pass object.
  /// @param {string|void} pass The pass or undefined.
  /// @returns {Request} The API request object.
  auth(dynamic user, {String pass}) {
    if (user is String && pass == null) {
      this.headers[HttpHeaders.authorizationHeader] = "Bearer $user";
      return;
    }

    if (user is Map) {
      pass = user['pass'];
      user = user['user'];
    }

    var bytes = utf8.encode("$user:$pass");
    var base64Str = base64.encode(bytes);
    this.headers[HttpHeaders.authorizationHeader] = "Basic $base64Str";

    return this;
  }

  /// Generic filter method.
  /// @param {string} columnName The name of the column.
  /// @param {string} filter The type of filter
  /// @param { object | array | string | integer | boolean | null } criteria The value of the column to be filtered.
  /// @name filter
  /// @function
  /// @memberOf module:Filters
  /// @returns {Request} The API request object.
  filter(String columnName, String operator, dynamic criteria) {
    if (['in', 'cs', 'cd', 'ova', 'ovr', 'sl', 'sr', 'nxr', 'nxl', 'adj']
            .contains(operator) &&
        criteria is! List) {
      return {
        'body': null,
        'status': 400,
        'statusCode': 400,
        'statusText':
            ".$operator() cannot be invoked with criteria that is not an Array.",
      };
    }

    // for ranges, length of array should always be equal to 2
    if (['ovr', 'sl', 'sr', 'nxr', 'nxl', 'adj'].contains(operator) &&
        criteria.length != 2) {
      return {
        'body': null,
        'status': 400,
        'statusCode': 400,
        'statusText':
            ".$operator() can only be invoked with a criteria that is an Array of length 2.",
      };
    }

    if (['fts', 'plfts', 'phfts', 'wfts'].contains(operator) &&
        criteria['queryText'] == 'undefined') {
      return {
        'body': null,
        'status': 400,
        'statusCode': 400,
        'statusText':
            ".$operator() can only be invoked with a criteria that is an Object with key queryText.",
      };
    }

    var filterFunction = Filters.getFunction("${operator.toLowerCase()}");
    var newQuery = filterFunction(columnName, criteria);

    return _query("${this.url}$newQuery");
  }

  /// Provides the inverse of the filter stated.
  /// @param {string} columnName The name of the column.
  /// @param {string} filter The type of filter
  /// @param { object | array | string | integer | boolean | null } criteria The value of the column to be filtered.
  /// @name filter
  /// @function
  /// @memberOf module:Filters
  /// @returns {Request} The API request object.
  not(String columnName, String operator, dynamic criteria) {
    var filterFunction = Filters.getFunction("${operator.toLowerCase()}");
    var newQuery = filterFunction(columnName, criteria);
    var enrichedQuery =
        "${newQuery.split('=')[0]}=not.${newQuery.split('=')[1]}";
    return _query(enrichedQuery);
  }

  /// Filter result rows by adding conditions on columns
  ///
  /// @example
  /// $or('id.gt.20,and(name.eq.New Zealand,name.eq.France)')
  ///
  /// @param {string} filters to satisfy
  /// @returns {Request} The API request object.
  or(String filters) {
    var filterFunction = Filters.getFunction("or");
    var newQuery = filterFunction(filters);
    return _query(newQuery);
  }

  /// Takes a query object and translates it to a PostgREST filter query string.
  /// All values are prefixed with `eq.`.
  ///
  /// @param {object} query The object to match against.
  /// @returns {Request} The API request object.
  match(Map query) {
    query.forEach((k, v) => _query("$k=eq.$v"));
    return this;
  }

  /// Cleans up a select string by stripping all whitespace. Then the string is
  /// set as a query string value. Also always forces a root @id column.
  ///
  /// @param {string} select The unformatted select string.
  /// @returns {Request} The API request object.
  select(String select) {
    if (select != null) {
      _query({select: select.replaceAll(RegExp(r'\s'), '')});
    }
    return this;
  }

  /// Tells PostgREST in what order the result should be returned.
  ///
  /// @param {string} columnName The columnName name to order by.
  /// @param {bool} ascending True for descending results, false by default.
  /// @param {bool} nullsFirst True for nulls first, false by default.
  /// @returns {Request} The API request object.
  order(String columnName, [bool ascending = false, bool nullsFirst = false]) {
    var cleanedResult = Helpers.cleanColumnName(columnName);
    var cleanedColumnName = cleanedResult['cleanedColumnName'];
    var foreignTableName = cleanedResult['foreignTableName'];

    var tableName = foreignTableName != null ? "$foreignTableName." : '';
    _query(
        "${tableName}order=$cleanedColumnName.${ascending ? 'asc' : 'desc'}.${nullsFirst ? 'nullsfirst' : 'nullslast'}");
    return this;
  }

  /// Tells PostgREST in what limit the result should be returned.
  ///
  /// @param {Int} criteria The number of rows to return.
  /// @param {string} columnName The columnName name to limit.
  /// @returns {Request} The API request object.
  limit(int criteria, [String columnName]) {
    if (criteria is! int) {
      return {
        'body': null,
        'status': 400,
        'statusCode': 400,
        'statusText':
            ".limit() cannot be invoked with criteria that is not a number.",
      };
    }

    var column = columnName != null ? "$columnName." : '';
    _query("${column}limit=$criteria");
    return this;
  }

  /// Tells PostgREST in what offset the result should be returned.
  ///
  /// @param {Int} criteria The number of rows to skip before starting to return.
  /// @param {string} columnName The columnName name to offset.
  /// @returns {Request} The API request object.
  offset(int criteria, [String columnName]) {
    if (criteria is! int) {
      return {
        'body': null,
        'status': 400,
        'statusCode': 400,
        'statusText':
            ".offset() cannot be invoked with criteria that is not a number.",
      };
    }

    var column = columnName != null ? "$columnName." : '';
    _query("${column}offset=$criteria");
    return this;
  }

  /// Specify a range of items for PostgREST to return. If the second value is
  /// not defined, the rest of the collection will be sent back.
  ///
  /// @param {number} from The first object to select.
  /// @param {number} to The last object to select. Value -1 considered as null.
  /// @returns {Request} The API request object.
  range(int from, [int to = -1]) {
    if (from is! int || to is! int) {
      return {
        'body': null,
        'status': 400,
        'statusCode': 400,
        'statusText':
            ".range() cannot be invoked with parameters that are not numbers.",
      };
    }

    var lowerBound = from;
    var upperBound = to == -1 ? '' : to;

    this.headers['Range-Unit'] = 'items';
    this.headers[HttpHeaders.rangeHeader] = "$lowerBound-$upperBound";
    return this;
  }

  /// Sets the header which signifies to PostgREST the response must be a single
  /// object or 406 Not Acceptable.
  ///
  /// @returns {Request} The API request object.
  single() {
    this.headers[HttpHeaders.acceptHeader] =
        'application/vnd.pgrst.object+json';
    this.headers['Prefer'] = 'return=representation';

    return this;
  }

  /// Sends the request and returns a Future.
  /// catch any error and returns with status 500
  ///
  /// @returns {Future} Resolves when the request has completed.
  Future<Map<String, dynamic>> end() async {
    try {
      var requestUrl = this.url;
      var uppercaseMethod = this.method.toUpperCase();
      var response;

      if (['DELETE', 'PATCH'].contains(uppercaseMethod) &&
          this.query.length == 0) {
        var methodString =
            uppercaseMethod == 'DELETE' ? '.delete()' : '.update()';

        return {
          'body': null,
          'status': 400,
          'statusCode': 400,
          'statusText': "$methodString cannot be invoked without any filters.",
        };
      }

      if (uppercaseMethod == "GET") {
        var params = this.query.length > 0 ? this.query.join('&') : "";
        if (params != null) requestUrl += "?$params";
        response = await this.get(requestUrl);
      } else if (uppercaseMethod == "POST") {
        response = await this.post(requestUrl, body: _body);
      } else if (uppercaseMethod == "PUT") {
        response = await this.put(requestUrl, body: _body);
      } else if (uppercaseMethod == "PATCH") {
        response = await this.patch(requestUrl, body: _body);
      } else if (uppercaseMethod == "DELETE") {
        var params = this.query.length > 0 ? this.query.join('&') : "";
        if (params != null) requestUrl += "?$params";
        response = await this.delete(requestUrl);
      }

      return parseJsonResponse(response);
    } catch (e) {
      return {
        'body': null,
        'status': 500,
        'statusCode': e.runtimeType.toString(),
        'statusText': e.toString()
      };
    }
  }

  /// Parse request response to json object
  ///
  /// @returns {Map<String, dynamic>}
  Map<String, dynamic> parseJsonResponse(dynamic response) {
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return {
        'body': json.decode(response.body),
        'status': response.statusCode,
        'statusCode': response.statusCode,
        'statusText': null,
      };
    } else {
      return {
        'body': null,
        'status': response.statusCode,
        'statusCode': response.statusCode,
        'statusText': response.body.toString(),
      };
    }
  }

  /// Makes the Request object then-able. Allows for usage with
  /// `Promise.resolve` and async/await contexts. Just a proxy for `.then()` on
  /// the promise returned from `.end()`.
  ///
  /// @param {function} Called when the request resolves.
  /// @param {function} Called when the request errors.
  /// @returns {Future} Resolves when the resolution resolves.
  ///
  then(FutureOr<dynamic> onValue(dynamic value), {Function onError}) {
    return this.end().then(onValue, onError: onError);
  }

  /// Just a proxy for `.catch()` on the promise returned from `.end()`.
  ///
  /// @param {function} Called when the request errors.
  /// @returns {Future} Resolves when there is an error.
  ///
  catchError(Function onError) {
    return this.end().catchError(onError);
  }
}
