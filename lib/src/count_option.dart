/// Returns count as part of the response when specified.
enum CountOption {
  exact,
  planned,
  estimated,
}

extension CountOptionName on CountOption {
  String name() {
    return toString().split('.').last;
  }
}
