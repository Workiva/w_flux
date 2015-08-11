library w_flux.example.todo_app.components.new_todo_input;

import 'package:react/react.dart' as react;

var NewTodoInput = react.registerComponent(() => new _NewTodoInput());
class _NewTodoInput extends react.Component {
  String get value => state['value'];
  Function get onSubmit => props['onSubmit'];

  getInitialState() => {'value': ''};

  render() {
    return react.form({'onSubmit': _onSubmit}, react.input({
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
