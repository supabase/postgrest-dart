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
    print(users);
  });

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  tearDown(() async {
    await postgrest.from('messages').delete().neq('message', 'dne').execute();
    await postgrest.from('channels').delete().neq('slug', 'dne').execute();
    await postgrest.from('users').delete().neq('username', 'dne').execute();
    final usersInsertRes =
        await postgrest.from('users').insert(users).execute();
    final channelsInsertRes =
        await postgrest.from('channels').insert(channels).execute();
    final messagesInsertRes =
        await postgrest.from('messages').insert(messages).execute();
    if (usersInsertRes.hasError) {
      fail(
        'users table was not properly reset. ${usersInsertRes.error.toString()}',
      );
    }
    if (channelsInsertRes.hasError) {
      fail(
        'channels table was not properly reset. ${channelsInsertRes.error.toString()}',
      );
    }
    if (messagesInsertRes.hasError) {
      fail(
        'messages table was not properly reset. ${messagesInsertRes.error.toString()}',
      );
    }
  });
  test('embedded select', () async {
    final res = await postgrest.from('users').select('messages(*)').execute();
    expect(
      (((res.data as List)[0] as Map)['messages'] as List).length,
      3,
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
      2,
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
      3,
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
      3,
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
