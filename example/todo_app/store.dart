library w_flux.example.todo_app.store;

import 'package:w_flux/w_flux.dart';

import 'actions.dart';

class ToDoStore extends Store {

  /// Public data
  List<Todo> _todos;
  List<Todo> get todos => _todos;

  /// Internals
  ToDoActions _actions;

  ToDoStore(ToDoActions this._actions) {
    _todos = [];

    triggerOnAction(_actions.createTodo, (todo) => _todos.add(todo));
    triggerOnAction(_actions.completeTodo, (todo) => todo.completed = true);
    triggerOnAction(_actions.deleteTodo, (todo) => _todos.remove(todo));
    triggerOnAction(_actions.clearTodoList, (_) => _todos = []);
  }
}

class Todo {
  String description;
  bool completed = false;

  Todo(String this.description);
}
