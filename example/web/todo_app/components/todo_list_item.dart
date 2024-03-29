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

library w_flux.example.todo_app.components.todo_list_item;

import 'package:react/react.dart' as react;

import '../store.dart';

var TodoListItem = react.registerComponent(() => _TodoListItem());

class _TodoListItem extends react.Component2 {
  Todo get todo => props['todo'] as String;
  Function get onClick => props['onClick'] as Function;

  get defaultProps => {'todo': null};

  render() {
    String className =
        todo.completed ? 'list-group-item completed' : 'list-group-item';
    return react.span({
      'className': className
    }, [
      react.label({}, [
        react.input({
          'type': 'checkbox',
          'label': todo.description,
          'checked': todo.completed,
          'onChange': _onClick
        }),
        todo.description
      ])
    ]);
  }

  _onClick(event) {
    onClick(todo);
  }
}
