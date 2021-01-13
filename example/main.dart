import 'package:postgrest/postgrest.dart';

/// Example to use with Supabase API https://supabase.io/
dynamic main() async {
  final client = PostgrestClient('SUPABASE_API_ENDPOINT/rest/v1',
      headers: {
        'apikey': 'SUPABSE_API_KEY',
      },
      schema: 'public');

  final response = await client.from('countries').select().order('name', ascending: true).execute();
  if (response.error == null) {
    return response.data;
  } else {
    return null;
  }
}
