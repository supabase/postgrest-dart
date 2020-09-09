import 'dart:convert';

import 'package:postgrest/utils/helpers.dart';

class Filters {
  /// All methods are prefixed with an $ to avoid collisions with reserved keywords (eg: "in")
  /// We can't use underscore (_)  as it's used for private method

  /// Finds all rows whose value on the stated columnName exactly matches the specified filterValue.
  /// @param {string} columnName Name of the database column
  /// @param { string | integer | boolean } filterValue Value to match
  /// @name eq
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $eq('name', 'New Zealand')
  /// //=>
  /// 'name=eq.New Zealand'
  static String $eq(String columnName, dynamic filterValue) {
    return "$columnName=eq.$filterValue";
  }

  /// Finds all rows whose value on the stated columnName is greater than the specified filterValue.
  /// @param {string} columnName Name of the database column
  /// @param { string | integer | boolean } filterValue Value to match
  /// @name gt
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $gt('id', 20)
  /// //=>
  /// 'id=gt.20'
  static String $gt(String columnName, dynamic filterValue) {
    return "$columnName=gt.$filterValue";
  }

  /// Finds all rows whose value on the stated columnName is less than the specified filterValue.
  /// @param {string} columnName Name of the database column
  /// @param { string | integer | boolean } filterValue Value to match
  /// @name lt
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $lt('id', 20)
  /// //=>
  /// 'id=lt.20'
  static String $lt(String columnName, dynamic filterValue) {
    return "$columnName=lt.$filterValue";
  }

  /// Finds all rows whose value on the stated columnName is greater than or equal to the specified filterValue.
  /// @param {string} columnName Name of the database column
  /// @param { string | integer | boolean } filterValue Value to match
  /// @name gte
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $gte('id', 20)
  /// //=>
  /// 'id=gte.20'
  static String $gte(String columnName, dynamic filterValue) {
    return "$columnName=gte.$filterValue";
  }

  /// Finds all rows whose value on the stated columnName is less than or equal to the specified filterValue.
  /// @param {string} columnName Name of the database column
  /// @param { string | integer | boolean } filterValue Value to match
  /// @name lte
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $lte('id', 20)
  /// //=>
  /// 'id=lte.20'
  static String $lte(String columnName, dynamic filterValue) {
    return "$columnName=lte.$filterValue";
  }

  /// Finds all rows whose value in the stated columnName matches the supplied pattern (case sensitive).
  /// @param {string} columnName Name of the database column
  /// @param { string } stringPattern String pattern to compare to
  /// @name like
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $like('name', '%United%')
  /// //=>
  /// 'name=like.*United*'
  ///
  /// @example
  /// $like('name', '%United States%')
  /// //=>
  /// 'name=like.*United States*'
  static String $like(String columnName, dynamic stringPattern) {
    var stringPatternEnriched = stringPattern.replaceAll(RegExp(r'%'), '*');
    return "$columnName=like.$stringPatternEnriched";
  }

  /// Finds all rows whose value in the stated columnName matches the supplied pattern (case insensitive).
  /// @param {string} columnName Name of the database column
  /// @param { string } stringPattern String pattern to compare to
  /// @name ilike
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $ilike('name', '%United%')
  /// //=>
  /// 'name=ilike.*United*'
  ///
  /// @example
  /// $ilike('name', '%United states%')
  /// //=>
  /// 'name=ilike.*United states*'
  static String $ilike(String columnName, dynamic stringPattern) {
    var stringPatternEnriched = stringPattern.replaceAll(RegExp(r'%'), '*');
    return "$columnName=ilike.$stringPatternEnriched";
  }

  /// A check for exact equality (null, true, false), finds all rows whose value on the state columnName exactly match the specified filterValue.
  /// @param {string} columnName Name of the database column
  /// @param { string | integer | boolean } filterValue Value to match
  /// @name is
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $is('name', null)
  /// //=>
  /// 'name=is.null'
  static String $is(String columnName, dynamic filterValue) {
    return "$columnName=is.$filterValue";
  }

  /// Finds all rows whose value on the stated columnName is found on the specified filterArray.
  /// @param {string} columnName Name of the database column
  /// @param { string | integer | boolean } filterValue Value to match
  /// @name in
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $in('name', ['China', 'France'])
  /// //=>
  /// 'name=in.(China,France)'
  ///
  /// @example
  /// $in('capitals', ['Beijing,China', 'Paris,France'])
  /// //=>
  /// 'capitals=in.("Beijing,China","Paris,France")'
  ///
  /// @example
  /// $in('food_supplies', ['carrot (big)', 'carrot (small)'])
  /// //=>
  /// 'food_supplies=in.("carrot (big)","carrot (small)")'
  static String $in(String columnName, dynamic filterArray) {
    var cleanedFilterArray = Helpers.cleanFilterArray(filterArray);

    return "$columnName=in.(${cleanedFilterArray.join(',')})";
  }

  /// Finds all rows whose value on the stated columnName is found on the specified filterArray.
  /// @param {string} columnName Name of the database column
  /// @param { string | integer | boolean } filterValue Value to match
  /// @name not
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $neq('name', 'China')
  /// //=>
  /// 'name=neq.China'
  static String $neq(String columnName, dynamic filterValue) {
    return "$columnName=neq.$filterValue";
  }

  /// Finds all rows whose tsvector value on the stated columnName matches to_tsquery(queryText).
  /// @param {string} columnName Name of the database column
  /// @param { object } filterObject query text and optionally config to base the match on
  /// @name fts
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $fts('phrase', {queryText: 'The Fat Cats'})
  /// //=>
  /// 'phrase=fts.The Fat Cats'
  ///
  /// @example
  /// $fts('phrase', {queryText: 'The Fat Cats', config: 'english'})
  /// //=>
  /// 'phrase=fts(english).The Fat Cats'
  static String $fts(String columnName, Map filterObject) {
    if (!filterObject.containsKey('config'))
      return "$columnName=fts.${filterObject['queryText']}";
    return "$columnName=fts(${filterObject['config']}).${filterObject['queryText']}";
  }

  /// Finds all rows whose tsvector value on the stated columnName matches plainto_tsquery(queryText).
  /// @param {string} columnName Name of the database column
  /// @param { object } filterObject query text and optionally config to base the match on
  /// @name plfts
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $plfts('phrase', {queryText: 'The Fat Cats'})
  /// //=>
  /// 'phrase=plfts.The Fat Cats'
  ///
  /// @example
  /// $plfts('phrase', {queryText: 'The Fat Cats', config: 'english'})
  /// //=>
  /// 'phrase=plfts(english).The Fat Cats'
  static String $plfts(String columnName, Map filterObject) {
    if (!filterObject.containsKey('config'))
      return "$columnName=plfts.${filterObject['queryText']}";
    return "$columnName=plfts(${filterObject['config']}).${filterObject['queryText']}";
  }

  /// Finds all rows whose tsvector value on the stated columnName matches phraseto_tsquery(queryText).
  /// @param {string} columnName Name of the database column
  /// @param { object } filterObject query text and optionally config to base the match on
  /// @name phfts
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $phfts('phrase', {queryText: 'The Fat Cats'})
  /// //=>
  /// 'phrase=phfts.The Fat Cats'
  ///
  /// @example
  /// $phfts('phrase', {queryText: 'The Fat Cats', config: 'english'})
  /// //=>
  /// 'phrase=phfts(english).The Fat Cats'
  static String $phfts(String columnName, Map filterObject) {
    if (!filterObject.containsKey('config'))
      return "$columnName=phfts.${filterObject['queryText']}";
    return "$columnName=phfts(${filterObject['config']}).${filterObject['queryText']}";
  }

  /// Finds all rows whose tsvector value on the stated columnName matches websearch_to_tsquery(queryText).
  /// @param {string} columnName Name of the database column
  /// @param { object } filterObject query text and optionally config to base the match on
  /// @name wfts
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $wfts('phrase', {queryText: 'The Fat Cats'})
  /// //=>
  /// 'phrase=wfts.The Fat Cats'
  ///
  /// @example
  /// $wfts('phrase', {queryText: 'The Fat Cats', config: 'english'})
  /// //=>
  /// 'phrase=wfts(english).The Fat Cats'
  static String $wfts(String columnName, Map filterObject) {
    if (!filterObject.containsKey('config'))
      return "$columnName=wfts.${filterObject['queryText']}";
    return "$columnName=wfts(${filterObject['config']}).${filterObject['queryText']}";
  }

  /// Finds all rows whose json || array || range value on the stated columnName contains the values specified in the filterObject.
  /// @param {string} columnName Name of the database column
  /// @param { array | object } filterObject Value to compare to
  /// @name cs
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $cs('countries', ['China', 'France'])
  /// //=>
  /// 'countries=cs.{China,France}'
  ///
  /// @example
  /// $cs('capitals', ['Beijing,China', 'Paris,France'])
  /// //=>
  /// 'capitals=cs.{"Beijing,China","Paris,France"}'
  ///
  /// @example
  /// $cs('food_supplies', {fruits:1000, meat:800})
  /// //=>
  /// 'food_supplies=cs.{"fruits":1000,"meat":800}'
  static String $cs(String columnName, dynamic filterObject) {
    if (filterObject is List) {
      var cleanedFilterArray = Helpers.cleanFilterArray(filterObject);
      return "$columnName=cs.{${cleanedFilterArray.join(',')}}";
    }

    final jsonEncoder = JsonEncoder();
    return "$columnName=cs.${jsonEncoder.convert(filterObject)}";
  }

  /// Finds all rows whose json || array || range value on the stated columnName is contained by the specified filterObject.
  /// @param {string} columnName Name of the database column
  /// @param { array | object } filterObject Value to compare to
  /// @name cd
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $cd('countries', ['China', 'France'])
  /// //=>
  /// 'countries=cd.{China,France}'
  ///
  /// @example
  /// $cd('capitals', ['Beijing,China', 'Paris,France'])
  /// //=>
  /// 'capitals=cd.{"Beijing,China","Paris,France"}'
  ///
  /// @example
  /// $cd('food_supplies', {fruits:1000, meat:800})
  /// //=>
  /// 'food_supplies=cd.{"fruits":1000,"meat":800}'
  static String $cd(String columnName, dynamic filterObject) {
    if (filterObject is List) {
      var cleanedFilterArray = Helpers.cleanFilterArray(filterObject);
      return "$columnName=cd.{${cleanedFilterArray.join(',')}}";
    }

    final jsonEncoder = JsonEncoder();
    return "$columnName=cd.${jsonEncoder.convert(filterObject)}";
  }

  /// Finds all rows whose array value on the stated columnName overlaps on the specified filterArray.
  /// @param {string} columnName Name of the database column
  /// @param {array} filterValue Value to compare to
  /// @name ova
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $ova('allies', ['China', 'France'])
  /// //=>
  /// 'allies=ov.{China,France}'
  ///
  /// @example
  /// $ova('capitals', ['Beijing,China', 'Paris,France'])
  /// //=>
  /// 'capitals=ov.{"Beijing,China","Paris,France"}'
  static String $ova(String columnName, List filterArray) {
    var cleanedFilterArray = Helpers.cleanFilterArray(filterArray);
    return "$columnName=ov.{${cleanedFilterArray.join(',')}}";
  }

  /// Finds all rows whose range value on the stated columnName overlaps on the specified filterRange.
  /// @param {string} columnName Name of the database column
  /// @param {array} filterRange Value to to compare to
  /// @name ovr
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $ovr('population_range', [100, 500])
  /// //=>
  /// 'population_range=ov.(100,500)'
  static String $ovr(String columnName, List filterRange) {
    return "$columnName=ov.(${filterRange.join(',')})";
  }

  /// Finds all rows whose range value on the stated columnName is strictly on the left of the specified filterRange.
  /// @param {string} columnName Name of the database column
  /// @param {array} filterRange Value to compare to
  /// @name sl
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $sl('population_range', [100, 500])
  /// //=>
  /// 'population_range=sl.(100,500)'
  static String $sl(String columnName, List filterRange) {
    return "$columnName=sl.(${filterRange.join(',')})";
  }

  /// Finds all rows whose range value on the stated columnName is strictly on the right of the specified filterRange.
  /// @param {string} columnName Name of the database column
  /// @param {array} filterRange Value to compare to
  /// @name sr
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $sr('population_range', [100,500])
  /// //=>
  /// 'population_range=sr.(100,500)'
  static String $sr(String columnName, List filterRange) {
    return "$columnName=sr.(${filterRange.join(',')})";
  }

  /// Finds all rows whose range value on the stated columnName does not extend to the left of the specified filterRange.
  /// @param {string} columnName Name of the database column
  /// @param {array} filterRange Value to compare to
  /// @name nxl
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $nxl('population_range', [100, 500])
  /// //=>
  /// 'population_range=nxl.(100,500)'
  static String $nxl(String columnName, List filterRange) {
    return "$columnName=nxl.(${filterRange.join(',')})";
  }

  /// Finds all rows whose range value on the stated columnName does not extend to the right of the specified filterRange.
  /// @param {string} columnName Name of the database column
  /// @param {array} filterRange Value to compare to
  /// @name nxr
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $nxr('population_range', [100, 500])
  /// //=>
  /// 'population_range=nxr.(100,500)'
  static String $nxr(String columnName, List filterRange) {
    return "$columnName=nxr.(${filterRange.join(',')})";
  }

  /// Finds all rows whose range value on the stated columnName is adjacent to the specified filterRange.
  /// @param {string} columnName Name of the database column
  /// @param {array} filterRange Value to compare to
  /// @name adj
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $adj('population_range', [100, 500])
  /// //=>
  /// 'population_range=adj.(100,500)'
  static String $adj(String columnName, List filterRange) {
    return "$columnName=adj.(${filterRange.join(',')})";
  }

  /// Finds all rows that satisfy at least one of the specified `filters`.
  /// @param {string} filters Filters to satisfy
  /// @name or
  /// @function
  /// @returns {string}
  ///
  /// @example
  /// $or('id.gt.20,and(name.eq.New Zealand,name.eq.France)')
  /// //=>
  /// 'or=(id.gt.20,and(name.eq.New Zealand,name.eq.France))'
  static String $or(String filters) {
    var filtersEnriched = filters.replaceAll(RegExp(r'%'), '*');
    return "or=($filtersEnriched)";
  }
}
