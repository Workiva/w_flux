library w_flux.mixins.batched_redraws;

import 'dart:async';
import 'dart:html';

import 'package:react/react.dart' as react;

class _RedrawScheduler implements Function {
  Map<BatchedRedraws, List<Function>> _components =
      <BatchedRedraws, List<Function>>{};

  void call(BatchedRedraws component, [callback()]) {
    if (_components.isEmpty) {
      _tick();
    }

    _components[component] ??= [];

    if (callback != null) _components[component].add(callback);
  }

  Future _tick() async {
    await window.animationFrame;

    // Making a copy of `_components` so we don't iterate over the map while it's potentially being mutated.
    var entries = _components.entries.toList();
    _components.clear();
    for (var entry in entries) {
      var component = entry.key;
      var callbacks = entry.value;
      // Skip if the component doesn't want to batch redraw
      if (!component.shouldBatchRedraw) {
        continue;
      }

      Function() chainedCallbacks;

      if (callbacks.isNotEmpty) {
        chainedCallbacks = () {
          callbacks.forEach((callback) {
            callback();
          });
        };
      }

      (component as react.Component)?.setState({}, chainedCallbacks);

      // Waits a tick to prevent holding up the thread, allowing other scripts to execute in between each component.
      await Future(() {});
    }
  }
}

_RedrawScheduler _scheduleRedraw = _RedrawScheduler();

/// A mixin that overrides the [Component.redraw] method of a React
/// [Component] (including a [FluxComponent]) and prevents the component
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

  void redraw([callback()]) => _scheduleRedraw(this, callback);
}
