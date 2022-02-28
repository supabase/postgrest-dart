import 'package:postgrest/postgrest.dart';
import 'package:test/test.dart';

void main() {
  const rootUrl = 'http://localhost:3000';
  late PostgrestClient postgrest;
  late final List<Map<String, dynamic>> users;
  late final List<Map<String, dynamic>> channels;
  late final List<Map<String, dynamic>> messages;

  setUpAll(() async {
    postgrest = PostgrestClient(rootUrl);
    users = List<Map<String, dynamic>>.from(
      (await postgrest.from('users').select().execute()).data as List,
    );
    channels = List<Map<String, dynamic>>.from(
      (await postgrest.from('channels').select().execute()).data as List,
    );
    messages = List<Map<String, dynamic>>.from(
      (await postgrest.from('messages').select().execute()).data as List,
    );
  });

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  tearDown(() async {
    await postgrest.from('users').delete().execute();
    await postgrest.from('channels').delete().execute();
    await postgrest.from('messages').delete().execute();
    await postgrest.from('users').insert(users).execute();
    await postgrest.from('channels').insert(channels).execute();
    await postgrest.from('messages').insert(messages).execute();
  });

  test('not', () async {
    final res = await postgrest
        .from('users')
        .select('status')
        .not('status', 'eq', 'OFFLINE')
        .execute();
    for (final item in res.data as List) {
      expect((item as Map)['status'] != ('OFFLINE'), true);
    }
  });

  test('not with in filter', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .not('username', 'in', ['supabot', 'kiwicopple']).execute();
    for (final item in res.data as List) {
      expect((item as Map)['username'] != ('supabot'), true);
      expect(item['username'] != ('kiwicopple'), true);
    }
  });

  test('or', () async {
    final res = await postgrest
        .from('users')
        .select('status, username')
        .or('status.eq.OFFLINE,username.eq.supabot')
        .execute();
    for (final item in res.data as List) {
      expect(
        (item as Map)['username'] == ('supabot') ||
            item['status'] == ('OFFLINE'),
        true,
      );
    }
  });

  test('eq', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .eq('username', 'supabot')
        .execute();

    for (final item in res.data as List) {
      expect((item as Map)['username'] == ('supabot'), true);
    }
  });

  test('neq', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .neq('username', 'supabot')
        .execute();
    for (final item in res.data as List) {
      expect((item as Map)['username'] == ('supabot'), false);
    }
  });

  test('gt', () async {
    final res =
        await postgrest.from('messages').select('id').gt('id', 1).execute();
    for (final item in res.data as List) {
      expect(((item as Map)['id'] as int) > 1, true);
    }
  });

  test('gte', () async {
    final res =
        await postgrest.from('messages').select('id').gte('id', 1).execute();
    for (final item in res.data as List) {
      expect(((item as Map)['id'] as int) < 1, false);
    }
  });

  test('lt', () async {
    final res =
        await postgrest.from('messages').select('id').lt('id', 2).execute();
    for (final item in res.data as List) {
      expect(((item as Map)['id'] as int) < 2, true);
    }
  });

  test('lte', () async {
    final res =
        await postgrest.from('messages').select('id').lte('id', 2).execute();
    for (final item in res.data as List) {
      expect(((item as Map)['id'] as int) > 2, false);
    }
  });

  test('like', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .like('username', '%supa%')
        .execute();
    for (final item in res.data as List) {
      expect(((item as Map)['username'] as String).contains('supa'), true);
    }
  });

  test('ilike', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .ilike('username', '%SUPA%')
        .execute();
    for (final item in res.data as List) {
      final user = ((item as Map)['username'] as String).toLowerCase();
      expect(user.contains('supa'), true);
    }
  });

  test('is', () async {
    final res = await postgrest
        .from('users')
        .select('data')
        .is_('data', null)
        .execute();
    for (final item in res.data as List) {
      expect((item as Map)['data'], null);
    }
  });

  test('in', () async {
    final res = await postgrest
        .from('users')
        .select('status')
        .in_('status', ['ONLINE', 'OFFLINE']).execute();
    for (final item in res.data as List) {
      expect(
        (item as Map)['status'] == 'ONLINE' || item['status'] == 'OFFLINE',
        true,
      );
    }
  });

  test('contains', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .contains('age_range', '[1,2)')
        .execute();
    expect(
      ((res.data as List)[0] as Map)['username'],
      'supabot',
    );
  });

  test('containedBy', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .containedBy('age_range', '[1,2)')
        .execute();
    expect(((res.data as List)[0] as Map)['username'], 'supabot');
  });

  test('rangeLt', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .rangeLt('age_range', '[2,25)')
        .execute();
    expect(((res.data as List)[0] as Map)['username'], 'supabot');
  });

  test('rangeGt', () async {
    final res = await postgrest
        .from('users')
        .select('age_range')
        .rangeGt('age_range', '[2,25)')
        .execute();
    for (final item in res.data as List) {
      expect((item as Map)['username'] != 'supabot', true);
    }
  });

  test('rangeGte', () async {
    final res = await postgrest
        .from('users')
        .select('age_range')
        .rangeGte('age_range', '[2,25)')
        .execute();
    for (final item in res.data as List) {
      expect((item as Map)['username'] != 'supabot', true);
    }
  });

  test('rangeLte', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .rangeLte('age_range', '[2,25)')
        .execute();
    for (final item in res.data as List) {
      expect((item as Map)['username'] == 'supabot', true);
    }
  });

  test('rangeAdjacent', () async {
    final res = await postgrest
        .from('users')
        .select('age_range')
        .rangeAdjacent('age_range', '[2,25)')
        .execute();
    expect((res.data as List).length, 3);
  });

  test('overlaps', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .overlaps('age_range', '[2,25)')
        .execute();
    expect(
      ((res.data as List)[0] as Map)['username'],
      'dragarcia',
    );
  });

  test('textSearch', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .textSearch('catchphrase', "'fat' & 'cat'", config: 'english')
        .execute();
    expect(((res.data as List)[0] as Map)['username'], 'supabot');
  });

  test('textSearch with plainto_tsquery', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .textSearch(
          'catchphrase',
          "'fat' & 'cat'",
          config: 'english',
          type: TextSearchType.plain,
        )
        .execute();
    expect(((res.data as List)[0] as Map)['username'], 'supabot');
  });

  test('textSearch with phraseto_tsquery', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .textSearch(
          'catchphrase',
          'cat',
          config: 'english',
          type: TextSearchType.phrase,
        )
        .execute();
    expect((res.data as List).length, 2);
  });

  test('textSearch with websearch_to_tsquery', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .textSearch(
          'catchphrase',
          "'fat' & 'cat'",
          config: 'english',
          type: TextSearchType.websearch,
        )
        .execute();
    expect(((res.data as List)[0] as Map)['username'], 'supabot');
  });

  test('multiple filters', () async {
    final res = await postgrest
        .from('users')
        .select()
        .eq('username', 'supabot')
        .is_('data', null)
        .overlaps('age_range', '[1,2)')
        .eq('status', 'ONLINE')
        .textSearch('catchphrase', 'cat')
        .execute();
    expect(((res.data as List)[0] as Map)['username'], 'supabot');
  });

  test('filter', () async {
    final res = await postgrest
        .from('users')
        .select()
        .filter('username', 'eq', 'supabot')
        .execute();
    expect(((res.data as List)[0] as Map)['username'], 'supabot');
  });

  test('match', () async {
    final res = await postgrest
        .from('users')
        .select()
        .match({'username': 'supabot', 'status': 'ONLINE'}).execute();
    expect(((res.data as List)[0] as Map)['username'], 'supabot');
  });

  test('filter on rpc', () async {
    final res = await postgrest
        .rpc('get_username_and_status', params: {'name_param': 'supabot'})
        .neq('status', 'ONLINE')
        .execute();
    expect((res.data as List).isEmpty, true);
  });

  test('date range filter 1', () async {
    final res = await postgrest
        .from('messages')
        .select()
        .gte('inserted_at', DateTime.parse('2021-06-24').toIso8601String())
        .lte('inserted_at', DateTime.parse('2021-06-26').toIso8601String())
        .execute();
    expect((res.data as List).length, 1);
  });

  test('date range filter 2', () async {
    final res = await postgrest
        .from('messages')
        .select()
        .gte('inserted_at', DateTime.parse('2021-06-24').toIso8601String())
        .lte('inserted_at', DateTime.parse('2021-06-30').toIso8601String())
        .execute();
    expect((res.data as List).length, 2);
  });
}
