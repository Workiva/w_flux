import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:codemod/codemod.dart';

mixin ActionV2Migrator on AstVisitingSuggestor {
  bool shouldMigrate(NamedType node);

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
  visitInvocationExpression(InvocationExpression node) {
    if (shouldMigrate(node)) {
      for (var arg in node.argumentList.arguments) {
        final typeLibraryIdentifier =
            arg.staticType.element?.library?.identifier ?? '';
        if (arg.staticParameterElement.name == 'Action' &&
            typeLibraryIdentifier.startsWith('package:w_flux/')) {
          if (arg.staticParameterElement.parameters.isEmpty) {
            yieldPatch('ActionV2(null)', arg.offset, arg.end);
          } else {
            yieldPatch('ActionV2', arg.offset, arg.end);
          }
        }
      }
    }
    return super.visitInvocationExpression(node);
  }
}

/// TODO - will likely require overriding [visitInvocationExpression]
/// and checking the type of the thing being invoked to see if it's an Action
/// If it is and there are no arguments passed, need to pass in `null`
class ActionV2DispatchMigrator extends RecursiveAstVisitor
    with AstVisitingSuggestor, ActionV2Migrator {
  @override
  bool shouldMigrate(InvocationExpression node) =>
      node.staticInvokeType != null &&
      node.argumentList.arguments.isNotEmpty &&
      node.function.staticParameterElement.name == 'dispatch';
}

class ActionV2FieldAndVariableMigrator extends RecursiveAstVisitor
    with AstVisitingSuggestor, ActionV2Migrator {
  @override
  bool shouldMigrate(NamedType node) =>
      node.parent is DeclaredIdentifier ||
      node.parent is DeclaredVariablePattern ||
      node.parent is FieldFormalParameter ||
      node.parent is VariableDeclarationList ||
      node.thisOrAncestorOfType<ConstructorReference>() != null ||
      node.thisOrAncestorOfType<InstanceCreationExpression>() != null;
}

class ActionV2ParameterMigrator extends RecursiveAstVisitor
    with AstVisitingSuggestor, ActionV2Migrator {
  @override
  bool shouldMigrate(NamedType node) =>
      node.thisOrAncestorOfType<FormalParameter>() != null &&
      node.thisOrAncestorOfType<FieldFormalParameter>() == null;
}

class ActionV2ReturnTypeMigrator extends RecursiveAstVisitor
    with AstVisitingSuggestor, ActionV2Migrator {
  @override
  bool shouldMigrate(NamedType node) =>
      node.parent is FunctionDeclaration ||
      node.parent is FunctionTypeAlias ||
      node.parent is GenericFunctionType ||
      node.parent is MethodDeclaration;
}

class ActionV2SuperTypeMigrator extends RecursiveAstVisitor
    with AstVisitingSuggestor, ActionV2Migrator {
  @override
  bool shouldMigrate(NamedType node) =>
      node.parent is ExtendsClause ||
      node.parent is ImplementsClause ||
      node.parent is OnClause ||
      node.parent is TypeParameter;
}
