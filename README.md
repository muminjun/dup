# dup

A schema-based validation library for Dart, inspired by [yup](https://github.com/jquense/yup) and [zod](https://zod.dev).

Pure Dart — no Flutter dependency. Works in Flutter, server, and CLI environments.

## Features

- **Fluent, chainable API** — validators compose naturally
- **Phase-ordered execution** — `required` always fires first, regardless of chain order
- **Async validator support** — `addAsyncValidator()` + `validateAsync()`
- **Three-level error messages** — per-call override → global locale → hardcoded default
- **Full null contract** — every validator skips silently on `null` unless `.required()` is set

## Installation

```yaml
dependencies:
  dup: ^2.0.0
```

## Quick start

```dart
import 'package:dup/dup.dart';

final schema = BaseValidatorSchema({
  'email': ValidateString().setLabel('Email').email().required(),
  'age':   ValidateNumber().setLabel('Age').min(0).required(),
});

try {
  await useUiForm.validate(schema, {'email': 'user@example.com', 'age': 25});
  print('All good!');
} on FormValidationException catch (e) {
  // e.errors is Map<String, String>
  e.errors.forEach((field, msg) => print('$field: $msg'));
}
```

## Validators

### ValidateString

| Method | Description |
|---|---|
| `required()` | Field must be present and non-empty |
| `min(n)` | At least `n` characters (trims whitespace) |
| `max(n)` | At most `n` characters (trims whitespace) |
| `matches(RegExp)` | Value must match the regex |
| `email()` | Must be a valid email address |
| `password({minLength})` | Minimum length check (default 4), accepts any characters |
| `emoji()` | Fails if the value contains an emoji |
| `url()` | Must be a valid http/https URL |
| `uuid()` | Must be a valid UUID (any case) |
| `mobile({customRegex})` | Korean mobile format by default; supply `customRegex` to override |
| `phone({customRegex})` | Korean landline format by default; supply `customRegex` to override |
| `bizno({customRegex})` | Korean BRN format by default; supply `customRegex` to override |

```dart
// Korean default
ValidateString().setLabel('Phone').mobile().validate('010-1234-5678'); // null

// Custom regex for international numbers
ValidateString().setLabel('Phone')
  .mobile(customRegex: RegExp(r'^\+1\d{10}$'))
  .validate('+11234567890'); // null
```

### ValidateNumber

| Method | Description |
|---|---|
| `required()` | Field must be present |
| `min(n)` | Value must be ≥ n |
| `max(n)` | Value must be ≤ n |
| `isInteger()` | Value must be a whole number |
| `isPositive()` | Value must be > 0 |
| `isNegative()` | Value must be < 0 |
| `isNonNegative()` | Value must be ≥ 0 |
| `isNonPositive()` | Value must be ≤ 0 |

### ValidateList\<T\>

| Method | Description |
|---|---|
| `required()` | Field must be present |
| `isNotEmpty()` | List must have at least one item |
| `isEmpty()` | List must be empty |
| `minLength(n)` | At least `n` items |
| `maxLength(n)` | At most `n` items |
| `lengthBetween(min, max)` | Item count in range |
| `hasLength(n)` | Exactly `n` items |
| `contains(item)` | List must contain the item |
| `doesNotContain(item)` | List must not contain the item |
| `all(predicate)` | Every item must satisfy the predicate |
| `any(predicate)` | At least one item must satisfy the predicate |
| `hasNoDuplicates()` | No duplicate items |
| `eachItem(validator)` | Run a per-item validator; reports the first failing index |

### ValidateBool

| Method | Description |
|---|---|
| `required()` | Field must be present |
| `isTrue()` | Value must be `true` |
| `isFalse()` | Value must be `false` |

```dart
// Useful for "agree to terms" checkboxes
ValidateBool().setLabel('Terms').isTrue().required().validate(false);
// → 'Terms must be true.'
```

### ValidateDateTime

| Method | Description |
|---|---|
| `required()` | Field must be present |
| `isBefore(target)` | Value must be strictly before `target` |
| `isAfter(target)` | Value must be strictly after `target` |
| `min(date)` | Value must be on or after `date` |
| `max(date)` | Value must be on or before `date` |
| `between(min, max)` | Value must be within the inclusive range |

## Phase ordering

Validators always execute in phase order, regardless of how the chain is written:

| Phase | What runs |
|---|---|
| 0 | `required` |
| 1 | Format checks (`email`, `isInteger`, `isBefore`, …) |
| 2 | Constraint checks (`min`, `max`, `between`, …) |
| 3 | Custom validators (`addValidator`, `satisfy`, `equalTo`, …) |
| 4 | Async validators (`addAsyncValidator`) |

```dart
// Both of these behave identically — required always fires first
ValidateString().setLabel('Email').email().required();
ValidateString().setLabel('Email').required().email();
```

## Async validators

```dart
final v = ValidateString().setLabel('Username').required()
  ..addAsyncValidator((value) async {
    final taken = await db.usernameExists(value!);
    return taken ? 'Username is already taken.' : null;
  });

final error = await v.validateAsync('alice'); // runs DB check
```

When using `UiFormService`, `validate()` is already async and runs async validators automatically:

```dart
await useUiForm.validate(schema, request);
```

## Custom validators

```dart
ValidateString().setLabel('Code')
  .satisfy((v) => v != null && v.startsWith('APP-'),
    messageFactory: (label, _) => '$label must start with APP-');
```

## Error helpers

```dart
FormValidationException? error;
try {
  await useUiForm.validate(schema, request);
} on FormValidationException catch (e) {
  error = e;
}

useUiForm.hasError('email', error); // bool
useUiForm.getError('email', error); // String? — the message, or null
```

## Custom error messages

### Per-call (highest priority)

```dart
ValidateString().setLabel('Email')
  .email(messageFactory: (label, _) => 'Please enter a valid email for $label');
```

### Global locale

```dart
ValidatorLocale.setLocale(ValidatorLocale(
  mixed: {
    'required': (params) => '${params['name']}을 입력해 주세요.',
  },
  string: {
    'emailInvalid': (params) => '${params['name']} 형식이 올바르지 않습니다.',
  },
  number: {},
  array: {},
));
```

## Schema validation

```dart
final schema = BaseValidatorSchema({
  'username': ValidateString().setLabel('Username').min(3).max(20).required(),
  'email':    ValidateString().setLabel('Email').email().required(),
  'age':      ValidateNumber().setLabel('Age').min(18).required(),
  'tags':     ValidateList<String>().setLabel('Tags').isNotEmpty(),
  'agreed':   ValidateBool().setLabel('Terms').isTrue().required(),
});

try {
  await useUiForm.validate(schema, formData, abortEarly: false);
} on FormValidationException catch (e) {
  print(e.errors); // Map<String, String> of all field errors
}
```

## License

MIT
