/// Returns count as part of the response when specified.
enum ReturningOption {
  minimal,
  representation,
}

extension ReturningOptionName on ReturningOption {
  String name() {
    return toString().split('.').last;
  }
}
