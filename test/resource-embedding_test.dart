import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  var rootUrl = 'http://localhost:3000';
  var postgrest = PostgrestClient(rootUrl);

  test('embedded select', () async {
    var res = await postgrest.from('users').select('messages(*)').end();
    expect(res.body[0]['messages'].length, 2);
    expect(res.body[1]['messages'].length, 0);
  });
}
