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
  condition: (v) => v == 'card',
  then: {'cardNumber': ValidateString().required().creditCard()},
)
.when(
  field: 'paymentType',
  condition: (v) => v == 'bank',
  then: {'bankAccount': ValidateString().required()},
);
```

**Behavior:**
- Before any validation runs, all `when()` conditions are evaluated against the raw input data to compose the effective validator set. Only then does validation execute.
- When a condition matches, the `then` validators replace (not merge with) the base validators for those fields.
- Multiple `when()` blocks are evaluated independently; all matching blocks apply. If two blocks target the same field, the last matching block wins.
- If `pick()`/`omit()` removes the `field:` target of a `when()` rule, the entire rule is dropped from the derived schema.
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
- `when()` rules are dropped when their `field:` target is removed. Rules whose `then:` targets are removed are also dropped.
- Validator instances are reused (not cloned) in the derived schema. To prevent the new schema's constructor from overwriting custom labels with field names, `pick()`/`omit()` capture the current label from each validator (`validator.label`) and pass it as the `labels` map when constructing the derived schema. This preserves custom labels without mutating shared instances.

### 1-3. `partial()`

Returns a new `DupSchema` where `required` presence checks are removed from every field. All other validators remain active.

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
- `partial()` strips validators tagged as presence checks at validation time. Only `required` carries this tag. `notBlank` (phase 1) is unaffected.
- Implementation: `addPhaseValidator` gains an optional `isPresence: bool` flag (default `false`). `required` passes `isPresence: true`. No cloning is needed. `partial()` returns a new `DupSchema` with `_isPartial = true` and the **same validator instances**. During `validate()`/`validateSync()`, when `_isPartial` is `true`, phase entries tagged `isPresence: true` are skipped. This avoids the closure-rebinding problem: Dart closures capture the original instance's `this`, so copying entries to a new instance would cause `setLabel()` on the clone to have no effect on the captured label inside the closures.
- `when()` + `partial()` interaction: `required()` in a `then:` validator is also skipped when the parent schema is in partial mode, because the `isPresence` check happens at validation time, not at schema construction time.
- Useful for PATCH endpoints where only changed fields are submitted.

---

## 2. New Validator Types

### 2-1. `ValidateMap<V>`

Validates a `Map<String, V>` value. Keys are always `String` (covers JSON objects and the vast majority of real-world maps). Values can have their own validator.

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

**Type parameter:** `valueValidator` is declared as `valueValidator(covariant BaseValidator<V, dynamic> validator)`. Using `covariant` relaxes Dart's type checking at the call site while keeping the type parameter `V` on `ValidateMap<V>` for documentation clarity. Use `ValidateMap<num>` with `ValidateNumber` (which validates `num`, not `int`).

**Async propagation:** `ValidateMap.hasAsyncValidators` overrides the base to return `super.hasAsyncValidators || (keyValidator?.hasAsyncValidators ?? false) || (valueValidator?.hasAsyncValidators ?? false)`. `super.hasAsyncValidators` covers async validators registered directly on the map itself; the other terms cover key/value validators. The parent `DupSchema` checks `hasAsyncValidators` on all field validators including `ValidateMap`, so `validateSync()` will assert correctly.

**Error reporting:** Key/value errors use `NestedValidationFailure` (same mechanism as `ValidateObject`). `DupSchema.validate()` and `DupSchema.validateSync()` both flatten these into the parent `FormValidationFailure`:

- Key errors: `"metadata[badKey]"` — `mapKeyInvalid` code, label is the key string itself.
- Value errors: `"metadata[score]"` — individual validator's code and label (the key string).

```dart
result('metadata[score]')?.message   // "score must be at most 100"
result('metadata[badKey]')?.message  // "badKey is not alphabetic"
```

`mapKeyInvalid` and `mapValueInvalid` are wrapper codes used only when the inner validator itself does not produce a code (i.e., as a fallback). Normally, the inner validator's own code is preserved.

### 2-2. `ValidateObject`

Wraps a `DupSchema` as a single-field validator, enabling nested object validation.

```dart
final addressSchema = DupSchema({
  'street': ValidateString().required(),
  'city':   ValidateString().required(),
  'zip':    ValidateString().required().postalCode(),
});

final orderSchema = DupSchema({
  'orderId':         ValidateString().required().uuid(),
  'shippingAddress': ValidateObject(addressSchema).required(),
  'billingAddress':  ValidateObject(addressSchema),
});
```

**`NestedValidationFailure` class definition:**

```dart
// Internal transport type — not exported from dup.dart
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

**Internal flattening path:** `ValidateObject` and `ValidateMap` implement the internal `NestedValidator` interface defined in `lib/src/internal/nested_validator.dart` (imported by `validate_object.dart`, `validate_map.dart`, and `dup_schema.dart`, but **not** exported from `lib/dup.dart`). The interface returns a sealed result type so `DupSchema` can distinguish a normal field failure from inner-schema failures:

```dart
// lib/src/internal/nested_validator.dart — not exported
sealed class NestedValidationResult {}

/// A normal validator in the chain (e.g. required()) failed.
class NestedNormalFailure extends NestedValidationResult {
  final ValidationFailure failure;
  NestedNormalFailure(this.failure);
}

/// The inner schema/map validation failed; errors should be flattened.
class NestedInnerFailure extends NestedValidationResult {
  final Map<String, ValidationFailure> errors;
  NestedInnerFailure(this.errors);
}

abstract interface class NestedValidator {
  Future<NestedValidationResult?> validateNested(dynamic value);
  NestedValidationResult? validateNestedSync(dynamic value);
}
```

`validateNested()` runs the normal phase chain first (phases 0–3 + async). If a phase validator fails (e.g. `required()` rejects null), it returns `NestedNormalFailure(failure)`. Only if the normal chain passes does it run the inner schema and potentially return `NestedInnerFailure(errors)`. Returning `null` means everything passed.

`DupSchema.validate()` / `validateSync()` check `if (validator is NestedValidator)` and call `validateNested` / `validateNestedSync`:
- `NestedNormalFailure` → `errors[field] = failure` (normal field error)
- `NestedInnerFailure` → flatten: `errors['$field.subField'] = subFailure`
- `null` → field passes

`ValidateObject.hasAsyncValidators` overrides to return `super.hasAsyncValidators || _innerSchema.hasAsyncValidators`, covering both async validators on the object itself and those in the nested schema.

**Direct call path:** When `ValidateObject.validate(value)` or `ValidateObject.validateAsync(value)` is called directly (e.g. via `DupSchema.validateField()`), `ValidateObject` returns a single `ValidationFailure` with `ValidationCode.nestedFailed` and a message listing the first failing sub-field. The caller never sees `NestedValidationFailure`.

**Async propagation:** `ValidateObject.hasAsyncValidators` delegates to the inner schema's `hasAsyncValidators`, so the parent `DupSchema.validateSync()` assert fires correctly when the nested schema contains async validators.

---

## 3. New Validator Methods

### ValidateString — 9 new methods

> `oneOf` / `notOneOf` are already available as `includedIn(List<T>)` / `excludedFrom(List<T>)` on `BaseValidator` and work with `ValidateString` as-is. They are not re-added.

| Method | Phase | Description |
|---|---|---|
| `startsWith(String prefix)` | 1 | Trimmed value must start with prefix |
| `endsWith(String suffix)` | 1 | Trimmed value must end with suffix |
| `contains(String substring)` | 1 | Value must contain the substring (no trim — trimming would change match semantics) |
| `ipAddress()` | 1 | Valid IPv4 or IPv6 address |
| `hexColor()` | 1 | Valid hex color code (`#RGB` or `#RRGGBB`) |
| `base64()` | 1 | Valid Base64-encoded string |
| `json()` | 1 | Parseable JSON string |
| `creditCard()` | 1 | Valid credit card number (Luhn algorithm) |
| `postalCode()` | 1 | Korean 5-digit postal code |

All methods follow the null-skip pattern: return `null` (pass) when value is `null`.

`startsWith` and `endsWith` trim before checking (accidental leading/trailing whitespace is common). `contains` does not trim — trimming would prevent matching substrings that begin or end with spaces.

### ValidateNumber — 3 new methods

| Method | Phase | Description |
|---|---|---|
| `isPrecision(int digits)` | 1 | At most `digits` decimal places |
| `isPort()` | 1 | Integer in range 0–65535; non-integer values (e.g. `80.5`) also fail |
| `isIn(List<num>)` | 1 | Value must be one of the given numbers |

`isPort()` implicitly checks that the value is an integer. A float like `80.5` fails even if it is in range.

### ValidateDateTime — 5 new methods

| Method | Phase | Description |
|---|---|---|
| `isWeekday()` | 1 | Monday–Friday (local time) |
| `isWeekend()` | 1 | Saturday–Sunday (local time) |
| `isToday()` | 1 | Same calendar day as `DateTime.now()` (local time) |
| `isSameDay(DateTime target)` | 1 | Same calendar day as `target`; comparison uses local time on both sides |
| `isWithin(Duration duration, {DateTime? from})` | 2 | Within `duration` of `from` (default: `DateTime.now()` local time) |

**Phase rationale:** `isWeekday`, `isWeekend`, `isToday`, `isSameDay` classify the type of date (analogous to `isBefore`/`isAfter` at phase 1). `isWithin` is a range constraint (analogous to `between`/`isInFuture` at phase 2). All comparisons use local time (`DateTime.now()` returns local). Pass a UTC-converted `DateTime` explicitly if UTC behavior is needed.

### ValidateList — 1 new method

| Method | Phase | Description |
|---|---|---|
| `containsAll(List<T> items)` | 1 | List must contain every item in `items` |

`isSorted()` was considered and rejected — sorting is almost always the caller's responsibility, and `satisfy()` covers the rare cases where it's needed.

---

## 4. Locale Improvements

### Current state

`ValidatorLocale` already supports partial overrides — codes absent from the map fall back to the hardcoded English default. However, the English defaults are not accessible as a `ValidatorLocale` object, and there is no way to extend an existing locale.

### Changes

**`ValidatorLocale.base`** — exposes the built-in English defaults as a `ValidatorLocale` instance.

**`merge(Map<ValidationCode, LocaleMessage> overrides)`** — returns a new `ValidatorLocale` whose message map is the receiver's map with `overrides` applied on top (overlay semantics: `overrides` wins on conflict, all other receiver entries are preserved). The receiver is not mutated.

```dart
// Override a few messages, keep the rest in English
final myLocale = ValidatorLocale.base.merge({
  ValidationCode.required:     (p) => '${p['name']} 필수입력입니다.',
  ValidationCode.emailInvalid: (_) => '이메일 형식이 올바르지 않습니다.',
});

ValidatorLocale.setLocale(myLocale);
```

```dart
// Full custom locale built from scratch
ValidatorLocale.setLocale(ValidatorLocale({
  ValidationCode.required: (p) => '${p['name']} é obligatoire.',
  // ... others fall back to English
}));
```

**No built-in `KoLocale`** — each consumer defines their own messages. `ValidatorLocale.base` + `merge()` makes this low-friction without coupling the library to any particular language.

---

## 5. New ValidationCode Values Required

Every new method needs a corresponding `ValidationCode` entry and a hardcoded English default message. New codes:

`startsWith`, `endsWith`, `stringContains`, `ipAddress`, `hexColor`, `base64`, `json`, `creditCard`, `postalCode`, `numberPrecision`, `isPort`, `numberIn`, `isWeekday`, `isWeekend`, `isToday`, `isSameDay`, `isWithin`, `listContainsAll`, `mapMinSize`, `mapMaxSize`, `mapKeyInvalid`, `mapValueInvalid`, `nestedFailed`

> `oneOf` and `notOneOf` already exist in the enum (used by `includedIn()` / `excludedFrom()`). Do not add duplicates.

---

## Out of Scope

- Transform pipeline — validation and value mutation are separate concerns; callers normalize values themselves.
- Built-in `KoLocale` / `EnLocale` — locale content is the consumer's responsibility.
- `isSorted()` on `ValidateList` — too niche; `satisfy()` covers it.
- `ipv4()` / `ipv6()` as separate methods — `ipAddress()` covers both; `matches(RegExp)` covers edge cases.
