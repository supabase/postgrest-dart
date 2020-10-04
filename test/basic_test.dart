import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  var rootUrl = 'http://localhost:3000';
  var postgrest = PostgrestClient(rootUrl);

  test('basic select table', () async {
    var res = await postgrest.from('users').select().end();
    expect(res['body'].length, 4);
  });

  test('stored procedure', () async {
    var res = await postgrest.rpc('get_status', {'name_param': 'supabot'}).end();
    expect(res['body'], 'ONLINE');
  });
}
