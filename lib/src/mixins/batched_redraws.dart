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
    _components
      ..forEach((component, callbacks) {
        // Skip if the component doesn't want to batch redraw, or if it has
        // redrawn already in this batch.
        if (!component.shouldBatchRedraw || component.didBatchRedraw) {
          return;
        }

        var chainedCallbacks;

        if (callbacks.isNotEmpty) {
          chainedCallbacks = () {
            callbacks.forEach((callback) {
              callback();
            });
          };
        }

        (component as react.Component)?.setState({}, chainedCallbacks);
      })
      ..forEach((component, callbacks) {
        component.didBatchRedraw = false;
      })
      ..clear();
  }
}

_RedrawScheduler _scheduleRedraw = new _RedrawScheduler();

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

  /// A flag marking components that did update as the result of a batch redraw,
  /// and used to prevent excessive redraws in hierarchies of nested flux components.
  bool didBatchRedraw = false;

  void redraw([callback()]) => _scheduleRedraw(this, callback);
}
