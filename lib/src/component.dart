library w_flux.component;

import 'dart:async';

import 'package:react/react.dart' as react;

import './store.dart';


abstract class FluxComponent<ActionsT, StoresT> extends react.Component {

  ActionsT get actions => this.props['actions'];
  StoresT get stores => this.props['stores'];

  List<StreamSubscription> _subscriptions = [];

  componentDidMount(rootNode) {
    getStoreHandlers().forEach((store, handler) {
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

  Map<Store, Function> getStoreHandlers() {
    return {};
  }

  void addSubscription(StreamSubscription subscription) {
    _subscriptions.add(subscription);
  }
}
