w_flux
------
[![Pub](https://img.shields.io/pub/v/w_flux.svg)](https://pub.dartlang.org/packages/w_flux) [![Build Status](https://travis-ci.org/Workiva/w_flux.svg?branch=master)](https://travis-ci.org/Workiva/w_flux) [![codecov.io](http://codecov.io/github/Workiva/w_flux/coverage.svg?branch=master)](http://codecov.io/github/Workiva/w_flux?branch=master)

> A Dart app architecture library with uni-directional data flow inspired by [RefluxJS](https://github.com/reflux/refluxjs) and Facebook's [Flux](https://facebook.github.io/flux/).

- [**Overview**](#overview)
- [**What's Included**](#whats-included)
  - [**Action**](#action)
  - [**Store**](#store)
  - [**FluxComponent**](#fluxcomponent)
- [**Examples**](#examples)
- [**External Consumption**](#external-consumption)
- [**Development**](#development)

---

## Overview

![flux-diagram](https://github.com/Workiva/w_flux/blob/images/images/flux_diagram.png)

`w_flux` implements a uni-directional data flow pattern comprised of `Actions`, `Stores`, and `FluxComponents`.

- `Actions` initiate mutation of app data that resides in `Stores`.
- Data mutations within `Stores` trigger re-rendering of app view (defined in `FluxComponents`).
- `FluxComponents` dispatch `Actions` in response to user interaction.
- and the cycle continues...

---

## What's Included


### Action

An `Action` is a command that can be dispatched (with an optional data payload) and listened to.

In `w_flux`, `Actions` are the sole driver of application state change. `FluxComponents` dispatch `Actions` in response to
user interaction with the rendered view. `Stores` listen for these `Action` dispatches and mutate their internal data in
response, taking the `Action` payload into account as appropriate.

```dart
import 'package:w_flux/w_flux.dart';

// define an action
final Action<String> displayString = new Action<String>();

// dispatch the action with a payload
displayString('somePayload');

// listen for action dispatches
displayString.listen(_displayAlert);

_displayAlert(String payload) {
  print(payload);
}
```

**BONUS:** `Actions` are await-able!

They return a Future that completes after all registered `Action` listeners complete.  It's NOT generally recommended to
use this feature within normal app code, but it is quite useful in unit test code.


### Store

A `Store` is a repository and manager of app state. The base `Store` class provided by `w_flux` should be extended to fit
the needs of your app and its data. App state may be spread across many independent stores depending on the complexity
of the app and your desired app architecture.

By convention, a `Store`'s internal data cannot be mutated directly. Instead, `Store` data is mutated internally in
response to `Action` dispatches. `Stores` should otherwise be considered read-only, publicly exposing relevant data ONLY
via getter methods.  This limited data access ensures that the integrity of the uni-directional data flow is maintained.

A `Store` can be listened to to receive external notification of its data mutations. Whenever the data within a `Store`
is mutated, the `trigger` method is used to notify any registered listeners that updated data is available.  In `w_flux`,
`FluxComponents` listen to `Stores`, typically triggering re-rendering of UI elements based on the updated `Store` data.

```dart
import 'package:w_flux/w_flux.dart';

class RandomColorStore extends Store {

  // Public data is only available via getter method
  String _backgroundColor = 'gray';
  String get backgroundColor => _backgroundColor;

  // Actions relevant to the store are passed in during instantiation
  RandomColorActions _actions;

  RandomColorStore(RandomColorActions this._actions) {
    // listen for relevant action dispatches
    _actions.changeBackgroundColor.listen(_changeBackgroundColor);
  }

  _changeBackgroundColor(_) {
    // action dispatches trigger internal data mutations
    _backgroundColor = '#' + (new Random().nextDouble() * 16777215).floor().toRadixString(16);

    // trigger to notify external listeners that new data is available
    trigger();
  }
}
```

**BONUS:** `Stores` can be initialized with a stream transformer to modify the standard behavior of the `trigger` stream.
This can be useful for throttling UI rendering in response to high frequency `Store` mutations.

```dart
import 'package:rate_limit/rate_limit.dart';
import 'package:w_flux/w_flux.dart';

class ThrottledStore extends Store {
  ...

  ThrottledStore(this._actions) : super.withTransformer(new Throttler(const Duration(milliseconds: 30))) {
    ...
  }
}
```

**BONUS:** `Stores` provide an optional terse syntax for action -> data mutation -> trigger operations.

```dart
// verbose syntax
actions.incrementCounter.listen(_handleAction);

_handleAction(payload) {
    // perform data mutation
    counter += payload;
    trigger();
  }

// equivalent terse syntax
triggerOnAction(actions.incrementCounter, (payload) => counter += payload);
```


### FluxComponent

`FluxComponents` define the (optional) user interface for a `w_flux` unit and are responsible for rendering app view based
on 'Store' data as needed. `FluxComponents` listen to `Stores` and selectively re-render in response to their `trigger`
dispatches. `FluxComponents` retrieve relevant app data from these `Stores` via the exposed getter methods, and as such,
are internally stateless.

If user interaction with a `FluxComponent` is intended to mutate app state, this is accomplished by dispatching an
`Action` (with optional data payload). `FluxComponents` DO NOT mutate app state within `Stores` directly.

`FluxComponent` is an extension of [Component](https://github.com/cleandart/react-dart/blob/master/lib/react.dart#L10)
(as provided by [react-dart](https://github.com/cleandart/react-dart)) that reduces the amount of boilerplate needed to
operate within the `w_flux` architecture. The base `FluxComponent` class provided by `w_flux` should be extended to fit
the needs of your app.

By default, `FluxComponents` provide standard getters for the `Actions` and `Store` that they are initialized with.
They also automatically subscribe to the provided `Store` and re-render in response to its `triggers`.

```dart
import 'package:react/react.dart' as react;
import 'package:w_flux/w_flux.dart';

var RandomColorComponent = react.registerComponent(() => new _RandomColorComponent());
class _RandomColorComponent extends FluxComponent<RandomColorActions, RandomColorStore> {
  render() {
    return react.div({
      // accesses the backgroundColor via the store's public getter
      'style': {'padding': '50px', 'backgroundColor': store.backgroundColor, 'color': 'white'}
    }, [
      'This module uses a flux pattern to change its background color.',
      react.button({
        'style': {'padding': '10px', 'margin': '10px'},
        // triggers a change of background color by dispatching an action on button click
        'onClick': actions.changeBackgroundColor
      }, 'Change Background Color')
    ]);
  }
}
```

**BONUS:** Optional overrides are available for more granular control of `FluxComponent` rendering.

If the `FluxComponent`'s `Store` is actually a complex object containing multiple `Stores` (each `trigger` independently),
the component's `redrawOn` list can be overridden to confine re-rendering to `trigger` dispatches that originate from
specific sub-stores.

The `FluxComponent`'s `getStoreHandlers` method can be used to register more fine grained `Store` `trigger` handling if necessary.

```dart
import 'package:react/react.dart' as react;
import 'package:w_flux/w_flux.dart';

class ComplexStore {
  ThisStore thisOne = new ThisStore();
  ThatStore thatOne = new ThatStore();
  OtherStore otherOne = new OtherStore();
}

var ComplexComponent = react.registerComponent(() => new _ComplexComponent());
class _ComplexComponent extends FluxComponent<ComplexActions, ComplexStore> {

  // re-render will automatically be initiated in response to triggers from these two stores
  // (e.g. no rendering will occur on store.otherOne triggers)
  redrawOn() => [store.thisOne, store.thatOne];

  // whenever store.otherOne triggers, the _handleOtherTrigger method will be executed
  // (no rendering is triggered)
  getStoreHandlers() => {store.otherOne: _handleOtherTrigger};

  _handleOtherTrigger(otherStore) {
    // decide whether to re-render based on some criteria
    if (otherStore.isReady) {
      // manually initiate re-render of this component
      redraw();
    }
  }

  render() {
    ...
  }
}
```

---

## Examples

Simple examples of `w_flux` usage can be found in the `example` directory. The example [README](example/README.md)
includes instructions for building / running them.


---

## External Consumption

`w_flux` implements a uni-directional data flow within an isolated application or code module. If `w_flux` is used as the
internal architecture of a library, this internal data flow should be considered when defining the external API.

- External API methods intended to mutate internal state should dispatch `Actions`, just like any internal user interaction.
- External API methods intended to query internal state should leverage the existing read-only `Store` getter methods.
- External API streams intended to notify the consumer about internal state changes should be dispatched from the
internal `Stores`, similar to their `triggers`.
- Factory constructors for useful 'root' `FluxComponents` can be exposed publicly for use in external react-dart based
rendering hierarchies. These react components can be internally initialized with the `Actions` and `Stores` needed for
normal operation without inadvertently exposing them externally.

[w_module](https://github.com/Workiva/w_module) is a Dart library that defines a standard code module API that can be
used seamlessly with `w_flux` internals to satisfy the above recommendations (complete with examples).

---

## Development

This project leverages [the dart_dev package](https://github.com/Workiva/dart_dev)
for most of its tooling needs, including static analysis, code formatting,
running tests, collecting coverage, and serving examples. Check out the dart_dev
readme for more information.
