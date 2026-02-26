import 'package:flutter_test/flutter_test.dart' hide matches;
import 'package:flutter_reacton/flutter_reacton.dart';

void main() {
  // =========================================================================
  // Built-in Validators
  // =========================================================================
  group('Validators', () {
    group('required()', () {
      test('returns error for empty string', () {
        final validator = required();
        expect(validator(''), isNotNull);
        expect(validator(''), 'This field is required');
      });

      test('returns null for non-empty string', () {
        final validator = required();
        expect(validator('hello'), isNull);
      });

      test('custom error message', () {
        final validator = required(message: 'Please fill this in');
        expect(validator(''), 'Please fill this in');
      });
    });

    group('minLength()', () {
      test('returns error when too short', () {
        final validator = minLength(5);
        expect(validator('abc'), isNotNull);
        expect(validator('abc'), 'Must be at least 5 characters');
      });

      test('returns null when exactly min length', () {
        final validator = minLength(3);
        expect(validator('abc'), isNull);
      });

      test('returns null when longer than min', () {
        final validator = minLength(3);
        expect(validator('abcdef'), isNull);
      });

      test('custom error message', () {
        final validator = minLength(5, message: 'Too short!');
        expect(validator('ab'), 'Too short!');
      });

      test('empty string fails', () {
        final validator = minLength(1);
        expect(validator(''), isNotNull);
      });
    });

    group('maxLength()', () {
      test('returns error when too long', () {
        final validator = maxLength(3);
        expect(validator('abcdef'), isNotNull);
        expect(validator('abcdef'), 'Must be at most 3 characters');
      });

      test('returns null when exactly max length', () {
        final validator = maxLength(3);
        expect(validator('abc'), isNull);
      });

      test('returns null when shorter than max', () {
        final validator = maxLength(5);
        expect(validator('ab'), isNull);
      });

      test('custom error message', () {
        final validator = maxLength(3, message: 'Too long!');
        expect(validator('abcdef'), 'Too long!');
      });

      test('empty string passes', () {
        final validator = maxLength(10);
        expect(validator(''), isNull);
      });
    });

    group('email()', () {
      test('returns null for valid emails', () {
        final validator = email();
        expect(validator('user@example.com'), isNull);
        expect(validator('user.name@domain.co'), isNull);
        expect(validator('user-name@sub.domain.org'), isNull);
      });

      test('returns error for invalid emails', () {
        final validator = email();
        expect(validator('not-an-email'), isNotNull);
        expect(validator('missing@'), isNotNull);
        expect(validator('@domain.com'), isNotNull);
      });

      test('returns null for empty string (not required)', () {
        final validator = email();
        expect(validator(''), isNull);
      });

      test('custom error message', () {
        final validator = email(message: 'Bad email');
        expect(validator('invalid'), 'Bad email');
      });
    });

    group('pattern()', () {
      test('returns null when pattern matches', () {
        final validator = pattern(RegExp(r'^\d{3}$'));
        expect(validator('123'), isNull);
      });

      test('returns error when pattern does not match', () {
        final validator = pattern(RegExp(r'^\d{3}$'));
        expect(validator('abc'), isNotNull);
        expect(validator('12'), isNotNull);
        expect(validator('1234'), isNotNull);
      });

      test('returns null for empty string (not required)', () {
        final validator = pattern(RegExp(r'^\d+$'));
        expect(validator(''), isNull);
      });

      test('custom error message', () {
        final validator = pattern(RegExp(r'^\d+$'), message: 'Numbers only');
        expect(validator('abc'), 'Numbers only');
      });
    });

    group('range()', () {
      test('returns null for value within range', () {
        final validator = range(1, 10);
        expect(validator(5), isNull);
      });

      test('returns null for value at min boundary', () {
        final validator = range(1, 10);
        expect(validator(1), isNull);
      });

      test('returns null for value at max boundary', () {
        final validator = range(1, 10);
        expect(validator(10), isNull);
      });

      test('returns error for value below range', () {
        final validator = range(1, 10);
        expect(validator(0), isNotNull);
        expect(validator(0), 'Must be between 1 and 10');
      });

      test('returns error for value above range', () {
        final validator = range(1, 10);
        expect(validator(11), isNotNull);
      });

      test('custom error message', () {
        final validator = range(0, 100, message: 'Out of bounds');
        expect(validator(-1), 'Out of bounds');
      });

      test('works with double values', () {
        final validator = range(0.0, 1.0);
        expect(validator(0.5), isNull);
        expect(validator(1.5), isNotNull);
      });
    });

    group('matches()', () {
      test('returns null when values match', () {
        final validator = matches(() => 'password123');
        expect(validator('password123'), isNull);
      });

      test('returns error when values do not match', () {
        final validator = matches(() => 'password123');
        expect(validator('different'), isNotNull);
        expect(validator('different'), 'Values do not match');
      });

      test('custom error message', () {
        final validator = matches(
          () => 'a',
          message: 'Passwords must match',
        );
        expect(validator('b'), 'Passwords must match');
      });
    });

    group('compose()', () {
      test('returns null when all validators pass', () {
        final validator = compose<String>([
          required(),
          minLength(3),
          maxLength(10),
        ]);
        expect(validator('hello'), isNull);
      });

      test('returns first error from failing validator', () {
        final validator = compose<String>([
          required(),
          minLength(5),
          maxLength(3),
        ]);
        // Empty string fails 'required' first
        expect(validator(''), 'This field is required');
      });

      test('returns second validator error if first passes', () {
        final validator = compose<String>([
          required(),
          minLength(10),
        ]);
        expect(validator('short'), 'Must be at least 10 characters');
      });

      test('empty validators list always passes', () {
        final validator = compose<String>([]);
        expect(validator('anything'), isNull);
      });
    });
  });

  // =========================================================================
  // FieldState
  // =========================================================================
  group('FieldState', () {
    test('default state has no error, not dirty, not touched', () {
      const state = FieldState<String>(value: '');
      expect(state.value, '');
      expect(state.error, isNull);
      expect(state.isDirty, isFalse);
      expect(state.isTouched, isFalse);
      expect(state.isValidating, isFalse);
      expect(state.isValid, isTrue);
    });

    test('isValid is false when error is set', () {
      const state = FieldState<String>(value: '', error: 'Required');
      expect(state.isValid, isFalse);
    });

    test('copyWith updates value', () {
      const state = FieldState<String>(value: 'old');
      final updated = state.copyWith(value: 'new');
      expect(updated.value, 'new');
      expect(updated.error, isNull);
    });

    test('copyWith updates error with closure', () {
      const state = FieldState<String>(value: '');
      final updated = state.copyWith(error: () => 'Error occurred');
      expect(updated.error, 'Error occurred');
    });

    test('copyWith clears error with null closure', () {
      const state = FieldState<String>(value: '', error: 'Old error');
      final updated = state.copyWith(error: () => null);
      expect(updated.error, isNull);
    });

    test('copyWith preserves unmodified fields', () {
      const state = FieldState<String>(
        value: 'test',
        error: 'err',
        isDirty: true,
        isTouched: true,
        isValidating: true,
      );
      final updated = state.copyWith(value: 'new');
      expect(updated.error, 'err');
      expect(updated.isDirty, isTrue);
      expect(updated.isTouched, isTrue);
      expect(updated.isValidating, isTrue);
    });

    test('equality compares all fields', () {
      const a = FieldState<String>(value: 'x', isDirty: true);
      const b = FieldState<String>(value: 'x', isDirty: true);
      const c = FieldState<String>(value: 'y', isDirty: true);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode is consistent with equality', () {
      const a = FieldState<String>(value: 'x', isDirty: true);
      const b = FieldState<String>(value: 'x', isDirty: true);

      expect(a.hashCode, b.hashCode);
    });
  });

  // =========================================================================
  // FieldReacton
  // =========================================================================
  group('FieldReacton', () {
    test('creates with initial value and empty validators', () {
      final field = reactonField<String>('', name: 'email');
      expect(field.initialValue.value, '');
      expect(field.validators, isEmpty);
      expect(field.ref.debugName, 'email');
    });

    test('creates with validators', () {
      final field = reactonField<String>(
        '',
        validators: [required(), minLength(3)],
        name: 'username',
      );
      expect(field.validators, hasLength(2));
    });

    test('validate runs all validators and returns first error', () {
      final field = reactonField<String>(
        '',
        validators: [required(), minLength(5)],
      );

      expect(field.validate(''), 'This field is required');
      expect(field.validate('ab'), 'Must be at least 5 characters');
      expect(field.validate('hello'), isNull);
    });

    test('validate with no validators always returns null', () {
      final field = reactonField<String>('');
      expect(field.validate(''), isNull);
      expect(field.validate('anything'), isNull);
    });

    test('initialFieldValue returns the original value', () {
      final field = reactonField<String>('initial');
      expect(field.initialFieldValue, 'initial');
    });

    test('initialValue is a FieldState wrapping the initial value', () {
      final field = reactonField<int>(42);
      expect(field.initialValue, isA<FieldState<int>>());
      expect(field.initialValue.value, 42);
    });
  });

  // =========================================================================
  // ReactonStoreField extension
  // =========================================================================
  group('ReactonStoreField extension', () {
    late ReactonStore store;

    setUp(() {
      store = ReactonStore();
    });

    test('setFieldValue updates value and validates', () {
      final field = reactonField<String>(
        '',
        validators: [required()],
        name: 'sf_validate',
      );

      store.setFieldValue(field, 'hello');

      final state = store.get(field);
      expect(state.value, 'hello');
      expect(state.error, isNull);
      expect(state.isDirty, isTrue);
    });

    test('setFieldValue sets error when validation fails', () {
      final field = reactonField<String>(
        '',
        validators: [required()],
        name: 'sf_error',
      );

      store.setFieldValue(field, '');

      final state = store.get(field);
      expect(state.value, '');
      expect(state.error, 'This field is required');
    });

    test('setFieldValue tracks dirty state based on initial value', () {
      final field = reactonField<String>('original', name: 'sf_dirty');

      store.setFieldValue(field, 'changed');
      expect(store.get(field).isDirty, isTrue);

      store.setFieldValue(field, 'original');
      expect(store.get(field).isDirty, isFalse);
    });

    test('touchField marks field as touched', () {
      final field = reactonField<String>('', name: 'sf_touch');

      expect(store.get(field).isTouched, isFalse);

      store.touchField(field);
      expect(store.get(field).isTouched, isTrue);
    });

    test('touchField is idempotent', () {
      final field = reactonField<String>('', name: 'sf_touch_idem');

      store.touchField(field);
      store.touchField(field);
      expect(store.get(field).isTouched, isTrue);
    });

    test('setFieldValue preserves touched state', () {
      final field = reactonField<String>('', name: 'sf_touch_preserve');

      store.touchField(field);
      store.setFieldValue(field, 'new value');

      expect(store.get(field).isTouched, isTrue);
    });

    test('resetField resets to initial state', () {
      final field = reactonField<String>(
        'initial',
        validators: [required()],
        name: 'sf_reset',
      );

      store.setFieldValue(field, 'changed');
      store.touchField(field);

      store.resetField(field);

      final state = store.get(field);
      expect(state.value, 'initial');
      expect(state.error, isNull);
      expect(state.isDirty, isFalse);
      expect(state.isTouched, isFalse);
    });

    test('fieldValue returns the current value', () {
      final field = reactonField<String>('hello', name: 'sf_fieldval');
      expect(store.fieldValue(field), 'hello');
    });

    test('fieldError returns current error', () {
      final field = reactonField<String>(
        '',
        validators: [required()],
        name: 'sf_fielderr',
      );

      expect(store.fieldError(field), isNull);

      store.setFieldValue(field, '');
      expect(store.fieldError(field), 'This field is required');
    });
  });

  // =========================================================================
  // FormState
  // =========================================================================
  group('FormState', () {
    test('default state', () {
      const state = FormState();
      expect(state.isSubmitting, isFalse);
      expect(state.isSubmitted, isFalse);
      expect(state.submitError, isNull);
      expect(state.submitCount, 0);
    });

    test('copyWith updates fields', () {
      const state = FormState();
      final updated = state.copyWith(
        isSubmitting: true,
        submitCount: 1,
      );
      expect(updated.isSubmitting, isTrue);
      expect(updated.submitCount, 1);
    });

    test('copyWith clears submitError', () {
      const state = FormState(submitError: 'old error');
      final updated = state.copyWith(submitError: () => null);
      expect(updated.submitError, isNull);
    });

    test('equality', () {
      const a = FormState(isSubmitting: true);
      const b = FormState(isSubmitting: true);
      const c = FormState(isSubmitting: false);

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode consistency', () {
      const a = FormState(submitCount: 3);
      const b = FormState(submitCount: 3);
      expect(a.hashCode, b.hashCode);
    });
  });

  // =========================================================================
  // FormReacton
  // =========================================================================
  group('FormReacton', () {
    test('creates with fields', () {
      final emailField = reactonField<String>('', name: 'form_email');
      final passField = reactonField<String>('', name: 'form_pass');

      final form = reactonForm(
        fields: {'email': emailField, 'password': passField},
        name: 'loginForm',
      );

      expect(form.fields, hasLength(2));
      expect(form.fields.containsKey('email'), isTrue);
      expect(form.fields.containsKey('password'), isTrue);
      expect(form.ref.debugName, 'loginForm');
    });

    test('initial form state is default FormState', () {
      final form = reactonForm(
        fields: {'name': reactonField<String>('')},
      );

      expect(form.initialValue, const FormState());
    });
  });

  // =========================================================================
  // ReactonStoreForm extension
  // =========================================================================
  group('ReactonStoreForm extension', () {
    late ReactonStore store;
    late FieldReacton<String> emailField;
    late FieldReacton<String> passwordField;
    late FormReacton form;

    setUp(() {
      store = ReactonStore();
      emailField = reactonField<String>(
        '',
        validators: [required(), email()],
        name: 'form_test_email',
      );
      passwordField = reactonField<String>(
        '',
        validators: [required(), minLength(8)],
        name: 'form_test_pass',
      );
      form = reactonForm(
        fields: {'email': emailField, 'password': passwordField},
        name: 'form_test',
      );
    });

    group('isFormValid', () {
      test('returns true when all fields have no errors', () {
        // Initialize fields (default state has no error)
        store.get(emailField);
        store.get(passwordField);
        expect(store.isFormValid(form), isTrue);
      });

      test('returns false when a field has an error', () {
        store.setFieldValue(emailField, ''); // triggers required error
        expect(store.isFormValid(form), isFalse);
      });

      test('returns true when all fields pass validation', () {
        store.setFieldValue(emailField, 'user@test.com');
        store.setFieldValue(passwordField, 'password123');
        expect(store.isFormValid(form), isTrue);
      });
    });

    group('validateForm', () {
      test('validates all fields and returns true when valid', () {
        store.setFieldValue(emailField, 'user@test.com');
        store.setFieldValue(passwordField, 'password123');

        final result = store.validateForm(form);
        expect(result, isTrue);
      });

      test('validates all fields and returns false when invalid', () {
        // Leave fields at initial empty values
        store.get(emailField);
        store.get(passwordField);

        final result = store.validateForm(form);
        expect(result, isFalse);
      });

      test('marks all fields as touched after validation', () {
        store.get(emailField);
        store.get(passwordField);

        store.validateForm(form);

        expect(store.get(emailField).isTouched, isTrue);
        expect(store.get(passwordField).isTouched, isTrue);
      });

      test('sets validation errors on fields', () {
        store.get(emailField);
        store.get(passwordField);

        store.validateForm(form);

        // Both fields are empty, so required validator fires
        expect(store.get(emailField).error, 'This field is required');
        expect(store.get(passwordField).error, 'This field is required');
      });

      test('clears errors on valid fields', () {
        store.setFieldValue(emailField, 'user@test.com');
        store.setFieldValue(passwordField, 'password123');

        store.validateForm(form);

        expect(store.get(emailField).error, isNull);
        expect(store.get(passwordField).error, isNull);
      });
    });

    group('submitForm', () {
      test('calls onValid with field values when form is valid', () async {
        store.setFieldValue(emailField, 'user@test.com');
        store.setFieldValue(passwordField, 'securepass');

        Map<String, dynamic>? receivedValues;

        await store.submitForm(
          form,
          onValid: (values) async {
            receivedValues = values;
          },
        );

        expect(receivedValues, isNotNull);
        expect(receivedValues!['email'], 'user@test.com');
        expect(receivedValues!['password'], 'securepass');
      });

      test('does not call onValid when form is invalid', () async {
        store.get(emailField);
        store.get(passwordField);

        var onValidCalled = false;

        await store.submitForm(
          form,
          onValid: (values) async {
            onValidCalled = true;
          },
        );

        expect(onValidCalled, isFalse);
      });

      test('calls onError when form is invalid', () async {
        store.get(emailField);
        store.get(passwordField);

        String? receivedError;

        await store.submitForm(
          form,
          onValid: (values) async {},
          onError: (error) {
            receivedError = error;
          },
        );

        expect(receivedError, 'Form has validation errors');
      });

      test('sets isSubmitting during submission', () async {
        store.setFieldValue(emailField, 'user@test.com');
        store.setFieldValue(passwordField, 'password123');

        var wasSubmitting = false;

        await store.submitForm(
          form,
          onValid: (values) async {
            wasSubmitting = store.get(form).isSubmitting;
          },
        );

        expect(wasSubmitting, isTrue);
        // After submission completes, isSubmitting should be false
        expect(store.get(form).isSubmitting, isFalse);
      });

      test('sets isSubmitted after successful submission', () async {
        store.setFieldValue(emailField, 'user@test.com');
        store.setFieldValue(passwordField, 'password123');

        await store.submitForm(
          form,
          onValid: (values) async {},
        );

        expect(store.get(form).isSubmitted, isTrue);
      });

      test('increments submitCount after successful submission', () async {
        store.setFieldValue(emailField, 'user@test.com');
        store.setFieldValue(passwordField, 'password123');

        await store.submitForm(form, onValid: (values) async {});
        expect(store.get(form).submitCount, 1);
      });

      test('sets submitError when onValid throws', () async {
        store.setFieldValue(emailField, 'user@test.com');
        store.setFieldValue(passwordField, 'password123');

        String? receivedError;

        await store.submitForm(
          form,
          onValid: (values) async {
            throw Exception('Server error');
          },
          onError: (error) {
            receivedError = error;
          },
        );

        expect(store.get(form).submitError, contains('Server error'));
        expect(store.get(form).isSubmitting, isFalse);
        expect(receivedError, contains('Server error'));
      });

      test('does not increment submitCount when onValid throws', () async {
        store.setFieldValue(emailField, 'user@test.com');
        store.setFieldValue(passwordField, 'password123');

        await store.submitForm(
          form,
          onValid: (values) async {
            throw Exception('fail');
          },
          onError: (_) {},
        );

        expect(store.get(form).submitCount, 0);
      });
    });

    group('resetField (typed)', () {
      test('resets individual fields to initial values', () {
        store.setFieldValue(emailField, 'user@test.com');
        store.setFieldValue(passwordField, 'password123');
        store.touchField(emailField);

        store.resetField(emailField);
        store.resetField(passwordField);

        expect(store.get(emailField).value, '');
        expect(store.get(emailField).isDirty, isFalse);
        expect(store.get(emailField).isTouched, isFalse);
        expect(store.get(emailField).error, isNull);

        expect(store.get(passwordField).value, '');
        expect(store.get(passwordField).isDirty, isFalse);
      });

      test('resets form state via batch after resetting fields', () async {
        store.setFieldValue(emailField, 'user@test.com');
        store.setFieldValue(passwordField, 'password123');

        await store.submitForm(form, onValid: (values) async {});

        // Reset fields individually (typed) and form state
        store.batch(() {
          store.resetField(emailField);
          store.resetField(passwordField);
          store.set(form, const FormState());
        });

        final formState = store.get(form);
        expect(formState.isSubmitting, isFalse);
        expect(formState.isSubmitted, isFalse);
        expect(formState.submitError, isNull);
        expect(formState.submitCount, 0);
      });
    });

    group('touchAllFields', () {
      test('marks all fields as touched', () {
        store.get(emailField);
        store.get(passwordField);

        store.touchAllFields(form);

        expect(store.get(emailField).isTouched, isTrue);
        expect(store.get(passwordField).isTouched, isTrue);
      });
    });

    group('isFormDirty', () {
      test('returns false when no fields are modified', () {
        store.get(emailField);
        store.get(passwordField);

        expect(store.isFormDirty(form), isFalse);
      });

      test('returns true when any field is modified', () {
        store.get(emailField);
        store.get(passwordField);

        store.setFieldValue(emailField, 'changed');
        expect(store.isFormDirty(form), isTrue);
      });

      test('returns false after resetting modified fields', () {
        store.setFieldValue(emailField, 'changed');
        store.resetField(emailField);
        store.resetField(passwordField);
        expect(store.isFormDirty(form), isFalse);
      });
    });

    group('formField', () {
      test('returns field by name', () {
        final field = store.formField<String>(form, 'email');
        expect(identical(field, emailField), isTrue);
      });

      test('throws for non-existent field name', () {
        expect(
          () => store.formField<String>(form, 'nonexistent'),
          throwsA(isA<StateError>()),
        );
      });

      test('returns correctly typed field', () {
        final field = store.formField<String>(form, 'password');
        expect(field, isA<FieldReacton<String>>());
        expect(identical(field, passwordField), isTrue);
      });
    });
  });

  // =========================================================================
  // Integration: full form workflow
  // =========================================================================
  group('Full form workflow integration', () {
    test('complete registration form flow', () async {
      final store = ReactonStore();

      final nameField = reactonField<String>(
        '',
        validators: [required(), minLength(2)],
        name: 'reg_name',
      );
      final emailField = reactonField<String>(
        '',
        validators: [required(), email()],
        name: 'reg_email',
      );
      final ageField = reactonField<String>(
        '',
        validators: [required()],
        name: 'reg_age',
      );

      final regForm = reactonForm(
        fields: {
          'name': nameField,
          'email': emailField,
          'age': ageField,
        },
        name: 'registration',
      );

      // Step 1: User fills in fields
      store.setFieldValue(nameField, 'Jo');
      store.setFieldValue(emailField, 'invalid');
      store.setFieldValue(ageField, '25');

      // Step 2: Email is invalid
      expect(store.isFormValid(regForm), isFalse);
      expect(store.get(emailField).error, 'Invalid email address');

      // Step 3: User fixes email
      store.setFieldValue(emailField, 'jo@example.com');
      expect(store.isFormValid(regForm), isTrue);

      // Step 4: Dirty tracking
      expect(store.isFormDirty(regForm), isTrue);

      // Step 5: Submit
      Map<String, dynamic>? submitted;
      await store.submitForm(
        regForm,
        onValid: (values) async {
          submitted = values;
        },
      );

      expect(submitted, isNotNull);
      expect(submitted!['name'], 'Jo');
      expect(submitted!['email'], 'jo@example.com');
      expect(submitted!['age'], '25');
      expect(store.get(regForm).isSubmitted, isTrue);
      expect(store.get(regForm).submitCount, 1);

      // Step 6: Reset individual fields (typed) and form state
      store.batch(() {
        store.resetField(nameField);
        store.resetField(emailField);
        store.resetField(ageField);
        store.set(regForm, const FormState());
      });
      expect(store.isFormDirty(regForm), isFalse);
      expect(store.get(nameField).value, '');
      expect(store.get(regForm).submitCount, 0);
    });
  });
}
