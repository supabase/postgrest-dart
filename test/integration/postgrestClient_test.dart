import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  String rootUrl = 'http://localhost:3000';

  test("should return basic data", () async {
    var client = PostgrestClient(rootUrl);
    var res = await client
        .from('users')
        .select('username')
        .eq('status', 'OFFLINE')
        .end();
    expect(res['body'].length, 1);
    expect(res['body'], [
      {'username': 'kiwicopple'}
    ]);
  });
  test("should return relational joins", () async {
    var client = PostgrestClient(rootUrl);
    var res = await client
        .from('channels')
        .select('slug, messages(message)')
        .eq('slug', 'public')
        .end();
    var hasCorrectMessages =
        res['body'][0]['messages'].any((x) => x['message'] == 'Hello World 👋');
    expect(res['body'][0]['slug'], 'public');
    expect(hasCorrectMessages, true);
  });
  test("should be able to insert data", () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('messages').insert([
      {'message': 'Test message 0', 'channel_id': 1, 'username': 'kiwicopple'}
    ]).end();
    expect(res['status'], 201);
  });
  test(
      "should be able to insert data in the form of an object and return the object",
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('messages').insert([
      {'message': 'Test message 1', 'channel_id': 1, 'username': 'awailas'}
    ]).end();
    expect(res['body'][0]['message'], "Test message 1");
  });
  test("should be able to insert an array of data and return the array",
      () async {
    var client = PostgrestClient(rootUrl);
    var payload = [
      {'message': 'Test message 2', 'channel_id': 1, 'username': 'dragarcia'},
      {'message': 'Test message 3', 'channel_id': 1, 'username': 'dragarcia'},
    ];
    var res = await client.from('messages').insert(payload).end();
    expect(res['body'].length, payload.length);
    expect(res['body'][0]['message'], "Test message 2");
    expect(res['body'][1]['message'], "Test message 3");
  });
  test("should be able to upsert an array of data and return the array",
      () async {
    var client = PostgrestClient(rootUrl);
    var payload = [
      {'username': 'dragarcia', 'status': 'OFFLINE'},
      {'username': 'supabot2', 'status': 'ONLINE'}
    ];
    var res =
        await client.from('users').insert(payload, {'upsert': true}).end();
    expect(res['body'].length, payload.length);
    expect(res['body'][0]['username'], "dragarcia");
    expect(res['body'][0]['status'], "OFFLINE");
  });
  test("should be able to upsert data that exists in the database", () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').insert(
        {'username': 'dragarcia', 'status': 'ONLINE'}, {'upsert': true}).end();
    expect(res['body'][0]['username'], "dragarcia");
    expect(res['body'][0]['status'], "ONLINE");
  });
  test("should be able to upsert data that does not exist in the database",
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').insert(
        {'username': 'supabot3', 'status': 'ONLINE'}, {'upsert': true}).end();
    expect(res['body'][0]['username'], "supabot3");
    expect(res['body'][0]['status'], "ONLINE");
  });
  test("should not be able to update messages without any filters used",
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').update({
      'message': 'Updated test message x',
      'channel_id': 1,
      'username': 'kiwicopple'
    }).end();
    expect(res['status'], 400);
    expect(
        res['statusText'], ".update() cannot be invoked without any filters.");
  });
  test("should not accept an array when updating messages", () async {
    var client = PostgrestClient(rootUrl);
    var res = await client
        .from('users')
        .update([
          {
            'message': 'Updated test message xx',
            'channel_id': 1,
            'username': 'dragarcia'
          },
          {
            'message': 'Updated test message xxx',
            'channel_id': 1,
            'username': 'dragarcia'
          }
        ])
        .eq('username', 'dragarcia')
        .end();
    expect(res['status'], 400);
    expect(res['statusText'], "Data type should be an object.");
  });
  test("should be able to update messages", () async {
    var client = PostgrestClient(rootUrl);
    var res = await client
        .from('messages')
        .update({
          'message': 'Updated test message 1',
          'channel_id': 1,
          'username': 'kiwicopple'
        })
        .eq('message', 'Test message 0')
        .end();
    expect(res['status'], 200);
    expect(res['body'][0]['message'], "Updated test message 1");
  });
  test("should be able to update multiple messages", () async {
    var client = PostgrestClient(rootUrl);
    var readRes = await client
        .from('messages')
        .select('*')
        .neq('username', 'supabot')
        .end();
    var res = await client
        .from('messages')
        .update({'message': 'Updated test message 2'})
        .not('username', 'eq', 'supabot')
        .end();
    expect(res['body'].length, readRes['body'].length);
    res['body'].forEach((item) {
      expect(item['message'], "Updated test message 2");
    });
  });
  test("should not be able to delete messages without any filters used",
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('messages').delete().end();
    expect(res['status'], 400);
    expect(
        res['statusText'], '.delete() cannot be invoked without any filters.');
  });
  test("should be able to delete messages when any form of filters are used",
      () async {
    var client = PostgrestClient(rootUrl);
    var res =
        await client.from('messages').delete().neq('username', 'supabot').end();

    await client
        .from('users')
        .delete()
        .$in('username', ['supabot2', 'supabot3']).end();

    expect(res['status'], 204);
  });
  test("should be able to execute stored procedures", () async {
    var client = PostgrestClient(rootUrl);
    var res =
        await client.rpc('get_status', {'name_param': 'leroyjenkins'}).end();
    expect(res['body'], null);
  });
  test("should be able to chain filters", () {
    var client = PostgrestClient(rootUrl);
    var rest = client
        .from('messages')
        .select('*')
        .eq('username', 'supabot')
        .neq('message', 'hello world')
        .gte('channel_id', 1);
    var queries = rest.query;
    expect(queries.length, 4);
    expect(queries[1], 'username=eq.supabot');
    expect(queries[2], 'message=neq.hello world');
    expect(queries[3], 'channel_id=gte.1');
  });
}
