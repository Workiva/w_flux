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

library w_flux.store;

import 'dart:async';

import 'package:w_flux/src/action.dart';

class Store {
  StreamController<Store> _streamController;
  Stream<Store> _stream;

  Store({StreamTransformer transformer}) {
    _streamController = new StreamController<Store>();

    // apply a transform to the stream if supplied
    if (transformer != null) {
      _stream =
          _streamController.stream.transform(transformer).asBroadcastStream();
    } else {
      _stream = _streamController.stream.asBroadcastStream();
    }
  }

  void trigger() {
    _streamController.add(this);
  }

  triggerOnAction(Action action, [void onAction(payload)]) {
    if (onAction != null) {
      action.listen((payload) async {
        await onAction(payload);
        trigger();
      });
    } else {
      action.listen((_) {
        trigger();
      });
    }
  }

  StreamSubscription<Store> listen(void onData(Store event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }
}
