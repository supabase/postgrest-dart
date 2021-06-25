import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  const rootUrl = 'http://localhost:3000';
  late PostgrestClient postgrest;

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  test('order', () async {
    final res = await postgrest.from('users').select().order('username').execute();
    expect(res.data[1]['username'], 'kiwicopple');
    expect(res.data[3]['username'], 'awailas');
  });

  test('order on multiple columns', () async {
    final res = await postgrest.from('users').select().order('status', ascending: true).order('username').execute();
    expect(res.data[0]['username'], 'supabot');
    expect(res.data[2]['username'], 'kiwicopple');
    expect(res.data[3]['username'], 'dragarcia');
  });

  test('limit', () async {
    final res = await postgrest.from('users').select().limit(1).execute();
    expect(res.data.length, 1);
  });

  test('range', () async {
    const from = 1;
    const to = 3;
    final res = await postgrest.from('users').select().range(from, to).execute();
    //from -1 so that the index is included
    expect(res.data.length, to - (from - 1));
  });

  test('range 1-1', () async {
    const from = 1;
    const to = 1;
    final res = await postgrest.from('users').select().range(from, to).execute();
    //from -1 so that the index is included
    expect(res.data.length, to - (from - 1));
  });

  test('single', () async {
    final res = await postgrest.from('users').select().limit(1).single().execute();
    expect(res.data['username'], 'supabot');
    expect(res.data['status'], 'ONLINE');
  });
}
