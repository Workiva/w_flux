// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@TestOn('browser')
library w_flux.test.action_test;

import 'dart:async';

import 'package:w_flux/src/action.dart';
import 'package:test/test.dart';

void main() {
  group('Action', () {
    Action<String> action;

    setUp(() {
      action = Action<String>();
    });

    test('should only be equivalent to itself', () {
      Action _action = Action();
      Action _action2 = Action();
      expect(_action == _action, isTrue);
      expect(_action == _action2, isFalse);
    });

    test('should support dispatch without a payload', () async {
      Completer c = Completer();
      Action<String> _action = Action<String>()
        ..listen((String payload) {
          expect(payload, equals(null));
          c.complete();
        });

      await _action();
      return c.future;
    });

    test('should support dispatch with a payload', () async {
      Completer c = Completer();
      action.listen((String payload) {
        expect(payload, equals('990 guerrero'));
        c.complete();
      });

      await action('990 guerrero');
      return c.future;
    });

    test('should dispatch by default when called', () async {
      Completer c = Completer();
      action.listen((String payload) {
        expect(payload, equals('990 guerrero'));
        c.complete();
      });

      await action('990 guerrero');
      return c.future;
    });

    group('dispatch', () {
      test(
          'should invoke and complete synchronous listeners in future event in '
          'event queue', () async {
        var listenerCompleted = false;
        var action = Action()
          ..listen((_) {
            listenerCompleted = true;
          });

        // No immediate invocation.
        unawaited(action(null));
        expect(listenerCompleted, isFalse);

        // Invoked during the next scheduled event in the queue.
        await Future(() => {});
        expect(listenerCompleted, isTrue);
      });

      test(
          'should invoke asynchronous listeners in future event and complete '
          'in another future event', () async {
        var action = Action();
        var listenerInvoked = false;
        var listenerCompleted = false;
        action.listen((_) async {
          listenerInvoked = true;
          await Future(() => listenerCompleted = true);
        });

        // No immediate invocation.
        unawaited(action(null));
        expect(listenerInvoked, isFalse);

        // Invoked during next scheduled event in the queue.
        await Future(() => {});
        expect(listenerInvoked, isTrue);
        expect(listenerCompleted, isFalse);

        // Completed in next next scheduled event.
        await Future(() => {});
        expect(listenerCompleted, isTrue);
      });

      test('should complete future after listeners complete', () async {
        var action = Action();
        var asyncListenerCompleted = false;
        action.listen((_) async {
          await Future.delayed(const Duration(milliseconds: 100), () {
            asyncListenerCompleted = true;
          });
        });

        Future<dynamic> future = action();
        expect(asyncListenerCompleted, isFalse);

        await future;
        expect(asyncListenerCompleted, isTrue);
      });

      test('should surface errors in listeners', () {
        var action = Action()..listen((_) => throw UnimplementedError());
        expect(action(0), throwsUnimplementedError);
      });
    });

    group('listen', () {
      test('should stop listening when subscription is canceled', () async {
        var action = Action();
        var listened = false;
        var subscription = action.listen((_) => listened = true);

        await action();
        expect(listened, isTrue);

        listened = false;
        subscription.cancel();
        await action();
        expect(listened, isFalse);
      });

      test('should stop listening when listeners are cleared', () async {
        var action = Action();
        var listened = false;
        action.listen((_) => listened = true);

        await action();
        expect(listened, isTrue);

        listened = false;
        await action.dispose();
        await action();
        expect(listened, isFalse);
      });

      test('should stop listening when actions are disposed', () async {
        var action = Action();
        var listened = false;
        action.listen((_) => listened = true);

        await action();
        expect(listened, isTrue);

        listened = false;
        await action.dispose();
        await action();
        expect(listened, isFalse);
      });
    });

    group('benchmarks', () {
      test('should dispatch actions faster than streams :(', () async {
        const int sampleSize = 1000;
        var stopwatch = Stopwatch();

        var awaitableAction = Action()
          ..listen((_) => {})
          ..listen((_) async {});
        stopwatch.start();
        for (var i = 0; i < sampleSize; i++) {
          await awaitableAction();
        }
        stopwatch.stop();
        var averageActionDispatchTime =
            stopwatch.elapsedMicroseconds / sampleSize / 1000.0;

        stopwatch.reset();

        Completer syncCompleter;
        Completer asyncCompleter;
        var action = Action()
          ..listen((_) => syncCompleter.complete())
          ..listen((_) async {
            asyncCompleter.complete();
          });
        stopwatch.start();
        for (var i = 0; i < sampleSize; i++) {
          syncCompleter = Completer();
          asyncCompleter = Completer();
          await action();
          await Future.wait([syncCompleter.future, asyncCompleter.future]);
        }
        stopwatch.stop();
        var averageStreamDispatchTime =
            stopwatch.elapsedMicroseconds / sampleSize / 1000.0;

        print('awaitable action (ms): $averageActionDispatchTime; '
            'stream-based action (ms): $averageStreamDispatchTime');
      }, skip: true);
    });
  });

  group('Action2', () {
    Action2<String> action;

    setUp(() {
      action = Action2<String>();
    });

    test('should only be equivalent to itself', () {
      Action2 _action = Action2();
      Action2 _action2 = Action2();
      expect(_action == _action, isTrue);
      expect(_action == _action2, isFalse);
    });

    test('should support dispatch with a payload', () async {
      Completer c = Completer();
      action.listen((payload) {
        expect(payload, equals('990 guerrero'));
        c.complete();
      });

      await action('990 guerrero');
      return c.future;
    });

    test('should dispatch by default when called', () async {
      Completer c = Completer();
      action.listen((payload) {
        expect(payload, equals('990 guerrero'));
        c.complete();
      });

      await action('990 guerrero');
      return c.future;
    });

    group('dispatch', () {
      test(
          'should invoke and complete synchronous listeners in future event in '
          'event queue', () async {
        var listenerCompleted = false;
        action.listen((_) {
          listenerCompleted = true;
        });

        // No immediate invocation.
        unawaited(action('payload'));
        expect(listenerCompleted, isFalse);

        // Invoked during the next scheduled event in the queue.
        await Future(() => {});
        expect(listenerCompleted, isTrue);
      });

      test(
          'should invoke asynchronous listeners in future event and complete '
          'in another future event', () async {
        var listenerInvoked = false;
        var listenerCompleted = false;
        action.listen((_) async {
          listenerInvoked = true;
          await Future(() => listenerCompleted = true);
        });

        // No immediate invocation.
        unawaited(action('payload'));
        expect(listenerInvoked, isFalse);

        // Invoked during next scheduled event in the queue.
        await Future(() => {});
        expect(listenerInvoked, isTrue);
        expect(listenerCompleted, isFalse);

        // Completed in next next scheduled event.
        await Future(() => {});
        expect(listenerCompleted, isTrue);
      });

      test('should complete future after listeners complete', () async {
        var asyncListenerCompleted = false;
        action.listen((_) async {
          await Future.delayed(const Duration(milliseconds: 100), () {
            asyncListenerCompleted = true;
          });
        });

        Future<dynamic> future = action('payload');
        expect(asyncListenerCompleted, isFalse);

        await future;
        expect(asyncListenerCompleted, isTrue);
      });

      test('should surface errors in listeners', () {
        var actionWithError = action..listen((_) => throw UnimplementedError());
        expect(actionWithError('payload'), throwsUnimplementedError);
      });
    });

    group('listen', () {
      test('should stop listening when subscription is canceled', () async {
        var listened = false;
        var subscription = action.listen((_) => listened = true);

        await action('payload');
        expect(listened, isTrue);

        listened = false;
        subscription.cancel();
        await action('payload');
        expect(listened, isFalse);
      });

      test('should stop listening when listeners are cleared', () async {
        var listened = false;
        action.listen((_) => listened = true);

        await action('payload');
        expect(listened, isTrue);

        listened = false;
        await action.dispose();
        await action('payload');
        expect(listened, isFalse);
      });

      test('should stop listening when actions are disposed', () async {
        var listened = false;
        action.listen((_) => listened = true);

        await action('payload');
        expect(listened, isTrue);

        listened = false;
        await action.dispose();
        await action('payload');
        expect(listened, isFalse);
      });
    });

    group('Null typed', () {
      Action2<Null> nullAction;

      setUp(() {
        nullAction = Action2<Null>();
      });

      test('should support dispatch with a null payload', () async {
        Completer c = Completer();
        nullAction.listen((payload) {
          expect(payload, isNull);
          c.complete();
        });

        await nullAction(null);
        return c.future;
      });
    });

    group('void typed', () {
      var voidAction = Action2<void>();

      test('should support dispatch with a null payload', () async {
        Completer c = Completer();
        voidAction.listen((_) {
          c.complete();
        });

        await voidAction(null);
        return c.future;
      });
    });

    group('benchmarks', () {
      test('should dispatch actions faster than streams :(', () async {
        const int sampleSize = 1000;
        var stopwatch = Stopwatch();

        var awaitableAction = Action2()
          ..listen((_) => {})
          ..listen((_) async {});
        stopwatch.start();
        for (var i = 0; i < sampleSize; i++) {
          await awaitableAction(null);
        }
        stopwatch.stop();
        var averageActionDispatchTime =
            stopwatch.elapsedMicroseconds / sampleSize / 1000.0;

        stopwatch.reset();

        Completer syncCompleter;
        Completer asyncCompleter;
        var action = Action2()
          ..listen((_) => syncCompleter.complete())
          ..listen((_) async {
            asyncCompleter.complete();
          });
        stopwatch.start();
        for (var i = 0; i < sampleSize; i++) {
          syncCompleter = Completer();
          asyncCompleter = Completer();
          await action(null);
          await Future.wait([syncCompleter.future, asyncCompleter.future]);
        }
        stopwatch.stop();
        var averageStreamDispatchTime =
            stopwatch.elapsedMicroseconds / sampleSize / 1000.0;

        print('awaitable action (ms): $averageActionDispatchTime; '
            'stream-based action (ms): $averageStreamDispatchTime');
      }, skip: true);
    });
  });
}
