import 'package:flutter_test/flutter_test.dart';

import 'package:postgrest/utils/filters.dart';

void main() {
  test('will convert equal filter', () {
    var result = Filters.$eq('name', 'New Zealand');
    expect(result, 'name=eq.New Zealand');
  });
  test('will convert greater than filter', () {
    var result = Filters.$gt('id', 20);
    expect(result, 'id=gt.20');
  });
  test('will convert less than filter', () {
    var result = Filters.$lt('id', 20);
    expect(result, 'id=lt.20');
  });
  test('will convert greater than or equal filter', () {
    var result = Filters.$gte('id', 20);
    expect(result, 'id=gte.20');
  });
  test('will convert less than or equal filter', () {
    var result = Filters.$lte('id', 20);
    expect(result, 'id=lte.20');
  });
  test('will convert like filter', () {
    var result = Filters.$like('name', '%United%');
    expect(result, 'name=like.*United*');
    var result2 = Filters.$like('name', '%United States%');
    expect(result2, 'name=like.*United States*');
  });
  test('will convert is filter', () {
    var result = Filters.$is('name', null);
    expect(result, 'name=is.null');
  });
  test('will convert in filter', () {
    var result = Filters.$in('name', ['China', 'France']);
    expect(result, 'name=in.(China,France)');
    var result2 = Filters.$in('capitals', ['Beijing,China', 'Paris,France']);
    expect(result2, 'capitals=in.("Beijing,China","Paris,France")');
    var result3 =
        Filters.$in('food_supplies', ['carrot (big)', 'carrot (small)']);
    expect(result3, 'food_supplies=in.("carrot (big)","carrot (small)")');
  });
  test('will convert not equal filter', () {
    var result = Filters.$neq('name', 'China');
    expect(result, 'name=neq.China');
  });
  test('will convert full-text search filter', () {
    var result = Filters.$fts('phrase', {'queryText': 'The Fat Cats'});
    expect(result, 'phrase=fts.The Fat Cats');
    var result2 = Filters.$fts(
        'phrase', {'queryText': 'The Fat Cats', 'config': 'english'});
    expect(result2, 'phrase=fts(english).The Fat Cats');
  });
  test('will convert plain full-text search filter', () {
    var result = Filters.$plfts('phrase', {'queryText': 'The Fat Cats'});
    expect(result, 'phrase=plfts.The Fat Cats');
    var result2 = Filters.$plfts(
        'phrase', {'queryText': 'The Fat Cats', 'config': 'english'});
    expect(result2, 'phrase=plfts(english).The Fat Cats');
  });
  test('will convert phrase full-text search filter', () {
    var result = Filters.$phfts('phrase', {'queryText': 'The Fat Cats'});
    expect(result, 'phrase=phfts.The Fat Cats');
    var result2 = Filters.$phfts(
        'phrase', {'queryText': 'The Fat Cats', 'config': 'english'});
    expect(result2, 'phrase=phfts(english).The Fat Cats');
  });
  test('will convert websearch full-text search filter', () {
    var result = Filters.$wfts('phrase', {'queryText': 'The Fat Cats'});
    expect(result, 'phrase=wfts.The Fat Cats');
    var result2 = Filters.$wfts(
        'phrase', {'queryText': 'The Fat Cats', 'config': 'english'});
    expect(result2, 'phrase=wfts(english).The Fat Cats');
  });
  test('will convert cs filter', () {
    var result = Filters.$cs('countries', ['China', 'France']);
    expect(result, 'countries=cs.{China,France}');
    var result2 = Filters.$cs('capitals', ['Beijing,China', 'Paris,France']);
    expect(result2, 'capitals=cs.{"Beijing,China","Paris,France"}');
    var result3 = Filters.$cs('food_supplies', {'fruits': 1000, 'meat': 800});
    expect(result3, 'food_supplies=cs.{"fruits":1000,"meat":800}');
  });
  test('will convert cd filter', () {
    var result = Filters.$cd('countries', ['China', 'France']);
    expect(result, 'countries=cd.{China,France}');
    var result2 = Filters.$cd('capitals', ['Beijing,China', 'Paris,France']);
    expect(result2, 'capitals=cd.{"Beijing,China","Paris,France"}');
    var result3 = Filters.$cd('food_supplies', {'fruits': 1000, 'meat': 800});
    expect(result3, 'food_supplies=cd.{"fruits":1000,"meat":800}');
  });
  test('will convert ova filter', () {
    var result = Filters.$ova('allies', ['China', 'France']);
    expect(result, 'allies=ov.{China,France}');
    var result2 = Filters.$ova('capitals', ['Beijing,China', 'Paris,France']);
    expect(result2, 'capitals=ov.{"Beijing,China","Paris,France"}');
  });
  test('will convert ovr filter', () {
    var result = Filters.$ovr('population_range', [100, 500]);
    expect(result, 'population_range=ov.(100,500)');
  });
  test('will convert sl filter', () {
    var result = Filters.$sl('population_range', [100, 500]);
    expect(result, 'population_range=sl.(100,500)');
  });
  test('will convert sr filter', () {
    var result = Filters.$sr('population_range', [100, 500]);
    expect(result, 'population_range=sr.(100,500)');
  });
  test('will convert nxl filter', () {
    var result = Filters.$nxl('population_range', [100, 500]);
    expect(result, 'population_range=nxl.(100,500)');
  });
  test('will convert nxr filter', () {
    var result = Filters.$nxr('population_range', [100, 500]);
    expect(result, 'population_range=nxr.(100,500)');
  });
  test('will convert adj filter', () {
    var result = Filters.$adj('population_range', [100, 500]);
    expect(result, 'population_range=adj.(100,500)');
  });
  test('will convert or filter', () {
    var result =
        Filters.$or('id.gt.20,and(name.eq.New Zealand,name.eq.France)');
    expect(result, 'or=(id.gt.20,and(name.eq.New Zealand,name.eq.France))');
  });
}
