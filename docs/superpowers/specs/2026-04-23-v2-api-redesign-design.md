# dup v2.0.0 — API Redesign Design Spec

**Date:** 2026-04-23
**Status:** Approved
**Scope:** Full API redesign before first pub.dev release

---

## Background

dup was a pure Dart validation library returning `String?` from `validate()` (null = pass, string = error message) and throwing `FormValidationException` at the form level. Before the v2 public release, the entire API is being redesigned to be structured, type-safe, and modern — inspired by zod's discriminated union pattern but adapted for Dart idioms and form UX use cases.

---

## Goals

- Replace `String?` return with a sealed class discriminated union
- Replace `FormValidationException` / `useUiForm` with a clean `DupSchema` API
- Make error codes type-safe via `enum ValidationCode`
- Support Flutter `TextFormField` integration without adding a Flutter dependency
- Support locale customization and custom validators within the same architecture
- Include cross-field validation and per-field validation
- Publish a migration guide from v1.x

---

## Section 1 — Core Types

### `enum ValidationCode`

All built-in error codes plus `custom` for user-defined validators. Using enum ensures exhaustive `switch` checking at compile time — adding a new code surfaces missing cases immediately.

```dart
enum ValidationCode {
  // shared (BaseValidator)
  required, notBlank, equal, notEqual, oneOf, notOneOf, condition, custom,

  // string
  stringMin, stringMax, matches, emailInvalid, passwordMin, emoji,
  mobileInvalid, phoneInvalid, biznoInvalid, url, uuid,
  alpha, alphanumeric, numeric,

  // number
  numberMin, numberMax, integer, positive, negative,
  nonNegative, nonPositive, between, even, odd, multipleOf,

  // list
  listNotEmpty, listEmpty, listMin, listMax, listLengthBetween,
  listExactLength, contains, doesNotContain, all, any, none,
  noDuplicates, eachItem,

  // datetime
  dateMin, dateMax, dateBefore, dateAfter, dateBetween,
  dateInFuture, dateInPast,
}
```

### `sealed class ValidationResult`

Field-level result. Always returned (never null). `ValidationSuccess` carries no data — dup is a pure validator, not a parser/transformer like zod.

```dart
sealed class ValidationResult {
  const ValidationResult();
}

class ValidationSuccess extends ValidationResult {
  const ValidationSuccess();
}

class ValidationFailure extends ValidationResult {
  final ValidationCode code;
  final String message;
  final Map<String, dynamic> context; // e.g. {name: 'Email', min: 3}

  const ValidationFailure({
    required this.code,
    required this.message,
    this.context = const {},
  });
}
```

**Usage:**
```dart
switch (validator.validate(value)) {
  case ValidationSuccess():
    // pass
  case ValidationFailure(:final code, :final message):
    print('$code: $message');
}
```

---

## Section 2 — API Structure

### Removed

| Old | Reason |
|---|---|
| `useUiForm` singleton | Replaced by `DupSchema` |
| `FormValidationException` | Replaced by `FormValidationResult` sealed class |
| `BaseValidatorSchema` | Replaced by `DupSchema` |
| `hasError()` / `getError()` helpers | `FormValidationFailure` provides equivalent API |

### `DupSchema`

Central class for form-level validation. Schema keys are automatically used as field labels — `setLabel()` is not needed for schema-based use.

```dart
final schema = DupSchema({
  'email': ValidateString().email().required(),
  'password': ValidateString().password(minLength: 8).required(),
  'age': ValidateNumber().min(18).isInteger().required(),
});
```

**Methods:**

```dart
// Async — runs all validators including async
Future<FormValidationResult> validate(Map<String, dynamic> data)

// Sync — skips async validators
FormValidationResult validateSync(Map<String, dynamic> data)

// Per-field — for onChange use case
Future<ValidationResult> validateField(String field, dynamic value)

// Cross-field — chained after constructor
DupSchema crossValidate(
  Map<String, ValidationFailure>? Function(Map<String, dynamic> fields) fn
)
```

**`crossValidate` does not run during `validateField()`** — it requires all field values to be present.

**`crossValidate` callback is sync-only.** If cross-field logic requires async (e.g., checking a username+email combo against a server), use `addAsyncValidator` on individual fields instead.

### `sealed class FormValidationResult`

Form-level result. Mirrors `ValidationResult` pattern for consistency.

```dart
sealed class FormValidationResult {}

class FormValidationSuccess extends FormValidationResult {
  const FormValidationSuccess();
}

class FormValidationFailure extends FormValidationResult {
  final Map<String, ValidationFailure> errors;
  const FormValidationFailure(this.errors);

  // Access a specific field's failure
  ValidationFailure? call(String field) => errors[field];

  // Check if a specific field failed
  bool hasError(String field) => errors.containsKey(field);

  // All failing field names — for rendering error states
  List<String> get fields => errors.keys.toList();

  // First failing field — for focus management
  String? get firstField => errors.keys.firstOrNull;
}
```

**Usage:**
```dart
final result = await schema.validate(formData);

switch (result) {
  case FormValidationSuccess():
    submitForm();
  case FormValidationFailure(:final errors):
    // Move focus to first failing field
    focusNodes[errors.firstField]?.requestFocus();

    // Show error on a specific field
    errors('email')?.message;
    errors('email')?.code;

    // Render error indicator on all failing fields
    for (final field in errors.fields) {
      markError(field, errors(field)!.message);
    }
}
```

### Cross-field validation

```dart
final schema = DupSchema({
  'password': ValidateString().min(8).required(),
  'passwordConfirm': ValidateString().required(),
}).crossValidate((fields) {
  if (fields['password'] != fields['passwordConfirm']) {
    return {
      'passwordConfirm': ValidationFailure(
        code: ValidationCode.custom,
        message: 'Passwords do not match.',
      ),
    };
  }
  return null;
});
```

### `toValidator()` / `toAsyncValidator()` — Flutter TextFormField integration

Pure Dart — no Flutter dependency. The return type `String? Function(String?)` happens to be compatible with Flutter's `TextFormField.validator`.

```dart
// Sync chain
TextFormField(
  validator: ValidateString()
    .setLabel('이메일')
    .email()
    .required()
    .toValidator(), // String? Function(String?)
)

// Chain with addAsyncValidator
TextFormField(
  validator: ValidateString()
    .email()
    .addAsyncValidator(checkDuplicate)
    .toAsyncValidator(), // Future<String?> Function(String?)
)
```

**Non-string validator `toValidator()`** parses the string input before validating. Parse failure returns a fixed message using the field label; it does not go through `ValidatorLocale` since it's an adapter concern, not a validator concern.

```dart
// ValidateNumber — parses the string before validating
TextFormField(
  validator: ValidateNumber()
    .setLabel('나이')
    .min(18)
    .isInteger()
    .toValidator(),
  // 'abc' → '나이 is not a valid number.'  (parse failure)
  // '17'  → '나이 must be at least 18.'    (validation failure)
  // '20'  → null (pass)
)
```

**`setLabel()` is only required for standalone use** (without `DupSchema`). When used with `DupSchema`, the schema key is the label.

---

## Section 3 — Custom Validators & Locale

### Custom validators

`addValidator()` and `addAsyncValidator()` now return `ValidationFailure?` instead of `String?`. Use `ValidationCode.custom` for all user-defined codes. `null` means pass.

```dart
ValidateString()
  .email()
  .required()
  .addValidator((value) {
    if (value == 'admin@forbidden.com') {
      return ValidationFailure(
        code: ValidationCode.custom,
        message: 'This email is not allowed.',
      );
    }
    return null;
  });

// Async custom validator
ValidateString()
  .addAsyncValidator((value) async {
    final taken = await checkEmailTaken(value!);
    return taken
      ? ValidationFailure(
          code: ValidationCode.custom,
          message: 'Email already in use.',
        )
      : null;
  });
```

### Locale — `ValidationCode` enum keys

`ValidatorLocale` is redesigned to use `ValidationCode` as map keys. Only specified codes need to be provided — unspecified codes fall back to English defaults.

```dart
ValidatorLocale.setLocale(ValidatorLocale({
  ValidationCode.required:     (p) => '${p['name']}은(는) 필수입니다.',
  ValidationCode.emailInvalid: (p) => '올바른 이메일 주소를 입력하세요.',
  ValidationCode.stringMin:    (p) => '${p['name']}은(는) 최소 ${p['min']}자 이상이어야 합니다.',
  ValidationCode.numberMin:    (p) => '${p['name']}은(는) ${p['min']} 이상이어야 합니다.',
  // 명시하지 않은 코드는 영어 기본값 사용
}));

ValidatorLocale.resetLocale(); // 기본값으로 복원
```

**String key → enum key migration:** The old `Map<String, LocaleMessage>` is replaced by `Map<ValidationCode, LocaleMessage>`. Typos are now caught at compile time.

### Per-method `messageFactory`

Unchanged — still accepts `String?` since the code is fixed by the validator. Only the message is overridden.

```dart
ValidateString()
  .setLabel('이메일')
  .email(messageFactory: (label, params) => '$label 형식이 맞지 않습니다.')
  .required(messageFactory: (label, params) => '$label 을(를) 입력해주세요.')
```

---

## Migration Guide (v1.x → v2.0.0)

To be published on the GitHub Pages docs site.

### Before / After summary

| Before | After |
|---|---|
| `validate()` returns `String?` | `validate()` returns `ValidationResult` (sealed) |
| `null` = pass | `ValidationSuccess()` = pass |
| `'Error message'` = fail | `ValidationFailure(code, message, context)` = fail |
| `useUiForm.validate(schema, req)` throws | `schema.validate(data)` returns `FormValidationResult` |
| `FormValidationException` | `FormValidationFailure` |
| `useUiForm.getError(field, ex)` | `errors(field)?.message` |
| `addValidator((v) => String?)` | `addValidator((v) => ValidationFailure?)` |
| `ValidatorLocale(string: {...})` | `ValidatorLocale({ValidationCode.xxx: ...})` |

---

## Open Questions / Deferred

- **Schema composition** (`.merge()`, `.pick()`, `.omit()`) — deferred to post-v2
- **Type-safe schema inference** (Dart generics can't match TypeScript's mapped types) — limitation accepted
- **GitHub Pages docs site** — separate track, to include API reference + migration guide + examples
