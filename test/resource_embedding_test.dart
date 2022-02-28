import 'package:postgrest/postgrest.dart';
import 'package:test/test.dart';

import 'reset_helper.dart';

void main() {
  const rootUrl = 'http://localhost:3000';
  late PostgrestClient postgrest;
  final resetHelper = ResetHelper();

  setUpAll(() async {
    postgrest = PostgrestClient(rootUrl);
    await resetHelper.initialize(postgrest);
  });

  setUp(() {
    postgrest = PostgrestClient(rootUrl);
  });

  tearDown(() async {
    await resetHelper.reset();
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
