import 'dart:io';

import 'package:codemod/codemod.dart';
import 'package:glob/glob.dart';
import 'package:w_flux_codemod/src/action_v2_suggestor.dart';
import 'package:w_flux_codemod/src/utils.dart';

void main(List<String> args) async {
  final dartPaths = filePathsFromGlob(Glob('**.dart', recursive: true));

  await pubGetForAllPackageRoots(dartPaths);
  exitCode = await runInteractiveCodemod(
    dartPaths,
    aggregate([
      ActionV2FieldAndVariableMigrator(),
      ActionV2ReturnTypeMigrator(),
      ActionV2SuperTypeMigrator(),
      ActionV2DispatchMigrator(),
      ActionV2ImportMigrator(),
    ]),
    args: args,
  );
}
