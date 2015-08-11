library w_flux.example.todo_app;

import 'dart:html';

import 'package:react/react.dart' as react;
import 'package:react/react_client.dart' as react_client;

import 'actions.dart';
import 'store.dart';
import 'components/todo_app_component.dart';

main() async {

  // initialize action, stores, and components
  ToDoActions actions = new ToDoActions();
  ToDoStore store = new ToDoStore(actions);

  // render the component
  react_client.setClientConfiguration();
  react.render(
      ToDoAppComponent({'actions': actions, 'store': store}), querySelector('#content-container'));
}
