library w_flux.mixins.batched_redraws;

import 'dart:async';
import 'dart:html';

import 'package:react/react.dart' as react;

class _RedrawScheduler implements Function {
  Completer<Null> _completer;
  Map<BatchedRedraws, List<Function>> _components =
      <BatchedRedraws, List<Function>>{};
  StreamSubscription<Event> _documentVisibilitySubscription;

  void call(BatchedRedraws component, [callback()]) {
    if (_components.isEmpty) {
      _tick();
    }

    _components[component] ??= [];

    if (callback != null) _components[component].add(callback);
  }

  Future _tick() async {
    if (_documentVisibilitySubscription == null) {
      _documentVisibilitySubscription = document.onVisibilityChange.listen((_) {
        if (document.hidden && _completer != null && !_completer.isCompleted) {
          print('    end waiting because document is no longer visible.');
          _completer.complete();
          _documentVisibilitySubscription.cancel();
        }
      });
    }
    // `requestAnimationFrame()` (called by [window.animationFrame]) does not
    // fire (or fires with a significant delay depending on the browser) when
    // the current tab/window is not focused.
    // [source: https://stackoverflow.com/questions/15871942/how-do-browsers-pause-change-javascript-when-tab-or-window-is-not-active]
    //
    // To prevent creating huge batches that all fire when the window is
    // focused again, do not batch updates if the document is hidden.
    if (!document.hidden) {
      print('waiting for animationFrame...');
      _completer = new Completer<Null>();
      window.animationFrame.then((_) {
        if (!_completer.isCompleted) {
          _completer.complete();
        }
      });

      await _completer.future;
      print('   done waiting.');
    } else {
      print('Skipping awiat animationFrame, document is hidden!');
    }
    _components
      ..forEach((component, callbacks) {
        // Skip if the component doesn't want to batch redraw
        if (!component.shouldBatchRedraw) {
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

  void redraw([callback()]) => _scheduleRedraw(this, callback);
}
