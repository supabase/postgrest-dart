import 'package:postgrest/src/count_option.dart';
import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  const rootUrl = 'http://localhost:3000';
  late PostgrestClient postgrest;

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  test('basic select table', () async {
    final res = await postgrest.from('users').select().execute();
    expect(res.data.length, 4);
  });

  test('stored procedure', () async {
    final res = await postgrest
        .rpc('get_status', params: {'name_param': 'supabot'}).execute();
    expect(res.data, 'ONLINE');
  });

  test('select on stored procedure', () async {
    final res = await postgrest
        .rpc('get_username_and_status', params: {'name_param': 'supabot'})
        .select('status')
        .execute();
    expect(res.data[0]['status'], 'ONLINE');
  });

  test('stored procedure returns void', () async {
    final res = await postgrest.rpc('void_func').execute();
    expect(res.data, isNull);
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

  test('on_conflict upsert', () async {
    final res = await postgrest.from('users').upsert(
        {'username': 'dragarcia', 'status': 'OFFLINE'},
        onConflict: 'username').execute();
    expect(res.data[0]['status'], 'OFFLINE');
  });

  test('upsert', () async {
    final res = await postgrest.from('messages').upsert({
      'id': 3,
      'message': 'foo',
      'username': 'supabot',
      'channel_id': 2
    }).execute();
    expect(res.data[0]['id'], 3);

    final resMsg = await postgrest.from('messages').select().execute();
    expect(resMsg.data.length, 3);
  });

  test('ignoreDuplicates upsert', () async {
    final res = await postgrest.from('users').upsert({'username': 'dragarcia'},
        onConflict: 'username', ignoreDuplicates: true).execute();
    expect(res.data.length, 0);
    expect(res.error, isNull);
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
    expect(res.error, isNotNull);
  });

  test('connection error', () async {
    final postgrest = PostgrestClient('http://this.url.does.not.exist');
    final res = await postgrest.from('user').select().execute();
    expect(res.error!.code, 'SocketException');
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

  test('select with csv', () async {
    final res = await postgrest.from('users').select().csv().execute();
    expect(res.data, const TypeMatcher<String>());
  });

  test('stored procedure with head: true', () async {
    final res = await postgrest.rpc('get_status').execute(head: true);
    expect(res.error, isNotNull);
    expect(res.error!.code, '404');
  });

  test('stored procedure with count: exact', () async {
    final res =
        await postgrest.rpc('get_status').execute(count: CountOption.exact);
    expect(res.error, isNotNull);
    expect(res.error!.hint, isNotNull);
    expect(res.error!.message, isNotNull);
  });

  test('insert with count: exact', () async {
    final res = await postgrest.from('users').upsert(
        {'username': 'countexact', 'status': 'OFFLINE'},
        onConflict: 'username').execute(count: CountOption.exact);
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

  test('execute without table operation', () async {
    final res = await postgrest.from('users').execute();
    expect(res.error, isNotNull);
  });

  test('select from uppercase table name', () async {
    final res = await postgrest.from('TestTable').select().execute();
    expect(res.data.length, 2);
  });

  test('insert from uppercase table name', () async {
    final res = await postgrest.from('TestTable').insert([
      {'slug': 'new slug'}
    ]).execute();
    expect(res.data[0]['slug'], 'new slug');
  });

  test('delete from uppercase table name', () async {
    final res = await postgrest
        .from('TestTable')
        .delete()
        .eq('slug', 'new slug')
        .execute(count: CountOption.exact);
    expect(res.count, 1);
  });

  test('row level security error', () async {
    final res = await postgrest.from('sample').update({'id': 2}).execute();
    expect(res.error, isNotNull);
  });
}
