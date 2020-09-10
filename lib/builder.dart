class Builder {
  String url;
  Map headers;
  String schema;

  Builder(String url, {Map headers, String schema}) {
    this.url = url;
    this.headers = headers == null ? {} : headers;
    this.schema = schema;
  }
}
