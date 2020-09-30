import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  String rootUrl = 'http://localhost:3000';
  var postgrest = PostgrestClient(rootUrl);

  test("basic select table", () async {
    var res = await postgrest.from('users').select().end();
    expect(res['body'].length, 4);
  });
}