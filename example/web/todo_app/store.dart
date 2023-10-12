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

library w_flux.example.todo_app.store;

import 'package:w_flux/w_flux.dart';

import 'actions.dart';

class ToDoStore extends Store {
  /// Public data
  List<Todo> _todos = [];
  List<Todo> get todos => _todos;

  /// Internals
  ToDoActions _actions;

  ToDoStore(ToDoActions this._actions) {
    triggerOnActionV2(_actions.createTodo, (Todo todo) => _todos.add(todo));
    triggerOnActionV2(
        _actions.completeTodo, (Todo todo) => todo.completed = true);
    triggerOnActionV2(_actions.deleteTodo, (Todo todo) => _todos.remove(todo));
    triggerOnActionV2(_actions.clearTodoList, (_) => _todos = []);
  }
}

class Todo {
  String description;
  bool completed = false;

  Todo(String this.description);
}
