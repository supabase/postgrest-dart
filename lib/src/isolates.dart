//Modified from package:flutter/foundation/isolates.dart

import 'dart:async';

import '_isolates_io.dart' if (dart.library.html) '_isolates_web.dart'
    as isolates;

typedef ComputeCallback<Q, R> = FutureOr<R> Function(Q message);
typedef ComputeImpl = Future<R> Function<Q, R>(
  ComputeCallback<Q, R> callback,
  Q message,
);

const ComputeImpl compute = isolates.compute;
