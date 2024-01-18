// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library w_flux.example.random_color;

import 'dart:html';
import 'dart:math';

import 'package:react/react.dart' as react;
import 'package:react/react_dom.dart' as react_dom;
import 'package:react/react_client.dart' as react_client;

import 'package:w_flux/w_flux.dart';

main() async {
  // initialize action, stores, and components
  RandomColorActions actions = RandomColorActions();
  RandomColorStore store = RandomColorStore(actions);

  // render the component
  react_client.setClientConfiguration();
  react_dom.render(RandomColorComponent({'actions': actions, 'store': store}),
      querySelector('#content-container'));
}

class RandomColorActions {
  final ActionV2 changeBackgroundColor = ActionV2();
}

class RandomColorStore extends Store {
  /// Public data
  String _backgroundColor = 'gray';
  String get backgroundColor => _backgroundColor;

  /// Internals
  RandomColorActions _actions;

  RandomColorStore(RandomColorActions this._actions) {
    triggerOnActionV2(_actions.changeBackgroundColor, _changeBackgroundColor);
  }

  _changeBackgroundColor(_) {
    // generate a random hex color string
    _backgroundColor =
        '#' + (Random().nextDouble() * 16777215).floor().toRadixString(16);
  }
}

var RandomColorComponent =
    react.registerComponent(() => _RandomColorComponent());

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
        'onClick': (_) => actions.changeBackgroundColor(null)
      }, 'Change Background Color')
    ]);
  }
}
