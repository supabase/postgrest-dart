import 'package:postgrest/src/count_option.dart';
import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  const rootUrl = 'http://localhost:3000';
  PostgrestClient postgrest;

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  test('basic select table', () async {
    final res = await postgrest.from('users').select().execute();
    expect(res.data.length, 4);
  });

  test('stored procedure', () async {
    final res =
        await postgrest.rpc('get_status', {'name_param': 'supabot'}).execute();
    expect(res.data, 'ONLINE');
  });

  test('custom headers', () async {
    final postgrest = PostgrestClient(rootUrl, headers: {'apikey': 'foo'});
    expect(postgrest.from('users').select().headers['apikey'], 'foo');
  });

  test('auth', () async {
    postgrest = PostgrestClient(rootUrl).auth('foo');
    expect(postgrest.from('users').select().headers['Authorization'],
        'Bearer foo');
  });

  test('switch schema', () async {
    final postgrest = PostgrestClient(rootUrl, schema: 'personal');
    final res = await postgrest.from('users').select().execute();
    expect(res.data.length, 5);
  });

  test('on_conflict insert', () async {
    final res = await postgrest.from('users').insert(
        {'username': 'dragarcia', 'status': 'OFFLINE'},
        upsert: true, onConflict: 'username').execute();
    expect(res.data[0]['status'], 'OFFLINE');
  });

  test('upsert', () async {
    final res = await postgrest.from('messages').insert(
        {'id': 3, 'message': 'foo', 'username': 'supabot', 'channel_id': 2},
        upsert: true).execute();
    //{id: 3, message: foo, username: supabot, channel_id: 2}
    expect(res.data[0]['id'], 3);

    final resMsg = await postgrest.from('messages').select().execute();
    expect(resMsg.data.length, 3);
  });

  test('bulk insert', () async {
    final res = await postgrest.from('messages').insert([
      {'id': 4, 'message': 'foo', 'username': 'supabot', 'channel_id': 2},
      {'id': 5, 'message': 'foo', 'username': 'supabot', 'channel_id': 1}
    ]).execute();
    expect(res.data.length, 2);
  });

  test('basic update', () async {
    await postgrest
        .from('messages')
        .update({'channel_id': 2})
        .eq('message', 'foo')
        .execute();

    final resMsg = await postgrest
        .from('messages')
        .select()
        .filter('message', 'eq', 'foo')
        .execute();
    resMsg.data.forEach((rec) => expect(rec['channel_id'], 2));
  });

  test('basic delete', () async {
    await postgrest.from('messages').delete().eq('message', 'foo').execute();

    final resMsg = await postgrest
        .from('messages')
        .select()
        .filter('message', 'eq', 'foo')
        .execute();
    expect(resMsg.data.length, 0);
  });

  test('missing table', () async {
    final res = await postgrest.from('missing_table').select().execute();
    expect(res.error.code, '404');
  });

  test('connection error', () async {
    final postgrest = PostgrestClient('http://this.url.does.not.exist');
    final res = await postgrest.from('user').select().execute();
    expect(res.error.code, 'SocketException');
  });

  test('select with head:true', () async {
    final res = await postgrest.from('users').select().execute(head: true);
    expect(res.data, null);
  });

  test('select with head:true, count: exact', () async {
    final res = await postgrest
        .from('users')
        .select()
        .execute(head: true, count: CountOption.exact);
    expect(res.data, null);
    expect(res.count, 4);
  });

  test('select with  count: planned', () async {
    final res = await postgrest
        .from('users')
        .select()
        .execute(count: CountOption.exact);
    expect(res.count, const TypeMatcher<int>());
  });

  test('select with head:true, count: estimated', () async {
    final res = await postgrest
        .from('users')
        .select()
        .execute(count: CountOption.exact);
    expect(res.count, const TypeMatcher<int>());
  });

  test('stored procedure with head: true', () async {
    final res =
        await postgrest.from('users').rpc('get_status', head: true).execute();
    expect(res.data, null);
  });

  test('stored procedure with count: exact', () async {
    final res = await postgrest
        .from('users')
        .rpc('get_status')
        .execute(count: CountOption.exact);
    expect(res.count, const TypeMatcher<int>());
  });

  test('insert with count: exact', () async {
    final res = await postgrest.from('users').insert(
        {'username': 'countexact', 'status': 'OFFLINE'},
        upsert: true, onConflict: 'username').execute(count: CountOption.exact);
    expect(res.count, 1);
  });

  test('update with count: exact', () async {
    final res = await postgrest
        .from('users')
        .update({'status': 'ONLINE'})
        .eq('username', 'countexact')
        .execute(count: CountOption.exact);
    expect(res.count, 1);
  });

  test('delete with count: exact', () async {
    final res = await postgrest
        .from('users')
        .delete()
        .eq('username', 'countexact')
        .execute(count: CountOption.exact);

    expect(res.count, 1);
  });
}
