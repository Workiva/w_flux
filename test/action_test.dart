library w_flux.test.action_test;

import 'dart:async';

import 'package:w_flux/w_flux.dart';
import 'package:test/test.dart';

void main() {
  group('Action', () {
    Action<String> action;

    setUp(() {
      action = new Action<String>();
    });

    test('should support dispatch without a payload', () {
      Action _action = new Action();

      expectAsync(_action.listen)((payload) {
        expect(payload, equals(null));
      });

      _action();
    });

    test('should support dispatch with a payload', () {
      expectAsync(action.listen)((payload) {
        expect(payload, equals('990 guerrero'));
      });

      action('990 guerrero');
    });

    test('should dispatch by default when called', () {
      expectAsync(action.listen)((payload) {
        expect(payload, equals('990 guerrero'));
      });

      action('990 guerrero');
    });

    group('dispatch', () {
      test('should invoke and complete synchronous listeners in future event in '
          'event queue', () async {
        var action = new Action();
        var listenerCompleted = false;
        action.listen((_) {
          listenerCompleted = true;
        });

        // No immediate invocation.
        action();
        expect(listenerCompleted, isFalse);

        // Invoked during the next scheduled event in the queue.
        await new Future(() => {});
        expect(listenerCompleted, isTrue);
      });

      test('should invoke asynchronous listeners in future event and complete '
          'in another future event', () async {
        var action = new Action();
        var listenerInvoked = false;
        var listenerCompleted = false;
        action.listen((_) async {
          listenerInvoked = true;
          await new Future(() => listenerCompleted = true);
        });

        // No immediate invocation.
        action();
        expect(listenerInvoked, isFalse);

        // Invoked during next scheduled event in the queue.
        await new Future(() => {});
        expect(listenerInvoked, isTrue);
        expect(listenerCompleted, isFalse);

        // Completed in next next scheduled event.
        await new Future(() => {});
        expect(listenerCompleted, isTrue);
      });

      test('should complete future after listeners complete', () async {
        var action = new Action();
        var asyncListenerCompleted = false;
        action.listen((_) async {
          await new Future.delayed(new Duration(milliseconds: 100), () {
            asyncListenerCompleted = true;
          });
        });

        var future = action();
        expect(asyncListenerCompleted, isFalse);

        await future;
        expect(asyncListenerCompleted, isTrue);
      });

      test('should surface errors in listeners', () {
        var action = new Action();
        action.listen((_) => throw new UnimplementedError());
        expect(action(0), throwsUnimplementedError);
      });
    });

    group('listen', () {
      test('should stop listening when subscription is canceled', () async {
        var action = new Action();
        var listened = false;
        var subscription = action.listen((_) => listened = true);

        await action();
        expect(listened, isTrue);

        listened = false;
        subscription.cancel();
        await action();
        expect(listened, isFalse);
      });
    });

    group('benchmarks', () {
      test('should dispatch actions faster than streams :(', () async {
        const int sampleSize = 1000;
        var stopwatch = new Stopwatch();

        var awaitableAction = new Action();
        awaitableAction.listen((_) => {});
        awaitableAction.listen((_) async {});
        stopwatch.start();
        for (var i = 0; i < sampleSize; i++) {
          await awaitableAction();
        }
        stopwatch.stop();
        var averageActionDispatchTime = stopwatch.elapsedMicroseconds / sampleSize / 1000.0;

        stopwatch.reset();

        Completer syncCompleter;
        Completer asyncCompleter;
        var action = new Action();
        action.listen((_) => syncCompleter.complete());
        action.listen((_) async {
          asyncCompleter.complete();
        });
        stopwatch.start();
        for (var i = 0; i < sampleSize; i++) {
          syncCompleter = new Completer();
          asyncCompleter = new Completer();
          action();
          await Future.wait([syncCompleter.future, asyncCompleter.future]);
        }
        stopwatch.stop();
        var averageStreamDispatchTime = stopwatch.elapsedMicroseconds / sampleSize / 1000.0;

        print('awaitable action (ms): $averageActionDispatchTime; '
            'stream-based action (ms): $averageStreamDispatchTime');
      }, skip: true);
    });
  });
}
