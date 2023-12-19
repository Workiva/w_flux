# w_flux_codemod

> **Built with [dart_codemod][dart_codemod].**

A codemod to convert existing usages of non null-safe `Action` to null-safe `ActionV2`.

## Motivation

`w_flux` was upgraded to dart 3 and made null safe, but we ran into an issue when migrating the `Action` class.

The `Action` class has a call method with an optional `payload` paramater that now must be typed as nullable. However, this means that we cannot make `listener` payloads non-nullable, since there's no guarantee that the argument was specified.

```
class Action<T> /*...*/ {
  Future call([T? payload]) { 
    for (final listener in _listeners) {
      await listener(payload);
      //             ^^^^^^^
      // Error: can't assign T? to T
    }
  }
  
  ActionSubscription listen(dynamic onData(T event)) {/*...*/}
  
  /*...*/
}
```

To be able to support non-nullable payloads (in addition to nullable payloads), we made a new `ActionV2` class with required payloads.

## Usage

1. Ensure you have the codemod package installed.
    ```bash
    dart pub global activate w_flux_codemod
    ```

2. Run the codemod:

    - step by step:
    ```bash
    dart pub global run w_flux_codemod:action_v2_migrate_step_1
    dart pub global run w_flux_codemod:action_v2_migrate_step_2
    ```

    - all at once:
    ```bash
    dart pub global run w_flux_codemod:action_v2_migrate
    ```

3. Review the changes:

    - It's advisable to review the changes and ensure they are correct and meet your project's requirements.
    - This codemod is not gauranteed to catch every implementation of `Action` and convert to `ActionV2`. For example: assigning `Action` to prop in a callback will be missed by this codemod.
    - Dart Analysis should be able to catch anything missed or errors caused by the codemod, and a passing CI should suffice for QA when making these updates.


## Example

Before codemod:

```dart
import 'package:w_flux/w_flux.dart';

class C {
    Action action;
} 

void main() {
    C().action();
}
```

After codemod:

```dart
import 'package:w_flux/w_flux.dart';

class C {
    ActionV2 action;
} 

void main() {
    // A payload is required for ActionV2, so `null` is added when needed.
    C().action(null);
}
```

[dart_codemod]: https://github.com/Workiva/dart_codemod