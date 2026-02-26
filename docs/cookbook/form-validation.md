# Form Validation

A complex registration form with per-field validation, async email validation, password confirmation, and submit handling using `FormReacton`, `FieldReacton`, and built-in validators.

## Form Definition

```dart
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// --- Field Reactons ---

final emailField = reactonField<String>(
  '',
  validators: [required(), email()],
  asyncValidator: (value) async {
    // Simulate checking if email is already taken
    await Future.delayed(const Duration(milliseconds: 500));
    if (value == 'taken@example.com') {
      return 'This email is already registered';
    }
    return null;
  },
  name: 'email',
);

final passwordField = reactonField<String>(
  '',
  validators: [
    required(message: 'Password is required'),
    minLength(8, message: 'Password must be at least 8 characters'),
  ],
  name: 'password',
);

final confirmPasswordField = reactonField<String>(
  '',
  validators: [
    required(message: 'Please confirm your password'),
  ],
  name: 'confirmPassword',
);

final nameField = reactonField<String>(
  '',
  validators: [
    required(message: 'Name is required'),
    minLength(2, message: 'Name must be at least 2 characters'),
    maxLength(50, message: 'Name must be at most 50 characters'),
  ],
  name: 'name',
);

final ageField = reactonField<String>(
  '',
  validators: [
    required(message: 'Age is required'),
    (value) {
      final age = int.tryParse(value);
      if (age == null) return 'Must be a number';
      if (age < 13 || age > 120) return 'Must be between 13 and 120';
      return null;
    },
  ],
  name: 'age',
);

// --- Form Reacton ---

final registrationForm = reactonForm(
  fields: {
    'name': nameField,
    'email': emailField,
    'password': passwordField,
    'confirmPassword': confirmPasswordField,
    'age': ageField,
  },
  name: 'registrationForm',
);

// --- Computed: password match validation ---

final passwordMatchReacton = computed((read) {
  final password = read(passwordField).value;
  final confirm = read(confirmPasswordField).value;
  if (confirm.isNotEmpty && password != confirm) {
    return 'Passwords do not match';
  }
  return null;
}, name: 'passwordMatch');
```

## Form UI

```dart
void main() => runApp(ReactonScope(child: const FormApp()));

class FormApp extends StatelessWidget {
  const FormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registration Form',
      theme: ThemeData(colorSchemeSeed: Colors.purple, useMaterial3: true),
      home: const RegistrationPage(),
    );
  }
}

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final formState = context.watch(registrationForm);

    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _FormField(
              field: nameField,
              label: 'Full Name',
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 16),
            _FormField(
              field: emailField,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _FormField(
              field: passwordField,
              label: 'Password',
              obscure: true,
            ),
            const SizedBox(height: 16),
            _ConfirmPasswordField(),
            const SizedBox(height: 16),
            _FormField(
              field: ageField,
              label: 'Age',
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            if (formState.submitError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  formState.submitError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),

            FilledButton(
              onPressed: formState.isSubmitting
                  ? null
                  : () => _submit(context),
              child: formState.isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Register'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.reactonStore.resetForm(registrationForm),
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    final store = context.reactonStore;

    // Touch all fields to show errors
    store.touchAllFields(registrationForm);

    // Check password match manually
    final passwordMatchError = store.get(passwordMatchReacton);
    if (passwordMatchError != null) return;

    await store.submitForm(
      registrationForm,
      onValid: (values) async {
        // Simulate API call
        await Future.delayed(const Duration(seconds: 2));

        debugPrint('Registration submitted:');
        for (final entry in values.entries) {
          debugPrint('  ${entry.key}: ${entry.value}');
        }
      },
      onError: (error) {
        debugPrint('Form error: $error');
      },
    );
  }
}

/// Reusable form field widget.
class _FormField extends StatelessWidget {
  final FieldReacton<String> field;
  final String label;
  final TextInputType? keyboardType;
  final bool obscure;

  const _FormField({
    required this.field,
    required this.label,
    this.keyboardType,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch(field);
    final store = context.reactonStore;

    return TextField(
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        errorText: state.isTouched ? state.error : null,
        suffixIcon: state.isValidating
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : state.isTouched && state.isValid
                ? const Icon(Icons.check_circle, color: Colors.green)
                : null,
      ),
      onChanged: (value) => store.setFieldValue(field, value),
      onTap: () => store.touchField(field),
    );
  }
}

/// Special field for password confirmation with cross-field validation.
class _ConfirmPasswordField extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch(confirmPasswordField);
    final matchError = context.watch(passwordMatchReacton);
    final store = context.reactonStore;

    // Show the password match error if touched and passwords do not match
    final displayError = state.isTouched
        ? (state.error ?? matchError)
        : null;

    return TextField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        border: const OutlineInputBorder(),
        errorText: displayError,
        suffixIcon: state.isTouched && displayError == null && state.value.isNotEmpty
            ? const Icon(Icons.check_circle, color: Colors.green)
            : null,
      ),
      onChanged: (value) => store.setFieldValue(confirmPasswordField, value),
      onTap: () => store.touchField(confirmPasswordField),
    );
  }
}
```

## Key Concepts

### FieldReacton and Validators

Each `reactonField()` holds a `FieldState<T>` that tracks the value, error, dirty state, touch state, and async validation state. Built-in validators are composed to produce the first error:

```dart
final emailField = reactonField<String>(
  '',
  validators: [required(), email()],
  asyncValidator: (value) async { ... },
);
```

### Async Validation

When `asyncValidator` is provided, it runs after synchronous validators pass. The `isValidating` flag is set to true during the async check, which can be used to show a loading indicator.

### Cross-Field Validation

Use `computed()` to validate across fields. The password match check watches both the password and confirmation fields:

```dart
final passwordMatchReacton = computed((read) {
  final password = read(passwordField).value;
  final confirm = read(confirmPasswordField).value;
  if (confirm.isNotEmpty && password != confirm) {
    return 'Passwords do not match';
  }
  return null;
});
```

### Form Submission

The `submitForm` extension on `ReactonStore` validates all fields, sets the submitting state, collects values, and calls the handler:

```dart
await store.submitForm(
  registrationForm,
  onValid: (values) async {
    // values is Map<String, dynamic> -- field names to values
    await api.register(values);
  },
  onError: (error) {
    // Handle validation or submission errors
  },
);
```

### Showing Errors Only After Touch

Errors are only displayed when `state.isTouched` is true. This prevents showing errors before the user has interacted with a field. Call `store.touchAllFields(form)` before submission to reveal all errors.

### Reset

```dart
store.resetForm(registrationForm);
```

Resets all fields to their initial values and clears the form state (submitting, submitted, error, submit count).

## What's Next

- [Pagination](./pagination) -- Infinite scroll with QueryReacton
- [Authentication](./authentication) -- State machine for auth flow
- [Offline-First](./offline-first) -- Persistence and optimistic updates
