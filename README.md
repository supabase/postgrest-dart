# Postgrest Dart

Dart client for [PostgREST](https://postgrest.org). The goal of this library is to make an "ORM-like" restful interface. 

[![pub package](https://img.shields.io/pub/v/http.svg)](https://pub.dev/packages/postgrest)

## Using

The usage should be the same as postgrest-js except:
- When using with `async/await`, you need to call `end()` to finish your query chain.
- `$is` and `$in` filter methods are prefixed with `$` sign to avoid collisions with reserved keywords.

You can find detail documentation from [here](https://supabase.io/docs/about).

#### Reading your data

```dart
import 'package:postgrest/postgrest.dart' as postgrestClient;

var url = 'https://example.com/postgrest/endpoint';
var client = postgrestClient(url);
var response = await client.from('users')
      .select('*')
      .eq('username', 'dragarcia')
      .end();
print('Response status: ${response.status}');
print('Response body: ${response.body}');
```

#### Insert records

```dart
import 'package:postgrest/postgrest.dart' as postgrestClient;

var url = 'https://example.com/postgrest/endpoint';
var client = postgrestClient(url);
var response = await client.from('users')
      .insert([
        { 'username': 'supabot', 'status': 'ONLINE'}
      ])
      .end();
print('Created user: ${response.body[0]['username']}');
```

#### Update a record

```dart
import 'package:postgrest/postgrest.dart' as postgrestClient;

var url = 'https://example.com/postgrest/endpoint';
var client = postgrestClient(url);
var response = await client.from('users')
      .update({ 'status': 'OFFLINE' })
      .eq('username', 'dragarcia')
      .end();
print('Updated user status: ${response.body[0]['status']}');
```

#### Delete records

```dart
import 'package:postgrest/postgrest.dart' as postgrestClient;

var url = 'https://example.com/postgrest/endpoint';
var client = postgrestClient(url);
var response = await client.from('users')
      .delete()
      .eq('username', 'supabot')
      .end();
print('Response status: ${response.status}');
```

#### Using with `then()/catchError()`

```dart
import 'package:postgrest/postgrest.dart' as postgrestClient;

var url = 'https://example.com/postgrest/endpoint';
var client = postgrestClient(url);
client.from('users').select('username').eq('status', 'OFFLINE').then((res) {
      // Do something with the response
}).catchError((error) => throw (error));
```

## Contributing

- Fork the repo on [GitHub](https://github.com/supabase/postgrest-dart)
- Clone the project to your own machine
- Commit changes to your own branch
- Push your work back up to your fork
- Submit a Pull request so that we can review your changes and merge

## License

This repo is liscenced under MIT.

## Credits

- https://github.com/supabase/postgrest-js - ported from postgrest-js library

## Sponsors

We are building the features of Firebase using enterprise-grade, open source products. We support existing communities wherever possible, and if the products don’t exist we build them and open source them ourselves. Thanks to these sponsors who are making the OSS ecosystem better for everyone.

[![Worklife VC](https://user-images.githubusercontent.com/10214025/90451355-34d71200-e11e-11ea-81f9-1592fd1e9146.png)](https://www.worklife.vc)
[![New Sponsor](https://user-images.githubusercontent.com/10214025/90518111-e74bbb00-e198-11ea-8f88-c9e3c1aa4b5b.png)](https://github.com/sponsors/supabase)
