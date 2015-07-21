library w_flux.test.store_test;

import 'dart:async';

import 'package:w_flux/w_flux.dart';
import 'package:rate_limit/rate_limit.dart';
import 'package:test/test.dart';

class ExtendingStore extends Store {
  String name = 'Max Peterson';
}

void main() {
  group('Store', () {
    Store store;

    setUp(() {
      store = new Store();
    });

    test('should inherit from Stream', () {
      expect(store is Stream, isTrue);
    });

    test('should trigger with itself as the payload', () {
      store.listen(expectAsync((payload) {
        expect(payload, equals(store));
      }));
      store.trigger();
    });

    test('should support other stream methods', () {
      // The point of this test is to exercise the `where` method which is made available
      // on a store by extending stream and overriding `listen`
      ExtendingStore _store = new ExtendingStore();
      Stream<Store> filteredStream = _store.where((payload) => payload.name == 'Max Peterson');
      filteredStream.listen(expectAsync((ExtendingStore payload) {
        expect(payload.name, equals('Max Peterson'));
      }));
      _store.trigger();
    });

    test('should support stream transforms', () {

      // ensure that multiple trigger executions emit
      // exactly 2 throttled triggers to external listeners
      // (1 for the initial trigger and 1 as the aggregate of
      // all others that occurred within the throttled duration)
      store = new Store(transformer: new Throttler(const Duration(milliseconds: 30)));
      store.listen(expectAsync((payload) {
        expect(payload, equals(store));
      }, count: 2));

      store.trigger();
      store.trigger();
      store.trigger();
      store.trigger();
      store.trigger();
    });

    test('should trigger in response to an action', () {
      Action _action = new Action();
      store.triggerOnAction(_action);
      store.listen(expectAsync((payload) {
        expect(payload, equals(store));
      }));
      _action();
    });

    test('should execute a given method and then trigger in response to an action', () {
      Action _action = new Action();
      store.triggerOnAction(_action);
      store.listen(expectAsync((payload) {
        expect(payload, equals(store));
      }));
      _action();
    });

    test('should execute a given async method and then trigger in response to an action', () {
      Action _action = new Action();
      bool afterTimer = false;
      asyncCallback(_) async {
        await new Future.delayed(new Duration(milliseconds: 30));
        afterTimer = true;
      }
      store.triggerOnAction(_action, asyncCallback);
      store.listen(expectAsync((payload) {
        expect(payload, equals(store));
        expect(afterTimer, equals(true));
      }));
      _action();
    });

    test('should execute a given method and then trigger in response to an action with payload',
        () {
      Action<num> _action = new Action<num>();
      num counter = 0;
      store.triggerOnAction(_action, (payload) => counter = payload);
      store.listen(expectAsync((payload) {
        expect(payload, equals(store));
        expect(counter, equals(17));
      }));
      _action(17);
    });
  });
}
