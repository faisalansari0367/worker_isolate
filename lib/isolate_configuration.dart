import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

class IsolateConfiguration<Q, R> {
  const IsolateConfiguration({
    this.callback,
    this.message,
    required this.resultPort,
  });
  final ComputeCallback<Q, R>? callback;
  final Q? message;
  final SendPort resultPort;

  FutureOr<R> apply() => callback!(message!);
}
