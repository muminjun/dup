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
  'paymentType': ValidateString().required().oneOf(['card', 'bank']),
  'cardNumber':  ValidateString(),
  'bankAccount': ValidateString(),
})
.when(
  field: 'paymentType',
  is: (v) => v == 'card',
  then: {'cardNumber': ValidateString().required().creditCard()},
)
.when(
  field: 'paymentType',
  is: (v) => v == 'bank',
  then: {'bankAccount': ValidateString().required()},
);
```

**Behavior:**
- Before any validation runs, all `when()` conditions are evaluated against the raw input data to compose the effective validator set. Only then does validation execute.
- When a condition matches, the `then` validators replace (not merge with) the base validators for those fields.
- Multiple `when()` blocks are evaluated independently; all matching blocks apply. If two blocks target the same field, the last matching block wins.
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

final loginSchema  = userSchema.pick(['email', 'password']);
final profileSchema = userSchema.omit(['password']);
```

**Behavior:**
- `pick(fields)` — keeps only the named fields; ignores unknown names.
- `omit(fields)` — removes the named fields; ignores unknown names.
- `crossValidate` is not carried over (depends on fields that may no longer exist).
- `when()` rules referencing omitted/non-picked fields are also dropped.

### 1-3. `partial()`

Returns a new `DupSchema` where `required` presence checks are removed from every field. All other validators remain active.

```dart
final patchSchema = userSchema.partial();

await patchSchema.validate({'name': 'John'});        // ✓ — only name sent
await patchSchema.validate({'email': 'bad'});        // ✗ — email format still checked
await patchSchema.validate({'name': '   '});         // ✗ — notBlank still active
```

**Behavior:**
- `partial()` strips validators tagged as presence checks. Only `required` carries this tag. `notBlank` does NOT — it is a value-quality check, not a presence check.
- Implementation: `addPhaseValidator` gains an optional `isPresence: bool` flag (default `false`). `required` passes `isPresence: true`. `partial()` filters out only those entries.
- `notBlank` stays at phase 0 and its execution order is unchanged. No phase migration needed.
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
| `keyValidator(ValidateString)` | 1 | Applied to every key (`String` only) |
| `valueValidator(ValidateNumber \| ValidateString \| ValidateList \| ValidateBool \| ValidateDateTime)` | 1 | Applied to every value |

`valueValidator` accepts any concrete `BaseValidator<V, dynamic>` subclass. The type parameter `V` on `ValidateMap<V>` constrains which validator type is valid at the call site. Use `ValidateMap<num>` with `ValidateNumber` (which validates `num`, not `int`).

**Error reporting:** Key/value errors use `NestedValidationFailure` (same mechanism as `ValidateObject`). `DupSchema.validate()` and `DupSchema.validateSync()` both flatten these into the parent `FormValidationFailure` using bracket notation:

```dart
result('metadata[score]')?.message   // "score must be at most 100"
result('metadata[rank]')?.message    // "rank must be at least 0"
```

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

**Error reporting:** `ValidateObject` returns a `NestedValidationFailure extends ValidationFailure`, which carries the inner `DupSchema`'s error map. Both `DupSchema.validate()` and `DupSchema.validateSync()` detect this type and flatten entries with dot notation into the parent `FormValidationFailure`:

```dart
result('shippingAddress.street')?.message  // "street is required"
result('shippingAddress.zip')?.message     // "zip is not a valid postal code"
```

The `NestedValidationFailure` type is internal — callers always interact with the flattened `FormValidationFailure` map.

---

## 3. New Validator Methods

### ValidateString — 9 new methods

> `oneOf` / `notOneOf` are already available as `includedIn(List<T>)` / `excludedFrom(List<T>)` on `BaseValidator` and work with `ValidateString` as-is. They are not re-added.

| Method | Phase | Description |
|---|---|---|
| `startsWith(String prefix)` | 1 | Trimmed value must start with prefix |
| `endsWith(String suffix)` | 1 | Trimmed value must end with suffix |
| `contains(String substring)` | 1 | Value must contain the substring |
| `ipAddress()` | 1 | Valid IPv4 or IPv6 address |
| `hexColor()` | 1 | Valid hex color code (`#RGB` or `#RRGGBB`) |
| `base64()` | 1 | Valid Base64-encoded string |
| `json()` | 1 | Parseable JSON string |
| `creditCard()` | 1 | Valid credit card number (Luhn algorithm) |
| `postalCode()` | 1 | Korean 5-digit postal code |

All methods follow the null-skip pattern: return `null` (pass) when value is `null`.

### ValidateNumber — 3 new methods

| Method | Phase | Description |
|---|---|---|
| `isPrecision(int digits)` | 1 | At most `digits` decimal places |
| `isPort()` | 1 | Integer in range 0–65535 |
| `isIn(List<num>)` | 1 | Value must be one of the given numbers |

### ValidateDateTime — 5 new methods

| Method | Phase | Description |
|---|---|---|
| `isWeekday()` | 1 | Monday–Friday |
| `isWeekend()` | 1 | Saturday–Sunday |
| `isToday()` | 1 | Same calendar day as `DateTime.now()` |
| `isSameDay(DateTime target)` | 1 | Same calendar day as `target` |
| `isWithin(Duration duration, {DateTime? from})` | 2 | Within `duration` of `from` (default: `DateTime.now()`) |

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

**`merge(Map<ValidationCode, LocaleMessage>)`** — returns a new `ValidatorLocale` with the given messages overlaid on top of the receiver.

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

`startsWith`, `endsWith`, `stringContains`, `ipAddress`, `hexColor`, `base64`, `json`, `creditCard`, `postalCode`, `numberPrecision`, `isPort`, `numberIn`, `isWeekday`, `isWeekend`, `isToday`, `isSameDay`, `isWithin`, `listContainsAll`, `mapMinSize`, `mapMaxSize`, `mapKeyInvalid`, `mapValueInvalid`

> `oneOf` and `notOneOf` already exist in the enum (used by `includedIn()` / `excludedFrom()`). Do not add duplicates.

---

## Out of Scope

- Transform pipeline — validation and value mutation are separate concerns; callers normalize values themselves.
- Built-in `KoLocale` / `EnLocale` — locale content is the consumer's responsibility.
- `isSorted()` on `ValidateList` — too niche; `satisfy()` covers it.
- `ipv4()` / `ipv6()` as separate methods — `ipAddress()` covers both; `matches(RegExp)` covers edge cases.
