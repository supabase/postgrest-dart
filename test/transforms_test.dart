import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  var rootUrl = 'http://localhost:3000';
  var postgrest;

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  test('order', () async {
    var res = await postgrest.from('users').select().order('username', {'ascending': false}).end();
    expect(res.data[1]['username'], 'kiwicopple');
    expect(res.data[3]['username'], 'awailas');
  });

  test('limit', () async {
    var res = await postgrest.from('users').select().limit(1).end();
    expect(res.data.length, 1);
  });

  test('range', () async {
    var from = 1;
    var to = 3;
    var res = await postgrest.from('users').select().range(from, to).end();
    //from -1 so that the index is included
    expect(res.data.length, to - (from - 1));
  });

  test('range 1-1', () async {
    var from = 1;
    var to = 1;
    var res = await postgrest.from('users').select().range(from, to).end();
    //from -1 so that the index is included
    expect(res.data.length, to - (from - 1));
  });

  test('single', () async {
    var res = await postgrest.from('users').select().limit(1).single().end();
    expect(res.data['username'], 'supabot');
  });
}
