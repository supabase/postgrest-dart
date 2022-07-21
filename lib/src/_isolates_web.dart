//Copied from package:flutter/foundation/_isolates_web.dart

import 'isolates.dart' as isolates;

/// The dart:html implementation of [isolates.compute].
Future<R> compute<Q, R>(isolates.ComputeCallback<Q, R> callback, Q message,
    {String? debugLabel}) async {
  // To avoid blocking the UI immediately for an expensive function call, we
  // pump a single frame to allow the framework to complete the current set
  // of work.
  await null;
  return callback(message);
}
