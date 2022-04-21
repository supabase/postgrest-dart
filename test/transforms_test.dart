import 'package:postgrest/postgrest.dart';
import 'package:test/test.dart';

import 'reset_helper.dart';

void main() {
  const rootUrl = 'http://localhost:3000';
  late PostgrestClient postgrest;
  final resetHelper = ResetHelper();

  setUpAll(() async {
    postgrest = PostgrestClient(rootUrl);
    await resetHelper.initialize(postgrest);
  });

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  tearDown(() async {
    await resetHelper.reset();
  });

  test('order', () async {
    final res = await postgrest.from('users').select().order('username');
    expect(
      ((res as List)[1] as Map)['username'],
      'kiwicopple',
    );
    expect(((res)[3] as Map)['username'], 'awailas');
  });

  test('order on multiple columns', () async {
    final res = await postgrest
        .from('users')
        .select()
        .order('status', ascending: true)
        .order('username');
    expect(
      (res as List).map((row) => (row as Map)['status']),
      [
        'ONLINE',
        'ONLINE',
        'ONLINE',
        'OFFLINE',
      ],
    );
    expect(
      (res).map((row) => (row as Map)['username']),
      [
        'supabot',
        'dragarcia',
        'awailas',
        'kiwicopple',
      ],
    );
  });

  test('order with filters on the same column', () async {
    final res = await postgrest
        .from('users')
        .select()
        .gt('username', 'b')
        .lt('username', 'r')
        .order('username');
    expect(
      (res as List).map((row) => (row as Map)['username']),
      [
        'kiwicopple',
        'dragarcia',
      ],
    );
  });

  test('limit', () async {
    final res = await postgrest.from('users').select().limit(1);
    expect((res as List).length, 1);
  });

  test('range', () async {
    const from = 1;
    const to = 3;
    final res = await postgrest.from('users').select().range(from, to);
    //from -1 so that the index is included
    expect((res as List).length, to - (from - 1));
  });

  test('range 1-1', () async {
    const from = 1;
    const to = 1;
    final res = await postgrest.from('users').select().range(from, to);
    //from -1 so that the index is included
    expect((res as List).length, to - (from - 1));
  });

  test('single', () async {
    final res = await postgrest
        .from('users')
        .select()
        .eq('username', 'supabot')
        .single();
    expect((res as Map)['username'], 'supabot');
    expect((res)['status'], 'ONLINE');
  });

  test('maybeSingle', () async {
    final Map<String, dynamic> user = await postgrest
        .from('users')
        .select()
        .eq('username', 'dragarcia')
        .maybeSingle();
    expect(user, isNotNull);
    expect(user['username'], 'dragarcia');
  });
}
