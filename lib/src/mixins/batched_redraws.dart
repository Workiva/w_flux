library w_flux.mixins.batched_redraws;

import 'dart:async';
import 'dart:html';

import 'package:react/react.dart' as react;

class _RedrawScheduler implements Function {
  Set<react.Component> _components = new Set();

  void call(react.Component component) {
    if (_components.isEmpty) {
      _tick();
    }
    _components.add(component);
  }

  Future _tick() async {
    await window.animationFrame;
    _components
      ..forEach((c) {
        c.setState({});
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
  void redraw() => _scheduleRedraw(this as react.Component);
}
