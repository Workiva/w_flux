library w_flux.test.store_test;

import 'dart:async';

import 'package:w_flux/w_flux.dart';
import 'package:test/test.dart';


class ExtendingStore extends Store {
  String name = 'Evan Weible';
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

    test('should support other stream methods', () {

      ExtendingStore _store = new ExtendingStore();

      Stream<Store> filteredStream = _store.where((value) => value == 'Max Peterson');
      expectAsync(filteredStream.listen)((ExtendingStore payload) {
        expect(payload.name, equals('Max Peterson'));
      });

      // On first trigger name is Evan Weible, which doesn't pass through the filter
      _store.trigger();
      _store.name = 'Max Peterson';
      _store.trigger();
    });

  });
}