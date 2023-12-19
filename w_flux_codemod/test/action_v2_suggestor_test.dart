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

String wFluxImport(WFluxImportMode mode) {
  switch (mode) {
    case WFluxImportMode.none:
      return '';
    case WFluxImportMode.standard:
      return "import 'package:w_flux/w_flux.dart';";
    case WFluxImportMode.prefixed:
      return "import 'package:w_flux/w_flux.dart' as w_flux;";
  }
}

enum WFluxImportMode {
  none, // don't import w_flux
  standard, // import w_flux
  prefixed, // import w_flux with a prefix
}

void main() {
  group('ActionV2 suggestors', () {
    late PackageContextForTest pkg;

    setUpAll(() async {
      pkg = await PackageContextForTest.fromPubspec(pubspec);
    });

    @isTest
    void testSuggestor(
      String description,
      Suggestor Function() suggestor,
      String before,
      String after, {
      WFluxImportMode importMode = WFluxImportMode.standard,
      bool shouldMigrateVariablesAndFields = false,
    }) {
      test(description, () async {
        final context = await pkg.addFile('''
${wFluxImport(importMode)}
${before}
''');
        final expectedOutput = '''
${wFluxImport(importMode)}
${after}
''';
        expectSuggestorGeneratesPatches(
          suggestor(),
          context,
          expectedOutput,
        );
      });
    }

    group('ActionV2DispatchMigrator', () {
      Suggestor suggestor() => ActionV2DispatchMigrator();
      testSuggestor(
        'local invocation of variable',
        suggestor,
        'void main() { var a = ActionV2(); a(); }',
        'void main() { var a = ActionV2(); a(null); }',
      );
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
        'with import prefix',
        suggestor,
        'void main() { var a = w_flux.ActionV2(); a(); }',
        'void main() { var a = w_flux.ActionV2(); a(null); }',
        importMode: WFluxImportMode.prefixed,
      );
      testSuggestor(
        'ignores Action type',
        suggestor,
        'void main() { var a = Action(); a(); }',
        'void main() { var a = Action(); a(); }',
      );
      testSuggestor(
        'ignores types not from w_flux',
        suggestor,
        'class ActionV2 { call(); } void main() { var a = ActionV2(); a(); }',
        'class ActionV2 { call(); } void main() { var a = ActionV2(); a(); }',
        importMode: WFluxImportMode.none,
      );
    });

    group('FieldAndVariableMigrator', () {
      Suggestor suggestor() => ActionV2FieldAndVariableMigrator();
      group('VariableDeclarationList', () {
        group('with type, no intializer', () {
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
      group('SimpleFormalParameter.type (function)', () {
        testSuggestor(
          'standard prefix',
          suggestor,
          'fn(Action action) {}',
          'fn(ActionV2 action) {}',
        );
        testSuggestor(
          'prefixed import',
          suggestor,
          'fn(w_flux.Action action) {}',
          'fn(w_flux.ActionV2 action) {}',
          importMode: WFluxImportMode.prefixed,
        );
        testSuggestor(
          'ignore types not from w_flux',
          suggestor,
          'fn(Action action) {}',
          'fn(Action action) {}',
          importMode: WFluxImportMode.none,
        );
      });
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

      group('FunctionDeclaration.returnType', () {
        testSuggestor(
          'standard import',
          suggestor,
          'Action fn() {}',
          'ActionV2 fn() {}',
        );
        testSuggestor(
          'prefixed import',
          suggestor,
          'w_flux.Action fn() {}',
          'w_flux.ActionV2 fn() {}',
          importMode: WFluxImportMode.prefixed,
        );
        testSuggestor(
          'ignore types not from w_flux',
          suggestor,
          'Action fn() {}',
          'Action fn() {}',
          importMode: WFluxImportMode.none,
        );
      });
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
    });

    group('TypeParameterMigrator', () {
      Suggestor suggestor() => ActionV2SuperTypeMigrator();

      group('ExtendsClause.superclass', () {
        testSuggestor(
          'standard import',
          suggestor,
          'class C extends Action {}',
          'class C extends ActionV2 {}',
        );
        testSuggestor(
          'prefixed import',
          suggestor,
          'class C extends w_flux.Action {}',
          'class C extends w_flux.ActionV2 {}',
          importMode: WFluxImportMode.prefixed,
        );
        testSuggestor(
          'ignore types not from w_flux',
          suggestor,
          'class C extends Action {}',
          'class C extends Action {}',
          importMode: WFluxImportMode.none,
        );
      });
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
