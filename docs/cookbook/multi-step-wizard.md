# Multi-Step Wizard

A checkout wizard with state-machine-driven flow control, per-step form validation, history for back/forward navigation, and state branching to preview before submitting. Demonstrates `stateMachine`, `reactonField`, `store.enableHistory`, and `store.createBranch`.

## Full Source

```dart
import 'package:flutter/material.dart';
import 'package:flutter_reacton/flutter_reacton.dart';

// --- State Machine ---

enum WizardStep { shipping, payment, review, confirmation }

enum WizardEvent { next, back, submit, reset }

final wizardMachine = stateMachine<WizardStep, WizardEvent>(
  initial: WizardStep.shipping,
  transitions: {
    WizardStep.shipping: {
      WizardEvent.next: (ctx) => WizardStep.payment,
    },
    WizardStep.payment: {
      WizardEvent.next: (ctx) => WizardStep.review,
      WizardEvent.back: (ctx) => WizardStep.shipping,
    },
    WizardStep.review: {
      WizardEvent.submit: (ctx) => WizardStep.confirmation,
      WizardEvent.back: (ctx) => WizardStep.payment,
    },
    WizardStep.confirmation: {
      WizardEvent.reset: (ctx) => WizardStep.shipping,
    },
  },
  onTransition: (from, to) {
    debugPrint('Wizard: $from -> $to');
  },
  name: 'wizard',
);

// --- Form Fields ---

// Shipping fields
final nameField = reactonField<String>(
  '',
  validators: [
    FieldValidator.required('Name is required'),
    FieldValidator.minLength(2, 'Name must be at least 2 characters'),
  ],
  name: 'shipping.name',
);

final addressField = reactonField<String>(
  '',
  validators: [
    FieldValidator.required('Address is required'),
    FieldValidator.minLength(10, 'Please enter a full address'),
  ],
  name: 'shipping.address',
);

final cityField = reactonField<String>(
  '',
  validators: [FieldValidator.required('City is required')],
  name: 'shipping.city',
);

final zipField = reactonField<String>(
  '',
  validators: [
    FieldValidator.required('ZIP code is required'),
    FieldValidator.pattern(RegExp(r'^\d{5}$'), 'Enter a valid 5-digit ZIP'),
  ],
  name: 'shipping.zip',
);

// Payment fields
final cardNumberField = reactonField<String>(
  '',
  validators: [
    FieldValidator.required('Card number is required'),
    FieldValidator.pattern(
      RegExp(r'^\d{16}$'),
      'Enter a valid 16-digit card number',
    ),
  ],
  name: 'payment.cardNumber',
);

final expiryField = reactonField<String>(
  '',
  validators: [
    FieldValidator.required('Expiry date is required'),
    FieldValidator.pattern(
      RegExp(r'^\d{2}/\d{2}$'),
      'Use MM/YY format',
    ),
  ],
  name: 'payment.expiry',
);

final cvvField = reactonField<String>(
  '',
  validators: [
    FieldValidator.required('CVV is required'),
    FieldValidator.pattern(RegExp(r'^\d{3,4}$'), 'Enter a valid CVV'),
  ],
  name: 'payment.cvv',
);

// --- Computed ---

/// Checks whether all shipping fields are valid.
final shippingValid = computed<bool>(
  (read) =>
      read(nameField.errorReacton) == null &&
      read(addressField.errorReacton) == null &&
      read(cityField.errorReacton) == null &&
      read(zipField.errorReacton) == null &&
      read(nameField.valueReacton).isNotEmpty,
  name: 'shippingValid',
);

/// Checks whether all payment fields are valid.
final paymentValid = computed<bool>(
  (read) =>
      read(cardNumberField.errorReacton) == null &&
      read(expiryField.errorReacton) == null &&
      read(cvvField.errorReacton) == null &&
      read(cardNumberField.valueReacton).isNotEmpty,
  name: 'paymentValid',
);

/// Summary data for the review step.
final orderSummary = computed((read) {
  return (
    name: read(nameField.valueReacton),
    address: read(addressField.valueReacton),
    city: read(cityField.valueReacton),
    zip: read(zipField.valueReacton),
    cardLast4: read(cardNumberField.valueReacton).length >= 4
        ? read(cardNumberField.valueReacton)
            .substring(read(cardNumberField.valueReacton).length - 4)
        : '****',
  );
}, name: 'orderSummary');

// --- App ---

void main() {
  final store = ReactonStore();

  // Enable history on the wizard step for undo/redo navigation
  store.enableHistory(wizardMachine.stateReacton);

  runApp(ReactonScope(store: store, child: const WizardApp()));
}

class WizardApp extends StatelessWidget {
  const WizardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checkout Wizard',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const WizardPage(),
    );
  }
}

class WizardPage extends StatelessWidget {
  const WizardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final step = context.watch(wizardMachine.stateReacton);
    final stepIndex = WizardStep.values.indexOf(step);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        leading: step != WizardStep.shipping && step != WizardStep.confirmation
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Use history undo for back navigation
                  context.reactonStore.undo(wizardMachine.stateReacton);
                },
              )
            : null,
      ),
      body: Column(
        children: [
          // Stepper indicator
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: WizardStep.values.map((s) {
                final i = WizardStep.values.indexOf(s);
                final isActive = i <= stepIndex;
                final isCurrent = s == step;
                return Expanded(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: isActive
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: isCurrent
                            ? Icon(Icons.edit, size: 16,
                                color: Theme.of(context).colorScheme.onPrimary)
                            : isActive
                                ? Icon(Icons.check, size: 16,
                                    color: Theme.of(context).colorScheme.onPrimary)
                                : Text('${i + 1}',
                                    style: Theme.of(context).textTheme.labelSmall),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        s.name[0].toUpperCase() + s.name.substring(1),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontWeight: isCurrent ? FontWeight.bold : null,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Step content
          Expanded(
            child: switch (step) {
              WizardStep.shipping => const _ShippingStep(),
              WizardStep.payment => const _PaymentStep(),
              WizardStep.review => const _ReviewStep(),
              WizardStep.confirmation => const _ConfirmationStep(),
            },
          ),
        ],
      ),
    );
  }
}

// --- Shipping Step ---

class _ShippingStep extends StatelessWidget {
  const _ShippingStep();

  @override
  Widget build(BuildContext context) {
    final isValid = context.watch(shippingValid);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Shipping Address',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _FormField(field: nameField, label: 'Full Name'),
          const SizedBox(height: 12),
          _FormField(field: addressField, label: 'Street Address'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _FormField(field: cityField, label: 'City')),
              const SizedBox(width: 12),
              SizedBox(
                  width: 120, child: _FormField(field: zipField, label: 'ZIP')),
            ],
          ),
          const Spacer(),
          FilledButton(
            onPressed: isValid
                ? () => wizardMachine.send(context.reactonStore, WizardEvent.next)
                : null,
            child: const Text('Continue to Payment'),
          ),
        ],
      ),
    );
  }
}

// --- Payment Step ---

class _PaymentStep extends StatelessWidget {
  const _PaymentStep();

  @override
  Widget build(BuildContext context) {
    final isValid = context.watch(paymentValid);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Payment Details',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          _FormField(field: cardNumberField, label: 'Card Number'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _FormField(field: expiryField, label: 'Expiry (MM/YY)')),
              const SizedBox(width: 12),
              SizedBox(
                  width: 100, child: _FormField(field: cvvField, label: 'CVV')),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              OutlinedButton(
                onPressed: () =>
                    wizardMachine.send(context.reactonStore, WizardEvent.back),
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: isValid
                      ? () => _previewBeforeSubmit(context)
                      : null,
                  child: const Text('Review Order'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Create a branch to preview the review step without committing.
  void _previewBeforeSubmit(BuildContext context) {
    final store = context.reactonStore;

    // Create a preview branch so the review step sees a snapshot
    store.createBranch('preview');

    // Advance to review on the main store
    wizardMachine.send(store, WizardEvent.next);
  }
}

// --- Review Step ---

class _ReviewStep extends StatelessWidget {
  const _ReviewStep();

  @override
  Widget build(BuildContext context) {
    final summary = context.watch(orderSummary);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Review Order',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Shipping',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(summary.name),
                  Text(summary.address),
                  Text('${summary.city}, ${summary.zip}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Payment',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Card ending in ${summary.cardLast4}'),
                ],
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              OutlinedButton(
                onPressed: () {
                  // Discard the preview branch and go back
                  context.reactonStore.discardBranch('preview');
                  wizardMachine.send(context.reactonStore, WizardEvent.back);
                },
                child: const Text('Back'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    // Merge the preview branch and submit
                    context.reactonStore.mergeBranch('preview');
                    wizardMachine.send(
                        context.reactonStore, WizardEvent.submit);
                  },
                  child: const Text('Place Order'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- Confirmation Step ---

class _ConfirmationStep extends StatelessWidget {
  const _ConfirmationStep();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle,
              size: 80, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 24),
          Text('Order Placed!',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          Text('Thank you for your purchase.',
              style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () =>
                wizardMachine.send(context.reactonStore, WizardEvent.reset),
            child: const Text('Start New Order'),
          ),
        ],
      ),
    );
  }
}

// --- Reusable Form Field Widget ---

class _FormField extends StatelessWidget {
  final dynamic field; // ReactonField<String>
  final String label;

  const _FormField({required this.field, required this.label});

  @override
  Widget build(BuildContext context) {
    final error = context.watch(field.errorReacton);

    return TextField(
      decoration: InputDecoration(
        labelText: label,
        errorText: error,
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        context.set(field.valueReacton, value);
        field.validate(context.reactonStore);
      },
    );
  }
}
```

## Walkthrough

### State Machine for Flow Control

The wizard defines four steps and four events. Each step declares exactly which events it accepts:

```dart
final wizardMachine = stateMachine<WizardStep, WizardEvent>(
  initial: WizardStep.shipping,
  transitions: {
    WizardStep.shipping: {
      WizardEvent.next: (ctx) => WizardStep.payment,
    },
    WizardStep.payment: {
      WizardEvent.next: (ctx) => WizardStep.review,
      WizardEvent.back: (ctx) => WizardStep.shipping,
    },
    // ...
  },
);
```

This makes the flow explicit and prevents invalid transitions. The `shipping` step cannot handle `back` because there is no previous step. The `confirmation` step can only handle `reset`.

### Form Fields with Validation

Each field is a `reactonField` with synchronous validators:

```dart
final nameField = reactonField<String>(
  '',
  validators: [
    FieldValidator.required('Name is required'),
    FieldValidator.minLength(2, 'Name must be at least 2 characters'),
  ],
  name: 'shipping.name',
);
```

`reactonField` provides two sub-reactons: `valueReacton` (the current value) and `errorReacton` (the first failing validation message, or `null`). The `validate` method runs all validators and updates the error reacton.

### Computed Step Validity

```dart
final shippingValid = computed<bool>(
  (read) =>
      read(nameField.errorReacton) == null &&
      read(addressField.errorReacton) == null &&
      read(cityField.errorReacton) == null &&
      read(zipField.errorReacton) == null &&
      read(nameField.valueReacton).isNotEmpty,
  name: 'shippingValid',
);
```

The "Continue" button is disabled until all fields pass validation. Because this is a computed reacton, it automatically recomputes whenever any field's error state changes.

### History for Back Navigation

```dart
store.enableHistory(wizardMachine.stateReacton);
```

Enabling history on the wizard's state reacton records every transition. The back button uses `store.undo` to revert to the previous step:

```dart
onPressed: () {
  context.reactonStore.undo(wizardMachine.stateReacton);
},
```

This is an alternative to sending `WizardEvent.back`. Both approaches work; history-based undo is useful when you want browser-like back/forward behavior without defining explicit back transitions for every step.

### State Branching for Preview

Before moving to the review step, a branch is created:

```dart
void _previewBeforeSubmit(BuildContext context) {
  final store = context.reactonStore;
  store.createBranch('preview');
  wizardMachine.send(store, WizardEvent.next);
}
```

On the review step, the user can either discard the branch (going back to payment without side effects) or merge it (committing the preview state and submitting the order):

```dart
// Discard and go back
context.reactonStore.discardBranch('preview');
wizardMachine.send(context.reactonStore, WizardEvent.back);

// Merge and submit
context.reactonStore.mergeBranch('preview');
wizardMachine.send(context.reactonStore, WizardEvent.submit);
```

Branching isolates the review step so that navigating backward never leaves partial state behind.

### Stepper UI

The stepper indicator at the top uses the current step index to mark completed, active, and upcoming steps:

```dart
CircleAvatar(
  backgroundColor: isActive
      ? Theme.of(context).colorScheme.primary
      : Theme.of(context).colorScheme.surfaceContainerHighest,
  child: isCurrent
      ? Icon(Icons.edit, size: 16, ...)
      : isActive
          ? Icon(Icons.check, size: 16, ...)
          : Text('${i + 1}', ...),
),
```

The exhaustive `switch` expression on the current step renders the correct form:

```dart
Expanded(
  child: switch (step) {
    WizardStep.shipping => const _ShippingStep(),
    WizardStep.payment => const _PaymentStep(),
    WizardStep.review => const _ReviewStep(),
    WizardStep.confirmation => const _ConfirmationStep(),
  },
),
```

## Key Takeaways

1. **State machines enforce valid navigation** -- Each step declares its allowed transitions, making it impossible to reach an invalid state.
2. **Form reactons decouple validation from UI** -- `reactonField` holds the value and error state; the widget just reads and displays them.
3. **Computed validity gates progression** -- The "Continue" button is enabled only when all fields in the current step pass validation.
4. **History enables undo/redo navigation** -- `store.enableHistory` records state changes, and `store.undo` provides browser-like back behavior.
5. **Branching isolates preview state** -- `createBranch` snapshots state before review; `discardBranch` rolls back cleanly, `mergeBranch` commits.

## What's Next

- [Authentication](./authentication) -- Another state machine pattern for auth flows
- [Form Validation](./form-validation) -- Deeper look at per-field validation and async validators
- [Shopping Cart](./shopping-cart) -- Modules, persistence, and optimistic updates
