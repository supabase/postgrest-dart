import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  String rootUrl = 'https://localhost:3000/';

  createArrayFilterCheck(filter) {
    test("should not accept non-array data type for $filter", () async {
      var client = PostgrestClient(rootUrl);
      var res = await client
          .from('users')
          .select('*')
          .filter('username', filter, 'non-array');
      expect(res['statusText'],
          ".$filter() cannot be invoked with criteria that is not an Array.");
    });
  }

  createDataTypeCheck(filter) {
    test(
        "should throw an error for $filter when data type and filter are incompatible",
        () {
      var client = PostgrestClient(rootUrl);
      var future =
          client.from('users').select('*').filter('username', filter, [1, 2]);
      future.catchError((error) => throw error);
    });
  }

  createRangeFilterCheck(filter) {
    test("should not accept an array that is not of length 2 for $filter",
        () async {
      var client = PostgrestClient(rootUrl);
      var res = await client
          .from('users')
          .select('*')
          .filter('username', filter, [1, 2, 3]);
      expect(res['statusText'],
          ".$filter() can only be invoked with a criteria that is an Array of length 2.");
    });
  }

  createFullTextSearchCheck(filter) {
    test(
        "should not accept anything else that is not an Object and does not have they key queryText for $filter",
        () async {
      var client = PostgrestClient(rootUrl);
      var res = await client
          .from('users')
          .select('*')
          .filter('username', filter, [1, 2, 3]);
      expect(res['statusText'],
          ".$filter() can only be invoked with a criteria that is an Object with key queryText.");
    });
  }

  test('Initialise', () {
    var client = PostgrestClient(rootUrl);
    expect(client.restUrl, "$rootUrl");
  });
  test('With optional query params', () {
    var client = PostgrestClient(rootUrl, {
      'queryParams': {'some-param': 'foo', 'other-param': 'bar'}
    });
    expect(client.queryString, 'some-param=foo&other-param=bar');
  });
  test('With optional api key', () {
    var client = PostgrestClient(rootUrl, {
      'headers': {'apikey': 'some-key'}
    });
    expect(client.headers['apikey'], 'some-key');
  });
  test('With from(some_table)', () {
    var clientBuilder = PostgrestClient(rootUrl).from('some_table');
    expect(clientBuilder.url, "$rootUrl/some_table");
  });
  test('With rpc(stored_procedure)', () {
    var clientBuilder = PostgrestClient(rootUrl).rpc('stored_procedure');
    expect(clientBuilder.url, "$rootUrl/rpc/stored_procedure");
  });

  var arrayFilterList = [
    'in',
    'cs',
    'cd',
    'ova',
    'ovr',
    'sl',
    'sr',
    'nxr',
    'nxl',
    'adj'
  ];
  arrayFilterList.forEach((filter) => createArrayFilterCheck(filter));

  var dataTypeList = [
    'cs',
    'cd',
    'ova',
    'ovr',
    'sl',
    'sr',
    'nxr',
    'nxl',
    'adj'
  ];
  dataTypeList.forEach((filter) => createDataTypeCheck(filter));

  var rangeFilterList = ['ovr', 'sl', 'sr', 'nxr', 'nxl', 'adj'];
  rangeFilterList.forEach((filter) => createRangeFilterCheck(filter));

  var fullTextSearchList = ['fts', 'plfts', 'phfts', 'wfts'];
  fullTextSearchList.forEach((filter) => createFullTextSearchCheck(filter));

  test('should throw an error for limit() when criteria is not of type number',
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').select('*').limit('test');
    expect(res['statusText'],
        ".limit() cannot be invoked with criteria that is not a number.");
  });
  test('should throw an error for offset() when criteria is not of type number',
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').select('*').offset('test');
    expect(res['statusText'],
        ".offset() cannot be invoked with criteria that is not a number.");
  });
  test(
      'should throw an error for range() when first parameter is not of type number',
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').select('*').range('test');
    expect(res['statusText'],
        ".range() cannot be invoked with parameters that are not numbers.");
  });
  test(
      'should throw an error for range() when second parameter is not of type number and not null',
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').select('*').range(0, 'test');
    expect(res['statusText'],
        ".range() cannot be invoked with parameters that are not numbers.");
  });
}
