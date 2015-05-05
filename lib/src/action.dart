library w_flux.action;

import 'dart:async';


class Action<T> extends Stream<T> {

  Stream<T> _stream;
  StreamController<T> _streamController;

  Action() {
    _streamController = new StreamController<T>();
    _stream = _streamController.stream.asBroadcastStream();
  }

  void dispatch([T payload]) {
    _streamController.add(payload);
  }

  StreamSubscription<T> listen(void onData(T event), { Function onError, void onDone(), bool cancelOnError}) {
    return _stream.listen(onData, onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

}
