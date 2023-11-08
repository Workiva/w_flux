import 'package:codemod/test.dart';
import 'package:test/test.dart';

import '../bin/action_v2_migrate.dart';

final testCases = [
  {
    'context': '''Function(Action action) {}''',
    'expectedOutput': '''Function(ActionV2 action) {}''',
  },
  {
    'context': '''Function(Action<T> action) {}''',
    'expectedOutput': '''Function(ActionV2<T> action) {}''',
  },
  {
    'context': '''Function(Action<String> action) {}''',
    'expectedOutput': '''Function(ActionV2<String> action) {}''',
  },
  {
    'context': '''Function(List<Action> action) {}''',
    'expectedOutput': '''Function(List<ActionV2> action) {}''',
  },
  // {
  //   'context': 'class SuperFancyClass {'
  //       'Action get action;'
  //       '}',
  //   'expectedOutput': 'Function(ActionV2<String> action) {}',
  // },
];

void main() {
  group('DeprecatedRemover', () {
    final filename = 'test.dart';
    for (final testCase in testCases) {
      test('removes deprecated variable', () async {
        final context = await fileContextForTest(filename, '''
  // Not deprecated.
  var foo = 'foo';
  @deprecated
  var bar = 'bar';''');
        final expectedOutput = '''
  // Not deprecated.
  var foo = 'foo';
  ''';
        expectSuggestorGeneratesPatches(
          ActionV2Suggestor(),
          context,
          expectedOutput,
        );
      });
    }
  });
}
