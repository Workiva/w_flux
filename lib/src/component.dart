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

library w_flux.component;

import 'dart:async';

import 'package:react/react.dart' as react;

import './store.dart';

abstract class FluxComponent<ActionsT, StoresT> extends react.Component {
  ActionsT get actions => this.props['actions'];
  StoresT get store => this.props['store'];

  List<StreamSubscription> _subscriptions = [];

  componentWillMount() {
    Map<Store, Function> handlers = new Map.fromIterable(redrawOn(),
        value: (_) => (_) => redraw())..addAll(getStoreHandlers());
    handlers.forEach((store, handler) {
      StreamSubscription subscription = store.listen(handler);
      _subscriptions.add(subscription);
    });
  }

  componentWillUnmount() {
    _subscriptions.forEach((StreamSubscription subscription) {
      if (subscription != null) {
        subscription.cancel();
      }
    });
  }

  List<Store> redrawOn() {
    if (store is Store) {
      return [store];
    } else {
      return [];
    }
  }

  Map<Store, Function> getStoreHandlers() {
    return {};
  }

  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }
}
