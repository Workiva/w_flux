// Copyright 2016 Workiva Inc.
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
library w_flux.test.component_server_test;

import 'dart:async';

import 'package:react/react.dart' as react;
import 'package:test/test.dart';
import 'package:w_flux/w_flux_server.dart';

import 'utils.dart';

void main() {
  group('FluxComponent', () {
    test('should expose an actions getter', () {
      TestDefaultComponent component = TestDefaultComponent();
      TestActions testActions = TestActions();
      component.props = {'actions': testActions};

      expect(component.actions, equals(testActions));
    });

    test('should expose a store getter', () {
      TestDefaultComponent component = TestDefaultComponent();
      TestStore testStore = TestStore();
      component.props = {'store': testStore};

      expect(component.store, equals(testStore));
    });

    test('should subscribe to a single store by default', () async {
      // Setup the component
      TestDefaultComponent component = TestDefaultComponent();
      TestStore store = TestStore();
      component.props = {'store': store};
      component.componentWillMount();

      // Cause store to trigger, wait for it to propagate
      store.trigger();
      await nextTick();
      expect(component.numberOfRedraws, 1);

      // Simulate un-mounting the component
      component.componentWillUnmount();
      await component.didDispose;

      // Component should no longer be listening
      store.trigger();
      await nextTick();

      // Redraw should not have been called again
      expect(component.numberOfRedraws, 1);
    });

    test('should subscribe to any stores returned in redrawOn', () async {
      TestRedrawOnComponent component = TestRedrawOnComponent();
      TestStores stores = TestStores();
      component.props = {'store': stores};
      component.componentWillMount();

      stores.store1.trigger();
      await nextTick();
      expect(component.numberOfRedraws, 1);

      stores.store2.trigger();
      await nextTick();
      expect(component.numberOfRedraws, 2);

      stores.store3.trigger();
      await nextTick();
      expect(component.numberOfRedraws, 2);
    });

    test('should prefer a handler specified in getStoreHandlers over redrawOn',
        () async {
      TestHandlerPrecedence component = TestHandlerPrecedence();
      TestStores stores = TestStores();
      component.props = {'store': stores};
      component.componentWillMount();

      stores.store1.trigger();
      await nextTick();
      expect(component.numberOfRedraws, 0);
      expect(component.numberOfHandlerCalls, 1);

      stores.store2.trigger();
      await nextTick();
      expect(component.numberOfRedraws, 1);
      expect(component.numberOfHandlerCalls, 1);
    });

    test('should not attempt subscription if store is a composite of stores',
        () async {
      TestDefaultComponent component = TestDefaultComponent();
      TestStores stores = TestStores();
      component.props = {'store': stores};
      component.componentWillMount();

      stores.store1.trigger();
      await nextTick();
      expect(component.numberOfRedraws, 0);

      stores.store2.trigger();
      await nextTick();
      expect(component.numberOfRedraws, 0);
    });

    test(
        'should call handlers specified in getStoreHandlers when each store triggers',
        () async {
      // Setup the component
      TestStoreHandlersComponent component = TestStoreHandlersComponent();
      TestStore store = TestStore();
      component.props = {'store': store};
      component.componentWillMount();

      // Cause store to trigger, wait for it to propagate
      store.trigger();
      await nextTick();
      expect(component.numberOfHandlerCalls, 1);

      // Simulate un-mounting the component
      component.componentWillUnmount();
      await component.didDispose;

      // Component should no longer be listening
      store.trigger();
      await nextTick();

      // Handler should not have been called again
      expect(component.numberOfHandlerCalls, 1);
    });

    test('should cancel any subscriptions added with addSubscription',
        () async {
      // Setup a new subscription on a component
      int numberOfCalls = 0;
      StreamController controller = StreamController();
      TestDefaultComponent component = TestDefaultComponent();

      var subscription = controller.stream.listen((_) {
        numberOfCalls += 1;
      });
      component.getManagedDisposer(() async => subscription.cancel());

      // Add something to the stream and expect the handler to have been called
      controller.add('something');
      await nextTick();
      expect(numberOfCalls, 1);

      // Unmount the component, expect the subscription to have been canceled
      component.componentWillUnmount();
      await component.didDispose;
      controller.add('something else');
      await nextTick();
      expect(numberOfCalls, 1);

      await controller.close();
    });
  });
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
  redraw([callback()?]) {
    numberOfRedraws += 1;
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
  redraw([callback()?]) {
    numberOfRedraws += 1;
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
  redraw([callback()?]) {
    numberOfRedraws += 1;
  }
}
