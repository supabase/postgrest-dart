import 'dart:io';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:postgrest/request.dart';

void main() {
  test('will only ever accept json', () {
    Request request = Request('GET', '/');
    expect(request.headers[HttpHeaders.acceptHeader], 'application/json');
  });
  test('will init with url and headers', () {
    Request request = Request('GET', '/', {'a': 'b'});
    expect(request.url, '/');
    expect(request.headers, {'a': 'b', 'accept': 'application/json'});
  });
  test('will authorize in auth() using a token', () {
    Request request = Request('GET', '/');
    request.auth('token');
    expect(request.headers[HttpHeaders.authorizationHeader], 'Bearer token');
  });
  test('will authorize in auth() using a basic auth object', () {
    var user = 'user';
    var pass = 'pass';
    var bytes = utf8.encode("$user:$pass");
    var base64Str = base64.encode(bytes);
    Request request = Request('GET', '/').auth({'user': user, 'pass': pass});
    expect(
        request.headers[HttpHeaders.authorizationHeader], "Basic $base64Str");
  });
  test('will translate match() key/values to filter', () {
    var request =
        Request('GET', '/').match({'key1': 'value1', 'key2': 'value2'});
    expect(request.query, ['key1=eq.value1', 'key2=eq.value2']);
  });
  test('won‘t assign to the passed match() filter', () {
    var match = {'key1': 'value1', 'key2': 'value2'};
    var request = Request('GET', '/').match(match);
    expect(request.query, ['key1=eq.value1', 'key2=eq.value2']);
    expect(match, {'key1': 'value1', 'key2': 'value2'});
  });
  test('will translate not() into  modified filter', () {
    var request = Request('GET', '/').not('key1', 'in', ['value1', 'value2']);
    expect(request.query, ['key1=not.in.(value1,value2)']);
  });
  test('will translate order() into a query', () {
    var request = Request('GET', '/').order('columnName');
    expect(request.query, ['order=columnName.desc.nullslast']);
    var request2 = Request('GET', '/').order('columnName', true);
    expect(request2.query, ['order=columnName.asc.nullslast']);
    var request3 = Request('GET', '/').order('columnName', false, true);
    expect(request3.query, ['order=columnName.desc.nullsfirst']);
  });
  test('will translate order() of an embedded table into a query', () {
    var request = Request('GET', '/').order('foreignTable.columnName');
    expect(request.query, ['foreignTable.order=columnName.desc.nullslast']);
  });
  test('will translate limit() into a query', () {
    var request = Request('GET', '/').limit(1);
    expect(request.query, ['limit=1']);
  });
  test('will translate limit() of an embedded table into a query', () {
    var request = Request('GET', '/').limit(1, 'foreignTable');
    expect(request.query, ['foreignTable.limit=1']);
  });
  test('will translate offset() into a query', () {
    var request = Request('GET', '/').offset(1);
    expect(request.query, ['offset=1']);
  });
  test('will translate offset() of an embedded table into a query', () {
    var request = Request('GET', '/').offset(1, 'foreignTable');
    expect(request.query, ['foreignTable.offset=1']);
  });
  test('will translate single() into headers config', () {
    var request = Request('GET', '/').single();
    expect(request.headers[HttpHeaders.acceptHeader],
        'application/vnd.pgrst.object+json');
    expect(request.headers['Prefer'], 'return=representation');
  });
  test('will return a Future<Map> from end()', () {
    var future = Request('GET', '/').end();
    expect(future, isInstanceOf<Future<Map>>());
  });
  test('can be resolved', () {
    var future = Request('GET', '/').end();
    expect(future, isInstanceOf<Future<Map>>());
    future.then((value) {
      expect(value['body'], null);
      expect(value['status'], 500);
      expect(value['statusCode'], 'ArgumentError');
    }).catchError((error) => throw error);
  });
  test('can be used in an async/await context', () async {
    var response = await Request('DELETE', '/').end();
    expect(response['statusCode'], 400);
  });
}
