library w_flux.test.utils;

import 'dart:async';

Future nextTick([int milliseconds = 1]) {
  return new Future.delayed(new Duration(milliseconds: milliseconds));
}
