import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  var rootUrl = 'http://localhost:3000';
  var postgrest;

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  test('not', () async {
    var res = await postgrest.from('users').select().not('status', 'eq', 'OFFLINE').end();
    res.body.forEach((item) {
      expect(item['status'] != ('OFFLINE'), true);
    });
  });

  test('or', () async {
    var res =
        await postgrest.from('users').select().or('status.eq.OFFLINE,username.eq.supabot').end();
    res.body.forEach((item) {
      expect((item['username'] == ('supabot') || item['status'] == ('OFFLINE')), true);
    });
  });

  test('eq', () async {
    var res = await postgrest.from('users').select().eq('username', 'supabot').end();

    res.body.forEach((item) {
      expect(item['username'] == ('supabot'), true);
    });
  });

  test('neq', () async {
    var res = await postgrest.from('users').select().neq('username', 'supabot').end();
    res.body.forEach((item) {
      expect(item['username'] == ('supabot'), false);
    });
  });

  test('gt', () async {
    var res = await postgrest.from('messages').select().gt('id', 1).end();
    res.body.forEach((item) {
      expect(item['id'] > 1, true);
    });
  });

  test('gte', () async {
    var res = await postgrest.from('messages').select().gte('id', 1).end();
    res.body.forEach((item) {
      expect(item['id'] < 1, false);
    });
  });

  test('lt', () async {
    var res = await postgrest.from('messages').select().lt('id', 2).end();
    res.body.forEach((item) {
      expect(item['id'] < 2, true);
    });
  });

  test('lte', () async {
    var res = await postgrest.from('messages').select().lte('id', 2).end();
    res.body.forEach((item) {
      expect(item['id'] > 2, false);
    });
  });

  test('like', () async {
    var res = await postgrest.from('users').select().like('username', '%supa%').end();
    res.body.forEach((item) {
      expect(item['username'].contains('supa'), true);
    });
  });

  test('ilike', () async {
    var res = await postgrest.from('users').select().ilike('username', '%SUPA%').end();
    res.body.forEach((item) {
      var user = item['username'].toLowerCase();
      expect(user.contains('supa'), true);
    });
  });

  test('is', () async {
    var res = await postgrest.from('users').select().is_('data', null).end();
    res.body.forEach((item) {
      expect(item['data'], null);
    });
  });

  test('in', () async {
    var res = await postgrest.from('users').select().in_('status', ['ONLINE', 'OFFLINE']).end();
    res.body.forEach((item) {
      expect(item['status'] == 'ONLINE' || item['status'] == 'OFFLINE', true);
    });
  });

  test('cs', () async {
    var res = await postgrest.from('users').select().cs('age_range', '[1,2)').end();
    expect(res.body[0]['username'], 'supabot');
  });

  test('cd', () async {
    var res = await postgrest.from('users').select().cd('age_range', '[1,2)').end();
    expect(res.body[0]['username'], 'supabot');
  });

  test('sl', () async {
    var res = await postgrest.from('users').select().sl('age_range', '[2,25)').end();
    expect(res.body[0]['username'], 'supabot');
  });

  test('sr', () async {
    var res = await postgrest.from('users').select().sr('age_range', '[2,25)').end();
    res.body.forEach((item) {
      expect(item['username'] != 'supabot', true);
    });
  });

  test('nxl', () async {
    var res = await postgrest.from('users').select().nxl('age_range', '[2,25)').end();
    res.body.forEach((item) {
      expect(item['username'] != 'supabot', true);
    });
  });

  test('nxr', () async {
    var res = await postgrest.from('users').select().nxr('age_range', '[2,25)').end();
    res.body.forEach((item) {
      expect(item['username'] == 'supabot', true);
    });
  });

  test('adj', () async {
    var res = await postgrest.from('users').select().adj('age_range', '[2,25)').end();
    expect(res.body.length, 3);
  });

  test('ov', () async {
    var res = await postgrest.from('users').select().ov('age_range', '[2,25)').end();
    expect(res.body[0]['username'], 'dragarcia');
  });

  test('fts', () async {
    var res = await postgrest
        .from('users')
        .select()
        .fts('catchphrase', '\'fat\' & \'cat\'', {'config': 'english'}).end();
    expect(res.body[0]['username'], 'supabot');
  });

  test('plfts', () async {
    var res = await postgrest
        .from('users')
        .select()
        .plfts('catchphrase', '\'fat\' & \'cat\'', {'config': 'english'}).end();
    expect(res.body[0]['username'], 'supabot');
  });

  test('phfts', () async {
    var res = await postgrest
        .from('users')
        .select()
        .phfts('catchphrase', 'cat', {'config': 'english'}).end();
    expect(res.body.length, 2);
  });

  test('wfts', () async {
    var res = await postgrest
        .from('users')
        .select()
        .wfts('catchphrase', '\'fat\' & \'cat\'', {'config': 'english'}).end();
    expect(res.body[0]['username'], 'supabot');
  });

  test('multiple filters', () async {
    var res = await postgrest
        .from('users')
        .select()
        .eq('username', 'supabot')
        .is_('data', null)
        .ov('age_range', '[1,2)')
        .eq('status', 'ONLINE')
        .fts('catchphrase', 'cat')
        .end();
    expect(res.body[0]['username'], 'supabot');
  });

  test('filter', () async {
    var res = await postgrest.from('users').select().filter('username', 'eq', 'supabot').end();
    expect(res.body[0]['username'], 'supabot');
  });

  test('match', () async {
    var res = await postgrest
        .from('users')
        .select()
        .match({'username': 'supabot', 'status': 'ONLINE'}).end();
    expect(res.body[0]['username'], 'supabot');
  });
}
