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

library w_flux.example.todo_app.components.todo_app_component;

import 'package:react/react.dart' as react;
import 'package:w_flux/w_flux.dart';

import 'new_todo_input.dart';
import 'todo_list_item.dart';
import '../actions.dart';
import '../store.dart';

var ToDoAppComponent = react.registerComponent(() => _ToDoAppComponent());

class _ToDoAppComponent extends FluxComponent<ToDoActions, ToDoStore> {
  render() {
    List todoListItems = [];
    store.todos.forEach((Todo todo) {
      todoListItems.add(TodoListItem({'todo': todo, 'onClick': _completeTodo}));
    });
    var todoList = react.div({'className': 'list-group'}, todoListItems);

    var pageHeader =
        react.div({'className': 'page-header'}, react.h1({}, 'My Todos'));
    var clearButton = react.button(
        {'onClick': _clearList, 'disabled': store.todos.length == 0},
        'Clear Todo List');

    return react.div({}, [
      pageHeader,
      react.p({}, 'A sample Todo application'),
      NewTodoInput({'onSubmit': _createTodo}),
      todoList,
      clearButton
    ]);
  }

  _clearList(_) {
    this.actions.clearTodoList();
  }

  _createTodo(String value) {
    this.actions.createTodo(Todo(value));
  }

  _completeTodo(Todo todo) {
    this.actions.completeTodo(todo);
  }
}
