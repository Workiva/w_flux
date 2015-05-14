library w_flux.store;

import 'dart:async';


class Store extends Stream<Store> {

  StreamController<Store> _streamController;
  Stream<Store> _stream;

  Store() {
    _streamController = new StreamController<Store>();
    _stream = _streamController.stream.asBroadcastStream();
  }

  void trigger() {
    _streamController.add(this);
  }

  triggerOnAction(Stream action, [void onAction(T payload)]) {
    if (onAction != null) {
      action.listen((payload) {
        onAction(payload);
        trigger();
      });
    } else {
      action.listen((_) {
        trigger();
      });
    }
  }

  StreamSubscription<Store> listen(void onData(Store event), { Function onError, void onDone(), bool cancelOnError}) {
    return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

}
