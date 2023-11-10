// ignore_for_file: deprecated_member_use

library w_flux.mixins.batched_redraws;

import 'dart:async';
import 'dart:html';

import 'package:react/react.dart' as react;

import 'package:w_flux/src/component_client.dart';

class _RedrawScheduler {
  final _components = <BatchedRedraws, List<Function>>{};

  void call(BatchedRedraws component, [Function()? callback]) {
    if (_components.isEmpty) {
      _tick();
    }

    _components[component] ??= [];

    if (callback != null) _components[component]!.add(callback);
  }

  Future _tick() async {
    await window.animationFrame;

    // Making a copy of `_components` so we don't iterate over the map while it's potentially being mutated.
    final entries = _components.entries.toList();
    _components.clear();
    for (final entry in entries) {
      final component = entry.key;
      final callbacks = entry.value;
      // Skip if the component doesn't want to batch redraw
      if (!component.shouldBatchRedraw) {
        continue;
      }

      Function()? chainedCallbacks;

      if (callbacks.isNotEmpty) {
        chainedCallbacks = () {
          for (final callback in callbacks) {
            callback();
          }
        };
      }

      (component as react.Component).setState({}, chainedCallbacks);

      // Waits a tick to prevent holding up the thread, allowing other scripts to execute in between each component.
      await Future(() {});
    }
  }
}

_RedrawScheduler _scheduleRedraw = _RedrawScheduler();

/// A mixin that overrides the [react.Component.redraw] method of a React
/// [react.Component] (including a [FluxComponent]) and prevents the component
/// from being redrawn more than once per animation frame.
///
/// Example:
///
///     class MyComponent extends react.Component
///         with BatchedRedraws {
///       render() {...}
///     }
///
class BatchedRedraws {
  bool shouldBatchRedraw = true;

  void redraw([Function()? callback]) => _scheduleRedraw(this, callback);
}
