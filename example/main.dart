import 'package:postgrest/postgrest.dart';

/// Example to use with Supabase API https://supabase.io/
dynamic main() async {
  const supabaseUrl = 'https://myinyaxerywtmnkxexmm.supabase.co';
  const supabaseKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlhdCI6MTYzNjc2MjMyMywiZXhwIjoxOTUyMzM4MzIzfQ.y6T34WA09G2SXAB9m_b0DG9IKjj993yQq5rGWkYpZio';
  final client = PostgrestClient(
    '$supabaseUrl/rest/v1',
    headers: {'apikey': supabaseKey},
    schema: 'public',
  );
  try {
    final response = await client.from('countries').select(
          '*',
          FetchOptions(count: CountOption.exact),
        );
    print(response);
  } on PostgrestError catch (e) {
    // handle PostgrestError
    print(e.code);
    print(e.message);
  }
}
