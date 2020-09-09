class Helpers {
  static String objectToQueryString(Map obj) {
    var params = new List();
    obj.forEach((k, v) => params.add("$k=$v"));
    return params.join('&');
  }

  static List cleanFilterArray(filterArray) {
    var cleanedFilterArray = filterArray.map((filter) {
      var cleanedFilter = filter;
      if (filter is String &&
          (filter.contains(',') ||
              filter.contains('(') ||
              filter.contains(')'))) cleanedFilter = '"$filter"';

      return cleanedFilter;
    }).toList();

    return cleanedFilterArray;
  }

  static Map cleanColumnName(columnName) {
    var cleanedColumnName = columnName;
    var foreignTableName;

    if (columnName.contains('.')) {
      cleanedColumnName = columnName.split('.')[1];
      foreignTableName = columnName.split('.')[0];
    }

    return {
      'cleanedColumnName': cleanedColumnName,
      'foreignTableName': foreignTableName
    };
  }
}
