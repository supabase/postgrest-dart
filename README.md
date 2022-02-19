# Postgrest Dart

Dart client for [PostgREST](https://postgrest.org). The goal of this library is to make an "ORM-like" restful interface.

[![pub package](https://img.shields.io/pub/v/postgrest.svg)](https://pub.dev/packages/postgrest)
[![pub test](https://github.com/supabase/postgrest-dart/workflows/Test/badge.svg)](https://github.com/supabase/postgrest-dart/actions?query=workflow%3ATest)

## Using

The usage should be the same as postgrest-js except:

- You need to call `execute()` to finish your query chain.
- `is_` and `in_` filter methods are suffixed with `_` sign to avoid collisions with reserved keywords.

You can find detail documentation from [here](https://supabase.com/docs/reference/dart/select).

#### Reading your data

```dart
import 'package:postgrest/postgrest.dart';

var url = 'https://example.com/postgrest/endpoint';
var client = PostgrestClient(url);
var response = await client.from('users').select().execute();
```

#### Insert records

```dart
import 'package:postgrest/postgrest.dart';

var url = 'https://example.com/postgrest/endpoint';
var client = PostgrestClient(url);
var response = await client.from('users')
      .insert([
        {'username': 'supabot', 'status': 'ONLINE'}
      ])
      .execute();
```

#### Update a record

```dart
import 'package:postgrest/postgrest.dart';

var url = 'https://example.com/postgrest/endpoint';
var client = PostgrestClient(url);
var response = await client.from('users')
      .update({'status': 'OFFLINE'})
      .eq('username', 'dragarcia')
      .execute();
```

#### Delete records

```dart
import 'package:postgrest/postgrest.dart';

var url = 'https://example.com/postgrest/endpoint';
var client = PostgrestClient(url);
var response = await client.from('users')
      .delete()
      .eq('username', 'supabot')
      .execute();
```

#### Get Count

```dart
import 'package:postgrest/postgrest.dart';

var url = 'https://example.com/postgrest/endpoint';
var client = PostgrestClient(url);
var response = await client.from('countries')
      .select()
      .execute(count: CountOption.exact, head: true);
```

## Contributing

- Fork the repo on [GitHub](https://github.com/supabase/postgrest-dart)
- Clone the project to your own machine
- Commit changes to your own branch
- Push your work back up to your fork
- Submit a Pull request so that we can review your changes and merge

## License

This repo is licensed under MIT.

## Credits

- https://github.com/supabase/postgrest-js - ported from postgrest-js library
