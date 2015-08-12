library w_flux.example.todo_app.components.todo_app_component;

import 'package:react/react.dart' as react;
import 'package:w_flux/w_flux.dart';

import 'new_todo_input.dart';
import 'todo_list_item.dart';
import '../actions.dart';
import '../store.dart';

var ToDoAppComponent = react.registerComponent(() => new _ToDoAppComponent());
class _ToDoAppComponent extends FluxComponent<ToDoActions, ToDoStore> {
  render() {
    List todoListItems = [];
    store.todos.forEach((Todo todo) {
      todoListItems.add(TodoListItem({'todo': todo, 'onClick': _completeTodo}));
    });
    var todoList = react.div({'className': 'list-group'}, todoListItems);

    var pageHeader = react.div({'className': 'page-header'}, react.h1({}, 'My Todos'));
    var clearButton = react.button(
        {'onClick': _clearList, 'disabled': store.todos.length == 0}, 'Clear Todo List');

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
    this.actions.createTodo(new Todo(value));
  }

  _completeTodo(todo) {
    this.actions.completeTodo(todo);
  }
}
