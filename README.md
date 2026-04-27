# dup

A schema-based validation library for Dart, inspired by [zod](https://zod.dev) and [yup](https://github.com/jquense/yup).

Pure Dart — works in Flutter, server, and CLI projects with no platform dependencies.

## Features

- **Fluent, chainable API** — build validators with a readable method chain
- **Phase-ordered execution** — `required` always fires before format and range checks, regardless of chain order
- **Sealed result types** — `ValidationResult` and `FormValidationResult` enable exhaustive `switch` matching
- **DupSchema** — group validators into a form schema with cross-field validation
- **Nested validation** — `ValidateObject` and `ValidateMap` flatten errors to dot / bracket notation
- **Conditional rules** — `when()` replaces validators based on runtime field values
- **Schema derivation** — `pick()`, `omit()`, and `partial()` derive new schemas without duplication
- **Three-level error messages** — per-call override → global locale → English default
- **Async validator support** — `addAsyncValidator` for DB lookups and API checks
- **Null-skip semantics** — non-required validators pass silently on `null`

## Installation

```yaml
dependencies:
  dup: ^2.0.0
```

```dart
import 'package:dup/dup.dart';
```

## Quick Start

```dart
final schema = DupSchema({
  'email': ValidateString().email().required(),
  'age':   ValidateNumber().min(18).required(),
});

final result = await schema.validate({
  'email': 'user@example.com',
  'age':   25,
});

switch (result) {
  case FormValidationSuccess():
    print('All good!');
  case FormValidationFailure():
    for (final field in result.fields) {
      print('$field: ${result(field)!.message}');
    }
}
```

## DupSchema

### Basic usage

```dart
final schema = DupSchema(
  {
    'email':           ValidateString().email().required(),
    'password':        ValidateString().min(8).required(),
    'passwordConfirm': ValidateString().required(),
  },
  labels: {'passwordConfirm': 'Password confirmation'},
);
```

The `labels` map overrides the error message label for a field (defaults to the key name).

### Reading errors

```dart
if (result is FormValidationFailure) {
  result.hasError('email');       // bool
  result('email')?.message;      // String? — the error message
  result('email')?.code;         // ValidationCode enum value
  result.fields;                  // List<String> — all failing field names
  result.firstField;              // String? — first failing field name
}
```

### Validation methods

```dart
// Async — always safe; required when async validators are registered
final result = await schema.validate(data);

// Sync — throws StateError if async validators are present
final result = schema.validateSync(data);

// Single field — for on-change feedback in TextFormField
final fieldResult = await schema.validateField('email', value);

// Single field with when() rules applied
final fieldResult = await schema.validateField('type', value, data: formData);
```

### Cross-field validation

Runs only when all individual fields pass:

```dart
schema.crossValidate((data) {
  if (data['password'] != data['passwordConfirm']) {
    return {
      'passwordConfirm': const ValidationFailure(
        code: ValidationCode.custom,
        message: 'Passwords do not match.',
        context: {},
      ),
    };
  }
  return null;
});
```

### Conditional rules — `when()`

Replaces validators for specified fields when a condition is met at runtime:

```dart
final schema = DupSchema({
  'type':    ValidateString().required(),
  'company': ValidateString(),
}).when(
  field: 'type',
  condition: (v) => v == 'business',
  then: {'company': ValidateString().required()},
);
```

### Schema derivation — `pick()`, `omit()`, `partial()`

```dart
// Keep only listed fields
final loginSchema = fullSchema.pick(['email', 'password']);

// Remove listed fields
final publicSchema = fullSchema.omit(['passwordConfirm']);

// Skip all required checks (useful for PATCH requests)
final patchSchema = fullSchema.partial();
```

---

## Validators

### ValidateString

| Method | Phase | Description |
|---|---|---|
| `required()` | 0 | Fails for null or empty string |
| `notBlank()` | 1 | Fails for whitespace-only string |
| `min(n)` | 2 | At least `n` characters (trimmed) |
| `max(n)` | 2 | At most `n` characters (trimmed) |
| `matches(RegExp)` | 1 | Must match the regex |
| `email()` | 1 | Valid email address |
| `url()` | 1 | Valid HTTP/HTTPS URL |
| `uuid()` | 1 | Valid UUID v4 |
| `password({minLength})` | 1 | ASCII printable chars, default min length 4 |
| `alpha()` | 1 | Letters only (a–z, A–Z) |
| `alphanumeric()` | 1 | Letters and digits only |
| `numeric()` | 1 | Digits only (0–9) |
| `emoji()` | 1 | Fails when value contains emoji |
| `startsWith(prefix)` | 1 | Must start with prefix |
| `endsWith(suffix)` | 1 | Must end with suffix |
| `contains(substring)` | 1 | Must contain substring |
| `ipAddress()` | 1 | Valid IPv4 or IPv6 address |
| `hexColor()` | 1 | Valid hex color (`#RGB` or `#RRGGBB`) |
| `base64()` | 1 | Valid Base64-encoded string |
| `json()` | 1 | Valid JSON string |
| `creditCard()` | 1 | Valid credit card number (Luhn check, 13–19 digits) |
| `koMobile({customRegex})` | 1 | Mobile number (default: Korean format) |
| `koPhone({customRegex})` | 1 | Landline number (default: Korean format) |
| `bizno({customRegex})` | 1 | Business registration number (default: Korean) |
| `koPostalCode()` | 1 | Korean 5-digit postal code |
| `equalTo(other)` | 3 | Must equal another value |
| `satisfy(fn)` | 3 | Custom inline predicate |
| `addValidator(fn)` | 3 | Custom validator returning `ValidationFailure?` |
| `addAsyncValidator(fn)` | 4 | Async custom validator |

### ValidateNumber

| Method | Phase | Description |
|---|---|---|
| `required()` | 0 | Fails for null |
| `min(n)` | 2 | Value ≥ n |
| `max(n)` | 2 | Value ≤ n |
| `between(min, max)` | 2 | Inclusive range |
| `isInteger()` | 1 | No fractional part |
| `isPrecision(digits)` | 1 | At most `digits` decimal places |
| `isPort()` | 1 | Integer in range 0–65535 |
| `isPositive()` | 2 | Value > 0 |
| `isNegative()` | 2 | Value < 0 |
| `isNonNegative()` | 2 | Value ≥ 0 |
| `isNonPositive()` | 2 | Value ≤ 0 |
| `isEven()` | 2 | Even integer |
| `isOdd()` | 2 | Odd integer |
| `isMultipleOf(n)` | 2 | Multiple of n |

**Flutter TextFormField integration:**

```dart
TextFormField(
  validator: ValidateNumber()
    .setLabel('Age')
    .min(18)
    .max(120)
    .isInteger()
    .toValidator(),
)
```

`toValidator()` parses string input to `num` before validating, returning a parse error for non-numeric input like `"abc"` or `"17세"`.

### ValidateList\<T\>

| Method | Phase | Description |
|---|---|---|
| `required()` | 0 | Fails for null |
| `isNotEmpty()` | 1 | At least one item |
| `isEmpty()` | 1 | Must be empty |
| `minLength(n)` | 2 | At least `n` items |
| `maxLength(n)` | 2 | At most `n` items |
| `hasLength(n)` | 2 | Exactly `n` items |
| `lengthBetween(min, max)` | 2 | Item count in range |
| `contains(item)` | 2 | Must contain item |
| `doesNotContain(item)` | 2 | Must not contain item |
| `containsAll(items)` | 2 | Must contain all items |
| `hasNoDuplicates()` | 2 | No duplicate items |
| `all(predicate)` | 3 | Every item satisfies predicate |
| `any(predicate)` | 3 | At least one item satisfies predicate |
| `none(predicate)` | 3 | No items satisfy predicate |
| `eachItem(fn)` | 3 | Per-item validator; reports first failing index |

### ValidateBool

| Method | Phase | Description |
|---|---|---|
| `required()` | 0 | Fails for null |
| `isTrue()` | 1 | Must be `true` |
| `isFalse()` | 1 | Must be `false` |

```dart
// "Agree to terms" checkbox
ValidateBool().setLabel('Terms').isTrue().required();
```

### ValidateDateTime

| Method | Phase | Description |
|---|---|---|
| `required()` | 0 | Fails for null |
| `isBefore(target)` | 1 | Strictly before target |
| `isAfter(target)` | 1 | Strictly after target |
| `isSameDay(target)` | 1 | Same calendar day as target |
| `isToday()` | 1 | Same calendar day as today |
| `isWeekday()` | 1 | Monday–Friday |
| `isWeekend()` | 1 | Saturday or Sunday |
| `min(date)` | 2 | On or after date |
| `max(date)` | 2 | On or before date |
| `between(min, max)` | 2 | Inclusive range |
| `isInFuture()` | 2 | After `DateTime.now()` |
| `isInPast()` | 2 | Before `DateTime.now()` |
| `isWithin(duration)` | 2 | Within duration from now |

### ValidateObject

Validates a nested `Map<String, dynamic>` using an inner `DupSchema`. Errors are flattened with **dot notation**:

```dart
final schema = DupSchema({
  'user': ValidateObject(DupSchema({
    'name':  ValidateString().required(),
    'email': ValidateString().email().required(),
  })).required(),
});

final result = await schema.validate({
  'user': {'name': 'Alice', 'email': 'bad-email'},
});

// Error key: 'user.email'
print(result('user.email')?.message); // user.email is not a valid email address.
```

### ValidateMap\<V\>

Validates all keys and values of a `Map<String, V>`. Errors are flattened with **bracket notation**:

```dart
final schema = DupSchema({
  'scores': ValidateMap<int>()
    .keyValidator(ValidateString().alphanumeric())
    .valueValidator(ValidateNumber().between(0, 100).isInteger())
    .minSize(1)
    .required(),
});

final result = await schema.validate({
  'scores': {'math': 95, 'english': 110},
});

// Error key: 'scores[english]'
print(result('scores[english]')?.message); // english must be at most 100.
```

---

## Phase Ordering

Validators always run in phase order, regardless of chain order. `required` always fires first; async validators always run last.

| Phase | What runs |
|---|---|
| 0 | `required` |
| 1 | `notBlank`, format checks (`email`, `isInteger`, `isBefore`, …) |
| 2 | Constraint checks (`min`, `max`, `between`, …) |
| 3 | Custom (`addValidator`, `satisfy`, `equalTo`, …) |
| 4 | Async (`addAsyncValidator`) |

```dart
// These two chains behave identically
ValidateString().email().required();
ValidateString().required().email();
```

---

## Error Messages

Messages are resolved in this order:

1. **`messageFactory`** — argument on the specific method call
2. **`ValidatorLocale.current`** — global locale map keyed by `ValidationCode`
3. **Hardcoded default** — English fallback

### Per-call override

```dart
ValidateString()
  .setLabel('Email')
  .email(messageFactory: (label, _) => 'Please enter a valid $label address.');
```

### Global locale

```dart
ValidatorLocale.setLocale(ValidatorLocale({
  ValidationCode.required:     (p) => '${p['name']}은(는) 필수 입력입니다.',
  ValidationCode.emailInvalid: (p) => '${p['name']} 형식이 올바르지 않습니다.',
  ValidationCode.stringMin:    (p) => '${p['name']}은(는) 최소 ${p['min']}자 이상이어야 합니다.',
  ValidationCode.numberMin:    (p) => '${p['name']}은(는) ${p['min']} 이상이어야 합니다.',
}));
```

Reset in tests to avoid state leakage:

```dart
tearDown(() => ValidatorLocale.resetLocale());
```

---

## Async Validators

```dart
final usernameValidator = ValidateString()
  .setLabel('Username')
  .min(3)
  .max(20)
  .alphanumeric()
  .required()
  ..addAsyncValidator((value) async {
    final taken = await userRepository.exists(value!);
    if (taken) {
      return const ValidationFailure(
        code: ValidationCode.custom,
        message: 'Username is already taken.',
        context: {},
      );
    }
    return null;
  });

final result = await usernameValidator.validateAsync('alice');
```

Use `schema.hasAsyncValidators` to decide between `validate()` and `validateSync()`.

---

## Custom Validators

### Inline predicate

```dart
ValidateString()
  .setLabel('Code')
  .satisfy(
    (v) => v != null && v.startsWith('APP-'),
    messageFactory: (label, _) => '$label must start with APP-.',
  );
```

### Full validator function

```dart
ValidateNumber()
  .setLabel('Score')
  .addValidator((value) {
    if (value != null && value % 7 != 0) {
      return const ValidationFailure(
        code: ValidationCode.custom,
        message: 'Score must be a multiple of 7.',
        context: {},
      );
    }
    return null;
  });
```

---

## ValidationResult

Every single-field validator returns a sealed `ValidationResult`:

```dart
final result = ValidateString().email().validate(input);

switch (result) {
  case ValidationSuccess():
    // passed
  case ValidationFailure(:final code, :final message, :final context):
    // code    — ValidationCode enum value
    // message — resolved error string
    // context — parameters used to build the message (e.g. {'name': 'Email', 'min': 8})
}
```

---

## License

MIT
