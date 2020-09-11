import 'package:flutter_test/flutter_test.dart';

import 'package:postgrest/utils/helpers.dart';

void main() {
  test('will convert obj to query string', () {
    var result = Helpers.objectToQueryString({'a': 'value1', 'b': 'value2'});
    expect(result, 'a=value1&b=value2');
  });
  test('will clean filter array', () {
    var result = Helpers.cleanFilterArray(['Beijing,China', 'France']);
    expect(result, ['"Beijing,China"', 'France']);
  });
  test('will clean column name', () {
    var result = Helpers.cleanColumnName('user.id');
    expect(result, {'cleanedColumnName': 'id', 'foreignTableName': 'user'});
  });
}
