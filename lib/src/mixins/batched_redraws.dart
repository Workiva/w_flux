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

    _components[component].add(callback);
  }

  Future _tick() async {
    await window.animationFrame;
    _components
      ..forEach((component, callbacks) {
        var chainedCallbacks = callbacks.fold(null, _chain) ?? _noop;

        component.setState({}, chainedCallbacks);
      })
      ..clear();
  }

  void _noop() {}

  Function _chain(a(), b()) {
    if (a == null && b == null) return _noop;
    if (a == null) return b;
    if (b == null) return a;

    return () {
      a();
      b();
    };
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
