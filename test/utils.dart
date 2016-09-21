library w_flux.test.utils;

import 'dart:async';

Future nextTick([int milliseconds = 1]) {
  return new Future.delayed(new Duration(milliseconds: milliseconds));
}

Future waitFor(bool condition(),
    {Duration interval: const Duration(milliseconds: 1),
    int maximumTimeout: 10}) {
  Completer c = new Completer();
  Stopwatch w = new Stopwatch()..start();
  new Timer.periodic(interval, (timer) {
    if (condition() || w.elapsedMilliseconds > maximumTimeout) {
      timer.cancel();
      c.complete();
      w.stop();
      if (w.elapsedMilliseconds > maximumTimeout) {
        throw new TimeoutException(
            'The expected condition did not occur within $maximumTimeout milliseconds');
      }
    }
  });
  return c.future;
}
