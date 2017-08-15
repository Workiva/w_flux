// Copyright 2015 Workiva Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

library tool.dev;

import 'package:dart_dev/dart_dev.dart' show dev, config;

main(List<String> args) async {
  // https://github.com/Workiva/dart_dev

  // Perform task configuration here as necessary.
  List<String> dirs = ['example/', 'lib/', 'test/', 'tool/'];
  config.analyze.entryPoints = dirs;
  config.analyze.strong = true;
  config.copyLicense.directories = dirs;
  config.coverage.pubServe = true;
  config.format.paths = dirs;
  config.test.platforms = ['vm', 'content-shell'];
  config.test.pubServe = true;

  await dev(args);
}
