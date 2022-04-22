import 'dart:io';

import 'package:postgrest/postgrest.dart';
import 'package:test/test.dart';

import 'custom_http_client.dart';
import 'reset_helper.dart';

void main() {
  const rootUrl = 'http://localhost:3000';
  late PostgrestClient postgrest;
  late PostgrestClient postgrestCustomHttpClient;
  final resetHelper = ResetHelper();

  group("Default http client", () {
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

    test('basic select table', () async {
      final List res = await postgrest.from('users').select();
      expect(res.length, 4);
    });

    test('stored procedure', () async {
      final res = await postgrest.rpc('get_status', params: {
        'name_param': 'supabot',
      });
      expect(res, 'ONLINE');
    });

    test('select on stored procedure', () async {
      final List res = await postgrest.rpc(
        'get_username_and_status',
        params: {'name_param': 'supabot'},
      ).select('status');
      expect(
        (res.first as Map<String, dynamic>)['status'],
        'ONLINE',
      );
    });

    test('stored procedure returns void', () async {
      final res = await postgrest.rpc('void_func');
      expect(res, isNull);
    });

    // test('custom headers', () async {
    //   final postgrest = PostgrestClient(rootUrl, headers: {'apikey': 'foo'});
    //   expect(postgrest.from('users').select().headers['apikey'], 'foo');
    // });

    // test('override X-Client-Info', () async {
    //   final postgrest = PostgrestClient(
    //     rootUrl,
    //     headers: {'X-Client-Info': 'supabase-dart/0.0.0'},
    //   );
    //   expect(
    //     postgrest.from('users').select().headers['X-Client-Info'],
    //     'supabase-dart/0.0.0',
    //   );
    // });

    // test('auth', () async {
    //   postgrest = PostgrestClient(rootUrl).auth('foo');
    //   expect(
    //     postgrest.from('users').select().headers['Authorization'],
    //     'Bearer foo',
    //   );
    // });

    // test('switch schema', () async {
    //   final postgrest = PostgrestClient(rootUrl, schema: 'personal');
    //   final res = await postgrest.from('users').select();
    //   expect((res.data as List).length, 5);
    // });

    test('on_conflict upsert', () async {
      final List res = await postgrest.from('users').upsert(
        {'username': 'dragarcia', 'status': 'OFFLINE'},
        onConflict: 'username',
      );
      expect(
        (res.first as Map<String, dynamic>)['status'],
        'OFFLINE',
      );
    });

    test('upsert', () async {
      final List res = await postgrest.from('messages').upsert(
          {'id': 3, 'message': 'foo', 'username': 'supabot', 'channel_id': 2});
      expect((res.first as Map)['id'], 3);

      final List resMsg = await postgrest.from('messages').select();
      expect(resMsg.length, 3);
    });

    test('ignoreDuplicates upsert', () async {
      final List res = await postgrest.from('users').upsert(
        {'username': 'dragarcia'},
        onConflict: 'username',
        ignoreDuplicates: true,
      );
      expect(res, isEmpty);
    });

    test('bulk insert', () async {
      final List res = await postgrest.from('messages').insert([
        {'id': 4, 'message': 'foo', 'username': 'supabot', 'channel_id': 2},
        {'id': 5, 'message': 'foo', 'username': 'supabot', 'channel_id': 1}
      ]);
      expect(res.length, 2);
    });

    test('basic update', () async {
      final res = await postgrest.from('messages').update(
        {'channel_id': 2},
        returning: ReturningOption.minimal,
      );
      expect(res, null);

      final Iterable<Map<String, dynamic>> messages = (await postgrest
              .from('messages')
              .select()
              .withConverter<List>((data) => data as List))!
          .cast<Map<String, dynamic>>();
      for (final rec in messages) {
        expect(rec['channel_id'], 2);
      }
    });

    test('basic delete', () async {
      final res = await postgrest
          .from('messages')
          .delete(returning: ReturningOption.minimal)
          .eq('message', 'Supabase Launch Week is on fire');
      expect(res, null);

      final List resMsg = await postgrest
          .from('messages')
          .select()
          .eq('message', 'Supabase Launch Week is on fire');
      expect(resMsg, isEmpty);
    });

    test('missing table', () {
      postgrest.from('missing_table').select().then(
        (value) {
          fail('found missing table');
        },
        onError: (error) {
          expect(error, isA<PostgrestError>());
          expect(error.code, '404');
        },
      );
    });

    test('connection error', () {
      final postgrest = PostgrestClient('http://this.url.does.not.exist');
      postgrest.from('user').select().then(
        (value) {
          fail('Success on connection error');
        },
        onError: (error) {
          expect(error, isA<SocketException>());
        },
      );
    });

    test('select with head:true', () async {
      final res = await postgrest.from('users').select(
            '*',
            FetchOptions(head: true),
          );
      expect(res, null);
    });

    test('select with head:true, count: exact', () async {
      final PostgrestResponse res = await postgrest.from('users').select(
            '*',
            FetchOptions(head: true, count: CountOption.exact),
          );
      expect(res, isA<PostgrestResponse>());
      expect(res, isNotNull);
      expect(res.count, 4);
    });

    test('select with count: planned', () async {
      final PostgrestResponse res = await postgrest
          .from('users')
          .select('*', FetchOptions(count: CountOption.planned));
      expect(res.count, isNotNull);
    });

    test('select with head:true, count: estimated', () async {
      final PostgrestResponse res = await postgrest
          .from('users')
          .select('*', FetchOptions(head: true, count: CountOption.estimated));
      expect(res.count, const TypeMatcher<int>());
    });

    test('select with csv', () async {
      final res = await postgrest.from('users').select().csv();
      expect(res, isA<String>());
    });

    test('stored procedure with head: true', () async {
      final res = await postgrest.rpc(
        'get_status',
        params: {'name_param': 'supabot'},
        options: FetchOptions(head: true),
      );
      expect(res, isNotNull);
    });

    test('stored procedure with count: exact', () async {
      final res = await postgrest.rpc(
        'get_status',
        params: {'name_param': 'supabot'},
        options: FetchOptions(count: CountOption.exact),
      );
      expect(res, isNotNull);
    });

    test('insert with count: exact', () async {
      final res = await postgrest.from('users').upsert(
        {'username': 'countexact', 'status': 'OFFLINE'},
        onConflict: 'username',
        options: FetchOptions(count: CountOption.exact),
      );
      expect(res.count, 1);
    });

    test('update with count: exact', () async {
      final res = await postgrest.from('users').update(
        {'status': 'ONLINE'},
        options: FetchOptions(count: CountOption.exact),
      ).eq('username', 'kiwicopple');
      expect(res.count, 1);
    });

    test('delete with count: exact', () async {
      final res = await postgrest
          .from('users')
          .delete(options: FetchOptions(count: CountOption.exact))
          .eq('username', 'kiwicopple');

      expect(res.count, 1);
    });

    test('execute without table operation', () {
      postgrest.from('users').then(
        (value) {
          fail('can not execute without table operation');
        },
        onError: (error) {
          expect(error, isA<ArgumentError>());
        },
      );
    });

    test('select from uppercase table name', () async {
      final res = await postgrest.from('TestTable').select();
      expect((res as List).length, 2);
    });

    test('insert from uppercase table name', () async {
      final res = await postgrest.from('TestTable').insert([
        {'slug': 'new slug'}
      ]);
      expect(
        (res.first as Map<String, dynamic>)['slug'],
        'new slug',
      );
    });

    test('delete from uppercase table name', () async {
      final res = await postgrest
          .from('TestTable')
          .delete(options: FetchOptions(count: CountOption.exact))
          .eq('slug', 'new slug');
      expect(res.count, 1);
    });

    test('row level security error', () {
      postgrest.from('sample').update({'id': 2}).then(
        (value) {
          fail('Returned even with row level security');
        },
        onError: (error) {
          expect(error, isA<PostgrestError>());
          expect(error.code, '404');
        },
      );
    });

    test('withConverter', () async {
      final List? res = await postgrest
          .from('users')
          .select()
          .withConverter<List>((data) => [data]);
      expect(res, isNotNull);
      expect(res, isNotEmpty);
      expect(res!.first, isNotEmpty);
      expect(res.first, isA<List>());
    });
  });
  group("Custom http client", () {
    setUpAll(() {
      postgrestCustomHttpClient = PostgrestClient(
        rootUrl,
        httpClient: CustomHttpClient(),
      );
    });
    test('basic select table', () async {
      await postgrestCustomHttpClient.from('users').select().then(
        (value) {
          fail('Table was able to be selected, even tho it does not exist');
        },
        onError: (error) {
          expect(error, isA<PostgrestError>());
          expect(error.code, '420');
        },
      );
    });
    test('basic stored procedure call', () async {
      final res = await postgrest.rpc('get_status', params: {
        'name_param': 'supabot',
      });
      expect(res, 'ONLINE');
    });
  });
}
