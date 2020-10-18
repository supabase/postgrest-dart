import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  var rootUrl = 'http://localhost:3000';
  PostgrestClient postgrest;

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  test('basic select table', () async {
    var res = await postgrest.from('users').select().execute();
    expect(res.data.length, 4);
  });

  test('stored procedure', () async {
    var res = await postgrest.rpc('get_status', {'name_param': 'supabot'}).execute();
    expect(res.data, 'ONLINE');
  });

  test('custom headers', () async {
    var postgrest = PostgrestClient(rootUrl, headers: {'apikey': 'foo'});
    expect(postgrest.from('users').select().headers['apikey'], 'foo');
  });

  test('auth', () async {
    postgrest = PostgrestClient(rootUrl).auth('foo');
    expect(postgrest.from('users').select().headers['Authorization'], 'Bearer foo');
  });

  test('switch schema', () async {
    var postgrest = PostgrestClient(rootUrl, schema: 'personal');
    var res = await postgrest.from('users').select().execute();
    expect(res.data.length, 5);
  });

  test('on_conflict insert', () async {
    var res = await postgrest.from('users').insert({'username': 'dragarcia', 'status': 'OFFLINE'},
        upsert: true, onConflict: 'username').execute();
    expect(res.data[0]['status'], 'OFFLINE');
  });

  test('upsert', () async {
    var res = await postgrest.from('messages').insert(
        {'id': 3, 'message': 'foo', 'username': 'supabot', 'channel_id': 2},
        upsert: true).execute();
    //{id: 3, message: foo, username: supabot, channel_id: 2}
    expect(res.data[0]['id'], 3);

    var resMsg = await postgrest.from('messages').select().execute();
    expect(resMsg.data.length, 3);
  });

  test('bulk insert', () async {
    var res = await postgrest.from('messages').insert([
      {'id': 4, 'message': 'foo', 'username': 'supabot', 'channel_id': 2},
      {'id': 5, 'message': 'foo', 'username': 'supabot', 'channel_id': 1}
    ]).execute();
    expect(res.data.length, 2);
  });

  test('basic update', () async {
    await postgrest.from('messages').update({'channel_id': 2}).eq('message', 'foo').execute();

    var resMsg = await postgrest.from('messages').select().filter('message', 'eq', 'foo').execute();
    resMsg.data.forEach((rec) => expect(rec['channel_id'], 2));
  });

  test('basic delete', () async {
    await postgrest.from('messages').delete().eq('message', 'foo').execute();

    var resMsg = await postgrest.from('messages').select().filter('message', 'eq', 'foo').execute();
    expect(resMsg.data.length, 0);
  });

  test('missing table', () async {
    var res = await postgrest.from('missing_table').select().execute();
    expect(res.error.code, '404');
  });

  test('connection error', () async {
    var postgrest = PostgrestClient('http://this.url.does.not.exist');
    var res = await postgrest.from('user').select().execute();
    expect(res.error.code, 'SocketException');
  });
}
