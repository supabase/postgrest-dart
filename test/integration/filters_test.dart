import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

void main() {
  String rootUrl = 'http://localhost:3000';

  createArrayFilterCheck(filter) {
    test("should not accept non-array data type for $filter", () async {
      var client = PostgrestClient(rootUrl);
      var res = await client
          .from('users')
          .select('*')
          .filter('username', filter, 'non-array');
      expect(res['statusText'],
          ".$filter() cannot be invoked with criteria that is not an Array.");
    });
  }

  createDataTypeCheck(filter) {
    test(
        "should throw an error for $filter when data type and filter are incompatible",
        () {
      var client = PostgrestClient(rootUrl);
      var future =
          client.from('users').select('*').filter('username', filter, [1, 2]);
      future.catchError((error) => throw error);
    });
  }

  createRangeFilterCheck(filter) {
    test("should not accept an array that is not of length 2 for $filter",
        () async {
      var client = PostgrestClient(rootUrl);
      var res = await client
          .from('users')
          .select('*')
          .filter('username', filter, [1, 2, 3]);
      expect(res['statusText'],
          ".$filter() can only be invoked with a criteria that is an Array of length 2.");
    });
  }

  createFullTextSearchCheck(filter) {
    test(
        "should not accept anything else that is not an Object and does not have they key queryText for $filter",
        () async {
      var client = PostgrestClient(rootUrl);
      var res = await client
          .from('users')
          .select('*')
          .filter('username', filter, [1, 2, 3]);
      expect(res['statusText'],
          ".$filter() can only be invoked with a criteria that is an Object with key queryText.");
    });
  }

  var arrayFilterList = [
    'in',
    'cs',
    'cd',
    'ova',
    'ovr',
    'sl',
    'sr',
    'nxr',
    'nxl',
    'adj'
  ];
  arrayFilterList.forEach((filter) => createArrayFilterCheck(filter));

  var dataTypeList = [
    'cs',
    'cd',
    'ova',
    'ovr',
    'sl',
    'sr',
    'nxr',
    'nxl',
    'adj'
  ];
  dataTypeList.forEach((filter) => createDataTypeCheck(filter));

  var rangeFilterList = ['ovr', 'sl', 'sr', 'nxr', 'nxl', 'adj'];
  rangeFilterList.forEach((filter) => createRangeFilterCheck(filter));

  var fullTextSearchList = ['fts', 'plfts', 'phfts', 'wfts'];
  fullTextSearchList.forEach((filter) => createFullTextSearchCheck(filter));

  test('should throw an error for limit() when criteria is not of type number',
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').select('*').limit('test');

    expect(res['statusText'],
        ".limit() cannot be invoked with criteria that is not a number.");
  });
  test('should throw an error for offset() when criteria is not of type number',
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').select('*').offset('test');

    expect(res['statusText'],
        ".offset() cannot be invoked with criteria that is not a number.");
  });
  test(
      'should throw an error for range() when first parameter is not of type number',
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').select('*').range('test');

    expect(res['statusText'],
        ".range() cannot be invoked with parameters that are not numbers.");
  });
  test(
      'should throw an error for range() when second parameter is not of type number and not null',
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').select('*').range(0, 'test');

    expect(res['statusText'],
        ".range() cannot be invoked with parameters that are not numbers.");
  });
  test('should be able to support order() if invoked afterwards', () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').select('*').order('username').end();

    expect(res['body'][0]['username'], "supabot");
    expect(res['body'][3]['username'], "awailas");
  });
  test(
      'should be able to support order() with all parameters stated if invoked afterwards',
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client
        .from('users')
        .select('*')
        .order('username', true, false)
        .end();

    expect(res['body'][0]['username'], "awailas");
    expect(res['body'][3]['username'], "supabot");
  });
  test('should be able to support limit() if invoked afterwards', () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').select('*').limit(1).end();

    expect(res['body'].length, 1);
    expect(res['body'][0]['username'], "supabot");
  });
  test('should be able to support offset() if invoked afterwards', () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').select('*').offset(1).end();

    expect(res['body'].length, 3);
    expect(res['body'][0]['username'], "kiwicopple");
  });
  test('should be able to support range() if invoked afterwards', () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').select('*').range(0, 2).end();

    expect(res['body'].length, 3);
    expect(res['body'][0]['username'], "supabot");
    expect(res['body'][2]['username'], "awailas");
  });
  test(
      'should be able to support range() with only first parameter stated if invoked afterwards',
      () async {
    var client = PostgrestClient(rootUrl);
    var res = await client.from('users').select('*').range(1).end();

    expect(res['body'].length, 3);
    expect(res['body'][0]['username'], "kiwicopple");
    expect(res['body'][2]['username'], "dragarcia");
  });
  test('should be able to take in filters before an actual request is made',
      () {
    var client = PostgrestClient(rootUrl);
    var res = client
        .from('countries')
        .eq('name', 'New Zealand')
        .gt('id', 20)
        .lt('id', 20)
        .gte('id', 20)
        .lte('id', 20)
        .like('name', '%United%')
        .ilike('name', '%United%')
        .$is('name', null)
        .$in('name', ['China', 'France'])
        .neq('name', 'China')
        .fts('phrase', {'queryText': 'The Fat Cats', 'config': 'english'})
        .plfts('phrase', {'queryText': 'The Fat Cats'})
        .phfts('phrase', {'queryText': 'The Fat Cats', 'config': 'english'})
        .wfts('phrase', {'queryText': 'The Fat Cats'})
        .cs('countries', ['China', 'France'])
        .cd('countries', ['China', 'France'])
        .ova('allies', ['China', 'France'])
        .ovr('population_range', [100, 500])
        .sl('population_range', [100, 500])
        .sr('population_range', [100, 500])
        .nxl('population_range', [100, 500])
        .nxr('population_range', [100, 500])
        .adj('population_range', [100, 500])
        .or('id.gt.20,and(name.eq.New Zealand,name.eq.France)')
        .select('*');

    expect(res.query, [
      'select=*',
      'name=eq.New Zealand',
      'id=gt.20',
      'id=lt.20',
      'id=gte.20',
      'id=lte.20',
      'name=like.*United*',
      'name=ilike.*United*',
      'name=is.null',
      'name=in.(China,France)',
      'name=neq.China',
      'phrase=fts(english).The Fat Cats',
      'phrase=plfts.The Fat Cats',
      'phrase=phfts(english).The Fat Cats',
      'phrase=wfts.The Fat Cats',
      'countries=cs.{China,France}',
      'countries=cd.{China,France}',
      'allies=ov.{China,France}',
      'population_range=ov.(100,500)',
      'population_range=sl.(100,500)',
      'population_range=sr.(100,500)',
      'population_range=nxl.(100,500)',
      'population_range=nxr.(100,500)',
      'population_range=adj.(100,500)',
      'or=(id.gt.20,and(name.eq.New Zealand,name.eq.France))',
    ]);
  });
}
