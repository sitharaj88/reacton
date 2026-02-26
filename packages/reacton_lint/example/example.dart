/// Example demonstrating the lint rules provided by reacton_lint.
///
/// reacton_lint ships three rules:
///
/// 1. `avoid_reacton_in_build` - Do not create reactons inside build().
/// 2. `avoid_read_in_build`    - Prefer context.watch() over context.read()
///                                inside build methods.
/// 3. `prefer_computed`        - Extract derived state into computed() when
///                                a build method watches 3+ reactons.
///
/// ## Setup
///
/// Add to `pubspec.yaml`:
/// ```yaml
/// dev_dependencies:
///   reacton_lint: ^0.1.0
///   custom_lint: ^0.7.0
/// ```
///
/// Add to `analysis_options.yaml`:
/// ```yaml
/// analyzer:
///   plugins:
///     - custom_lint
/// ```
///
/// ## Bad patterns (these trigger warnings):
///
/// ```dart
/// class MyWidget extends StatelessWidget {
///   Widget build(BuildContext context) {
///     // BAD: avoid_reacton_in_build
///     final counter = reacton(0);
///
///     // BAD: avoid_read_in_build
///     final value = context.read(someReacton);
///
///     // BAD: prefer_computed (watching 3+ reactons inline)
///     final a = context.watch(reactonA);
///     final b = context.watch(reactonB);
///     final c = context.watch(reactonC);
///     final result = a + b + c;
///
///     return Text('$result');
///   }
/// }
/// ```
///
/// ## Good patterns:
///
/// ```dart
/// // Declare reactons at top level.
/// final counter = reacton(0);
/// final sum = computed((read) => read(reactonA) + read(reactonB) + read(reactonC));
///
/// class MyWidget extends StatelessWidget {
///   Widget build(BuildContext context) {
///     final value = context.watch(sum); // single watch
///     return Text('$value');
///   }
/// }
/// ```
void main() {
  print('reacton_lint - custom lint rules for Reacton');
  print('');
  print('Rules:');
  print('  avoid_reacton_in_build  Do not create reactons in build()');
  print('  avoid_read_in_build     Use context.watch() in build methods');
  print('  prefer_computed         Extract derived state into computed()');
}
