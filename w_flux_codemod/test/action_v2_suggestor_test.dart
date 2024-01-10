import 'package:codemod/codemod.dart';
import 'package:codemod/test.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:w_flux_codemod/src/action_v2_suggestor.dart';

const pubspec = '''
name: pkg
publish_to: none
environment:
  sdk: '>=2.11.0 <4.0.0'
dependencies:
  w_flux: ^3.0.0
''';

String wFluxInputImport(WFluxImportMode mode) {
  switch (mode) {
    case WFluxImportMode.none:
      return '';
    case WFluxImportMode.standard:
      return "import 'package:w_flux/w_flux.dart';";
    case WFluxImportMode.prefixed:
      return "import 'package:w_flux/w_flux.dart' as w_flux;";
    case WFluxImportMode.shown:
      return "import 'package:w_flux/w_flux.dart' show Action;";
    case WFluxImportMode.multipleShown:
      return "import 'package:w_flux/w_flux.dart' show Action, FluxComponent;";
    case WFluxImportMode.hidden:
      return "import 'package:w_flux/w_flux.dart' hide Action;";
  }
}

String wFluxOutputImport(WFluxImportMode mode) {
  switch (mode) {
    case WFluxImportMode.none:
    case WFluxImportMode.standard:
    case WFluxImportMode.prefixed:
      return wFluxInputImport(mode);
    case WFluxImportMode.shown:
      return "import 'package:w_flux/w_flux.dart' show ActionV2;";
    case WFluxImportMode.multipleShown:
      return "import 'package:w_flux/w_flux.dart' show ActionV2, FluxComponent;";
    case WFluxImportMode.hidden:
      return "import 'package:w_flux/w_flux.dart' hide ActionV2;";
  }
}

enum WFluxImportMode {
  none, // don't import w_flux
  standard, // import w_flux
  prefixed, // import w_flux with a prefix
  shown, // import but just show Action
  multipleShown,
  hidden, // hide from w_flux
}

void main() {
  group('ActionV2 suggestors', () {
    late PackageContextForTest pkg;

    setUpAll(() async {
      pkg = await PackageContextForTest.fromPubspec(pubspec);
    });

    @isTest
    void testSuggestor(String description, Suggestor Function() suggestor,
        String before, String after,
        {WFluxImportMode importMode = WFluxImportMode.standard,
        shouldImport = true}) {
      test(description, () async {
        final context = await pkg.addFile('''
${shouldImport ? wFluxInputImport(importMode) : ''}
${before}
''');
        final expectedOutput = '''
${shouldImport ? wFluxOutputImport(importMode) : ''}
${after}
''';
        expectSuggestorGeneratesPatches(
          suggestor(),
          context,
          expectedOutput,
        );
      });
    }

    group('ActionV2ImportMigrator', () {
      Suggestor suggestor() => ActionV2ImportMigrator();

      testSuggestor(
        'shown import',
        suggestor,
        '',
        '',
        importMode: WFluxImportMode.shown,
      );

      testSuggestor(
        'multiple shown import',
        suggestor,
        '',
        '',
        importMode: WFluxImportMode.multipleShown,
      );

      testSuggestor(
        'hidden import',
        suggestor,
        '',
        '',
        importMode: WFluxImportMode.hidden,
      );
    });

    group('ActionV2DispatchMigrator', () {
      Suggestor suggestor() => ActionV2DispatchMigrator();

      group(
          'test each import type for the dispatch migrator - local variable invocation',
          () {
        testSuggestor(
          'standard import',
          suggestor,
          'void main() { var a = Action(); a(); }',
          'void main() { var a = Action(); a(null); }',
        );
        testSuggestor(
          'import prefix',
          suggestor,
          'void main() { var a = w_flux.Action(); a(); }',
          'void main() { var a = w_flux.Action(); a(null); }',
          importMode: WFluxImportMode.prefixed,
        );
        // the following 3 tests use the "output" import statement because those
        // import statements should have been migrated by the other suggestors.
        testSuggestor(
          'shown import',
          suggestor,
          'void main() { var a = Action(); a(); }',
          'void main() { var a = Action(); a(null); }',
          importMode: WFluxImportMode.shown,
        );
        testSuggestor(
          'multiple shown imports',
          suggestor,
          'void main() { var a = Action(); a(); }',
          'void main() { var a = Action(); a(null); }',
          importMode: WFluxImportMode.multipleShown,
        );
        testSuggestor(
          'ignores types when hidden from w_flux',
          suggestor,
          'void main() { var a = Action(); a(); }',
          'void main() { var a = Action(); a(); }',
          importMode: WFluxImportMode.hidden,
        );
        testSuggestor(
          'ignores types not from w_flux',
          suggestor,
          'class Action { call(); } void main() { var a = Action(); a(); }',
          'class Action { call(); } void main() { var a = Action(); a(); }',
          importMode: WFluxImportMode.none,
        );
      });
      testSuggestor(
        'local invocation of field',
        suggestor,
        'class C { ActionV2 action; dispatch() => action(); }',
        'class C { ActionV2 action; dispatch() => action(null); }',
      );
      testSuggestor(
        'external invocation of field',
        suggestor,
        'class C { ActionV2 action; } void main() { C().action(); }',
        'class C { ActionV2 action; } void main() { C().action(null); }',
      );
      testSuggestor(
        'ignores Action type',
        suggestor,
        'void main() { var a = Action(); a(); }',
        'void main() { var a = Action(); a(); }',
      );
      testSuggestor(
        'nested dispatch',
        suggestor,
        '''
          class A { final ActionV2 action = ActionV2(); }
          class B { final actions = A(); }
          void main() {
            B().actions.action();
          }
        ''',
        '''
          class A { final Action action = Action(); }
          class B { final actions = A(); }
          void main() {
            B().actions.action(null);
          }
        ''',
      );
    });

    group('FieldAndVariableMigrator', () {
      Suggestor suggestor() => ActionV2FieldAndVariableMigrator();
      group('VariableDeclarationList', () {
        // test each import type on a named type migrator
        group('each import variation for type, with no intializer', () {
          testSuggestor(
            'standard import',
            suggestor,
            'Action<num> action;',
            'ActionV2<num> action;',
          );
          testSuggestor(
            'prefixed import',
            suggestor,
            'w_flux.Action<num> action;',
            'w_flux.ActionV2<num> action;',
            importMode: WFluxImportMode.prefixed,
          );
          testSuggestor(
            'ignore Action when hidden from w_flux',
            suggestor,
            '''
            ${wFluxOutputImport(WFluxImportMode.hidden)}
            'Action<num> action;'
            ''',
            '''
            ${wFluxOutputImport(WFluxImportMode.hidden)}
            'Action<num> action;'
            ''',
            importMode: WFluxImportMode.hidden,
            shouldImport: false,
          );
          testSuggestor(
            'ignore types not from w_flux',
            suggestor,
            'Action<num> action;',
            'Action<num> action;',
            importMode: WFluxImportMode.none,
          );
        });
        testSuggestor(
          'with type and intializer',
          suggestor,
          'Action<num> action = Action<num>();',
          'ActionV2<num> action = ActionV2<num>();',
        );
        testSuggestor(
          'no type, with intializer',
          suggestor,
          'var action = Action<num>();',
          'var action = ActionV2<num>();',
        );
        testSuggestor(
          'dynamic Actions',
          suggestor,
          'Action a; Action b = Action(); var c = Action();',
          'ActionV2 a; ActionV2 b = ActionV2(); var c = ActionV2();',
        );
        testSuggestor(
          'nested type',
          suggestor,
          'List<Action<num>> actions = [Action<num>(), Action<num>()];',
          'List<ActionV2<num>> actions = [ActionV2<num>(), ActionV2<num>()];',
        );
      });
      group('FieldDeclaration', () {
        testSuggestor(
          'with type, no intializer',
          suggestor,
          'class C { Action<num> action; }',
          'class C { ActionV2<num> action; }',
        );
        testSuggestor(
          'with type and intializer',
          suggestor,
          'class C { Action<num> action = Action<num>(); }',
          'class C { ActionV2<num> action = ActionV2<num>(); }',
        );
        testSuggestor(
          'no type, with intializer',
          suggestor,
          'class C { var action = Action<num>(); }',
          'class C { var action = ActionV2<num>(); }',
        );
        testSuggestor(
          'dynamic Actions',
          suggestor,
          'class C { Action a; Action b = Action(); var c = Action(); }',
          'class C { ActionV2 a; ActionV2 b = ActionV2(); var c = ActionV2(); }',
        );
        // List<Action> is a return type and will not be modified in this suggestor
        testSuggestor(
          'nested Action type',
          suggestor,
          '''
            abstract class Actions {
              final Action openAction = Action();
              final Action closeAction = Action();

              List<Action> get actions => <Action>[
                    openAction,
                    closeAction,
                  ];
            }
          ''',
          '''
            abstract class Actions {
              final ActionV2 openAction = ActionV2();
              final ActionV2 closeAction = ActionV2();

              List<Action> get actions => <Action>[
                    openAction,
                    closeAction,
                  ];
            }
          ''',
        );
      });
      group('InstanceCreationExpression', () {
        testSuggestor(
          'variable initialization',
          suggestor,
          'var action; action = Action();',
          'var action; action = ActionV2();',
        );
        testSuggestor(
          'field initialization',
          suggestor,
          'class C { var action; C() { action = Action(); } }',
          'class C { var action; C() { action = ActionV2(); } }',
        );
        testSuggestor(
          'function initialization',
          suggestor,
          'Action a; Action b = Action(); var c = Action();',
          'ActionV2 a; ActionV2 b = ActionV2(); var c = ActionV2();',
        );
      });
    });

    group('ParameterMigrator', () {
      Suggestor suggestor() => ActionV2ParameterMigrator();
      testSuggestor(
        'SimpleFormalParameter.type (function)',
        suggestor,
        'fn(Action action) {}',
        'fn(ActionV2 action) {}',
      );
      testSuggestor(
        'SimpleFormalParameter.type (method)',
        suggestor,
        'class C { m(Action action) {} }',
        'class C { m(ActionV2 action) {} }',
      );
      testSuggestor(
        'Parameter type with a generic',
        suggestor,
        'fn(Action<num> action) {}',
        'fn(ActionV2<num> action) {}',
      );
    });

    group('ReturnTypeMigrator', () {
      Suggestor suggestor() => ActionV2ReturnTypeMigrator();

      testSuggestor(
        'FunctionDeclaration.returnType',
        suggestor,
        'Action fn() {}',
        'ActionV2 fn() {}',
      );
      testSuggestor(
        'FunctionTypeAlias.returnType',
        suggestor,
        'typedef t = Action Function();',
        'typedef t = ActionV2 Function();',
      );
      testSuggestor(
        'FunctionTypedFormalParameter.returnType (function)',
        suggestor,
        'fn(Action Function() fn) {}',
        'fn(ActionV2 Function() fn) {}',
      );
      testSuggestor(
        'FunctionTypedFormalParameter.returnType (method)',
        suggestor,
        'class C { m(Action Function() fn) {} }',
        'class C { m(ActionV2 Function() fn) {} }',
      );
      testSuggestor(
        'GenericFunctionType.returnType',
        suggestor,
        'fn(Action Function() callback) {}',
        'fn(ActionV2 Function() callback) {}',
      );
      testSuggestor(
        'MethodDeclaration.returnType',
        suggestor,
        'class C { Action m() {} }',
        'class C { ActionV2 m() {} }',
      );
      testSuggestor(
        'Return type with a generic',
        suggestor,
        'Action<num> fn() {}',
        'ActionV2<num> fn() {}',
      );
      // field declarations (final Action) should not be migrated in this codemod
      testSuggestor(
        'nested return type',
        suggestor,
        '''
          abstract class Actions {
            final Action openAction = Action();
            final Action closeAction = Action();

            List<Action> get actions => <Action>[
                  openAction,
                  closeAction,
                ];
          }
        ''',
        '''
          abstract class Actions {
            final Action openAction = Action();
            final Action closeAction = Action();

            List<ActionV2> get actions => <ActionV2>[
                  openAction,
                  closeAction,
                ];
          }
        ''',
      );
    });

    group('TypeParameterMigrator', () {
      Suggestor suggestor() => ActionV2SuperTypeMigrator();
      testSuggestor(
        'standard import',
        suggestor,
        'class C extends Action {}',
        'class C extends ActionV2 {}',
      );
      testSuggestor(
        'ExtendsClause.superclass',
        suggestor,
        'class C extends Action {}',
        'class C extends ActionV2 {}',
      );
      testSuggestor(
        'ImplementsClause.interfaces',
        suggestor,
        'class C implements Action {}',
        'class C implements ActionV2 {}',
      );
      testSuggestor(
        'OnClause.superclassConstraints',
        suggestor,
        'class C extends Action {}',
        'class C extends ActionV2 {}',
      );
      testSuggestor(
        'Type parameter',
        suggestor,
        'fn<T extends Action>() {}',
        'fn<T extends ActionV2>() {}',
      );
      testSuggestor(
        'Type parameter with a generic',
        suggestor,
        'fn<T extends Action<num>>() {}',
        'fn<T extends ActionV2<num>>() {}',
      );
    });
  });
}
