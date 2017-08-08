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
library w_flux.test.component_test;

import 'dart:async';
import 'dart:html' show window;

import 'package:over_react/over_react.dart' show cloneElement;
import 'package:react/react.dart' as react;
import 'package:react/react_client.dart';
import 'package:react/react_test_utils.dart' as react_test_utils;
import 'package:test/test.dart';
import 'package:w_flux/w_flux.dart';

void main() {
  setClientConfiguration();

  group('FluxComponent', () {
    test('should expose an actions getter', () {
      TestDefaultComponent component = new TestDefaultComponent();
      TestActions testActions = new TestActions();
      component.props = {'actions': testActions};

      expect(component.actions, equals(testActions));
    });

    test('should expose a store getter', () {
      TestDefaultComponent component = new TestDefaultComponent();
      TestStore testStore = new TestStore();
      component.props = {'store': testStore};

      expect(component.store, equals(testStore));
    });

    test('should subscribe to a single store by default', () async {
      // Setup the component
      TestDefaultComponent component = new TestDefaultComponent();
      TestStore store = new TestStore();
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
      TestRedrawOnComponent component = new TestRedrawOnComponent();
      TestStores stores = new TestStores();
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
      TestHandlerPrecedence component = new TestHandlerPrecedence();
      TestStores stores = new TestStores();
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
      TestDefaultComponent component = new TestDefaultComponent();
      TestStores stores = new TestStores();
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
      TestStoreHandlersComponent component = new TestStoreHandlersComponent();
      TestStore store = new TestStore();
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

    test('should cancel any subscriptions added with addSubscription',
        () async {
      // Setup a new subscription on a component
      int numberOfCalls = 0;
      StreamController controller = new StreamController();
      TestDefaultComponent component = new TestDefaultComponent();
      var subscription = controller.stream.listen((_) {
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
      TestDefaultComponent component = new TestDefaultComponent();
      component.componentWillUnmount();
      await component.didDispose;
      component.redraw();
      await animationFrames(2);
      expect(component.numberOfRedraws, equals(0));
    });

    test(
        'only redraws once in response to a store trigger'
        ' combined with an ancestor rerendering', () async {
      var store = new Store();

      TestNestedComponent nested0;
      TestNestedComponent nested1;
      TestNestedComponent nested2;

      react_test_utils.renderIntoDocument(
        TestNested(
          {
            'store': store,
            'ref': (ref) {
              nested0 = ref;
            },
          },
          TestNested(
            {
              'store': store,
              'ref': (ref) {
                nested1 = ref;
              },
            },
            TestNested({
              'store': store,
              'ref': (ref) {
                nested2 = ref;
              },
            }),
          ),
        ),
      );
      expect(nested0.renderCount, 1, reason: 'setup check: initial render');
      expect(nested1.renderCount, 1, reason: 'setup check: initial render');
      expect(nested2.renderCount, 1, reason: 'setup check: initial render');

      nested0.redraw();
      await animationFrames(2);

      expect(nested0.renderCount, 2,
          reason: 'setup check: components should rerender their children');
      expect(nested1.renderCount, 2,
          reason: 'setup check: components should rerender their children');
      expect(nested2.renderCount, 2,
          reason: 'setup check: components should rerender their children');

      store.trigger();
      // Two async gaps just to be safe, since we're
      // asserting that additional redraws don't happen.
      await animationFrames(2);
      await animationFrames(2);

      expect(nested0.renderCount, 3,
          reason: 'should have rerendered once in response to'
              ' the store triggering');
      expect(nested1.renderCount, 3,
          reason: 'should have rerendered once in response to'
              ' the store triggering');
      expect(nested2.renderCount, 3,
          reason: 'should have rerendered once in response to'
              ' the store triggering');
    });
  });
}

Future animationFrames([int numFrames = 1]) async {
  for (int i = 0; i < numFrames; i++) {
    await window.animationFrame;
  }
}

class TestActions {}

class TestStore extends Store {}

class TestStores {
  TestStore store1 = new TestStore();
  TestStore store2 = new TestStore();
  TestStore store3 = new TestStore();
}

class TestDefaultComponent extends FluxComponent {
  int numberOfRedraws = 0;

  render() => react.div({});

  void setState(_, [callback()]) {
    numberOfRedraws++;
    if (callback != null) callback();
  }
}

class TestStoreHandlersComponent extends FluxComponent<TestActions, TestStore> {
  int numberOfHandlerCalls = 0;

  render() => react.div({});

  getStoreHandlers() => {store: increment};

  increment(Store _) {
    numberOfHandlerCalls += 1;
  }
}

class TestRedrawOnComponent extends FluxComponent<TestActions, TestStores> {
  int numberOfRedraws = 0;

  render() => react.div({});

  redrawOn() => [store.store1, store.store2];

  void setState(_, [callback()]) {
    numberOfRedraws++;
    if (callback != null) callback();
  }
}

class TestHandlerPrecedence extends FluxComponent<TestActions, TestStores> {
  int numberOfRedraws = 0;
  int numberOfHandlerCalls = 0;

  render() => react.div({});

  redrawOn() => [store.store1, store.store2];

  getStoreHandlers() => {store.store1: increment};

  increment(Store _) {
    numberOfHandlerCalls += 1;
  }

  void setState(_, [callback()]) {
    numberOfRedraws++;
    if (callback != null) callback();
  }
}

final TestNested = react.registerComponent(() => new TestNestedComponent());

class TestNestedComponent extends FluxComponent {
  int renderCount = 0;

  @override
  render() {
    renderCount++;

    var keyCounter = 0;
    var newChildren = props['children'].map((child) {
      // The keys are consistent across rerenders, so they aren't remounted,
      // but cloning the element is necessary for react to consider it changed,
      // since it returns new ReactElement instances.
      return cloneElement(child, {'key': keyCounter++});
    }).toList();

    return react.div({}, newChildren);
  }
}
