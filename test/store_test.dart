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
      expectAsync(store.listen)((payload) {
        expect(payload, equals(store));
      });

      store.trigger();
    });

    test('should support other stream methods', () async {
      ExtendingStore _store = new ExtendingStore();
      Completer completer = new Completer();

      // The point of this test is to exercise the `where` method which is made available
      // on a store by extending stream and overriding `listen`
      Stream<Store> filteredStream = _store.where((payload) => payload.name == 'Max Peterson');
      filteredStream.listen((ExtendingStore payload) {
        expect(payload.name, equals('Max Peterson'));
        completer.complete();
      });

      _store.trigger();
      return completer.future;
    });

    test('should support stream transforms', () {

      // ensure that multiple trigger executions only emits 1 throttled trigger to external listeners
      store = new Store(transformer: new Throttler(const Duration(milliseconds: 30)));
      num counter = 0;
      expectAsync(store.listen)((payload) {
        counter++;
        expect(payload, equals(store));
        expect(counter, equals(1));
      });

      store.trigger();
      store.trigger();
      store.trigger();
      store.trigger();
      store.trigger();
    });

    test('should trigger in response to an action', () {
      Action _action = new Action();
      store.triggerOnAction(_action);
      expectAsync(store.listen)((payload) {
        expect(payload, equals(store));
      });
      _action.dispatch();
    });

    test('should execute a given method and then trigger in response to an action', () {
      Action _action = new Action();
      num counter = 0;
      store.triggerOnAction(_action, (_) => counter++);
      expectAsync(store.listen)((payload) {
        expect(payload, equals(store));
        expect(counter, equals(1));
      });
      _action.dispatch();
    });

    test('should execute a given method and then trigger in response to an action with payload', () {
      Action<num> _action = new Action<num>();
      num counter = 0;
      store.triggerOnAction(_action, (payload) => counter = payload);
      expectAsync(store.listen)((payload) {
        expect(payload, equals(store));
        expect(counter, equals(17));
      });
      _action.dispatch(17);
    });
  });
}