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
library w_flux.test.store_test;

import 'dart:async';
import 'package:test/test.dart';
import 'package:w_flux/src/action.dart';
import 'package:w_flux/src/store.dart';

/// A mock transformer for tests that only ever outputs the first 2 times
class MockTransformer implements StreamTransformer<Store, Store> {
  MockTransformer();

  /// added NSM to handle the requirement to override cast() under Dart 2
  @override
  noSuchMethod(Invocation invocation) {
    // do nothing on purpose to handle missing methods
  }

  @override
  Stream<Store> bind(Stream<Store> stream) => _buildTransformer().bind(stream);

  static StreamTransformer<Store, Store> _buildTransformer() {
    int count = 0;
    return StreamTransformer<Store, Store>.fromHandlers(
        handleData: (Store data, EventSink<Store> sink) {
      if (count < 2) {
        count++;
        sink.add(data);
      }
    });
  }
}

void main() {
  group('Store', () {
    Store store;

    setUp(() {
      store = Store();
    });

    tearDown(() {
      store.dispose();
    });

    test('should extend Stream', () {
      expect(store, isA<Stream>());
    });

    group('isBroadcast', () {
      test('should be true when the default constructor is used', () {
        store = Store();
        expect(store.isBroadcast, isTrue);
      });

      test('should be true when the withTransformer constructor is used', () {
        store = Store.withTransformer(MockTransformer());
        expect(store.isBroadcast, isTrue);
      });
    });

    test('should trigger with itself as the payload', () {
      store.listen(expectAsync1((payload) {
        expect(payload, store);
      }) as StoreHandler);

      store.trigger();
    });

    test('should support stream transforms', () async {
      // ensure that multiple trigger executions emit
      // exactly 2 throttled triggers to external listeners
      store = Store.withTransformer(MockTransformer());
      store.listen(expectAsync1((payload) {}, count: 2) as StoreHandler);

      store.trigger();
      store.trigger();
      store.trigger();
      store.trigger();
    });

    test('should trigger in response to an action', () async {
      Action _action = Action();
      store.triggerOnActionV2(_action);

      _action();
      Store payload = await store.first;

      expect(payload, store);
    });

    test(
        'should execute a given method and then trigger in response to an action',
        () {
      Action _action = Action();
      bool methodCalled = false;
      syncCallback(_) {
        methodCalled = true;
      }

      store.triggerOnActionV2(_action, syncCallback);
      store.listen(expectAsync1((payload) {
        expect(payload, store);
        expect(methodCalled, isTrue);
      }) as StoreHandler);
      _action();
    });

    test(
        'should execute a given async method and then trigger in response to an action',
        () {
      Action _action = Action();
      bool afterTimer = false;
      asyncCallback(_) async {
        await Future.delayed(Duration(milliseconds: 30));
        afterTimer = true;
      }

      store.triggerOnActionV2(_action, asyncCallback);
      store.listen(expectAsync1((payload) {
        expect(payload, store);
        expect(afterTimer, isTrue);
      }) as StoreHandler);
      _action();
    });

    test(
        'should execute a given method and then trigger in response to an action with payload',
        () {
      Action<num> _action = Action<num>();
      num counter = 0;
      store.triggerOnActionV2(_action, (payload) => counter = payload);
      store.listen(expectAsync1((payload) {
        expect(payload, store);
        expect(counter, 17);
      }) as StoreHandler);
      _action(17);
    });

    test('cleans up its StreamController on dispose', () {
      bool afterDispose = false;

      store.listen(expectAsync1((payload) async {
        // Safety check to avoid infinite trigger loop
        expect(afterDispose, isFalse);

        // Dispose after first trigger
        await store.dispose();
        afterDispose = true;

        // This should no longer fire after dispose
        store.trigger();
      }) as StoreHandler);

      store.trigger();
    });

    test('cleans up its ActionSubscriptions on dispose', () {
      bool afterDispose = false;

      Action _action = Action();
      store.triggerOnActionV2(_action);
      store.listen(expectAsync1((payload) async {
        // Safety check to avoid infinite trigger loop
        expect(afterDispose, isFalse);

        // Dispose after first trigger
        await store.dispose();
        afterDispose = true;

        // This should no longer fire after dispose
        _action();
      }) as StoreHandler);

      _action();
    });

    test('does not allow adding action subscriptions after dispose', () async {
      await store.dispose();
      expect(() => store.triggerOnActionV2(Action()), throwsStateError);
    });

    test('does not allow listening after dispose', () async {
      await store.dispose();
      expect(() => store.listen((_) {}), throwsStateError);
    });
  });
}
