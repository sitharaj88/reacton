/// Built-in validators for form fields.
///
/// Validators return an error message string if validation fails,
/// or null if the value is valid.
typedef Validator<T> = String? Function(T value);

/// Validates that a string is not empty.
Validator<String> required({String message = 'This field is required'}) {
  return (value) => value.isEmpty ? message : null;
}

/// Validates minimum string length.
Validator<String> minLength(int min, {String? message}) {
  return (value) => value.length < min
      ? (message ?? 'Must be at least $min characters')
      : null;
}

/// Validates maximum string length.
Validator<String> maxLength(int max, {String? message}) {
  return (value) => value.length > max
      ? (message ?? 'Must be at most $max characters')
      : null;
}

/// Validates email format.
Validator<String> email({String message = 'Invalid email address'}) {
  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
  return (value) => value.isNotEmpty && !emailRegex.hasMatch(value) ? message : null;
}

/// Validates that a string matches a regex pattern.
Validator<String> pattern(RegExp regex, {String message = 'Invalid format'}) {
  return (value) => value.isNotEmpty && !regex.hasMatch(value) ? message : null;
}

/// Validates a numeric range.
Validator<num> range(num min, num max, {String? message}) {
  return (value) => (value < min || value > max)
      ? (message ?? 'Must be between $min and $max')
      : null;
}

/// Validates that two values match (for password confirmation).
Validator<String> matches(String Function() getOtherValue, {String message = 'Values do not match'}) {
  return (value) => value != getOtherValue() ? message : null;
}

/// Combines multiple validators. Returns the first error found.
Validator<T> compose<T>(List<Validator<T>> validators) {
  return (value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  };
}
