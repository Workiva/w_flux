library w_flux.example.todo_app.components.todo_list_item;

import 'package:react/react.dart' as react;

import '../store.dart';

var TodoListItem = react.registerComponent(() => new _TodoListItem());

class _TodoListItem extends react.Component {
  Todo get todo => props['todo'];
  Function get onClick => props['onClick'];

  getDefaultProps() => {'todo': null};

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
