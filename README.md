# dup

A schema-based validation library for Dart, inspired by [yup](https://github.com/jquense/yup) and [zod](https://zod.dev).

Pure Dart. Works in Flutter, server, and CLI environments.

## Features

- Fluent, chainable validators
- Structured results with sealed `ValidationResult` — switch exhaustiveness enforced
- Schema validation with `DupSchema` (replaces the old `useUiForm` + `BaseValidatorSchema`)
- Phase-ordered execution: `required` always fires before format and range checks
- Async validator support via `addAsyncValidator` and `validateAsync`
- Three-level message resolution: per-call override → global locale → hardcoded default
- Null-skip semantics for all non-required validators

## Installation

```yaml
dependencies:
  dup: ^2.0.0
```

## Quick Start

```dart
import 'package:dup/dup.dart';

final schema = DupSchema({
  'email': ValidateString().email().required(),
  'age':   ValidateNumber().min(18).required(),
});

final result = await schema.validate({'email': 'user@example.com', 'age': 25});

switch (result) {
  FormValidationSuccess() => print('All good!'),
  FormValidationFailure(:final errors) =>
      errors.forEach((field, f) => print('$field: ${f.message}')),
}
```

## DupSchema

```dart
final schema = DupSchema(
  {
    'email':           ValidateString().email().required(),
    'password':        ValidateString().min(8).required(),
    'passwordConfirm': ValidateString().required(),
  },
  // Override the label used in error messages (defaults to the key name)
  labels: {'passwordConfirm': 'Password confirmation'},
).crossValidate((data) {
  if (data['password'] != data['passwordConfirm']) {
    return {
      'passwordConfirm': const ValidationFailure(
        code: ValidationCode.custom,
        message: 'Passwords do not match.',
      ),
    };
  }
  return null; // pass
});

// Async (supports async validators)
final result = await schema.validate(formData);

// Sync (asserts in debug mode when async validators are present)
final result = schema.validateSync(formData);

// Single-field validation (e.g. on-change feedback)
final fieldResult = await schema.validateField('email', value);
```

### Reading errors

```dart
if (result is FormValidationFailure) {
  result.hasError('email');          // bool
  result('email')?.message;         // String? — the error message
  result('email')?.code;            // ValidationCode
  result.fields;                    // List<String> — all failing fields
  result.firstField;                // String? — first failing field
}
```

## Validators

### ValidateString

| Method | Description |
|---|---|
| `required()` | Fails for null or empty string |
| `notBlank()` | Fails for whitespace-only string |
| `min(n)` | At least `n` characters (after trim) |
| `max(n)` | At most `n` characters (after trim) |
| `matches(RegExp)` | Must match the regex |
| `email()` | Must be a valid email address |
| `password({minLength})` | Minimum length check (default 4) |
| `emoji()` | Fails when value contains emoji |
| `alpha()` | Letters only (a–z, A–Z) |
| `alphanumeric()` | Letters and digits only |
| `numeric()` | Digits only (0–9) |
| `url()` | Must be a valid HTTP/HTTPS URL |
| `uuid()` | Must be a valid UUID v4 |
| `mobile({customRegex})` | Mobile number format (default: Korean) |
| `phone({customRegex})` | Landline format (default: Korean) |
| `bizno({customRegex})` | Business registration number (default: Korean) |

### ValidateNumber

| Method | Description |
|---|---|
| `required()` | Fails for null |
| `min(n)` | Value ≥ n |
| `max(n)` | Value ≤ n |
| `isInteger()` | No fractional part |
| `isPositive()` | Value > 0 |
| `isNegative()` | Value < 0 |
| `isNonNegative()` | Value ≥ 0 |
| `isNonPositive()` | Value ≤ 0 |
| `between(min, max)` | Inclusive range check |
| `isEven()` | Even number |
| `isOdd()` | Odd number |
| `isMultipleOf(n)` | Multiple of n |

`ValidateNumber.toValidator()` parses a string input before validating —
compatible with Flutter's `TextFormField.validator`:

```dart
TextFormField(
  validator: ValidateNumber().setLabel('Age').min(18).toValidator(),
)
```

### ValidateList\<T\>

| Method | Description |
|---|---|
| `required()` | Fails for null |
| `isNotEmpty()` | At least one item |
| `isEmpty()` | Must be empty |
| `minLength(n)` | At least `n` items |
| `maxLength(n)` | At most `n` items |
| `lengthBetween(min, max)` | Item count in range |
| `hasLength(n)` | Exactly `n` items |
| `contains(item)` | Must contain item |
| `doesNotContain(item)` | Must not contain item |
| `all(predicate)` | Every item satisfies predicate |
| `any(predicate)` | At least one item satisfies predicate |
| `none(predicate)` | No items satisfy predicate |
| `hasNoDuplicates()` | No duplicate items |
| `eachItem(fn)` | Per-item validator; reports first failing index |

### ValidateBool

| Method | Description |
|---|---|
| `required()` | Fails for null |
| `isTrue()` | Must be `true` |
| `isFalse()` | Must be `false` |

```dart
// "Agree to terms" checkbox
ValidateBool().setLabel('Terms').isTrue().required().validate(false);
// → ValidationFailure(code: boolTrue, message: 'Terms must be true.')
```

### ValidateDateTime

| Method | Description |
|---|---|
| `required()` | Fails for null |
| `isBefore(target)` | Strictly before target |
| `isAfter(target)` | Strictly after target |
| `min(date)` | On or after date |
| `max(date)` | On or before date |
| `between(min, max)` | Inclusive range |
| `isInFuture()` | Must be after now |
| `isInPast()` | Must be before now |

## Phase Ordering

Validators always run in phase order regardless of chain order:

| Phase | What runs |
|---|---|
| 0 | `required`, `notBlank` |
| 1 | Format checks (`email`, `isInteger`, `isBefore`, …) |
| 2 | Constraint checks (`min`, `max`, `between`, …) |
| 3 | Custom (`addValidator`, `satisfy`, `equalTo`, …) |
| 4 | Async (`addAsyncValidator`) |

```dart
// These two chains behave identically — required always fires first
ValidateString().email().required();
ValidateString().required().email();
```

## Async Validators

```dart
final v = ValidateString().setLabel('Username').required()
  ..addAsyncValidator((value) async {
    final taken = await db.usernameExists(value!);
    if (taken) {
      return const ValidationFailure(
        code: ValidationCode.custom,
        message: 'Username is already taken.',
      );
    }
    return null; // pass
  });

final result = await v.validateAsync('alice');
```

## Custom Validators

```dart
ValidateString()
  .setLabel('Code')
  .addValidator((v) {
    if (v != null && !v.startsWith('APP-')) {
      return const ValidationFailure(
        code: ValidationCode.custom,
        message: 'Code must start with APP-.',
      );
    }
    return null;
  });
```

## Error Messages

Messages are resolved in this order for each failing check:

1. **`messageFactory`** — argument on the specific method call
2. **`ValidatorLocale.current`** — global locale map, keyed by `ValidationCode`
3. **Hardcoded default** — English fallback inside the validator

### Per-call override

```dart
ValidateString()
  .setLabel('Email')
  .email(messageFactory: (label, _) => 'Please enter a valid $label');
```

### Global locale

```dart
ValidatorLocale.setLocale(ValidatorLocale({
  ValidationCode.required:     (p) => '${p['name']} is required.',
  ValidationCode.emailInvalid: (p) => '${p['name']} is not a valid email.',
  ValidationCode.stringMin:    (p) => '${p['name']} must be at least ${p['min']} characters.',
}));
```

Reset in tests to avoid state leakage:

```dart
tearDown(() => ValidatorLocale.resetLocale());
```

## ValidationResult

Every validator returns a sealed `ValidationResult`:

```dart
final result = ValidateString().email().validate(input);

switch (result) {
  ValidationSuccess() => // passed
  ValidationFailure(:final code, :final message, :final context) =>
      // code   — ValidationCode enum value
      // message — resolved error string
      // context — map of parameters used to build the message
}
```

## License

MIT
