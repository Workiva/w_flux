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

library w_flux.example.todo_app.actions;

import 'package:w_flux/w_flux.dart';

import 'store.dart';

class ToDoActions {
  final Action2<Todo> createTodo = Action2<Todo>();
  final Action2<Todo> completeTodo = Action2<Todo>();
  final Action2<Todo> deleteTodo = Action2<Todo>();
  final Action2 clearTodoList = Action2<Todo>();
}
