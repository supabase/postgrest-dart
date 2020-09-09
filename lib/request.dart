import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class Request extends http.BaseClient {
  String url;
  Map headers;

  Request(String url, {Map headers}) {
    this.url = url;
    this.headers = headers == null ? {} : headers;
    this.headers[HttpHeaders.acceptHeader] = 'application/json';
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(headers);
    return request.send();
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
  }

  /// Generic filter method.
  /// @param {string} columnName The name of the column.
  /// @param {string} filter The type of filter
  /// @param { object | array | string | integer | boolean | null } criteria The value of the column to be filtered.
  /// @name filter
  /// @function
  /// @memberOf module:Filters
  /// @returns {string}
  filter(String columnName, String operator, dynamic criteria) {
    if (['in', 'cs', 'cd', 'ova', 'ovr', 'sl', 'sr', 'nxr', 'nxl', 'adj']
            .contains(operator) &&
        !(criteria is List)) {
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

    // var newQuery = Filters[`_${operator.toLowerCase()}`](columnName, criteria)
    // return this.query(newQuery)
  }

  /// Provides the inverse of the filter stated.
  /// @param {string} columnName The name of the column.
  /// @param {string} filter The type of filter
  /// @param { object | array | string | integer | boolean | null } criteria The value of the column to be filtered.
  /// @name filter
  /// @function
  /// @memberOf module:Filters
  /// @returns {string}
  // not(String columnName, String operator, dynamic criteria) {
  //   let newQuery = Filters[`_${operator.toLowerCase()}`](columnName, criteria)
  //   let enrichedQuery = `${newQuery.split('=')[0]}=not.${newQuery.split('=')[1]}`
  //   return this.query(enrichedQuery)
  // }
}
