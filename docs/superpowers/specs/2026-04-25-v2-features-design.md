# v2 Feature Additions Design

**Date:** 2026-04-25
**Status:** Approved

## Overview

Add the following to the existing v2 API before first public release. No breaking changes to `ValidationResult` or `FormValidationResult` (Transform rejected — validation and value mutation are separate concerns).

---

## 1. DupSchema Enhancements

### 1-1. `when()` — Conditional Validation

Applies a set of field validators only when a condition on another field is met. Multiple `when()` calls can be chained.

```dart
DupSchema({
  'paymentType': ValidateString().required().includedIn(['card', 'bank']),
  'cardNumber':  ValidateString(),
  'bankAccount': ValidateString(),
})
.when(
  field: 'paymentType',
  condition: (dynamic v) => v == 'card',
  then: {'cardNumber': ValidateString().required().creditCard()},
)
.when(
  field: 'paymentType',
  condition: (dynamic v) => v == 'bank',
  then: {'bankAccount': ValidateString().required()},
);
```

`condition` has type `bool Function(dynamic)`. The raw input value (possibly `null`) is passed as-is.

**Behavior:**
- Before any validation runs, all `when()` conditions are evaluated against the raw input data to compose the effective validator set. Only then does validation execute.
- When a condition matches, the `then` validators replace (not merge with) the base validators for those fields.
- Multiple `when()` blocks are evaluated independently; all matching blocks apply. If two blocks target the same field, the last matching block wins.
- If `pick()`/`omit()` removes the `field:` target of a `when()` rule, the entire rule is dropped. If only some `then:` fields are removed, the rule is retained with the remaining fields.
- `DupSchema.hasAsyncValidators` must inspect all `when().then` branch validators in addition to base validators, so `validateSync()` asserts correctly even when async validators appear only in conditional branches.
- Works with both `validate()` and `validateSync()`.

### 1-2. `pick()` / `omit()`

Return a new `DupSchema` containing only the specified fields. The original schema is unchanged.

```dart
final userSchema = DupSchema({
  'name':     ValidateString().required(),
  'email':    ValidateString().required().email(),
  'password': ValidateString().required().password(),
  'age':      ValidateNumber().required().min(18),
});

final loginSchema   = userSchema.pick(['email', 'password']);
final profileSchema = userSchema.omit(['password']);
```

**Behavior:**
- `pick(fields)` — keeps only the named fields; ignores unknown names.
- `omit(fields)` — removes the named fields; ignores unknown names.
- `crossValidate` is not carried over (depends on fields that may no longer exist).
- `when()` rules are dropped when their `field:` target is removed. Rules whose `then:` targets are partially removed are retained with the remaining fields.
- Validator instances are reused (not cloned). To prevent the new schema's constructor from overwriting custom labels, `pick()`/`omit()` capture each validator's current label (`validator.label.isNotEmpty ? validator.label : fieldName`) and pass it as the `labels` map to the derived schema's constructor.

### 1-3. `partial()`

Returns a new `DupSchema` where `required` presence checks are skipped at validation time. All other validators remain active.

```dart
// notBlank must be explicitly added for partial() to enforce it
final userSchema = DupSchema({
  'name':  ValidateString().required().notBlank(),
  'email': ValidateString().required().email(),
});

final patchSchema = userSchema.partial();

await patchSchema.validate({'name': 'John'});   // ✓ — only name sent
await patchSchema.validate({'email': 'bad'});   // ✗ — email format still checked
await patchSchema.validate({'name': '   '});    // ✗ — notBlank survives partial()
await patchSchema.validate({'name': null});     // ✓ — required removed, null is fine
```

**Behavior:**
- `partial()` returns a new `DupSchema` with `_isPartial = true` and the same validator instances. No cloning — Dart closures capture the original `this`, so copying phase entries to a new instance would leave label references bound to the original.
- `addPhaseValidator` gains a named parameter `{bool isPresence = false}`. `required` is registered with `isPresence: true`. All other validators use the default `false`.
- `BaseValidator.validateAsync` and `BaseValidator.validate` gain `{bool skipPresence = false}`. When `skipPresence` is `true`, phase entries where `isPresence == true` are skipped.
- `DupSchema` passes `skipPresence: _isPartial` when calling each field validator. This is the only change to the `DupSchema → BaseValidator` call boundary.
- `when()` + `partial()`: because the skip happens inside `BaseValidator` at call time, `required()` in `then:` validators is also skipped when the parent schema is in partial mode.
- Useful for PATCH endpoints where only changed fields are submitted.

---

## 2. New Validator Types

### 2-1. `ValidateMap<V>`

Validates a `Map<String, V>` value. Keys are always `String`.

```dart
ValidateMap<num>()
  .required()
  .minSize(1)
  .maxSize(10)
  .keyValidator(ValidateString().alpha())
  .valueValidator(ValidateNumber().min(0).max(100));
```

**Methods:**

| Method | Phase | Description |
|---|---|---|
| `minSize(int)` | 2 | Map must have at least N entries |
| `maxSize(int)` | 2 | Map must have at most N entries |
| `keyValidator(ValidateString)` | 1 | Applied to every key |
| `valueValidator(BaseValidator)` | 1 | Applied to every value |

**Type parameter:** `valueValidator` is declared as `valueValidator(covariant BaseValidator<V, dynamic> validator)`. Use `ValidateMap<num>` with `ValidateNumber` (which validates `num`, not `int`).

**Async propagation:** `ValidateMap.hasAsyncValidators` overrides to return `super.hasAsyncValidators || (keyValidator?.hasAsyncValidators ?? false) || (valueValidator?.hasAsyncValidators ?? false)`. `super.hasAsyncValidators` covers async validators on the map itself.

**Error reporting:** Uses bracket notation for flattened keys. `DupSchema` flattens via `NestedValidator` (see below):

```dart
result('metadata[score]')?.message   // "score must be at most 100"
result('metadata[badKey]')?.message  // "badKey is not alphabetic"
```

The bracket vs dot distinction is intentional: `[]` matches Map access syntax; `.` matches object property access syntax.

`mapKeyInvalid` and `mapValueInvalid` are fallback codes used only when the inner validator does not produce its own code. Normally the inner validator's code is preserved.

### 2-2. `ValidateObject`

Wraps a `DupSchema` as a single-field validator, enabling nested object validation.

```dart
final addressSchema = DupSchema({
  'street': ValidateString().required(),
  'city':   ValidateString().required(),
  'zip':    ValidateString().required().koPostalCode(),
});

final orderSchema = DupSchema({
  'orderId':         ValidateString().required().uuid(),
  'shippingAddress': ValidateObject(addressSchema).required(),
  'billingAddress':  ValidateObject(addressSchema),
});
```

**`NestedValidationFailure` class:**

```dart
// lib/src/internal/nested_validator.dart — not exported from dup.dart
class NestedValidationFailure extends ValidationFailure {
  final Map<String, ValidationFailure> nestedErrors;

  NestedValidationFailure(this.nestedErrors)
      : super(
          code: ValidationCode.nestedFailed,
          message: 'Nested validation failed: '
              '${nestedErrors.keys.first} — '
              '${nestedErrors.values.first.message}',
        );
}
```

**Internal flattening path:** `ValidateObject` and `ValidateMap` implement the internal `NestedValidator` interface in `lib/src/internal/nested_validator.dart`. Using a non-`_` name allows the interface to be shared across files:

```dart
// lib/src/internal/nested_validator.dart — not exported
sealed class NestedValidationResult {}

class NestedNormalFailure extends NestedValidationResult {
  final ValidationFailure failure;
  NestedNormalFailure(this.failure);
}

class NestedInnerFailure extends NestedValidationResult {
  final Map<String, ValidationFailure> errors;
  NestedInnerFailure(this.errors);
}

abstract interface class NestedValidator {
  Future<NestedValidationResult?> validateNested(dynamic value);
  NestedValidationResult? validateNestedSync(dynamic value);
}
```

`validateNested()` runs the normal phase chain first (via `validateAsync`/`validate`). If any phase validator fails, it returns `NestedNormalFailure(failure)`. Only if the normal chain passes does it run the inner schema and return `NestedInnerFailure(errors)` on failure, or `null` on success.

`DupSchema` checks `if (validator is NestedValidator)` and dispatches:
- `NestedNormalFailure` → `errors[field] = failure`
- `NestedInnerFailure` → flatten: `errors['$field.subField'] = subFailure` (dot) or `errors['$field[key]'] = subFailure` (bracket for map)
- `null` → field passes

The public `validateAsync()`/`validate()` on `ValidateObject` (called via `DupSchema.validateField()` or directly) never returns `NestedValidationFailure`. It returns a single `ValidationFailure(nestedFailed)` summarising the first failing sub-field, or `ValidationSuccess`. `NestedValidationFailure` is exclusively an internal transport type.

**`ValidateObject.validateAsync()` override:** `ValidateObject` overrides `validateAsync()` to run the normal inherited phase chain first, then if all phases pass, runs the inner schema and returns `ValidationFailure(nestedFailed)` on inner failure. This ensures `required()` and other normal validators on the object itself are respected on the direct-call path.

**Async propagation:** `ValidateObject.hasAsyncValidators` overrides to return `super.hasAsyncValidators || _innerSchema.hasAsyncValidators`.

---

## 3. New Validator Methods

### ValidateString — 9 new methods

> `oneOf` / `notOneOf` are already available as `includedIn(List<T>)` / `excludedFrom(List<T>)` on `BaseValidator`. They are not re-added.

| Method | Phase | Description |
|---|---|---|
| `startsWith(String prefix)` | 1 | Trimmed value must start with prefix |
| `endsWith(String suffix)` | 1 | Trimmed value must end with suffix |
| `contains(String substring)` | 1 | Value must contain substring (no trim — preserves match semantics) |
| `ipAddress()` | 1 | Valid IPv4 or IPv6 address |
| `hexColor()` | 1 | Valid hex color (`#RGB` or `#RRGGBB`) |
| `base64()` | 1 | Valid Base64-encoded string |
| `json()` | 1 | Parseable JSON string |
| `creditCard()` | 1 | Valid credit card number (Luhn algorithm) |
| `koPostalCode()` | 1 | Korean 5-digit postal code (renamed from `postalCode` for clarity) |

All methods null-skip. `startsWith`/`endsWith` trim before checking. `contains` does not trim.

`json()` passes any parseable JSON value including `"null"`, `"42"`, `"true"`. The validator checks parseability, not structure — use `addValidator` if object/array-only is needed.

### ValidateNumber — 2 new methods

> `isIn(List<num>)` removed — duplicate of `BaseValidator.includedIn(List<T>)` which already works on `ValidateNumber`.

| Method | Phase | Description |
|---|---|---|
| `isPrecision(int digits)` | 1 | At most `digits` decimal places |
| `isPort()` | 1 | Integer in range 0–65535; non-integer values (e.g. `80.5`) also fail |

`isPort()` implicitly checks that the value is an integer.

### ValidateDateTime — 5 new methods

| Method | Phase | Description |
|---|---|---|
| `isWeekday()` | 1 | Monday–Friday — intrinsic date property, no runtime reference |
| `isWeekend()` | 1 | Saturday–Sunday — intrinsic date property, no runtime reference |
| `isSameDay(DateTime target)` | 1 | Same calendar day as fixed `target` (like `isBefore`/`isAfter`) |
| `isToday()` | 2 | Same calendar day as `DateTime.now()` — runtime comparison, like `isInFuture` |
| `isWithin(Duration duration, {DateTime? from})` | 2 | Within `duration` of `from` (default `DateTime.now()`) |

**Phase rationale:** Phase 1 for fixed/intrinsic checks (`isWeekday`, `isWeekend`, `isSameDay`), phase 2 for runtime comparisons against `DateTime.now()` (`isToday`, `isWithin`) — consistent with existing `isInFuture`/`isInPast` at phase 2. All comparisons use local time.

### ValidateList — 1 new method

| Method | Phase | Description |
|---|---|---|
| `containsAll(List<T> items)` | 2 | List must contain every item in `items` |

Phase 2 — consistent with all other `ValidateList` constraint checks (`contains`, `doesNotContain`, `all`, `any`, etc.).

---

## 4. Locale Improvements

### Current state

`ValidatorLocale` supports partial overrides, but English defaults are not accessible as a `ValidatorLocale` object and there is no way to extend an existing locale.

### Changes

**`ValidatorLocale.base`** — exposes the built-in English defaults as a `ValidatorLocale` instance. Implementing this requires centralising all hardcoded English messages (currently spread across validator bodies) into a single map. This is non-trivial but necessary for `base` to be authoritative.

**`merge(Map<ValidationCode, LocaleMessage> overrides)`** — returns a new `ValidatorLocale` with overlay semantics: `overrides` wins on conflict; all other entries from the receiver are preserved. The receiver is not mutated.

```dart
final myLocale = ValidatorLocale.base.merge({
  ValidationCode.required:     (p) => '${p['name']} 필수입력입니다.',
  ValidationCode.emailInvalid: (_) => '이메일 형식이 올바르지 않습니다.',
});
ValidatorLocale.setLocale(myLocale);
```

---

## 5. New ValidationCode Values Required

`startsWith`, `endsWith`, `stringContains`, `ipAddress`, `hexColor`, `base64`, `json`, `creditCard`, `koPostalCode`, `numberPrecision`, `isPort`, `isWeekday`, `isWeekend`, `isToday`, `isSameDay`, `isWithin`, `listContainsAll`, `mapMinSize`, `mapMaxSize`, `mapKeyInvalid`, `mapValueInvalid`, `nestedFailed`

> `oneOf`/`notOneOf` already exist. `numberIn` removed (duplicate of `oneOf` via `includedIn`). `postalCode` renamed to `koPostalCode`.

---

## Out of Scope

- Transform pipeline
- Built-in locale files (`KoLocale` etc.) — consumer's responsibility
- `isSorted()` — `satisfy()` covers it
- `ipv4()`/`ipv6()` — `ipAddress()` covers both
- `isIn(List<num>)` — duplicate of `includedIn()`
