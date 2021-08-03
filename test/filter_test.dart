import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  const rootUrl = 'http://localhost:3000';
  late PostgrestClient postgrest;

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  test('not', () async {
    final res = await postgrest
        .from('users')
        .select('status')
        .not('status', 'eq', 'OFFLINE')
        .execute();
    res.data.forEach((item) {
      expect(item['status'] != ('OFFLINE'), true);
    });
  });

  test('not with in filter', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .not('username', 'in', ['supabot', 'kiwicopple']).execute();
    res.data.forEach((item) {
      expect(item['username'] != ('supabot'), true);
      expect(item['username'] != ('kiwicopple'), true);
    });
  });

  test('or', () async {
    final res = await postgrest
        .from('users')
        .select('status, username')
        .or('status.eq.OFFLINE,username.eq.supabot')
        .execute();
    res.data.forEach((item) {
      expect(item['username'] == ('supabot') || item['status'] == ('OFFLINE'),
          true);
    });
  });

  test('eq', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .eq('username', 'supabot')
        .execute();

    res.data.forEach((item) {
      expect(item['username'] == ('supabot'), true);
    });
  });

  test('neq', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .neq('username', 'supabot')
        .execute();
    res.data.forEach((item) {
      expect(item['username'] == ('supabot'), false);
    });
  });

  test('gt', () async {
    final res =
        await postgrest.from('messages').select('id').gt('id', 1).execute();
    res.data.forEach((item) {
      expect(item['id'] > 1, true);
    });
  });

  test('gte', () async {
    final res =
        await postgrest.from('messages').select('id').gte('id', 1).execute();
    res.data.forEach((item) {
      expect(item['id'] < 1, false);
    });
  });

  test('lt', () async {
    final res =
        await postgrest.from('messages').select('id').lt('id', 2).execute();
    res.data.forEach((item) {
      expect(item['id'] < 2, true);
    });
  });

  test('lte', () async {
    final res =
        await postgrest.from('messages').select('id').lte('id', 2).execute();
    res.data.forEach((item) {
      expect(item['id'] > 2, false);
    });
  });

  test('like', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .like('username', '%supa%')
        .execute();
    res.data.forEach((item) {
      expect(item['username'].contains('supa'), true);
    });
  });

  test('ilike', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .ilike('username', '%SUPA%')
        .execute();
    res.data.forEach((item) {
      final user = item['username'].toLowerCase();
      expect(user.contains('supa'), true);
    });
  });

  test('is', () async {
    final res = await postgrest
        .from('users')
        .select('data')
        .is_('data', null)
        .execute();
    res.data.forEach((item) {
      expect(item['data'], null);
    });
  });

  test('in', () async {
    final res = await postgrest
        .from('users')
        .select('status')
        .in_('status', ['ONLINE', 'OFFLINE']).execute();
    res.data.forEach((item) {
      expect(item['status'] == 'ONLINE' || item['status'] == 'OFFLINE', true);
    });
  });

  test('contains', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .contains('age_range', '[1,2)')
        .execute();
    expect(res.data[0]['username'], 'supabot');
  });

  test('containedBy', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .containedBy('age_range', '[1,2)')
        .execute();
    expect(res.data[0]['username'], 'supabot');
  });

  test('rangeLt', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .rangeLt('age_range', '[2,25)')
        .execute();
    expect(res.data[0]['username'], 'supabot');
  });

  test('rangeGt', () async {
    final res = await postgrest
        .from('users')
        .select('age_range')
        .rangeGt('age_range', '[2,25)')
        .execute();
    res.data.forEach((item) {
      expect(item['username'] != 'supabot', true);
    });
  });

  test('rangeGte', () async {
    final res = await postgrest
        .from('users')
        .select('age_range')
        .rangeGte('age_range', '[2,25)')
        .execute();
    res.data.forEach((item) {
      expect(item['username'] != 'supabot', true);
    });
  });

  test('rangeLte', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .rangeLte('age_range', '[2,25)')
        .execute();
    res.data.forEach((item) {
      expect(item['username'] == 'supabot', true);
    });
  });

  test('rangeAdjacent', () async {
    final res = await postgrest
        .from('users')
        .select('age_range')
        .rangeAdjacent('age_range', '[2,25)')
        .execute();
    expect(res.data.length, 3);
  });

  test('overlaps', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .overlaps('age_range', '[2,25)')
        .execute();
    expect(res.data[0]['username'], 'dragarcia');
  });

  test('textSearch', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .textSearch('catchphrase', "'fat' & 'cat'", config: 'english')
        .execute();
    expect(res.data[0]['username'], 'supabot');
  });

  test('textSearch with plainto_tsquery', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .textSearch('catchphrase', "'fat' & 'cat'",
            config: 'english', type: TextSearchType.plain)
        .execute();
    expect(res.data[0]['username'], 'supabot');
  });

  test('textSearch with phraseto_tsquery', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .textSearch('catchphrase', 'cat',
            config: 'english', type: TextSearchType.phrase)
        .execute();
    expect(res.data.length, 2);
  });

  test('textSearch with websearch_to_tsquery', () async {
    final res = await postgrest
        .from('users')
        .select('username')
        .textSearch('catchphrase', "'fat' & 'cat'",
            config: 'english', type: TextSearchType.websearch)
        .execute();
    expect(res.data[0]['username'], 'supabot');
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
    expect(res.data[0]['username'], 'supabot');
  });

  test('filter', () async {
    final res = await postgrest
        .from('users')
        .select()
        .filter('username', 'eq', 'supabot')
        .execute();
    expect(res.data[0]['username'], 'supabot');
  });

  test('match', () async {
    final res = await postgrest
        .from('users')
        .select()
        .match({'username': 'supabot', 'status': 'ONLINE'}).execute();
    expect(res.data[0]['username'], 'supabot');
  });
}
