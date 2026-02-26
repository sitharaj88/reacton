import 'reacton_base.dart';
import 'readonly_reacton.dart';

/// A selector reacton that watches a sub-value of another reacton.
///
/// Only triggers rebuilds when the selected sub-value actually changes,
/// providing fine-grained reactivity for complex state objects.
///
/// ```dart
/// final userNameReacton = selector(
///   userReacton,
///   (user) => user.name,
///   name: 'userName',
/// );
/// ```
class SelectorReacton<T, S> extends ReadonlyReacton<S> {
  /// The source reacton being selected from.
  final ReactonBase<T> source;

  /// The selector function that extracts the sub-value.
  final S Function(T) select;

  SelectorReacton(
    this.source,
    this.select, {
    String? name,
    ReactonOptions<S>? options,
  }) : super(
          (read) => select(read(source)),
          name: name,
          options: options,
        );
}

/// Create a selector reacton that watches a sub-value of another reacton.
///
/// Only triggers updates when the selected value actually changes.
///
/// ```dart
/// final userNameReacton = selector(userReacton, (user) => user.name);
/// ```
SelectorReacton<T, S> selector<T, S>(
  ReactonBase<T> source,
  S Function(T) select, {
  String? name,
  ReactonOptions<S>? options,
}) {
  return SelectorReacton<T, S>(source, select, name: name, options: options);
}
