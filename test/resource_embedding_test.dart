import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  const rootUrl = 'http://localhost:3000';
  late PostgrestClient postgrest;

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  test('embedded select', () async {
    final res = await postgrest.from('users').select('messages(*)').execute();
    expect(res.data[0]['messages'].length, 2);
    expect(res.data[1]['messages'].length, 0);
  });

  test('embedded eq', () async {
    final res = await postgrest
        .from('users')
        .select('messages(*)')
        .eq('messages.channel_id', 1)
        .execute();
    expect(res.data[0]['messages'].length, 1);
    expect(res.data[1]['messages'].length, 0);
    expect(res.data[2]['messages'].length, 0);
    expect(res.data[3]['messages'].length, 0);
  });

  test('embedded order', () async {
    final res = await postgrest
        .from('users')
        .select('messages(*)')
        .order('channel_id', foreignTable: 'messages')
        .execute();
    expect(res.data[0]['messages'].length, 2);
    expect(res.data[1]['messages'].length, 0);
    expect(res.data[0]['messages'][0]['id'], 2);
  });

  test('embedded order on multiple columns', () async {
    final res = await postgrest
        .from('users')
        .select('username, messages(*)')
        .order('username', ascending: true)
        .order('channel_id', foreignTable: 'messages')
        .execute();
    expect(res.data[0]['username'], 'awailas');
    expect(res.data[3]['username'], 'supabot');
    expect(res.data[0]['messages'].length, 0);
    expect(res.data[3]['messages'].length, 2);
    expect(res.data[3]['messages'][0]['id'], 2);
  });

  test('embedded limit', () async {
    final res = await postgrest
        .from('users')
        .select('messages(*)')
        .limit(1, foreignTable: 'messages')
        .execute();
    expect(res.data[0]['messages'].length, 1);
    expect(res.data[1]['messages'].length, 0);
    expect(res.data[2]['messages'].length, 0);
    expect(res.data[3]['messages'].length, 0);
  });

  test('embedded range', () async {
    final res = await postgrest
        .from('users')
        .select('messages(*)')
        .range(1, 1, foreignTable: 'messages')
        .execute();
    expect(res.data[0]['messages'].length, 1);
    expect(res.data[1]['messages'].length, 0);
    expect(res.data[2]['messages'].length, 0);
    expect(res.data[3]['messages'].length, 0);
  });
}
