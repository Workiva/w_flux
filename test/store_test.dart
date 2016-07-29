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

@TestOn('vm')
library w_flux.test.store_test;

import 'dart:async';

import 'package:w_flux/src/action.dart';
import 'package:w_flux/src/store.dart';
import 'package:rate_limit/rate_limit.dart';
import 'package:test/test.dart';

import 'utils.dart';

void main() {
  group('Store', () {
    Store store;

    setUp(() {
      store = new Store();
    });

    test('should trigger with itself as the payload', () async {
      Completer c = new Completer();
      store.listen((Store payload) {
        expect(payload, equals(store));
        c.complete();
      });

      store.trigger();
      return c.future;
    });

    test('should support stream transforms', () async {
      // ensure that multiple trigger executions emit
      // exactly 2 throttled triggers to external listeners
      // (1 for the initial trigger and 1 as the aggregate of
      // all others that occurred within the throttled duration)
      int count = 0;
      store = new Store.withTransformer(
          new Throttler(const Duration(milliseconds: 30)));
      store.listen((Store payload) {
        count += 1;
      });

      store.trigger();
      store.trigger();
      store.trigger();
      store.trigger();
      store.trigger();
      await nextTick(60);
      expect(count, equals(2));
    });

    test('should trigger in response to an action', () {
      Action _action = new Action();
      store.triggerOnAction(_action);
      store.listen((Store payload) => expectAsync((payload) {
            expect(payload, equals(store));
          }));
      _action();
    });

    test(
        'should execute a given method and then trigger in response to an action',
        () {
      Action _action = new Action();
      bool methodCalled = false;
      syncCallback(_) {
        methodCalled = true;
      }

      store.triggerOnAction(_action, syncCallback);
      store.listen((Store payload) => expectAsync((payload) {
            expect(payload, equals(store));
            expect(methodCalled, equals(true));
          }));
      _action();
    });

    test(
        'should execute a given async method and then trigger in response to an action',
        () {
      Action _action = new Action();
      bool afterTimer = false;
      asyncCallback(_) async {
        await new Future.delayed(new Duration(milliseconds: 30));
        afterTimer = true;
      }

      store.triggerOnAction(_action, asyncCallback);
      store.listen((Store payload) => expectAsync((payload) {
            expect(payload, equals(store));
            expect(afterTimer, equals(true));
          }));
      _action();
    });

    test(
        'should execute a given method and then trigger in response to an action with payload',
        () {
      Action<num> _action = new Action<num>();
      num counter = 0;
      store.triggerOnAction(_action, (payload) => counter = payload);
      store.listen((Store payload) => expectAsync((payload) {
            expect(payload, equals(store));
            expect(counter, equals(17));
          }));
      _action(17);
    });
  });
}
