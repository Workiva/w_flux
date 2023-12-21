import 'dart:io';

import 'package:codemod/codemod.dart';
import 'package:logging/logging.dart';
import 'package:glob/glob.dart';
import 'package:w_flux_codemod/src/action_v2_suggestor.dart';
import 'package:w_flux_codemod/src/utils.dart';

final _log = Logger('orcm.required_flux_props');

Future<void> pubGetForAllPackageRoots(Iterable<String> files) async {
  _log.info(
      'Running `pub get` if needed so that all Dart files can be resolved...');
  final packageRoots = files.map(findPackageRootFor).toSet();
  for (final packageRoot in packageRoots) {
    await runPubGetIfNeeded(packageRoot);
  }
}

void main(List<String> args) async {
  final dartPaths = filePathsFromGlob(Glob('**.dart', recursive: true));

  await pubGetForAllPackageRoots(dartPaths);
  exitCode = await runInteractiveCodemod(
    dartPaths,
    aggregate([
      ActionV2ParameterMigrator(),
      ActionV2FieldAndVariableMigrator(),
      ActionV2ReturnTypeMigrator(),
      ActionV2SuperTypeMigrator(),
      ActionV2ImportMigrator(),
    ]),
    args: args,
  );
  if (exitCode != 0) {
    return;
  }
  exitCode = await runInteractiveCodemod(
    dartPaths,
    ActionV2DispatchMigrator(),
    args: args,
  );
}
