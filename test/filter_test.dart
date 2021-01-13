import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  const rootUrl = 'http://localhost:3000';
  PostgrestClient postgrest;

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  test('not', () async {
    final res = await postgrest.from('users').select().not('status', 'eq', 'OFFLINE').execute();
    res.data.forEach((item) {
      expect(item['status'] != ('OFFLINE'), true);
    });
  });

  test('or', () async {
    final res = await postgrest
        .from('users')
        .select()
        .or('status.eq.OFFLINE,username.eq.supabot')
        .execute();
    res.data.forEach((item) {
      expect(item['username'] == ('supabot') || item['status'] == ('OFFLINE'), true);
    });
  });

  test('eq', () async {
    final res = await postgrest.from('users').select().eq('username', 'supabot').execute();

    res.data.forEach((item) {
      expect(item['username'] == ('supabot'), true);
    });
  });

  test('neq', () async {
    final res = await postgrest.from('users').select().neq('username', 'supabot').execute();
    res.data.forEach((item) {
      expect(item['username'] == ('supabot'), false);
    });
  });

  test('gt', () async {
    final res = await postgrest.from('messages').select().gt('id', 1).execute();
    res.data.forEach((item) {
      expect(item['id'] > 1, true);
    });
  });

  test('gte', () async {
    final res = await postgrest.from('messages').select().gte('id', 1).execute();
    res.data.forEach((item) {
      expect(item['id'] < 1, false);
    });
  });

  test('lt', () async {
    final res = await postgrest.from('messages').select().lt('id', 2).execute();
    res.data.forEach((item) {
      expect(item['id'] < 2, true);
    });
  });

  test('lte', () async {
    final res = await postgrest.from('messages').select().lte('id', 2).execute();
    res.data.forEach((item) {
      expect(item['id'] > 2, false);
    });
  });

  test('like', () async {
    final res = await postgrest.from('users').select().like('username', '%supa%').execute();
    res.data.forEach((item) {
      expect(item['username'].contains('supa'), true);
    });
  });

  test('ilike', () async {
    final res = await postgrest.from('users').select().ilike('username', '%SUPA%').execute();
    res.data.forEach((item) {
      final user = item['username'].toLowerCase();
      expect(user.contains('supa'), true);
    });
  });

  test('is', () async {
    final res = await postgrest.from('users').select().is_('data', null).execute();
    res.data.forEach((item) {
      expect(item['data'], null);
    });
  });

  test('in', () async {
    final res =
        await postgrest.from('users').select().in_('status', ['ONLINE', 'OFFLINE']).execute();
    res.data.forEach((item) {
      expect(item['status'] == 'ONLINE' || item['status'] == 'OFFLINE', true);
    });
  });

  test('cs', () async {
    final res = await postgrest.from('users').select().cs('age_range', '[1,2)').execute();
    expect(res.data[0]['username'], 'supabot');
  });

  test('cd', () async {
    final res = await postgrest.from('users').select().cd('age_range', '[1,2)').execute();
    expect(res.data[0]['username'], 'supabot');
  });

  test('sl', () async {
    final res = await postgrest.from('users').select().sl('age_range', '[2,25)').execute();
    expect(res.data[0]['username'], 'supabot');
  });

  test('sr', () async {
    final res = await postgrest.from('users').select().sr('age_range', '[2,25)').execute();
    res.data.forEach((item) {
      expect(item['username'] != 'supabot', true);
    });
  });

  test('nxl', () async {
    final res = await postgrest.from('users').select().nxl('age_range', '[2,25)').execute();
    res.data.forEach((item) {
      expect(item['username'] != 'supabot', true);
    });
  });

  test('nxr', () async {
    final res = await postgrest.from('users').select().nxr('age_range', '[2,25)').execute();
    res.data.forEach((item) {
      expect(item['username'] == 'supabot', true);
    });
  });

  test('adj', () async {
    final res = await postgrest.from('users').select().adj('age_range', '[2,25)').execute();
    expect(res.data.length, 3);
  });

  test('ov', () async {
    final res = await postgrest.from('users').select().ov('age_range', '[2,25)').execute();
    expect(res.data[0]['username'], 'dragarcia');
  });

  test('fts', () async {
    final res = await postgrest
        .from('users')
        .select()
        .fts('catchphrase', "'fat' & 'cat'", config: 'english')
        .execute();
    expect(res.data[0]['username'], 'supabot');
  });

  test('plfts', () async {
    final res = await postgrest
        .from('users')
        .select()
        .plfts('catchphrase', "'fat' & 'cat'", config: 'english')
        .execute();
    expect(res.data[0]['username'], 'supabot');
  });

  test('phfts', () async {
    final res = await postgrest
        .from('users')
        .select()
        .phfts('catchphrase', 'cat', config: 'english')
        .execute();
    expect(res.data.length, 2);
  });

  test('wfts', () async {
    final res = await postgrest
        .from('users')
        .select()
        .wfts('catchphrase', "'fat' & 'cat'", config: 'english')
        .execute();
    expect(res.data[0]['username'], 'supabot');
  });

  test('multiple filters', () async {
    final res = await postgrest
        .from('users')
        .select()
        .eq('username', 'supabot')
        .is_('data', null)
        .ov('age_range', '[1,2)')
        .eq('status', 'ONLINE')
        .fts('catchphrase', 'cat')
        .execute();
    expect(res.data[0]['username'], 'supabot');
  });

  test('filter', () async {
    final res =
        await postgrest.from('users').select().filter('username', 'eq', 'supabot').execute();
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
