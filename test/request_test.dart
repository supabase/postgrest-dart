import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:postgrest/request.dart';

void main() {
  test('will only ever accept json', () {
    Request request = Request('/');
    expect(request.headers[HttpHeaders.acceptHeader], 'application/json');
  });
  test('will init with url and headers', () {
    Request request = Request('/', headers: {'a': 'b'});
    expect(request.url, '/');
    expect(request.headers, {'a': 'b', 'accept': 'application/json'});
  });
  test('will authorize in auth() using a token', () {
    Request request = Request('/');
    request.auth('token');
    expect(request.headers[HttpHeaders.authorizationHeader], 'Bearer token');
  });
  test('will authorize in auth() using a basic auth object', () {
    var user = 'user';
    var pass = 'pass';
    var bytes = utf8.encode("$user:$pass");
    var base64Str = base64.encode(bytes);
    Request request = Request('/');
    request.auth({'user': user, 'pass': pass});
    expect(
        request.headers[HttpHeaders.authorizationHeader], "Basic $base64Str");
  });
}
