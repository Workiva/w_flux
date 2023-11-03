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

library w_flux.action;

import 'dart:async';

import 'package:w_common/disposable.dart';

import 'package:w_flux/src/constants.dart' show v3Deprecation;

/// Like [ActionV2], but payloads cannot be made non-nullable since the argument
/// to [call] is optional.
@Deprecated('Use ActionV2 instead, which supports non-nullable payloads.')
class Action<T> extends ActionV2<T> {
  @override
  String get disposableTypeName => 'Action';

  @override
  Future call([T payload]) => super.call(payload);
}

/// A command that can be dispatched and listened to.
///
/// An [ActionV2] manages a collection of listeners and the manner of
/// their invocation. It *does not* rely on [Stream] for managing listeners. By
/// managing its own listeners, an [ActionV2] can track a [Future] that completes
/// when all registered listeners have completed. This allows consumers to use
/// `await` to wait for an action to finish processing.
///
///     var asyncListenerCompleted = false;
///     action.listen((_) async {
///       await new Future.delayed(new Duration(milliseconds: 100), () {
///         asyncListenerCompleted = true;
///       });
///     });
///
///     var future = action();
///     print(asyncListenerCompleted); // => 'false'
///
///     await future;
///     print(asyncListenerCompleted). // => 'true'
///
/// Providing a [Future] for listener completion makes actions far easier to use
/// when a consumer needs to check state changes immediately after invoking an
/// action.
///
class ActionV2<T> extends Object with Disposable implements Function {
  @override
  String get disposableTypeName => 'ActionV2';

  List<_ActionListener<T>> _listeners = [];

  /// Dispatch this [ActionV2] to all listeners. The payload will be passed to
  /// each listener's callback.
  Future call(T payload) {
    // Invoke all listeners in a microtask to enable waiting on futures. The
    // microtask queue is emptied before the event loop continues. This ensures
    // synchronous listeners are invoked in the current tick of the event loop
    // without being scheduled at the back of the event queue. A Dart [Stream]
    // behaves in a similar fashion.
    //
    // Performance benchmarks over 10,000 samples show no performance
    // degradation when dispatching actions using this action implementation vs
    // a [Stream]-based action implementation. At smaller sample sizes this
    // implementation slows down in comparison, yielding average times of 0.1 ms
    // for stream-based actions vs. 0.14 ms for this action implementation.
    Future callListenerInMicrotask(_ActionListener<T> l) =>
        Future.microtask(() => l(payload));
    return Future.wait(_listeners.map(callListenerInMicrotask));
  }

  /// Cancel all subscriptions that exist on this [ActionV2] as a result of
  /// [listen] being called. Useful when tearing down a flux cycle in some
  /// module or unit test.
  @Deprecated('Use (and await) dispose() instead. $v3Deprecation')
  void clearListeners() {
    _listeners.clear();
  }

  /// Supply a callback that will be called any time this [ActionV2] is
  /// dispatched. A payload of type [T] will be passed to the callback if
  /// supplied at dispatch time, otherwise null will be passed. Returns an
  /// [ActionSubscription] which provides means to cancel the subscription.
  ActionSubscription listen(dynamic Function(T event) onData) {
    _listeners.add(onData);
    return ActionSubscription(() => _listeners.remove(onData));
  }

  @override
  Future<Null> onDispose() async {
    _listeners.clear();
  }

  /// Actions are only deemed equivalent if they are the exact same Object
  bool operator ==(Object other) {
    return identical(this, other);
  }
}

typedef _ActionListener<T> = dynamic Function(T event);

/// A subscription used to cancel registered listeners to an [ActionV2].
class ActionSubscription {
  Function _onCancel;

  ActionSubscription(this._onCancel);

  /// Cancel this subscription to an [ActionV2]
  void cancel() {
    if (_onCancel != null) {
      _onCancel();
      _onCancel = null;
    }
  }
}
