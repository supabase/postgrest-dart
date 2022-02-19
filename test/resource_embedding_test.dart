import 'package:postgrest/postgrest.dart';
import 'package:test/test.dart';

void main() {
  const rootUrl = 'http://localhost:3000';
  late PostgrestClient postgrest;

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  test('embedded select', () async {
    final res = await postgrest.from('users').select('messages(*)').execute();
    expect(
      ((res.data as List<Map<String, dynamic>>)[0]['messages'] as List).length,
      2,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[1]['messages'] as List).length,
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
      ((res.data as List<Map<String, dynamic>>)[0]['messages'] as List).length,
      1,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[1]['messages'] as List).length,
      0,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[2]['messages'] as List).length,
      0,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[3]['messages'] as List).length,
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
      ((res.data as List<Map<String, dynamic>>)[0]['messages']
              as List<Map<String, dynamic>>)
          .length,
      2,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[1]['messages']
              as List<Map<String, dynamic>>)
          .length,
      0,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[0]['messages']
          as List<Map<String, dynamic>>)[0]['id'],
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
    expect((res.data as List<Map<String, dynamic>>)[0]['username'], 'awailas');
    expect((res.data as List<Map<String, dynamic>>)[3]['username'], 'supabot');
    expect(
      ((res.data as List<Map<String, dynamic>>)[0]['messages']
              as List<Map<String, dynamic>>)
          .length,
      0,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[3]['messages']
              as List<Map<String, dynamic>>)
          .length,
      2,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[3]['messages']
          as List<Map<String, dynamic>>)[0]['id'],
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
      ((res.data as List<Map<String, dynamic>>)[0]['messages'] as List).length,
      1,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[1]['messages'] as List).length,
      0,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[2]['messages'] as List).length,
      0,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[3]['messages'] as List).length,
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
      ((res.data as List<Map<String, dynamic>>)[0]['messages'] as List).length,
      1,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[1]['messages'] as List).length,
      0,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[2]['messages'] as List).length,
      0,
    );
    expect(
      ((res.data as List<Map<String, dynamic>>)[3]['messages'] as List).length,
      0,
    );
  });
}
