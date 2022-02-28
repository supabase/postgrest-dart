import 'package:postgrest/postgrest.dart';
import 'package:test/test.dart';

void main() {
  const rootUrl = 'http://localhost:3000';
  late PostgrestClient postgrest;
  late List<Map<String, dynamic>> users;
  late List<Map<String, dynamic>> channels;
  late List<Map<String, dynamic>> messages;

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

  test('embedded select', () async {
    final res = await postgrest.from('users').select('messages(*)').execute();
    expect(
      (((res.data as List)[0] as Map)['messages'] as List).length,
      2,
    );
    expect(
      (((res.data as List)[1] as Map)['messages'] as List).length,
      0,
    );
  });

  test('embedded eq', () async {
    final res = await postgrest
        .from('users')
        .select('messages(*)')
        .eq('messages.channel_id', 1)
        .execute();
    expect(
      (((res.data as List)[0] as Map)['messages'] as List).length,
      1,
    );
    expect(
      (((res.data as List)[1] as Map)['messages'] as List).length,
      0,
    );
    expect(
      (((res.data as List)[2] as Map)['messages'] as List).length,
      0,
    );
    expect(
      (((res.data as List)[3] as Map)['messages'] as List).length,
      0,
    );
  });

  test('embedded order', () async {
    final res = await postgrest
        .from('users')
        .select('messages(*)')
        .order('channel_id', foreignTable: 'messages')
        .execute();
    expect(
      (((res.data as List)[0] as Map)['messages'] as List).length,
      2,
    );
    expect(
      (((res.data as List)[1] as Map)['messages'] as List).length,
      0,
    );
    expect(
      ((((res.data as List)[0] as Map)['messages'] as List)[0] as Map)['id'],
      2,
    );
  });

  test('embedded order on multiple columns', () async {
    final res = await postgrest
        .from('users')
        .select('username, messages(*)')
        .order('username', ascending: true)
        .order('channel_id', foreignTable: 'messages')
        .execute();
    expect(
      ((res.data as List)[0] as Map)['username'],
      'awailas',
    );
    expect(
      ((res.data as List)[3] as Map)['username'],
      'supabot',
    );
    expect(
      (((res.data as List)[0] as Map)['messages'] as List).length,
      0,
    );
    expect(
      (((res.data as List)[3] as Map)['messages'] as List).length,
      2,
    );
    expect(
      ((((res.data as List)[3] as Map)['messages'] as List)[0] as Map)['id'],
      2,
    );
  });

  test('embedded limit', () async {
    final res = await postgrest
        .from('users')
        .select('messages(*)')
        .limit(1, foreignTable: 'messages')
        .execute();
    expect(
      (((res.data as List)[0] as Map)['messages'] as List).length,
      1,
    );
    expect(
      (((res.data as List)[1] as Map)['messages'] as List).length,
      0,
    );
    expect(
      (((res.data as List)[2] as Map)['messages'] as List).length,
      0,
    );
    expect(
      (((res.data as List)[3] as Map)['messages'] as List).length,
      0,
    );
  });

  test('embedded range', () async {
    final res = await postgrest
        .from('users')
        .select('messages(*)')
        .range(1, 1, foreignTable: 'messages')
        .execute();
    expect(
      (((res.data as List)[0] as Map)['messages'] as List).length,
      1,
    );
    expect(
      (((res.data as List)[1] as Map)['messages'] as List).length,
      0,
    );
    expect(
      (((res.data as List)[2] as Map)['messages'] as List).length,
      0,
    );
    expect(
      (((res.data as List)[3] as Map)['messages'] as List).length,
      0,
    );
  });
}
