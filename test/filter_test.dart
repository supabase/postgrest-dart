import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  String rootUrl = 'http://localhost:3000';
  var postgrest = PostgrestClient(rootUrl);

  test("not", () async {
    var res = await postgrest.from('users').select().not('status', 'eq', 'OFFLINE').end();
    expect(res['body'].length, 3);
    expect(res['body'][1]['username'], 'awailas');
  });
}
