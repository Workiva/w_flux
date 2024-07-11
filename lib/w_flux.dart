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

/// The w_flux library implements a uni-directional data flow pattern comprised
/// of [ActionV2]s, [Store]s, and [FluxComponent]s.
///
/// - [ActionV2]s initiate mutation of app data that resides in [Store]s.
/// - Data mutations within [Store]s trigger re-rendering of app view (defined
///   in [FluxComponent]s).
/// - [FluxComponent]s dispatch [ActionV2]s in response to user interaction.
library w_flux;

import 'src/action.dart';
import 'src/component_client.dart';
import 'src/store.dart';

export 'src/action.dart';
export 'src/component_client.dart';
export 'src/mixins/batched_redraws.dart';
export 'src/store.dart';
