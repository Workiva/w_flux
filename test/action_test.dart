// @dart=2.7
// ^ Do not remove until migrated to null safety. More info at https://wiki.atl.workiva.net/pages/viewpage.action?pageId=189370832
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
      Action<String> _action = Action<String>();

      _action.listen((String payload) {
        expect(payload, equals(null));
        c.complete();
      });

      _action();
      return c.future;
    });

    test('should support dispatch with a payload', () async {
      Completer c = Completer();
      action.listen((String payload) {
        expect(payload, equals('990 guerrero'));
        c.complete();
      });

      action('990 guerrero');
      return c.future;
    });

    test('should dispatch by default when called', () async {
      Completer c = Completer();
      action.listen((String payload) {
        expect(payload, equals('990 guerrero'));
        c.complete();
      });

      action('990 guerrero');
      return c.future;
    });

    group('dispatch', () {
      test(
          'should invoke and complete synchronous listeners in future event in '
          'event queue', () async {
        var action = Action();
        var listenerCompleted = false;
        action.listen((_) {
          listenerCompleted = true;
        });

        // No immediate invocation.
        action();
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
        action();
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
          await Future.delayed(Duration(milliseconds: 100), () {
            asyncListenerCompleted = true;
          });
        });

        var future = action();
        expect(asyncListenerCompleted, isFalse);

        await future;
        expect(asyncListenerCompleted, isTrue);
      });

      test('should surface errors in listeners', () {
        var action = Action();
        action.listen((_) => throw UnimplementedError());
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

        var awaitableAction = Action();
        awaitableAction.listen((_) => {});
        awaitableAction.listen((_) async {});
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
        var action = Action();
        action.listen((_) => syncCompleter.complete());
        action.listen((_) async {
          asyncCompleter.complete();
        });
        stopwatch.start();
        for (var i = 0; i < sampleSize; i++) {
          syncCompleter = Completer();
          asyncCompleter = Completer();
          action();
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
