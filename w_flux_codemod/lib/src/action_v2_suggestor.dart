import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:codemod/codemod.dart';

mixin ActionV2Migrator on AstVisitingSuggestor {
  @override
  bool shouldResolveAst(_) => true;

  @override
  bool shouldSkip(FileContext context) =>
      !context.sourceText.contains('Action');
}

mixin ActionV2NamedTypeMigrator on ActionV2Migrator {
  bool shouldMigrate(dynamic node);

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
}

class ActionV2DispatchMigrator extends RecursiveAstVisitor
    with AstVisitingSuggestor, ActionV2Migrator {
  @override
  visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    final typeLibraryIdentifier =
        node.function.staticType?.element?.library?.identifier ?? '';
    final staticTypeName = node.function.staticType?.element?.name;
    if (typeLibraryIdentifier.startsWith('package:w_flux/') &&
        // The type migration should have happened prior to this suggestor.
        staticTypeName == 'ActionV2' &&
        node.argumentList.arguments.isEmpty) {
      yieldPatch('(null)', node.end - 2, node.end);
    }
    return super.visitFunctionExpressionInvocation(node);
  }
}

class ActionV2FieldAndVariableMigrator extends RecursiveAstVisitor
    with AstVisitingSuggestor, ActionV2Migrator, ActionV2NamedTypeMigrator {
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
    with AstVisitingSuggestor, ActionV2Migrator, ActionV2NamedTypeMigrator {
  @override
  bool shouldMigrate(node) {
    node as NamedType;
    return node.thisOrAncestorOfType<FormalParameter>() != null &&
        node.thisOrAncestorOfType<FieldFormalParameter>() == null;
  }
}

class ActionV2ReturnTypeMigrator extends RecursiveAstVisitor
    with AstVisitingSuggestor, ActionV2Migrator, ActionV2NamedTypeMigrator {
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
    with AstVisitingSuggestor, ActionV2Migrator, ActionV2NamedTypeMigrator {
  @override
  bool shouldMigrate(node) {
    node as NamedType;
    return node.parent is ExtendsClause ||
        node.parent is ImplementsClause ||
        node.parent is OnClause ||
        node.parent is TypeParameter;
  }
}
