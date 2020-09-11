import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  String rootUrl = 'https://localhost:3000/';

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
}
