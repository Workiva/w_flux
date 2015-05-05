library w_flux.test.store_test;

import 'dart:async';

import 'package:w_flux/w_flux.dart';
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

      // On first trigger name is Evan Weible, which doesn't pass through the filter
      _store.trigger();
      return completer.future;
    });

  });
}