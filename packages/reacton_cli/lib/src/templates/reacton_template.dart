/// Template for generating a basic writable reacton file.
const reactonTemplate = r'''
import 'package:reacton/reacton.dart';

/// {{description}}
final {{name}}Reacton = reacton<{{type}}>(
  {{defaultValue}},
  name: '{{snakeName}}',
);
''';

/// Template for generating a computed reacton file.
const computedReactonTemplate = r'''
import 'package:reacton/reacton.dart';

{{imports}}

/// {{description}}
final {{name}}Reacton = computed<{{type}}>(
  (read) {
    {{body}}
  },
  name: '{{snakeName}}',
);
''';

/// Template for generating an async reacton file.
const asyncReactonTemplate = r'''
import 'package:reacton/reacton.dart';

/// {{description}}
final {{name}}Reacton = asyncReacton<{{type}}>(
  (read) async {
    // TODO: Implement async fetch logic
    {{body}}
  },
  name: '{{snakeName}}',
);
''';

/// Template for generating a selector reacton file.
const selectorReactonTemplate = r'''
import 'package:reacton/reacton.dart';

{{imports}}

/// {{description}}
final {{name}}Selector = selector<{{sourceType}}, {{type}}>(
  {{sourceReacton}},
  (value) => {{transform}},
  name: '{{snakeName}}',
);
''';

/// Template for generating a reacton family file.
const familyReactonTemplate = r'''
import 'package:reacton/reacton.dart';

/// {{description}}
final {{name}}Family = family<{{type}}, {{paramType}}>(
  (param) => reacton<{{type}}>(
    {{defaultValue}},
    name: '{{snakeName}}_$param',
  ),
);
''';
