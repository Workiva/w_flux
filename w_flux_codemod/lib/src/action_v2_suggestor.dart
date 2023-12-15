import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:codemod/codemod.dart';

mixin ActionV2Migrator on AstVisitingSuggestor {
  bool shouldMigrate(dynamic node);

  @override
  bool shouldResolveAst(_) => true;

  @override
  bool shouldSkip(FileContext context) =>
      !context.sourceText.contains('Action');

  @override
  visitNamedType(NamedType node) {
    if (shouldMigrate(node)) {
      final typeNameToken = node.name2;
      final typeLibraryIdentifier = node.element?.library?.identifier ?? '';
      if (typeNameToken.lexeme == 'Action' &&
          typeLibraryIdentifier.startsWith('package:w_flux/')) {
        yieldPatch('ActionV2', typeNameToken.offset, typeNameToken.end);
      }
    }
    return super.visitNamedType(node);
  }

  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    if (shouldMigrate(node)) {
      final typeLibraryIdentifier =
          node.function.staticType?.element?.library?.identifier ?? '';
      if (typeLibraryIdentifier.startsWith('package:w_flux/') &&
          node.argumentList.arguments.isEmpty) {
        yieldPatch('(null)', node.end - 2, node.end);
      }
    }
    return super.visitFunctionExpressionInvocation(node);
  }
}

/// TODO - will likely require overriding [visitInvocationExpression]
/// and checking the type of the thing being invoked to see if it's an Action
/// If it is and there are no arguments passed, need to pass in `null`
class ActionV2DispatchMigrator extends RecursiveAstVisitor
    with AstVisitingSuggestor, ActionV2Migrator {
  @override
  bool shouldMigrate(node) {
    if (node is FunctionExpressionInvocation) {
      final name = node.function.staticType?.element?.displayName;
      // the type migration should have happened prior to this suggestor.
      return name == 'ActionV2';
    }
    return false;
  }
}

class ActionV2FieldAndVariableMigrator extends RecursiveAstVisitor
    with AstVisitingSuggestor, ActionV2Migrator {
  @override
  bool shouldMigrate(node) {
    node as NamedType;
    return node.parent is DeclaredIdentifier ||
        node.parent is DeclaredVariablePattern ||
        node.parent is FieldFormalParameter ||
        node.parent is VariableDeclarationList ||
        node.thisOrAncestorOfType<ConstructorReference>() != null ||
        node.thisOrAncestorOfType<InstanceCreationExpression>() != null;
  }
}

class ActionV2ParameterMigrator extends RecursiveAstVisitor
    with AstVisitingSuggestor, ActionV2Migrator {
  @override
  bool shouldMigrate(node) {
    node as NamedType;
    return node.thisOrAncestorOfType<FormalParameter>() != null &&
        node.thisOrAncestorOfType<FieldFormalParameter>() == null;
  }
}

class ActionV2ReturnTypeMigrator extends RecursiveAstVisitor
    with AstVisitingSuggestor, ActionV2Migrator {
  @override
  shouldMigrate(node) {
    node as NamedType;
    return node.parent is FunctionDeclaration ||
        node.parent is FunctionTypeAlias ||
        node.parent is GenericFunctionType ||
        node.parent is MethodDeclaration;
  }
}

class ActionV2SuperTypeMigrator extends RecursiveAstVisitor
    with AstVisitingSuggestor, ActionV2Migrator {
  @override
  bool shouldMigrate(node) {
    node as NamedType;
    return node.parent is ExtendsClause ||
        node.parent is ImplementsClause ||
        node.parent is OnClause ||
        node.parent is TypeParameter;
  }
}