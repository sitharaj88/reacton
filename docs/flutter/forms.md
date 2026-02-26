# Form State

Reacton provides a reactive form system built on top of its core primitives. Forms are composed of `FieldReacton` instances managed by a `FormReacton`, with built-in validation, dirty tracking, touch state, and async validation support.

## Overview

The form system consists of three parts:

1. **`FieldReacton<T>`** -- A writable reacton that holds a `FieldState<T>` with value, error, dirty, and touched tracking
2. **`FormReacton`** -- Groups multiple fields together and tracks form-level submission state
3. **Validators** -- Composable validation functions that return error messages or `null`

## FieldReacton

A `FieldReacton<T>` is a `WritableReacton<FieldState<T>>` that wraps a form field's value along with its validation and interaction state.

### Creating Fields

```dart
final emailField = reactonField<String>(
  '',
  validators: [required(), email()],
  name: 'email',
);

final passwordField = reactonField<String>(
  '',
  validators: [required(), minLength(8)],
  name: 'password',
);

final ageField = reactonField<int>(
  0,
  name: 'age',
);
```

### Signature

```dart
FieldReacton<T> reactonField<T>(
  T initialValue, {
  List<Validator<T>> validators = const [],
  Future<String?> Function(T value)? asyncValidator,
  String? name,
})
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `initialValue` | `T` | The starting value for the field |
| `validators` | `List<Validator<T>>` | Synchronous validators (run in order, first error wins) |
| `asyncValidator` | `Future<String?> Function(T)?` | Optional async validator (e.g., server-side uniqueness check) |
| `name` | `String?` | Debug name |

### FieldState

Every `FieldReacton<T>` holds a `FieldState<T>`:

```dart
class FieldState<T> {
  final T value;          // Current field value
  final String? error;    // Validation error message (null if valid)
  final bool isDirty;     // Has the value changed from initial?
  final bool isTouched;   // Has the user interacted with this field?
  final bool isValidating; // Is async validation in progress?

  bool get isValid => error == null;
}
```

| Property | Type | Description |
|----------|------|-------------|
| `value` | `T` | The current field value |
| `error` | `String?` | Current validation error, or `null` if valid |
| `isDirty` | `bool` | `true` if the value differs from the initial value |
| `isTouched` | `bool` | `true` if the user has interacted with this field |
| `isValidating` | `bool` | `true` if async validation is running |
| `isValid` | `bool` | Convenience getter: `error == null` |

### Store Extensions for Fields

The `ReactonStoreField` extension provides convenience methods for working with fields:

| Method | Signature | Description |
|--------|-----------|-------------|
| `setFieldValue` | `void setFieldValue<T>(FieldReacton<T> field, T value)` | Set value with automatic validation and dirty tracking |
| `touchField` | `void touchField<T>(FieldReacton<T> field)` | Mark field as touched |
| `resetField` | `void resetField<T>(FieldReacton<T> field)` | Reset to initial state |
| `fieldValue` | `T fieldValue<T>(FieldReacton<T> field)` | Get current value (convenience) |
| `fieldError` | `String? fieldError<T>(FieldReacton<T> field)` | Get current error (convenience) |

```dart
// Set a field value with automatic validation
store.setFieldValue(emailField, 'user@example.com');

// Mark as touched (show errors after blur)
store.touchField(emailField);

// Read convenience getters
final email = store.fieldValue(emailField);
final error = store.fieldError(emailField);
```

## FormReacton

A `FormReacton` groups multiple `FieldReacton` instances together and tracks form-level submission state.

### Creating Forms

```dart
final loginForm = reactonForm(
  fields: {
    'email': emailField,
    'password': passwordField,
  },
  name: 'loginForm',
);
```

### Signature

```dart
FormReacton reactonForm({
  required Map<String, FieldReacton> fields,
  String? name,
})
```

| Parameter | Type | Description |
|-----------|------|-------------|
| `fields` | `Map<String, FieldReacton>` | Named map of field reactons |
| `name` | `String?` | Debug name |

### FormState

The `FormReacton` holds a `FormState` (from the form_reacton.dart module, not Flutter's `FormState`):

```dart
class FormState {
  final bool isSubmitting;   // Is the form currently being submitted?
  final bool isSubmitted;    // Has the form been successfully submitted?
  final String? submitError; // Error from the last submission attempt
  final int submitCount;     // Number of successful submissions
}
```

### Store Extensions for Forms

The `ReactonStoreForm` extension provides form-level operations:

| Method | Signature | Description |
|--------|-----------|-------------|
| `isFormValid` | `bool isFormValid(FormReacton form)` | Check if all fields are valid |
| `validateForm` | `bool validateForm(FormReacton form)` | Validate all fields, returns `true` if all valid |
| `submitForm` | `Future<void> submitForm(FormReacton form, {...})` | Validate and submit with callback |
| `resetForm` | `void resetForm(FormReacton form)` | Reset all fields and form state |
| `touchAllFields` | `void touchAllFields(FormReacton form)` | Mark all fields as touched |
| `isFormDirty` | `bool isFormDirty(FormReacton form)` | Check if any field has been modified |
| `formField` | `FieldReacton<T> formField<T>(FormReacton form, String name)` | Get a field by name |

### Submitting Forms

```dart
await store.submitForm(
  loginForm,
  onValid: (values) async {
    // values is Map<String, dynamic> of field name -> value
    await api.login(
      email: values['email'] as String,
      password: values['password'] as String,
    );
  },
  onError: (error) {
    print('Submission failed: $error');
  },
);
```

The `submitForm` method:
1. Validates all fields (calls `validateForm`)
2. If invalid, calls `onError` with a message and returns
3. Sets `isSubmitting = true` on the form state
4. Calls `onValid` with a `Map<String, dynamic>` of field names to values
5. On success, sets `isSubmitted = true` and increments `submitCount`
6. On exception, sets `submitError` with the error message

## Built-in Validators

Reacton ships with composable validators for common use cases. Each validator is a function that returns a `Validator<T>` (a `String? Function(T)` typedef).

| Validator | Signature | Description |
|-----------|-----------|-------------|
| `required()` | `Validator<String> required({String message})` | Fails if the string is empty |
| `minLength(n)` | `Validator<String> minLength(int min, {String? message})` | Fails if length < `min` |
| `maxLength(n)` | `Validator<String> maxLength(int max, {String? message})` | Fails if length > `max` |
| `email()` | `Validator<String> email({String message})` | Fails if not a valid email format |
| `pattern(regex)` | `Validator<String> pattern(RegExp regex, {String message})` | Fails if the string does not match the regex |
| `range(min, max)` | `Validator<num> range(num min, num max, {String? message})` | Fails if value is outside the range |
| `matches(getter)` | `Validator<String> matches(String Function() getOtherValue, {String message})` | Fails if value does not equal the other value (for confirmation fields) |
| `compose(validators)` | `Validator<T> compose<T>(List<Validator<T>> validators)` | Runs validators in order, returns first error |

### Custom Error Messages

Every built-in validator accepts a custom `message` parameter:

```dart
final emailField = reactonField<String>(
  '',
  validators: [
    required(message: 'Email is required'),
    email(message: 'Please enter a valid email'),
  ],
);
```

### Custom Validators

A validator is simply a `String? Function(T)`. Return `null` for valid, or an error message string:

```dart
Validator<String> noSpaces({String message = 'Must not contain spaces'}) {
  return (value) => value.contains(' ') ? message : null;
}

// Use it
final usernameField = reactonField<String>(
  '',
  validators: [required(), noSpaces(), minLength(3)],
);
```

### Composing Validators

Use `compose()` to combine multiple validators into one:

```dart
final passwordValidator = compose<String>([
  required(),
  minLength(8),
  pattern(RegExp(r'[A-Z]'), message: 'Must contain an uppercase letter'),
  pattern(RegExp(r'[0-9]'), message: 'Must contain a number'),
]);

final passwordField = reactonField<String>(
  '',
  validators: [passwordValidator],
);
```

## Complete Login Form Example

Here is a full login form demonstrating fields, validation, submission, and UI integration:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// 1. Define fields
final emailField = reactonField<String>(
  '',
  validators: [required(), email()],
  name: 'email',
);

final passwordField = reactonField<String>(
  '',
  validators: [required(), minLength(8)],
  name: 'password',
);

// 2. Define form
final loginForm = reactonForm(
  fields: {
    'email': emailField,
    'password': passwordField,
  },
  name: 'loginForm',
);

// 3. Build the UI
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final emailState = context.watch(emailField);
    final passwordState = context.watch(passwordField);
    final formState = context.watch(loginForm);

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                errorText: emailState.isTouched ? emailState.error : null,
              ),
              onChanged: (value) {
                context.reactonStore.setFieldValue(emailField, value);
              },
              onTap: () {
                context.reactonStore.touchField(emailField);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                errorText: passwordState.isTouched ? passwordState.error : null,
              ),
              onChanged: (value) {
                context.reactonStore.setFieldValue(passwordField, value);
              },
              onTap: () {
                context.reactonStore.touchField(passwordField);
              },
            ),
            const SizedBox(height: 24),
            if (formState.submitError != null)
              Text(
                formState.submitError!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: formState.isSubmitting
                  ? null
                  : () async {
                      final store = context.reactonStore;
                      store.touchAllFields(loginForm);
                      await store.submitForm(
                        loginForm,
                        onValid: (values) async {
                          // Call your API
                          await Future.delayed(
                            const Duration(seconds: 1),
                          );
                          print('Logged in with: $values');
                        },
                        onError: (error) {
                          print('Login failed: $error');
                        },
                      );
                    },
              child: formState.isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Password Confirmation with `matches`

Use the `matches()` validator for confirmation fields:

```dart
final passwordField = reactonField<String>(
  '',
  validators: [required(), minLength(8)],
  name: 'password',
);

final confirmPasswordField = reactonField<String>(
  '',
  validators: [
    required(),
    matches(
      () => store.fieldValue(passwordField),
      message: 'Passwords do not match',
    ),
  ],
  name: 'confirmPassword',
);
```

## Async Validation

For server-side validation (e.g., checking if a username is taken):

```dart
final usernameField = reactonField<String>(
  '',
  validators: [required(), minLength(3)],
  asyncValidator: (value) async {
    final isTaken = await api.checkUsername(value);
    return isTaken ? 'Username is already taken' : null;
  },
  name: 'username',
);
```

When `setFieldValue` is called and synchronous validation passes, the async validator runs automatically. While it is running, `FieldState.isValidating` is `true`.

## What's Next

- [Widgets](/flutter/widgets) -- `ReactonBuilder`, `ReactonConsumer`, and other reactive widgets
- [Context Extensions](/flutter/context-extensions) -- `context.watch()` and `context.set()`
- [Auto-Dispose](/flutter/auto-dispose) -- Automatic subscription cleanup
