library worker_isolate;

/// A Calculator.
import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'isolate_configuration.dart';

class Worker {
  static late Isolate _isolate;
  static late SendPort _sendPort;
  static late ReceivePort _resultPort;
  static late ReceivePort _exitPort;
  static late ReceivePort _errorPort;
  static bool _isInitialized = false;
  Worker() {
    // ignore: unnecessary_null_comparison
    if (_isInitialized) return;
    initWorker();
  }

  Future<void> initWorker<Q, R>() async {
    _isInitialized = true;
    _resultPort = ReceivePort();
    _exitPort = ReceivePort();
    _errorPort = ReceivePort();
    _isolate = await Isolate.spawn<IsolateConfiguration<Q, FutureOr<R>>>(
      _spawn,
      IsolateConfiguration<Q, FutureOr<R>>(resultPort: _resultPort.sendPort),
      errorsAreFatal: true,
      onExit: _exitPort.sendPort,
      onError: _errorPort.sendPort,
    );
    final result = Completer<R>();
    _errorPort.listen((dynamic errorData) {
      assert(errorData is List<dynamic>);
      if (errorData is List<dynamic>) {
        assert(errorData.length == 2);
        final exception = Exception(errorData[0]);
        final stack = StackTrace.fromString(errorData[1] as String);
        if (result.isCompleted) {
          Zone.current.handleUncaughtError(exception, stack);
        } else {
          result.completeError(exception, stack);
        }
      }
    });
    _exitPort.listen((dynamic exitData) {
      if (!result.isCompleted) {
        result.completeError(Exception('Isolate exited without result or error.'));
      }
    });
    _resultPort.listen((dynamic resultData) {
      if (resultData is SendPort) {
        log('isolate instantiated');
        _sendPort = resultData;
      }
      assert(resultData == null || resultData is R);
      if (!result.isCompleted) result.complete(resultData as R);
    });
  }

  Future<R> compute<Q, R>(ComputeCallback<Q, R> callback, Q message) async {
    final resultPort = ReceivePort();
    final isolateConfiguration = IsolateConfiguration(
      callback: callback,
      message: message,
      resultPort: resultPort.sendPort,
    );
    _sendPort.send(isolateConfiguration);

    final result = Completer<R>();
    resultPort.listen(
      (resultData) {
        assert(resultData == null || resultData is R);
        if (!result.isCompleted) result.complete(resultData as R);
      },
    );
    await result.future;
    resultPort.close();
    return result.future;
  }

  Future<void> _spawn<Q, R>(IsolateConfiguration<Q, FutureOr<R>> configuration) async {
    final toIsolate = ReceivePort();
    configuration.resultPort.send(toIsolate.sendPort);
    toIsolate.listen((message) async {
      if (message is IsolateConfiguration) {
        try {
          final result = await message.apply();
          message.resultPort.send(result);
        } catch (e) {
          message.resultPort.send(e);
        }
      }
    });
  }

  void stop() {
    _errorPort.close();
    _resultPort.close();
    _exitPort.close();
    _isolate.kill();
  }

  void pause() {
    _isolate.pause();
  }

  void resume() {
    // final resumeCapability = _isolate.pauseCapability;
    // _isolate.resume(resumeCapability);
  }
}
