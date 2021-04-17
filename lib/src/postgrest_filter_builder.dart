import 'dart:convert';

import 'package:postgrest/src/text_search_type.dart';

import 'postgrest_builder.dart';
import 'postgrest_transform_builder.dart';

class PostgrestFilterBuilder extends PostgrestTransformBuilder {
  PostgrestFilterBuilder(PostgrestBuilder builder) : super(builder);

  /// Convert list filter to query params string
  String _cleanFilterArray(List filter) {
    return filter.map((s) => '"$s"').join(',');
  }

  /// Finds all rows which doesn't satisfy the filter.
  ///
  /// ```dart
  /// postgrest.from('users').select().not('status', 'eq', 'OFFLINE')
  /// ```
  PostgrestFilterBuilder not(String column, String operator, dynamic value) {
    appendSearchParams(column, 'not.$operator.$value');
    return this;
  }

  /// Finds all rows satisfying at least one of the filters.
  ///
  /// ```dart
  /// postgrest.from('users').select().or('status.eq.OFFLINE,username.eq.supabot')
  /// ```
  PostgrestFilterBuilder or(String filters) {
    appendSearchParams('or', '($filters)');
    return this;
  }

  /// Finds all rows whose value on the stated [column] exactly matches the specified [value].
  ///
  /// ```dart
  /// postgrest.from('users').select().eq('username', 'supabot')
  /// ```
  PostgrestFilterBuilder eq(String column, dynamic value) {
    appendSearchParams(column, 'eq.$value');
    return this;
  }

  /// Finds all rows whose value on the stated [column] doesn't match the specified [value].
  ///
  /// ```dart
  /// postgrest.from('users').select().neq('username', 'supabot')
  /// ```
  PostgrestFilterBuilder neq(String column, dynamic value) {
    appendSearchParams(column, 'neq.$value');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is greater than the specified [value].
  ///
  /// ```dart
  /// postgrest.from('messages').select().gt('id', 1)
  /// ```
  PostgrestFilterBuilder gt(String column, dynamic value) {
    appendSearchParams(column, 'gt.$value');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is greater than or equal to the specified [value].
  ///
  /// ```dart
  /// postgrest.from('messages').select().gte('id', 1)
  /// ```
  PostgrestFilterBuilder gte(String column, dynamic value) {
    appendSearchParams(column, 'gte.$value');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is less than the specified [value].
  ///
  /// ```dart
  /// postgrest.from('messages').select().lt('id', 2)
  /// ```
  PostgrestFilterBuilder lt(String column, dynamic value) {
    appendSearchParams(column, 'lt.$value');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is less than or equal to the specified [value].
  ///
  /// ```dart
  /// postgrest.from('messages').select().lte('id', 2)
  /// ```
  PostgrestFilterBuilder lte(String column, dynamic value) {
    appendSearchParams(column, 'lte.$value');
    return this;
  }

  /// Finds all rows whose value in the stated [column] matches the supplied [pattern] (case sensitive).
  ///
  /// ```dart
  /// postgrest.from('users').select().like('username', '%supa%')
  /// ```
  PostgrestFilterBuilder like(String column, String pattern) {
    appendSearchParams(column, 'like.$pattern');
    return this;
  }

  /// Finds all rows whose value in the stated [column] matches the supplied [pattern] (case insensitive).
  ///
  /// ```dart
  /// postgrest.from('users').select().ilike('username', '%SUPA%')
  /// ```
  PostgrestFilterBuilder ilike(String column, String pattern) {
    appendSearchParams(column, 'ilike.$pattern');
    return this;
  }

  /// A check for exact equality (null, true, false)
  ///
  /// Finds all rows whose value on the stated [column] exactly match the specified [value].
  /// ```dart
  /// postgrest.from('users').select().is_('data', null)
  /// ```
  // ignore: non_constant_identifier_names
  PostgrestFilterBuilder is_(String column, dynamic value) {
    appendSearchParams(column, 'is.$value');
    return this;
  }

  /// Finds all rows whose value on the stated [column] is found on the specified [values].
  ///
  /// ```dart
  /// postgrest.from('users').select().in_('status', ['ONLINE', 'OFFLINE'])
  /// ```
  // ignore: non_constant_identifier_names
  PostgrestFilterBuilder in_(String column, List values) {
    appendSearchParams(column, 'in.(${_cleanFilterArray(values)})');
    return this;
  }

  /// Finds all rows whose json, array, or range value on the stated [column] contains the values specified in [value].
  ///
  /// ```dart
  /// postgrest.from('users').select().contains('age_range', '[1,2)')
  /// ```
  PostgrestFilterBuilder contains(String column, dynamic value) {
    if (value is String) {
      // range types can be inclusive '[', ']' or exclusive '(', ')' so just
      // keep it simple and accept a string
      appendSearchParams(column, 'cs.$value');
    } else if (value is List) {
      // array
      appendSearchParams(column, 'cs.{${_cleanFilterArray(value)}}');
    } else {
      // json
      appendSearchParams(column, 'cs.${json.encode(value)}');
    }
    return this;
  }

  ///   /** @deprecated Use `contains()` instead. */
  @Deprecated('Use `contains()` instead.')
  PostgrestFilterBuilder Function(String, dynamic) get cs => contains;

  /// Finds all rows whose json, array, or range value on the stated [column] is contained by the specified [value].
  ///
  /// ```dart
  /// postgrest.from('users').select().containedBy('age_range', '[1,2)')
  /// ```
  PostgrestFilterBuilder containedBy(String column, dynamic value) {
    if (value is String) {
      // range types can be inclusive '[', ']' or exclusive '(', ')' so just
      // keep it simple and accept a string
      appendSearchParams(column, 'cd.$value');
    } else if (value is List) {
      // array
      appendSearchParams(column, 'cd.{${_cleanFilterArray(value)}}');
    } else {
      // json
      appendSearchParams(column, 'cd.${json.encode(value)}');
    }
    return this;
  }

  @Deprecated('Use `containedBy()` instead.')
  PostgrestFilterBuilder Function(String, dynamic) get cd => containedBy;

  /// Finds all rows whose range value on the stated [column] is strictly to the left of the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().sl('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder rangeLt(String column, String range) {
    appendSearchParams(column, 'sl.$range');
    return this;
  }

  @Deprecated('Use `rangeLt()` instead.')
  PostgrestFilterBuilder Function(String, String) get sl => rangeLt;

  /// Finds all rows whose range value on the stated [column] is strictly to the right of the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().rangeGt('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder rangeGt(String column, String range) {
    appendSearchParams(column, 'sr.$range');
    return this;
  }

  @Deprecated('Use `rangeGt()` instead.')
  PostgrestFilterBuilder Function(String, String) get sr => rangeGt;

  /// Finds all rows whose range value on the stated [column] does not extend to the left of the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().rangeGte('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder rangeGte(String column, String range) {
    appendSearchParams(column, 'nxl.$range');
    return this;
  }

  @Deprecated('Use `rangeGte()` instead.')
  PostgrestFilterBuilder Function(String, String) get nxl => rangeGte;

  /// Finds all rows whose range value on the stated [column] does not extend to the right of the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().rangeLte('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder rangeLte(String column, String range) {
    appendSearchParams(column, 'nxr.$range');
    return this;
  }

  @Deprecated('Use `rangeGte()` instead.')
  PostgrestFilterBuilder Function(String, String) get nxr => rangeLte;

  /// Finds all rows whose range value on the stated [column] is adjacent to the specified [range].
  ///
  /// ```dart
  /// postgrest.from('users').select().rangeAdjacent('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder rangeAdjacent(String column, String range) {
    appendSearchParams(column, 'adj.$range');
    return this;
  }

  @Deprecated('Use `rangeGte()` instead.')
  PostgrestFilterBuilder Function(String, String) get adj => rangeAdjacent;

  /// Finds all rows whose array or range value on the stated [column] overlaps (has a value in common) with the specified [value].
  ///
  /// ```dart
  /// postgrest.from('users').select().overlaps('age_range', '[2,25)')
  /// ```
  PostgrestFilterBuilder overlaps(String column, dynamic value) {
    if (value is String) {
      // range types can be inclusive '[', ']' or exclusive '(', ')' so just
      // keep it simple and accept a string
      appendSearchParams(column, 'ov.$value');
    } else if (value is List) {
      // array
      appendSearchParams(column, 'ov.{${_cleanFilterArray(value)}}');
    }
    return this;
  }

  @Deprecated('Use `rangeGte()` instead.')
  PostgrestFilterBuilder Function(String, String) get ov => overlaps;

/**
   * Finds all rows whose text or tsvector value on the stated `column` matches
   * the tsquery in `query`.
   *
   * @param column  The column to filter on.
   * @param query  The Postgres tsquery string to filter with.
   * @param config  The text search configuration to use.
   * @param type  The type of tsquery conversion to use on `query`.
   */

  /// Finds all rows whose text or tsvector value on the stated [column] matches the tsquery in [query].
  ///
  ///
  /// ```dart
  /// postgrest.from('users').select().textSearch('bio', 'cat')
  /// ```
  PostgrestFilterBuilder textSearch(
    String column,
    String query, {

    /// The text search configuration to use.
    String? config,

    /// The type of tsquery conversion to use on [query].
    TextSearchType? type,
  }) {
    var typePart = '';
    if (type == TextSearchType.plain) {
      typePart = 'pl';
    } else if (type == TextSearchType.phrase) {
      typePart = 'ph';
    } else if (type == TextSearchType.websearch) {
      typePart = 'w';
    }
    final configPart = config == null ? '' : '($config)';
    appendSearchParams(column, '${typePart}fts$configPart.$query');
    return this;
  }

  /// This class is deprecated, please use `textSearch()` instead.
  /// Finds all rows whose tsvector value on the stated [column] matches to_tsquery([query]).
  ///
  /// [options] can contains `config` key which is text search configuration to use.
  /// ```dart
  /// postgrest.from('users').select().fts('catchphrase', "'fat' & 'cat'", { config: 'english' })
  /// ```
  @Deprecated('Use `textSearch()` instead.')
  PostgrestFilterBuilder fts(String column, String query, {String? config}) {
    final configPart = config == null ? '' : '($config)';
    appendSearchParams(column, 'fts$configPart.$query');
    return this;
  }

  /// This class is deprecated, please use `textSearch()` instead.
  /// Finds all rows whose tsvector value on the stated [column] matches plainto_tsquery([query]).
  ///
  /// [options] can contains `config` key which is text search configuration to use.
  /// ```dart
  /// postgrest.from('users').select().plfts('catchphrase', "'fat' & 'cat'", { config: 'english' })
  /// ```
  @Deprecated('Use `textSearch()` instead.')
  PostgrestFilterBuilder plfts(String column, String query, {String? config}) {
    final configPart = config == null ? '' : '($config)';
    appendSearchParams(column, 'plfts$configPart.$query');
    return this;
  }

  /// This class is deprecated, please use `textSearch()` instead.
  /// Finds all rows whose tsvector value on the stated [column] matches phraseto_tsquery([query]).
  ///
  /// [options] can contains `config` key which is text search configuration to use.
  /// ```dart
  /// postgrest.from('users').select().phfts('catchphrase', 'cat', { config: 'english' })
  /// ```
  @Deprecated('Use `textSearch()` instead.')
  PostgrestFilterBuilder phfts(String column, String query, {String? config}) {
    final configPart = config == null ? '' : '($config)';
    appendSearchParams(column, 'phfts$configPart.$query');
    return this;
  }

  /// This class is deprecated, please use `textSearch()` instead.
  /// Finds all rows whose tsvector value on the stated [column] matches websearch_to_tsquery([query]).
  ///
  /// [options] can contains `config` key which is text search configuration to use.
  /// ```dart
  /// postgrest.from('users').select().wfts('catchphrase', "'fat' & 'cat'", { config: 'english' })
  /// ```
  @Deprecated('Use `textSearch()` instead.')
  PostgrestFilterBuilder wfts(String column, String query, {String? config}) {
    final configPart = config == null ? '' : '($config)';
    appendSearchParams(column, 'wfts$configPart.$query');
    return this;
  }

  /// Finds all rows whose [column] satisfies the filter.
  ///
  /// ```dart
  /// postgrest.from('users').select().filter('username', 'eq', 'supabot')
  /// ```
  PostgrestFilterBuilder filter(String column, String operator, dynamic value) {
    appendSearchParams(column, '$operator.$value');
    return this;
  }

  /// Finds all rows whose columns match the specified [query] object.
  ///
  /// [query] contains column names as keys mapped to their filter values.
  /// ```dart
  /// postgrest.from('users').select().match({ 'username': 'supabot', 'status': 'ONLINE' })
  /// ```
  PostgrestFilterBuilder match(Map query) {
    query.forEach((k, v) => appendSearchParams('$k', 'eq.$v'));
    return this;
  }
}
