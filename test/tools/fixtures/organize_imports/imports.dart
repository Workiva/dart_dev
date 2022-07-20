
const unorganizedImports1 = '''
import 'dart:html';
import 'dart:typed_data';
import 'dart:async';

void main() {
   // content
}
''';

const organizedImports1 = '''
import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

void main() {
   // content
}
''';

const unorganizedImports2 = '''
import 'package:over_react_format/a.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:over_react_format/b.dart';

void main() {
   // content
}
''';

const organizedImports2 = '''
import 'package:meta/meta.dart';
import 'package:over_react_format/a.dart';
import 'package:over_react_format/b.dart';
import 'package:test/test.dart';

void main() {
   // content
}
''';

const unorganizedImports3 = '''
import '../../test_utils/mocks/review_bar/review_bar.dart';
import '../../test_utils/mocks/network/skaar_client.dart';
import '../../test_utils/helpers/document_events.dart';
import '../../test_utils/mocks/html/html.dart';

void main() {
   // content
}
''';

const organizedImports3 = '''
import '../../test_utils/helpers/document_events.dart';
import '../../test_utils/mocks/html/html.dart';
import '../../test_utils/mocks/network/skaar_client.dart';
import '../../test_utils/mocks/review_bar/review_bar.dart';

void main() {
   // content
}
''';

const unorganizedImports4 = '''
import '../../test_utils/mocks/review_bar/review_bar.dart';
import 'dart:typed_data';
import 'dart:async';
import 'package:over_react_format/b.dart';
import '../../test_utils/mocks/network/skaar_client.dart';
import 'package:over_react_format/a.dart';
import 'package:meta/meta.dart';
import '../../test_utils/helpers/document_events.dart';
import 'package:test/test.dart';
import 'dart:html';
import '../../test_utils/mocks/html/html.dart';

void main() {
   // content
}
''';

const organizedImports4 = '''
import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:over_react_format/a.dart';
import 'package:over_react_format/b.dart';
import 'package:test/test.dart';

import '../../test_utils/helpers/document_events.dart';
import '../../test_utils/mocks/html/html.dart';
import '../../test_utils/mocks/network/skaar_client.dart';
import '../../test_utils/mocks/review_bar/review_bar.dart';

void main() {
   // content
}
''';

const unorganizedImports5 = '''
import 'dart:html';
import "../b.dart";
import "package:over_react_format/a.dart";
import '../a.dart';
import "dart:async";
import 'package:meta/meta.dart';

void main() {
   // content
}
''';

const organizedImports5 = '''
import 'dart:async';
import 'dart:html';

import 'package:meta/meta.dart';
import 'package:over_react_format/a.dart';

import '../a.dart';
import '../b.dart';

void main() {
   // content
}
''';

const unorganizedImports6 = '''
import '../b.dart';
import '../a.dart';

void main() {
  var import = 'import as a string';
}
''';

const organizedImports6 = '''
import '../a.dart';
import '../b.dart';

void main() {
  var import = 'import as a string';
}
''';

const unorganizedImports7 = '''
import 'dart:html';
import 'package:glob/your_really_really_really_really_really_really_really_long_import.dart'
    as shorty2;
import 'package:args/my_really_really_really_really_really_really_really_long_import.dart'
    as shorty;
import '../b.dart';

void main() {
  // content
}
''';

const organizedImports7 = '''
import 'dart:html';

import 'package:args/my_really_really_really_really_really_really_really_long_import.dart'
    as shorty;
import 'package:glob/your_really_really_really_really_really_really_really_long_import.dart'
    as shorty2;

import '../b.dart';

void main() {
  // content
}
''';

const unorganizedImports8 = '''
import 'package:glob/your_really_really_really_really_really_really_really_long_import.dart'
    as shorty2;
import 'package:args/my_really_really_really_really_really_really_really_long_import.dart'
    as shorty;

void main() {
  // content
}
''';

const organizedImports8 = '''
import 'package:args/my_really_really_really_really_really_really_really_long_import.dart'
    as shorty;
import 'package:glob/your_really_really_really_really_really_really_really_long_import.dart'
    as shorty2;

void main() {
  // content
}
''';

const unorganizedImports9 = '''
@TestOn('browser')
library my_cool_lib;

import 'dart:async';
import 'package:meta/meta.dart';
import '../a.dart';

void main() {
   // content
}
''';

const organizedImports9 = '''
@TestOn('browser')
library my_cool_lib;

import 'dart:async';

import 'package:meta/meta.dart';

import '../a.dart';

void main() {
   // content
}
''';

const unorganizedImports10 = '''
import 'package:glob/your_really_really_really_really_really_really_really_long_import.dart'
    show first, second, third;
import 'package:args/my_really_really_really_really_really_really_really_long_import.dart'
    hide cat, dog, fish;
import 'package:args/your_really_really_really_really_really_really_really_long_import_2.dart'
    show
        TextBlacklineExperienceConfig,
        TextProductExperienceConfig,
        TextReviewExperienceConfig,
        TextTranslateExperienceConfig;

void main() {
  // content
}
''';

const organizedImports10 = '''
import 'package:args/my_really_really_really_really_really_really_really_long_import.dart'
    hide cat, dog, fish;
import 'package:args/your_really_really_really_really_really_really_really_long_import_2.dart'
    show
        TextBlacklineExperienceConfig,
        TextProductExperienceConfig,
        TextReviewExperienceConfig,
        TextTranslateExperienceConfig;
import 'package:glob/your_really_really_really_really_really_really_really_long_import.dart'
    show first, second, third;

void main() {
  // content
}
''';

const unorganizedImports11 = '''
import 'dart:b.dart';
import 'dart:a.dart';

import 'package:args/b.dart';
import 'package:args/a.dart';

import '../b.dart';
import '../a.dart';

void main() {
  // content
}
''';

const organizedImports11 = '''
import 'dart:a.dart';
import 'dart:b.dart';

import 'package:args/a.dart';
import 'package:args/b.dart';

import '../a.dart';
import '../b.dart';

void main() {
  // content
}
''';

const unorganizedImports12 = '''
import 'package_things_b.dart';
import 'package:args/dart_stuff.dart';
import 'dart:b.dart';
import 'package_things_a.dart';
import 'dart_sync_mocks.dart';
import 'dart:a.dart';
import 'package:glob/dart_stuff.dart';
import 'dart_async_mocks.dart';

void main() {
  // content
}
''';

const organizedImports12 = '''
import 'dart:a.dart';
import 'dart:b.dart';

import 'package:args/dart_stuff.dart';
import 'package:glob/dart_stuff.dart';

import 'dart_async_mocks.dart';
import 'dart_sync_mocks.dart';
import 'package_things_a.dart';
import 'package_things_b.dart';

void main() {
  // content
}
''';

const unorganizedImports13 = '''
import 'package:args/src/datatable/import_event.dart' //ignore: implementation_imports
    show
        DatatableImportEventV1ActionType,
        DatatableImportEventV1ImportAs;
import 'dart:async'; // a comment here about async
import 'package:workiva_dart_dev/dart_dev_workiva.dart'
    show // comment
        TextBlacklineExperienceConfig,
        TextProductExperienceConfig, // comment
        TextReviewExperienceConfig, // comment
        TextTranslateExperienceConfig;

void main() {
  // content
}
''';

const organizedImports13 = '''
import 'dart:async'; // a comment here about async

import 'package:args/src/datatable/import_event.dart' //ignore: implementation_imports
    show
        DatatableImportEventV1ActionType,
        DatatableImportEventV1ImportAs;
import 'package:workiva_dart_dev/dart_dev_workiva.dart'
    show // comment
        TextBlacklineExperienceConfig,
        TextProductExperienceConfig, // comment
        TextReviewExperienceConfig, // comment
        TextTranslateExperienceConfig;

void main() {
  // content
}
''';

const unorganizedImports14 = '''
import 'package:args/src/datatable/import_event.dart'
    show
        DatatableImportEventV1ActionType,
        DatatableImportEventV1ImportAs; // trailing comment 2
import 'dart:async'; // trailing comment 1
import 'package:workiva_dart_dev/dart_dev_workiva.dart'
    show
        TextBlacklineExperienceConfig,
        TextProductExperienceConfig,
        TextReviewExperienceConfig,
        TextTranslateExperienceConfig; // trailing comment 3

void main() {
  // content
}
''';

const organizedImports14 = '''
import 'dart:async'; // trailing comment 1

import 'package:args/src/datatable/import_event.dart'
    show
        DatatableImportEventV1ActionType,
        DatatableImportEventV1ImportAs; // trailing comment 2
import 'package:workiva_dart_dev/dart_dev_workiva.dart'
    show
        TextBlacklineExperienceConfig,
        TextProductExperienceConfig,
        TextReviewExperienceConfig,
        TextTranslateExperienceConfig; // trailing comment 3

void main() {
  // content
}
''';

const unorganizedImports15 = '''
// a: comment 3
import 'package:args/src/datatable/import_event.dart'
    show
        DatatableImportEventV1ActionType,
        DatatableImportEventV1ImportAs;

// f: comment 5
import '../a.dart';
// b: comment 6
import '../b.dart';

// c: comment 2
import 'dart:html';

// d: comment 4
import 'package:workiva_dart_dev/dart_dev_workiva.dart'
    show
        TextBlacklineExperienceConfig,
        TextProductExperienceConfig,
        TextReviewExperienceConfig,
        TextTranslateExperienceConfig;

// e: comment 1
import 'dart:async';

// A comment describing main
void main() {
  // content
}
''';

const organizedImports15 = '''
// e: comment 1
import 'dart:async';
// c: comment 2
import 'dart:html';

// a: comment 3
import 'package:args/src/datatable/import_event.dart'
    show
        DatatableImportEventV1ActionType,
        DatatableImportEventV1ImportAs;
// d: comment 4
import 'package:workiva_dart_dev/dart_dev_workiva.dart'
    show
        TextBlacklineExperienceConfig,
        TextProductExperienceConfig,
        TextReviewExperienceConfig,
        TextTranslateExperienceConfig;

// f: comment 5
import '../a.dart';
// b: comment 6
import '../b.dart';

// A comment describing main
void main() {
  // content
}
''';

const unorganizedImports16 = '''
// comment 1

@TestOn('browser')

// comment 2

library my_cool_lib;


// comment 3

// comment 4
import 'dart:async';

// comment 7
// comment 8

import '../a.dart';

// comment 5

// comment 6

import 'package:meta/meta.dart';

// comment down here

void main() {
   // content
}
''';

const organizedImports16 = '''
// comment 1

@TestOn('browser')

// comment 2

library my_cool_lib;


// comment 3

// comment 4
import 'dart:async';

// comment 5

// comment 6

import 'package:meta/meta.dart';

// comment 7
// comment 8

import '../a.dart';

// comment down here

void main() {
   // content
}
''';

const unorganizedImports17 = '''
import 'dart:html';
import 'dart:typed_data';
import 'dart:async';

void main() {
  final import = 'not an import';
  import = 'oh this is definitely not an import!!!!';
}
''';

const organizedImports17 = '''
import 'dart:async';
import 'dart:html';
import 'dart:typed_data';

void main() {
  final import = 'not an import';
  import = 'oh this is definitely not an import!!!!';
}
''';

const unorganizedImports18 = '''
import 'package:args/src/datatable/import_event.dart'; //ignore: implementation_imports
import 'dart:async';
import 'package:workiva_dart_dev/dart_dev_workiva.dart';

void main() {
  // content
}
''';

const organizedImports18 = '''
import 'dart:async';

import 'package:args/src/datatable/import_event.dart'; //ignore: implementation_imports
import 'package:workiva_dart_dev/dart_dev_workiva.dart';

void main() {
  // content
}
''';

const unorganizedImports19 = '''
/* Multi-line comment 3 */
import 'dart:html';
/* Multi-line comment 4 */
/* 
Multi-line comment 5 
*/
import 'dart:typed_data';
/* 
 Multi-line comment 1
*/
/* Multi-line comment 2 */
import 'dart:async';

void main() {
   // content
}
''';

const organizedImports19 = '''
/* 
 Multi-line comment 1
*/
/* Multi-line comment 2 */
import 'dart:async';
/* Multi-line comment 3 */
import 'dart:html';
/* Multi-line comment 4 */
/* 
Multi-line comment 5 
*/
import 'dart:typed_data';

void main() {
   // content
}
''';

const unorganizedImports20 = '''
import 'dart:typed_data'; /* why 3 */ /* why 4 */
import 'dart:html'; /* why 1 */ /* why 2 */
import 'dart:async'; /* why would anyone do this? */

void main() {
   // content
}
''';

const organizedImports20 = '''
import 'dart:async'; /* why would anyone do this? */
import 'dart:html'; /* why 1 */ /* why 2 */
import 'dart:typed_data'; /* why 3 */ /* why 4 */

void main() {
   // content
}
''';

const unorganizedImports21 = '''
import 'b.dart'; import 'a.dart'; /* comment 1 */ /* comment 2 */
import 'package:meta/meta.dart'; import 'package:over_react_format/a.dart';
import 'dart:html'; import 'dart:async'; /* single comment */

void main() {
   // content
}
''';

const organizedImports21 = '''
import 'dart:async'; /* single comment */
import 'dart:html';

import 'package:meta/meta.dart';
import 'package:over_react_format/a.dart';

import 'a.dart'; /* comment 1 */ /* comment 2 */
import 'b.dart';

void main() {
   // content
}
''';

const unorganizedImports22 = '';

const organizedImports22 = '';

const unorganizedImports23 = '''
void main() {
  print('hello world');
}
''';

const organizedImports23 = '''
void main() {
  print('hello world');
}
''';

const unorganizedImports24 = '''
// comment 0
// comment 1
import 'b.dart'; /* comment 2 */ /* comment 3 */ import 'a.dart'; /* comment 4 */ // comment 5
// comment 6
import 'package:meta/meta.dart'; /* comment 7 */ import 'package:over_react_format/a.dart';
import 'dart:html'; import 'dart:async';

void main() {
   // content
}
''';

const organizedImports24 = '''
import 'dart:async';
import 'dart:html';

// comment 6
import 'package:meta/meta.dart'; /* comment 7 */
import 'package:over_react_format/a.dart';

import 'a.dart'; /* comment 4 */ // comment 5
// comment 0
// comment 1
import 'b.dart'; /* comment 2 */ /* comment 3 */

void main() {
   // content
}
''';


const unorganizedImports25 = '''
// Copyright 2019 Workiva Inc.
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

// The logging utility in this file was originally modeled after:
// https://github.com/dart-lang/build/blob/0e79b63c6387adbb7e7f4c4f88d572b1242d24df/build_runner/lib/src/logging/std_io_logging.dart

import 'dart:async';
import 'dart:io' as io;
import 'dart:convert' as convert;
''';

const organizedImports25 = '''
// Copyright 2019 Workiva Inc.
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

// The logging utility in this file was originally modeled after:
// https://github.com/dart-lang/build/blob/0e79b63c6387adbb7e7f4c4f88d572b1242d24df/build_runner/lib/src/logging/std_io_logging.dart

import 'dart:async';
import 'dart:convert' as convert;
import 'dart:io' as io;
''';
