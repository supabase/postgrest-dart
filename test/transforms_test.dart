import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  var rootUrl = 'http://localhost:3000';
  var postgrest = PostgrestClient(rootUrl);

  test('order', () async {
    var res = await postgrest
        .from('users')
        .select()
        .order('username', {'ascending': false}).end();
    expect(res['body'][1]['username'], 'kiwicopple');
    expect(res['body'][3]['username'], 'awailas');
  });
}
