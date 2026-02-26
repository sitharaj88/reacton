import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

import '../../shared/state.dart';

// ============================================================================
// Registration Form Page
//
// Demonstrates:
//   - reactonField<T>()       field with validators, dirty/touched tracking
//   - reactonForm()           groups fields for coordinated validation
//   - Built-in validators     required(), email(), minLength(), matches()
//   - store.setFieldValue()   write with automatic validation
//   - store.touchField()      mark field as interacted
//   - store.validateForm()    validate all fields at once
//   - store.submitForm()      validate + collect values + call handler
//   - store.resetForm()       reset all fields to initial state
//   - store.isFormValid()     check overall form validity
//   - store.isFormDirty()     check if any field has been modified
// ============================================================================

class RegistrationPage extends StatelessWidget {
  const RegistrationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Form'),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Text(
              'Form State Management',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'reactonField() manages per-field state including value, error, '
              'dirty, and touched flags. reactonForm() groups fields and provides '
              'coordinated validation and submission.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // --- Form fields ---
            _FormFieldWidget(
              label: 'Username',
              hint: 'Enter your username',
              field: usernameField,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            _FormFieldWidget(
              label: 'Email',
              hint: 'Enter your email address',
              field: emailField,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _FormFieldWidget(
              label: 'Password',
              hint: 'Minimum 8 characters',
              field: passwordField,
              icon: Icons.lock_outline,
              obscure: true,
            ),
            const SizedBox(height: 16),
            _FormFieldWidget(
              label: 'Confirm Password',
              hint: 'Re-enter your password',
              field: confirmPasswordField,
              icon: Icons.lock_outline,
              obscure: true,
            ),
            const SizedBox(height: 24),

            // --- Form status bar ---
            _FormStatusBar(),
            const SizedBox(height: 24),

            // --- Action buttons ---
            _FormActions(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Individual field widget
// ---------------------------------------------------------------------------

class _FormFieldWidget extends StatefulWidget {
  final String label;
  final String hint;
  final FieldReacton<String> field;
  final IconData icon;
  final bool obscure;
  final TextInputType? keyboardType;

  const _FormFieldWidget({
    required this.label,
    required this.hint,
    required this.field,
    required this.icon,
    this.obscure = false,
    this.keyboardType,
  });

  @override
  State<_FormFieldWidget> createState() => _FormFieldWidgetState();
}

class _FormFieldWidgetState extends State<_FormFieldWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Watch the field state so the widget rebuilds on validation changes
    final fieldState = context.watch(widget.field);

    // Sync the text controller if the store value changed externally (e.g. reset)
    if (_controller.text != fieldState.value) {
      _controller.text = fieldState.value;
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }

    final showError = fieldState.isTouched && fieldState.error != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        TextField(
          controller: _controller,
          obscureText: widget.obscure,
          keyboardType: widget.keyboardType,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(widget.icon),
            border: const OutlineInputBorder(),
            errorText: showError ? fieldState.error : null,
            suffixIcon: fieldState.isDirty
                ? Icon(
                    fieldState.isValid ? Icons.check_circle : Icons.error,
                    color: fieldState.isValid ? Colors.green : null,
                    size: 20,
                  )
                : null,
          ),
          onChanged: (value) {
            // setFieldValue writes the value and runs synchronous validators
            context.reactonStore.setFieldValue(widget.field, value);
          },
          onTap: () {
            // touchField marks the field as interacted, enabling error display
            context.reactonStore.touchField(widget.field);
          },
        ),
        if (fieldState.isDirty || fieldState.isTouched)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Row(
              children: [
                if (fieldState.isDirty)
                  const _Tag(label: 'dirty', color: Colors.orange),
                if (fieldState.isTouched) ...[
                  const SizedBox(width: 6),
                  const _Tag(label: 'touched', color: Colors.blue),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Form status bar
// ---------------------------------------------------------------------------

class _FormStatusBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = context.reactonStore;
    // Watch the form reacton itself to track submission state
    final formState = context.watch(registrationForm);
    final isValid = store.isFormValid(registrationForm);
    final isDirty = store.isFormDirty(registrationForm);

    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Form Status',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _StatusItem(
                  label: 'Valid',
                  value: isValid,
                  trueIcon: Icons.check_circle,
                  falseIcon: Icons.cancel,
                ),
                _StatusItem(
                  label: 'Dirty',
                  value: isDirty,
                  trueIcon: Icons.edit,
                  falseIcon: Icons.edit_off,
                ),
                _StatusItem(
                  label: 'Submitting',
                  value: formState.isSubmitting,
                  trueIcon: Icons.hourglass_top,
                  falseIcon: Icons.hourglass_empty,
                ),
                _StatusItem(
                  label: 'Submitted',
                  value: formState.isSubmitted,
                  trueIcon: Icons.send,
                  falseIcon: Icons.send_outlined,
                ),
              ],
            ),
            if (formState.submitError != null) ...[
              const SizedBox(height: 8),
              Text(
                'Error: ${formState.submitError}',
                style: TextStyle(color: colors.error),
              ),
            ],
            if (formState.submitCount > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Submit count: ${formState.submitCount}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form action buttons
// ---------------------------------------------------------------------------

class _FormActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = context.reactonStore;
    final formState = context.watch(registrationForm);

    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: formState.isSubmitting
                ? null
                : () => _submit(context),
            icon: formState.isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: Text(formState.isSubmitting ? 'Submitting...' : 'Register'),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => store.resetForm(registrationForm),
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
        ),
      ],
    );
  }

  Future<void> _submit(BuildContext context) async {
    final store = context.reactonStore;

    // Validate the confirm-password field manually (cross-field validation).
    // First touch all fields to show any errors.
    store.touchAllFields(registrationForm);

    // Check cross-field validation: passwords must match
    final password = store.get(passwordField).value;
    final confirm = store.get(confirmPasswordField).value;
    if (password != confirm && confirm.isNotEmpty) {
      store.setFieldValue(confirmPasswordField, confirm);
      // Manually set an error on the confirm field
      store.set(
        confirmPasswordField,
        store.get(confirmPasswordField).copyWith(
              error: () => 'Passwords do not match',
            ),
      );
      return;
    }

    await store.submitForm(
      registrationForm,
      onValid: (values) async {
        // Simulate network request
        await Future<void>.delayed(const Duration(seconds: 2));
        // In a real app you would call an API here.
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );

    if (store.get(registrationForm).isSubmitted) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color),
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final String label;
  final bool value;
  final IconData trueIcon;
  final IconData falseIcon;

  const _StatusItem({
    required this.label,
    required this.value,
    required this.trueIcon,
    required this.falseIcon,
  });

  @override
  Widget build(BuildContext context) {
    final color = value ? Colors.green : Theme.of(context).colorScheme.outline;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(value ? trueIcon : falseIcon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}
