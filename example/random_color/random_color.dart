library w_flux.example.random_color;

import 'dart:html';
import 'dart:math';

import 'package:react/react.dart' as react;
import 'package:react/react_client.dart' as react_client;

import 'package:w_flux/w_flux.dart';

main() async {
  // initialize action, stores, and components
  RandomColorActions actions = new RandomColorActions();
  RandomColorStore store = new RandomColorStore(actions);

  // render the component
  react_client.setClientConfiguration();
  react.render(RandomColorComponent({'actions': actions, 'store': store}),
      querySelector('#content-container'));
}

class RandomColorActions {
  final Action changeBackgroundColor = new Action();
}

class RandomColorStore extends Store {
  /// Public data
  String _backgroundColor = 'gray';
  String get backgroundColor => _backgroundColor;

  /// Internals
  RandomColorActions _actions;

  RandomColorStore(RandomColorActions this._actions) {
    triggerOnAction(_actions.changeBackgroundColor, _changeBackgroundColor);
  }

  _changeBackgroundColor(_) {
    // generate a random hex color string
    _backgroundColor =
        '#' + (new Random().nextDouble() * 16777215).floor().toRadixString(16);
  }
}

var RandomColorComponent =
    react.registerComponent(() => new _RandomColorComponent());

class _RandomColorComponent
    extends FluxComponent<RandomColorActions, RandomColorStore> {
  render() {
    return react.div({
      'style': {
        'padding': '50px',
        'backgroundColor': store.backgroundColor,
        'color': 'white'
      }
    }, [
      'This module uses a flux pattern to change its background color.',
      react.button({
        'style': {'padding': '10px', 'margin': '10px'},
        'onClick': actions.changeBackgroundColor
      }, 'Change Background Color')
    ]);
  }
}
