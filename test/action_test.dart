library w_flux.test.action_test;

import 'dart:async';

import 'package:w_flux/w_flux.dart';
import 'package:test/test.dart';


void main() {

  group('Action', () {
    Action<String> action;

    setUp(() {
      action = new Action<String>();
    });

    test('should inherit from Stream', () {
      expect(action is Stream, isTrue);
    });

    test('should support dispatch without a payload', () {
      Action _action = new Action();

      expectAsync(_action.listen)((payload) {
        expect(payload, equals(null));
      });

      _action.dispatch();
    });

    test('should support dispatch with a payload', () {
      expectAsync(action.listen)((payload) {
        expect(payload, equals('990 guerrero'));
      });

      action.dispatch('990 guerrero');
    });

    test('should support other stream methods', () async {
      Completer completer = new Completer();

      // The point of this test is to exercise the `where` method which is made available
      // on an action by extending stream and overriding `listen`
      Stream<String> filteredStream = action.where((value) => value == 'water');
      expectAsync(filteredStream.listen)((payload) {
        expect(payload, equals('water'));
        completer.complete();
      });

      action.dispatch('water');
      return completer.future;
    });

    test('should dispatch by default when called', () {
      expectAsync(action.listen)((payload) {
        expect(payload, equals('990 guerrero'));
      });

      action('990 guerrero');
    });

  });
}
