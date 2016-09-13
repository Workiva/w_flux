library w_flux.test.utils;

import 'dart:async';

Future nextTick([int milliseconds = 1]) {
  return new Future.delayed(new Duration(milliseconds: milliseconds));
}

Future waitFor(bool condition(),
    {Duration interval: const Duration(milliseconds: 1)}) {
  Completer c = new Completer();
  new Timer.periodic(interval, (timer) {
    if (condition()) {
      timer.cancel();
      c.complete();
    }
  });
  return c.future;
}
