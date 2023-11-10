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

// ignore_for_file: always_declare_return_types, type_annotate_public_apis

@TestOn('browser')
library w_flux.test.component_test;

import 'dart:async';
import 'dart:html' show window;

import 'package:react/react.dart' as react;
import 'package:test/test.dart';
import 'package:w_flux/w_flux.dart';

void main() {
  group('FluxComponent', () {
    test('should expose an actions getter', () {
      final component = TestDefaultComponent();
      final testActions = TestActions();
      component.props = {'actions': testActions};

      expect(component.actions, equals(testActions));
    });

    test('should expose a store getter', () {
      final component = TestDefaultComponent();
      final testStore = TestStore();
      component.props = {'store': testStore};

      expect(component.store, equals(testStore));
    });

    test('should subscribe to a single store by default', () async {
      // Setup the component
      final component = TestDefaultComponent();
      final store = TestStore();
      component.props = {'store': store};
      component.componentWillMount();

      // Cause store to trigger, wait for it to propagate
      store.trigger();
      await animationFrames(2);
      expect(component.numberOfRedraws, 1);

      // Simulate un-mounting the component
      component.componentWillUnmount();
      await component.didDispose;

      // Component should no longer be listening
      store.trigger();
      await animationFrames(2);

      // Redraw should not have been called again
      expect(component.numberOfRedraws, 1);
    });

    test('should subscribe to any stores returned in redrawOn', () async {
      final component = TestRedrawOnComponent();
      final stores = TestStores();
      component.props = {'store': stores};
      component.componentWillMount();

      stores.store1.trigger();
      await animationFrames(2);
      expect(component.numberOfRedraws, 1);

      stores.store2.trigger();
      await animationFrames(2);
      expect(component.numberOfRedraws, 2);

      stores.store3.trigger();
      await animationFrames(2);
      expect(component.numberOfRedraws, 2);
    });

    test('should prefer a handler specified in getStoreHandlers over redrawOn',
        () async {
      final component = TestHandlerPrecedence();
      final stores = TestStores();
      component.props = {'store': stores};
      component.componentWillMount();

      stores.store1.trigger();
      await animationFrames(2);
      expect(component.numberOfRedraws, 0);
      expect(component.numberOfHandlerCalls, 1);

      stores.store2.trigger();
      await animationFrames(2);
      expect(component.numberOfRedraws, 1);
      expect(component.numberOfHandlerCalls, 1);
    });

    test('should not attempt subscription if store is a composite of stores',
        () async {
      final component = TestDefaultComponent();
      final stores = TestStores();
      component.props = {'store': stores};
      component.componentWillMount();

      stores.store1.trigger();
      await animationFrames(2);
      expect(component.numberOfRedraws, 0);

      stores.store2.trigger();
      await animationFrames(2);
      expect(component.numberOfRedraws, 0);
    });

    test(
        'should call handlers specified in getStoreHandlers when each store triggers',
        () async {
      // Setup the component
      final component = TestStoreHandlersComponent();
      final store = TestStore();
      component.props = {'store': store};
      component.componentWillMount();

      // Cause store to trigger, wait for it to propagate
      store.trigger();
      await animationFrames(2);
      expect(component.numberOfHandlerCalls, 1);

      // Simulate un-mounting the component
      component.componentWillUnmount();
      await component.didDispose;

      // Component should no longer be listening
      store.trigger();
      await animationFrames(2);

      // Handler should not have been called again
      expect(component.numberOfHandlerCalls, 1);
    });

    test('should call lifecycle methods related to store handlers', () async {
      final component = TestHandlerLifecycle();
      final store = TestStore();
      component.props = {'store': store};
      component.componentWillMount();

      expect(component.lifecycleCalls, [
        ['listenToStoreForRedraw', store],
      ]);
      component.lifecycleCalls.clear();

      // Cause store to trigger, wait for it to propagate
      store.trigger();
      await animationFrames(2);

      expect(component.lifecycleCalls, [
        ['handleRedrawOn', store],
      ]);
    });

    test('should cancel any subscriptions added with addSubscription',
        () async {
      // Setup a new subscription on a component
      var numberOfCalls = 0;
      final controller = StreamController();
      final component = TestDefaultComponent();
      final subscription = controller.stream.listen((_) {
        numberOfCalls += 1;
      });
      component.getManagedDisposer(() async => subscription.cancel());

      // Add something to the stream and expect the handler to have been called
      controller.add('something');
      await animationFrames(2);
      expect(numberOfCalls, 1);

      // Unmount the component, expect the subscription to have been canceled
      component.componentWillUnmount();
      await component.didDispose;
      controller.add('something else');
      await animationFrames(2);
      expect(numberOfCalls, 1);

      await controller.close();
    });

    test('should not redraw after being unmounted', () async {
      final component = TestDefaultComponent();
      component.componentWillUnmount();
      await component.didDispose;
      component.redraw();
      await animationFrames(2);
      expect(component.numberOfRedraws, equals(0));
    });
  });
}

Future animationFrames([int numFrames = 1]) async {
  for (var i = 0; i < numFrames; i++) {
    await window.animationFrame;
  }
}

class TestActions {}

class TestStore extends Store {}

class TestStores {
  TestStore store1 = TestStore();
  TestStore store2 = TestStore();
  TestStore store3 = TestStore();
}

class TestDefaultComponent extends FluxComponent {
  int numberOfRedraws = 0;

  @override
  render() => react.div({});

  @override
  void setState(_, [Function()? callback]) {
    numberOfRedraws++;
    if (callback != null) callback();
  }
}

class TestStoreHandlersComponent extends FluxComponent<TestActions, TestStore> {
  int numberOfHandlerCalls = 0;

  @override
  render() => react.div({});

  @override
  getStoreHandlers() => {store: increment};

  increment(Store _) {
    numberOfHandlerCalls += 1;
  }
}

class TestRedrawOnComponent extends FluxComponent<TestActions, TestStores> {
  int numberOfRedraws = 0;

  @override
  render() => react.div({});

  @override
  redrawOn() => [store.store1, store.store2];

  @override
  void setState(_, [Function()? callback]) {
    numberOfRedraws++;
    if (callback != null) callback();
  }
}

class TestHandlerPrecedence extends FluxComponent<TestActions, TestStores> {
  int numberOfRedraws = 0;
  int numberOfHandlerCalls = 0;

  @override
  render() => react.div({});

  @override
  redrawOn() => [store.store1, store.store2];

  @override
  getStoreHandlers() => {store.store1: increment};

  increment(Store _) {
    numberOfHandlerCalls += 1;
  }

  @override
  void setState(_, [Function()? callback]) {
    numberOfRedraws++;
    if (callback != null) callback();
  }
}

class TestHandlerLifecycle extends FluxComponent<TestActions, TestStore> {
  int numberOfRedraws = 0;
  List<List<dynamic>> lifecycleCalls = [];

  @override
  render() => react.div({});

  @override
  void setState(_, [Function()? callback]) {
    numberOfRedraws++;
    if (callback != null) callback();
  }

  @override
  void handleRedrawOn(Store store) {
    lifecycleCalls.add(['handleRedrawOn', store]);
    super.handleRedrawOn(store);
  }

  @override
  void listenToStoreForRedraw(Store store) {
    lifecycleCalls.add(['listenToStoreForRedraw', store]);
    super.listenToStoreForRedraw(store);
  }
}
