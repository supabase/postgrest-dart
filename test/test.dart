import 'package:test/test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  PostgrestClient postgrest;

  setUp(() {
    postgrest = PostgrestClient('https://oeznfpyyelnwcalojjtc.supabase.net/rest/v1',
        headers: {
          'apikey':
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlhdCI6MTYxMDM1NTc0NywiZXhwIjoxOTI1OTMxNzQ3fQ.hdnv95uc_JDLxZqMtZ0ZIEzTaHEXo1yZYU-84qIWNuw',
        },
        schema: 'public');
  });

  // test('basic select table', () async {
  //   final response =
  //       await postgrest.from('countries').select().order('name', ascending: true).execute();
  //   if (response.status == 200) {
  //     print('Countries List: ${response.data}.');
  //   } else {
  //     print('Request failed with status: ${response.status}.');
  //   }
  // });

  test('Insert to table', () async {
    final response = await postgrest.from('countries').insert([
      {
        'iso2': "another name here",
      }
    ]).execute();
    if (response.error == null) {
      print('Insert country: ${response.data}.');
    } else {
      print('Request failed with status: ${response.status}.');
    }
  });
}
