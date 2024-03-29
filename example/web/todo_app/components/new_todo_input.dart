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

library w_flux.example.todo_app.components.new_todo_input;

import 'package:react/react.dart' as react;

var NewTodoInput = react.registerComponent(() => _NewTodoInput());

class _NewTodoInput extends react.Component2 {
  String get value => state['value'] as String;
  Function get onSubmit => props['onSubmit'] as Function;

  get initialState => {'value': ''};

  render() {
    return react.form(
        {'onSubmit': _onSubmit},
        react.input({
          'className': 'form-control',
          'placeholder': 'Add a new todo...',
          'type': 'text',
          'value': value,
          'onChange': _onChange
        }));
  }

  _onChange(react.SyntheticFormEvent event) {
    setState({'value': event.target.value});
  }

  _onSubmit(event) {
    event.preventDefault();
    onSubmit(value);
    this.setState({'value': ''});
  }
}
