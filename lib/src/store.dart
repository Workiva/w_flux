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

  StreamSubscription<Store> listen(void onData(Store event), { Function onError, void onDone(), bool cancelOnError}) {
    return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

}
