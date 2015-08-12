library w_flux.example.todo_app.actions;

import 'package:w_flux/w_flux.dart';

import 'store.dart';

class ToDoActions {
  final Action<Todo> createTodo = new Action<Todo>();
  final Action<Todo> completeTodo = new Action<Todo>();
  final Action<Todo> deleteTodo = new Action<Todo>();
  final Action clearTodoList = new Action<Todo>();
}
