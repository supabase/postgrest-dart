import 'package:collection/collection.dart';
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
      (res.data as List).map((row) => (row as Map)['status']),
      [
        'ONLINE',
        'ONLINE',
        'ONLINE',
        'OFFLINE',
      ],
    );
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

  test('order with filters on the same column', () async {
    final res = await postgrest
        .from('users')
        .select()
        .gt('username', 'b')
        .lt('username', 'r')
        .order('username')
        .execute();
    expect(
      (res.data as List).map((row) => (row as Map)['username']),
      [
        'kiwicopple',
        'dragarcia',
      ],
    );
  });

  test("order on foreign table", () async {
    final response = await postgrest
        .from("users")
        .select(
          '''
          username,
          messages(
            id,
            reactions(
              emoji,
              created_at
            )
          )
        ''',
        )
        .eq("username", "supabot")
        .order("created_at",
            foreignTable: "messages.reactions", ascending: false)
        .single()
        .execute();

    final data = response.data as Map;
    final messages = data['messages'] as List;

    for (final message in messages) {
      final reactions = (message as Map)["reactions"] as List;
      final isSorted = reactions.isSorted((a, b) {
        final aCreatedAt = DateTime.parse((a as Map)["created_at"].toString());
        final bCreatedAt = DateTime.parse((b as Map)["created_at"].toString());
        return bCreatedAt.compareTo(aCreatedAt);
      });
      expect(isSorted, isTrue);
    }
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
