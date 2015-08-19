library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  // https://github.com/Workiva/dart_dev

  // Perform task configuration here as necessary.
  List<String> dirs = ['example/', 'lib/', 'test/', 'tool/'];
  config.analyze.entryPoints = dirs;
  config.format.directories = dirs;

  await dev(args);
}
