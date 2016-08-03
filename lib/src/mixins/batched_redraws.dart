library w_flux.mixins.batched_redraws;

import 'dart:async';
import 'dart:html';

import 'package:react/react.dart' as react;

class _RedrawScheduler implements Function {
  Map<react.Component, List<Function>> _components =
      <react.Component, List<Function>>{};

  void call(react.Component component, [callback()]) {
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
        var chainedCallbacks;

        if (callbacks.isNotEmpty) {
          chainedCallbacks = () {
            callbacks.forEach((callback) {
              callback();
            });
          };
        }

        component.setState({}, chainedCallbacks);
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
  void redraw([callback()]) =>
      _scheduleRedraw(this as react.Component, callback);
}
