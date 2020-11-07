import 'package:postgrest/postgrest.dart';

/// Example to use with Supabase API https://supabase.io/
void main() async {
  final client = PostgrestClient('SUPABASE_API_ENDPOINT/rest/v1',
      headers: {
        'apikey': 'SUPABSE_API_KEY',
      },
      schema: 'public');

  final response =
      await client.from('countries').select('*').order('name', ascending: true).execute();
  if (response.status == 200) {
    print('Countries List: ${response.data}.');
  } else {
    print('Request failed with status: ${response.status}.');
  }
}
