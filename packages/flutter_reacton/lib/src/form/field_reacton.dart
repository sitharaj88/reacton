import 'package:reacton/reacton.dart';
import 'validators.dart';

/// The state of a single form field.
class FieldState<T> {
  final T value;
  final String? error;
  final bool isDirty;
  final bool isTouched;
  final bool isValidating;

  const FieldState({
    required this.value,
    this.error,
    this.isDirty = false,
    this.isTouched = false,
    this.isValidating = false,
  });

  FieldState<T> copyWith({
    T? value,
    String? Function()? error,
    bool? isDirty,
    bool? isTouched,
    bool? isValidating,
  }) {
    return FieldState<T>(
      value: value ?? this.value,
      error: error != null ? error() : this.error,
      isDirty: isDirty ?? this.isDirty,
      isTouched: isTouched ?? this.isTouched,
      isValidating: isValidating ?? this.isValidating,
    );
  }

  bool get isValid => error == null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FieldState<T> &&
          value == other.value &&
          error == other.error &&
          isDirty == other.isDirty &&
          isTouched == other.isTouched &&
          isValidating == other.isValidating;

  @override
  int get hashCode => Object.hash(value, error, isDirty, isTouched, isValidating);
}

/// A reactive form field with validation, dirty tracking, and touch state.
///
/// ```dart
/// final emailField = reactonField<String>(
///   '',
///   validators: [required(), email()],
///   name: 'email',
/// );
/// ```
class FieldReacton<T> extends WritableReacton<FieldState<T>> {
  final List<Validator<T>> validators;
  final Future<String?> Function(T value)? asyncValidator;
  final T _initialFieldValue;

  FieldReacton(
    T initialValue, {
    this.validators = const [],
    this.asyncValidator,
    String? name,
    ReactonOptions<FieldState<T>>? options,
  })  : _initialFieldValue = initialValue,
        super(
          FieldState<T>(value: initialValue),
          name: name,
          options: options,
        );

  /// The initial value of this field (before any changes).
  T get initialFieldValue => _initialFieldValue;

  /// Synchronously validate the given value.
  String? validate(T value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }
}

/// Create a reactive form field.
///
/// ```dart
/// final emailField = reactonField<String>(
///   '',
///   validators: [required(), email()],
///   name: 'email',
/// );
/// ```
FieldReacton<T> reactonField<T>(
  T initialValue, {
  List<Validator<T>> validators = const [],
  Future<String?> Function(T value)? asyncValidator,
  String? name,
}) {
  return FieldReacton<T>(
    initialValue,
    validators: validators,
    asyncValidator: asyncValidator,
    name: name,
  );
}

/// Extension on [ReactonStore] for field operations.
extension ReactonStoreField on ReactonStore {
  /// Set a field's value with automatic validation and dirty tracking.
  void setFieldValue<T>(FieldReacton<T> field, T value) {
    final error = field.validate(value);
    set(field, FieldState<T>(
      value: value,
      error: error,
      isDirty: value != field.initialFieldValue,
      isTouched: get(field).isTouched,
    ));

    // Run async validation if provided
    if (error == null && field.asyncValidator != null) {
      set(field, get(field).copyWith(isValidating: true));
      field.asyncValidator!(value).then((asyncError) {
        // Only update if the value hasn't changed since
        if (get(field).value == value) {
          set(field, get(field).copyWith(
            error: () => asyncError,
            isValidating: false,
          ));
        }
      });
    }
  }

  /// Mark a field as touched (user has interacted with it).
  void touchField<T>(FieldReacton<T> field) {
    final current = get(field);
    if (!current.isTouched) {
      set(field, current.copyWith(isTouched: true));
    }
  }

  /// Reset a field to its initial state.
  void resetField<T>(FieldReacton<T> field) {
    set(field, FieldState<T>(value: field.initialFieldValue));
  }

  /// Get the current value of a field (convenience).
  T fieldValue<T>(FieldReacton<T> field) {
    return get(field).value;
  }

  /// Get the current error of a field (convenience).
  String? fieldError<T>(FieldReacton<T> field) {
    return get(field).error;
  }
}
