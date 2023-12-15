library;

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

const wFluxImport = "import 'package:w_flux/w_flux.dart';";

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
      bool shouldImportWFlux = true,
      bool shouldMigrateVariablesAndFields = false,
    }) {
      test(description, () async {
        final context = await pkg.addFile('''
${shouldImportWFlux ? wFluxImport : ''}
${before}
''');
        final expectedOutput = '''
${shouldImportWFlux ? wFluxImport : ''}
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
        'Function Expression Invocation',
        suggestor,
        'class C { ActionV2 action; } void main() { C().action(); }',
        'class C { ActionV2 action; } void main() { C().action(null); }',
      );
      testSuggestor(
        'Function Expression Invocation type 2',
        suggestor,
        'void main() { var a = ActionV2(); a(); }',
        'void main() { var a = ActionV2(); a(null); }',
      );
    });

    group('FieldAndVariableMigrator', () {
      Suggestor suggestor() => ActionV2FieldAndVariableMigrator();
      group('VariableDeclarationList', () {
        testSuggestor(
          'with type, no intializer',
          suggestor,
          'Action<num> action;',
          'ActionV2<num> action;',
        );
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
          'skips dynamic Actions',
          suggestor,
          'Action a; Action b = Action(); var c = Action();',
          'Action a; Action b = Action(); var c = Action();',
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
    });

    group('TypeParameterMigrator', () {
      Suggestor suggestor() => ActionV2SuperTypeMigrator();
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
