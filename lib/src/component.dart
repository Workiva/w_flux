library w_flux.component;

import 'dart:async';

import 'package:react/react.dart' as react;

import './store.dart';

abstract class FluxComponent<ActionsT, StoresT> extends react.Component {
  ActionsT get actions => this.props['actions'];
  StoresT get stores => this.props['stores'];

  List<StreamSubscription> _subscriptions = [];

  componentWillMount() {
    Map<Store, Function> handlers =
        new Map.fromIterable(redrawOn(), value: (_) => (_) => redraw())
      ..addAll(getStoreHandlers());
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
    if (stores is Store) {
      return [stores];
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
