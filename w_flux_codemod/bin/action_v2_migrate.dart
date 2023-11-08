import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:codemod/codemod.dart';
import 'package:glob/glob.dart';

void main(List<String> args) async {
  exitCode = await runInteractiveCodemod(
    filePathsFromGlob(Glob('**.dart', recursive: true)),
    ActionV2Suggestor(),
    args: args,
  );
}

class ActionV2Suggestor extends GeneralizingAstVisitor
    with AstVisitingSuggestor {
  @override
  bool shouldResolveAst(_) => true;

  @override
  visitSimpleFormalParameter(SimpleFormalParameter node) {
    final nodeType = node.type;
    final typeNameToken = nodeType is NamedType ? nodeType.name2 : null;
    if (typeNameToken != null) {
      final typeName =
          context.sourceFile.getText(typeNameToken.offset, typeNameToken.end);
      final identifier =
          node.declaredElement?.type.element?.library?.identifier;
      print(identifier);
      print(typeName);
      if (typeName == 'Action' &&
          identifier?.startsWith('package:w_flux/') == true) {
        yieldPatch('ActionV2', typeNameToken.offset, typeNameToken.end);
      }
    }
    return super.visitSimpleFormalParameter(node);
  }
}
