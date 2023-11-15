import 'dart:io';

import 'package:codemod/codemod.dart';
import 'package:glob/glob.dart';
import 'package:w_flux_codemod/src/action_v2_suggestor.dart';

void main(List<String> args) async {
  exitCode = await runInteractiveCodemod(
    filePathsFromGlob(Glob('**.dart', recursive: true)),
    aggregate([
      ActionV2FieldAndVariableMigrator(),
      ActionV2ReturnTypeMigrator(),
      ActionV2SuperTypeMigrator(),
    ]),
    args: args,
  );
}
