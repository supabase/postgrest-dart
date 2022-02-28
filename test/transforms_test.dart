import 'package:postgrest/postgrest.dart';
import 'package:test/test.dart';

void main() {
  const rootUrl = 'http://localhost:3000';
  late PostgrestClient postgrest;

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  test('order', () async {
    final res =
        await postgrest.from('users').select().order('username').execute();
    expect(
      ((res.data as List)[1] as Map)['username'],
      'kiwicopple',
    );
    expect(((res.data as List)[3] as Map)['username'], 'awailas');
  });

  test('order on multiple columns', () async {
    final res = await postgrest
        .from('users')
        .select()
        .order('status', ascending: true)
        .order('username')
        .execute();
    expect(
      (res.data as List).map((row) => (row as Map)['username']),
      [
        'supabot',
        'dragarcia',
        'awailas',
        'kiwicopple',
      ],
    );
  });

  test('limit', () async {
    final res = await postgrest.from('users').select().limit(1).execute();
    expect((res.data as List).length, 1);
  });

  test('range', () async {
    const from = 1;
    const to = 3;
    final res =
        await postgrest.from('users').select().range(from, to).execute();
    //from -1 so that the index is included
    expect((res.data as List).length, to - (from - 1));
  });

  test('range 1-1', () async {
    const from = 1;
    const to = 1;
    final res =
        await postgrest.from('users').select().range(from, to).execute();
    //from -1 so that the index is included
    expect((res.data as List).length, to - (from - 1));
  });

  test('single', () async {
    final res = await postgrest
        .from('users')
        .select()
        .eq('username', 'supabot')
        .single()
        .execute();
    expect((res.data as Map)['username'], 'supabot');
    expect((res.data as Map)['status'], 'ONLINE');
  });

  test('maybeSingle', () async {
    final res = await postgrest
        .from('users')
        .select()
        .eq('username', 'goldstein')
        .maybeSingle()
        .execute();
    expect(res.status, 200);
    expect(res.data, isNull);
  });
}
