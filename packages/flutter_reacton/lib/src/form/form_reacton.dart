import 'package:flutter/widgets.dart';
import 'package:reacton/reacton.dart';
import '../widgets/reacton_scope.dart';
import 'field_reacton.dart';

/// The state of an entire form.
class FormState {
  final bool isSubmitting;
  final bool isSubmitted;
  final String? submitError;
  final int submitCount;

  const FormState({
    this.isSubmitting = false,
    this.isSubmitted = false,
    this.submitError,
    this.submitCount = 0,
  });

  FormState copyWith({
    bool? isSubmitting,
    bool? isSubmitted,
    String? Function()? submitError,
    int? submitCount,
  }) {
    return FormState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      submitError: submitError != null ? submitError() : this.submitError,
      submitCount: submitCount ?? this.submitCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FormState &&
          isSubmitting == other.isSubmitting &&
          isSubmitted == other.isSubmitted &&
          submitError == other.submitError &&
          submitCount == other.submitCount;

  @override
  int get hashCode => Object.hash(isSubmitting, isSubmitted, submitError, submitCount);
}

/// A reactive form that manages a group of field reactons.
///
/// ```dart
/// final loginForm = reactonForm(
///   fields: {
///     'email': reactonField<String>('', validators: [required(), email()]),
///     'password': reactonField<String>('', validators: [required(), minLength(8)]),
///   },
///   name: 'loginForm',
/// );
/// ```
class FormReacton extends WritableReacton<FormState> {
  final Map<String, FieldReacton> fields;

  FormReacton({
    required this.fields,
    String? name,
  }) : super(const FormState(), name: name);
}

/// Create a reactive form.
FormReacton reactonForm({
  required Map<String, FieldReacton> fields,
  String? name,
}) {
  return FormReacton(fields: fields, name: name);
}

/// Extension on [ReactonStore] for form operations.
extension ReactonStoreForm on ReactonStore {
  /// Check if all fields in a form are valid.
  bool isFormValid(FormReacton form) {
    for (final field in form.fields.values) {
      final state = get(field);
      if (state.error != null) return false;
    }
    return true;
  }

  /// Validate all fields in the form. Returns true if all valid.
  bool validateForm(FormReacton form) {
    var allValid = true;
    batch(() {
      for (final field in form.fields.values) {
        final state = get(field);
        final error = field.validate(state.value);
        if (error != null) allValid = false;
        set(field, state.copyWith(
          error: () => error,
          isTouched: true,
        ));
      }
    });
    return allValid;
  }

  /// Submit a form with a handler function.
  ///
  /// Validates all fields first. If valid, calls onValid with
  /// a map of field names to their values.
  Future<void> submitForm(
    FormReacton form, {
    required Future<void> Function(Map<String, dynamic> values) onValid,
    void Function(String error)? onError,
  }) async {
    // Validate all fields
    if (!validateForm(form)) {
      onError?.call('Form has validation errors');
      return;
    }

    // Set submitting state
    final currentState = get(form);
    set(form, currentState.copyWith(
      isSubmitting: true,
      submitError: () => null,
    ));

    try {
      // Collect values
      final values = <String, dynamic>{};
      for (final entry in form.fields.entries) {
        values[entry.key] = get(entry.value).value;
      }

      await onValid(values);

      set(form, get(form).copyWith(
        isSubmitting: false,
        isSubmitted: true,
        submitCount: get(form).submitCount + 1,
      ));
    } catch (e) {
      set(form, get(form).copyWith(
        isSubmitting: false,
        submitError: () => e.toString(),
      ));
      onError?.call(e.toString());
    }
  }

  /// Reset all fields in the form to their initial values.
  void resetForm(FormReacton form) {
    batch(() {
      for (final field in form.fields.values) {
        resetField(field);
      }
      set(form, const FormState());
    });
  }

  /// Touch all fields (useful before form submission to show all errors).
  void touchAllFields(FormReacton form) {
    batch(() {
      for (final field in form.fields.values) {
        touchField(field);
      }
    });
  }

  /// Check if any field in the form has been modified.
  bool isFormDirty(FormReacton form) {
    for (final field in form.fields.values) {
      if (get(field).isDirty) return true;
    }
    return false;
  }

  /// Get a specific field from a form by name.
  FieldReacton<T> formField<T>(FormReacton form, String fieldName) {
    final field = form.fields[fieldName];
    if (field == null) {
      throw StateError('Field "$fieldName" not found in form "${form.ref}"');
    }
    return field as FieldReacton<T>;
  }
}

/// Extension on BuildContext for convenient form field access.
extension ReactonFormBuildContextExtension on BuildContext {
  /// Watch a specific field in a form and get its current state.
  FieldState<T> watchField<T>(FormReacton form, String fieldName) {
    final field = form.fields[fieldName] as FieldReacton<T>;
    // Use the existing watch infrastructure from build_context_ext.dart
    // We need to import and call the extension method
    final store = ReactonScope.of(this);
    return store.get(field);
  }
}
