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

import 'package:meta/meta.dart';
import 'package:w_common/disposable.dart' show Disposable;
import 'package:w_flux/src/action.dart';

typedef StoreHandler = Function(Store event);

/// A `Store` is a repository and manager of app state. This class should be
/// extended to fit the needs of your application and its data. The number and
/// hierarchy of stores is dependent upon the state management needs of your
/// application.
///
/// General guidelines with respect to a `Store`'s data:
/// - A `Store`'s data should not be exposed for direct mutation.
/// - A `Store`'s data should be mutated internally in response to [Action]s.
/// - A `Store` should expose relevant data ONLY via public getters.
///
/// To receive notifications of a `Store`'s data mutations, `Store`s can be
/// listened to. Whenever a `Store`'s data is mutated, the `trigger` method is
/// used to tell all registered listeners that updated data is available.
///
/// In a typical application using `w_flux`, a [FluxComponent] listens to
/// `Store`s, triggering re-rendering of the UI elements based on the updated
/// `Store` data.
class Store extends Stream<Store> with Disposable {
  @override
  String get disposableTypeName => 'Store';

  /// Stream controller for [_stream]. Used by [trigger].
  final StreamController<Store> _streamController;

  /// Broadcast stream of "data updated" events. Listened to in [listen].
  late Stream<Store> _stream;

  /// Construct a new [Store] instance.
  Store() : _streamController = StreamController<Store>.broadcast() {
    manageStreamController(_streamController);
    _stream = _streamController.stream;
  }

  /// Construct a new [Store] instance with a transformer.
  ///
  /// The standard behavior of the "trigger" stream will be modified. The
  /// underlying stream will be transformed using [transformer].
  ///
  /// As an example, [transformer] could be used to throttle the number of
  /// triggers this [Store] emits for state that may update extremely frequently
  /// (like scroll position).
  Store.withTransformer(StreamTransformer<dynamic, dynamic> transformer)
      : _streamController = StreamController<Store>() {
    manageStreamController(_streamController);

    // apply a transform to the stream if supplied
    _stream = _streamController.stream
        .transform(transformer as StreamTransformer<Store, dynamic>)
        .asBroadcastStream() as Stream<Store>;
  }

  @override
  bool get isBroadcast => _stream.isBroadcast;

  /// The stream underlying [trigger] events and [listen].
  ///
  /// Deprecated: [Store] now extends [Stream]. Since the store itself
  /// can be treated as a stream this is no longer required.
  @Deprecated('3.0.0')
  @visibleForTesting
  Stream<Store> get stream => _stream;

  /// Adds a subscription to this `Store`.
  ///
  /// Each time this `Store` triggers (by calling [trigger]), indicating that
  /// data has been mutated, [onData] will be called.
  ///
  /// If the `Store` has been disposed, this method throws a [StateError].
  ///
  /// It is the caller's responsibility to cancel the subscription when
  /// needed.
  @override
  StreamSubscription<Store> listen(StoreHandler? onData,
      {Function? onError, void onDone()?, bool? cancelOnError}) {
    if (isDisposed) {
      throw StateError('Store of type $runtimeType has been disposed');
    }

    return _stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  /// Registers an [ActionSubscription] to be canceled when the store is disposed.
  ///
  /// This supports the following pattern for consumers:
  ///
  ///     manageActionSubscription(myAction.listen(_myHandler));
  ///
  @mustCallSuper
  @protected
  void manageActionSubscription(ActionSubscription subscription) {
    getManagedDisposer(() async => subscription.cancel());
  }

  /// Trigger a "data updated" event. All registered listeners of this `Store`
  /// will receive the event, at which point they can use the latest data
  /// from this `Store` as necessary.
  ///
  /// This should be called whenever this `Store`'s data has finished mutating in
  /// response to an action.
  ///
  /// If the `Store` is disposing or has been disposed, this method has no effect.
  void trigger() {
    if (isOrWillBeDisposed) return;

    _streamController.add(this);
  }

  /// A convenience method for listening to an [action] and triggering
  /// automatically once the callback for said action has completed.
  ///
  /// If [onAction] is provided, it will be called every time [action] is
  /// dispatched. If [onAction] returns a [Future], [trigger] will not be
  /// called until that future has resolved.
  ///
  /// If the `Store` has been disposed, this method throws a [StateError].
  /// Deprecated: 2.9.5
  /// To be removed: 3.0.0
  @deprecated
  triggerOnAction(Action action, [void onAction(payload)?]) {
    triggerOnActionV2(action, onAction);
  }

  /// A convenience method for listening to an [action] and triggering
  /// automatically once the callback for said action has completed.
  ///
  /// If [onAction] is provided, it will be called every time [action] is
  /// dispatched. If [onAction] returns a [Future], [trigger] will not be
  /// called until that future has resolved.
  ///
  /// If the `Store` has been disposed, this method throws a [StateError].
  void triggerOnActionV2<T>(Action<T> action,
      [FutureOr<dynamic> onAction(T payload)?]) {
    if (isOrWillBeDisposed) {
      throw StateError('Store of type $runtimeType has been disposed');
    }
    manageActionSubscription(action.listen((payload) async {
      if (onAction != null) {
        await onAction(payload);
      }
      trigger();
    }));
  }
}
