# dup v2.0 — Design Spec

> **⚠️ SUPERSEDED** — This document describes the initial v2 design and contains APIs that were replaced during implementation.
> The `ValidatorLocaleKeys` string-constants API, the multi-parameter `ValidatorLocale` constructor, and `UiFormService`
> were all removed in the final implementation. See the codebase and CLAUDE.md for the authoritative architecture.

**Date:** 2026-04-23  
**Status:** Superseded  
**Scope:** Full package overhaul — bug fixes, new validator types, async support, phase-based execution, pure Dart

---

## 1. Goals

- Fix all known correctness bugs and API inconsistencies
- Add `ValidateBool`, `ValidateDateTime` as first-class types
- Introduce zod-style phase-based execution so validator order in a chain is irrelevant
- Add true async validator support
- Move `phone()` / `bizno()` from `ValidateNumber` → `ValidateString` (type correctness)
- Make all format-specific validators (`mobile`, `phone`, `bizno`) accept a `customRegex` for global use
- Remove Flutter SDK dependency → usable in any Dart environment (server, CLI, Flutter)
- Comprehensive test coverage

---

## 2. Architecture

### 2.1 Phase-Based Execution (zod-style)

`BaseValidator` stores validators tagged by phase. `validate()` and `validateAsync()` always run phases in order, regardless of chain order.

```
Phase 0 — Presence    : required()
Phase 1 — Format      : email(), url(), uuid(), mobile(), phone(), bizno(),
                        matches(), isInteger(), isTrue(), isFalse(), isBefore(), isAfter()
Phase 2 — Constraint  : min(), max(), isPositive(), isNegative(),
                        isNonNegative(), isNonPositive(), between(), minLength(), maxLength()
Phase 3 — Custom      : satisfy(), addValidator()
Phase 4 — Async       : addAsyncValidator()
```

**Result:** `ValidateString().min(3).email().required()` behaves identically to `.required().email().min(3)`.

### 2.2 Internal Structure

```dart
class _ValidatorEntry<T> {
  final int phase;
  final String? Function(T?) fn;
}

abstract class BaseValidator<T, V extends BaseValidator<T, V>> {
  final List<_ValidatorEntry<T>> _entries = [];
  final List<Future<String?> Function(T?)> _asyncEntries = [];

  V addPhaseValidator(int phase, String? Function(T?) fn); // used by subclass methods
  V addValidator(String? Function(T?) fn);                 // public, phase 3
  V addAsyncValidator(Future<String?> Function(T?) fn);    // public, phase 4

  String? validate(T? value);           // runs phases 0–3
  Future<String?> validateAsync(T? value); // runs phases 0–4
}
```

### 2.3 Null Contract

Every validator (all phases) skips silently when `value == null` **unless** it is a Phase 0 (presence) validator. This applies uniformly across all classes including `satisfy()`, `email()`, `mobile()`, `minLength()`, `any()`.

- **Before (bug):** `email()`, `mobile()`, `password()` returned errors on null — acting as implicit `required()`.
- **After:** These return `null` on null input. Callers use `.required()` explicitly for presence checks.

---

## 3. File Structure

### Modified files

| File | Changes |
|------|---------|
| `pubspec.yaml` | Remove `flutter` dependency; use `test` + `lints` in dev |
| `lib/src/util/validator_base.dart` | Phase system, `addAsyncValidator`, `validateAsync`, `satisfy` null-fix |
| `lib/src/util/validate_string.dart` | Add `phone`, `bizno`, `url`, `uuid`; add `customRegex` to `mobile`/`phone`/`bizno`; fix `password` ASCII restriction; fix null-skip on format validators; fix emoji regex |
| `lib/src/util/validate_number.dart` | Remove `phone`, `bizno`; add `isPositive`, `isNegative`, `isNonNegative`, `isNonPositive` |
| `lib/src/util/validate_list.dart` | Fix `minLength`/`hasLength`/`any` null handling; fix trailing period on messages |
| `lib/src/util/validate_locale.dart` | Add `resetLocale()`; add `bool` and `date` categories; add `ValidatorLocaleKeys` constants |
| `lib/src/util/ui_form_service.dart` | Remove raw `BaseValidator` type; add `getError()`; make `validate()` truly async |
| `lib/src/util/form_validate_exception.dart` | Change `Map<String, String?>` → `Map<String, String>` |
| `lib/dup.dart` | Export new files |
| `.gitignore` | Add `doc/` |

### New files

| File | Purpose |
|------|---------|
| `lib/src/util/validate_bool.dart` | `ValidateBool` |
| `lib/src/util/validate_date_time.dart` | `ValidateDateTime` |
| `test/validate_string_test.dart` | String validator tests |
| `test/validate_number_test.dart` | Number validator tests |
| `test/validate_list_test.dart` | List validator tests |
| `test/validate_bool_test.dart` | Bool validator tests |
| `test/validate_date_time_test.dart` | DateTime validator tests |
| `test/validate_base_test.dart` | BaseValidator phase/async tests |
| `test/ui_form_service_test.dart` | UiFormService integration tests |

---

## 4. ValidateString

### Existing methods (kept, fixed)

| Method | Fix |
|--------|-----|
| `min(int)` | No change |
| `max(int)` | No change |
| `matches(RegExp)` | No change |
| `email()` | Returns null on null input (presence delegated to `required()`) |
| `password({int minLength = 4})` | Remove ASCII-only restriction; `minLength` param; returns null on null input |
| `emoji()` | Fix regex to use `\p{Emoji}` with unicode flag |
| `mobile({RegExp? customRegex})` | Add `customRegex`; default = Korean format; returns null on null input |

### New methods

| Method | Phase | Description |
|--------|-------|-------------|
| `phone({RegExp? customRegex})` | 1 | Moved from `ValidateNumber`. Default = Korean landline regex. `customRegex` overrides. |
| `bizno({RegExp? customRegex})` | 1 | Moved from `ValidateNumber`. Default = Korean BRN regex. `customRegex` overrides. |
| `url()` | 1 | Validates `http://` or `https://` URL format |
| `uuid()` | 1 | Validates UUID v4 format |

### customRegex usage

```dart
// Korean (default)
ValidateString().mobile()

// US format
ValidateString().mobile(customRegex: RegExp(r'^\+1\d{10}$'))

// International E.164
ValidateString().phone(customRegex: RegExp(r'^\+?[1-9]\d{1,14}$'))
```

---

## 5. ValidateNumber

### Removed

- `phone()` → moved to `ValidateString`
- `bizno()` → moved to `ValidateString`

### Existing (kept)

- `min(num)`, `max(num)`, `isInteger()`

### New methods

| Method | Phase | Description |
|--------|-------|-------------|
| `isPositive()` | 2 | value > 0 |
| `isNegative()` | 2 | value < 0 |
| `isNonNegative()` | 2 | value >= 0 |
| `isNonPositive()` | 2 | value <= 0 |

---

## 6. ValidateBool (new)

```dart
class ValidateBool extends BaseValidator<bool, ValidateBool> {
  ValidateBool isTrue({MessageFactory? messageFactory});    // Phase 1
  ValidateBool isFalse({MessageFactory? messageFactory});   // Phase 1
}
```

Inherits `required()`, `equalTo()`, `satisfy()`, `addValidator()`, `addAsyncValidator()` from `BaseValidator`.

---

## 7. ValidateDateTime (new)

```dart
class ValidateDateTime extends BaseValidator<DateTime, ValidateDateTime> {
  ValidateDateTime min(DateTime min, {MessageFactory? messageFactory});      // Phase 2
  ValidateDateTime max(DateTime max, {MessageFactory? messageFactory});      // Phase 2
  ValidateDateTime isBefore(DateTime target, {MessageFactory? messageFactory}); // Phase 1
  ValidateDateTime isAfter(DateTime target, {MessageFactory? messageFactory});  // Phase 1
  ValidateDateTime between(DateTime min, DateTime max, {MessageFactory? messageFactory}); // Phase 2
}
```

Inherits `required()`, `equalTo()`, `satisfy()`, `addValidator()`, `addAsyncValidator()` from `BaseValidator`.

---

## 8. ValidateList (fixes)

| Fix | Detail |
|-----|--------|
| `minLength()` null handling | null → skip (was: null → fail) |
| `hasLength()` null handling | null → skip (was: null → fail) |
| `any()` null handling | null → skip (was: null → fail) |
| Error message periods | Add trailing `.` to all messages to match BaseValidator style |

---

## 9. ValidatorLocale

### New API

```dart
static void resetLocale() => _current = null;  // for test isolation
```

### New categories

```dart
ValidatorLocale({
  required Map<String, LocaleMessage> mixed,
  required Map<String, LocaleMessage> string,
  required Map<String, LocaleMessage> number,
  required Map<String, LocaleMessage> array,
  required Map<String, LocaleMessage> boolMessages,  // new (bool is a reserved keyword)
  required Map<String, LocaleMessage> date,           // new
})
```

### ValidatorLocaleKeys constants

```dart
abstract class ValidatorLocaleKeys {
  // mixed
  static const String required = 'required';
  static const String equal = 'equal';
  static const String notEqual = 'notEqual';
  static const String oneOf = 'oneOf';
  static const String notOneOf = 'notOneOf';
  static const String condition = 'condition';

  // string
  static const String stringMin = 'min';
  static const String stringMax = 'max';
  static const String stringMatches = 'matches';
  static const String stringEmail = 'emailInvalid';
  static const String stringPassword = 'passwordMin';
  static const String stringEmoji = 'emoji';
  static const String stringMobile = 'mobileInvalid';
  static const String stringPhone = 'phoneInvalid';
  static const String stringBizno = 'biznoInvalid';
  static const String stringUrl = 'url';
  static const String stringUuid = 'uuid';

  // number
  static const String numberMin = 'min';
  static const String numberMax = 'max';
  static const String numberInteger = 'integer';
  static const String numberPositive = 'positive';
  static const String numberNegative = 'negative';
  static const String numberNonNegative = 'nonNegative';
  static const String numberNonPositive = 'nonPositive';

  // array
  static const String arrayNotEmpty = 'notEmpty';
  static const String arrayEmpty = 'empty';
  static const String arrayMin = 'min';
  static const String arrayMax = 'max';
  static const String arrayLengthBetween = 'lengthBetween';
  static const String arrayExactLength = 'exactLength';
  static const String arrayContains = 'contains';
  static const String arrayDoesNotContain = 'doesNotContain';
  static const String arrayAllCondition = 'allCondition';
  static const String arrayAnyCondition = 'anyCondition';
  static const String arrayNoDuplicates = 'noDuplicates';
  static const String arrayEachItem = 'eachItem';

  // bool
  static const String boolTrue = 'isTrue';
  static const String boolFalse = 'isFalse';

  // date
  static const String dateMin = 'min';
  static const String dateMax = 'max';
  static const String dateBefore = 'before';
  static const String dateAfter = 'after';
  static const String dateBetween = 'between';
}
```

---

## 10. UiFormService

### Type safety fix

```dart
// Before (raw type — unsafe)
final BaseValidator validator = schema.schema[field]!;

// After (dynamic dispatch — safe, Dart handles it via covariance)
final validator = schema.schema[field]!;
final error = await validator.validateAsync(value);
```

### New method

```dart
String? getError(String path, FormValidationException? error) {
  if (error == null) return null;
  return error.errors[path];
}
```

### Async upgrade

```dart
Future<void> validate(
  BaseValidatorSchema schema,
  Map<String, dynamic> request, {
  bool abortEarly = false,
  String fallbackMessage = 'Invalid form.',
}) async {
  final errors = <String, String>{};
  for (final field in schema.schema.keys) {
    final error = await schema.schema[field]!.validateAsync(request[field]);
    if (error != null) {
      errors[field] = error;
      if (abortEarly) break;
    }
  }
  if (errors.isNotEmpty) throw FormValidationException(errors, fallbackMessage: fallbackMessage);
}
```

---

## 11. FormValidationException

```dart
// Before
final Map<String, String?> errors;

// After
final Map<String, String> errors;
```

---

## 12. pubspec.yaml

```yaml
name: dup
description: "A powerful, flexible schema-based validation library for Dart, inspired by JavaScript's yup."
version: 2.0.0

environment:
  sdk: ^3.7.2

dependencies: {}

dev_dependencies:
  test: ^1.25.0
  lints: ^5.0.0
```

---

## 13. Test Coverage Plan

Each test file covers:

| File | Coverage |
|------|----------|
| `validate_base_test.dart` | Phase order (required last in chain fires first), satisfy null-skip, addAsyncValidator, validateAsync, equalTo, includedIn, excludedFrom |
| `validate_string_test.dart` | All methods; null-skip behavior; customRegex on mobile/phone/bizno; email/password null-skip; url/uuid format cases |
| `validate_number_test.dart` | min/max/isInteger/isPositive/isNegative/isNonNegative/isNonPositive; null-skip |
| `validate_list_test.dart` | All methods; null-skip fix for minLength/hasLength/any; eachItem; hasNoDuplicates |
| `validate_bool_test.dart` | isTrue/isFalse; required; null-skip |
| `validate_date_time_test.dart` | min/max/isBefore/isAfter/between; null-skip; boundary values |
| `ui_form_service_test.dart` | Full schema validation; abortEarly; async validators; getError/hasError; type mismatch safety |

---

## 14. Breaking Changes (v1 → v2)

| Change | Migration |
|--------|-----------|
| `ValidateNumber().phone()` removed | Use `ValidateString().phone()` |
| `ValidateNumber().bizno()` removed | Use `ValidateString().bizno()` |
| `FormValidationException.errors` is `Map<String, String>` (was `Map<String, String?>`) | Remove `?` null checks on values |
| `ValidatorLocale` requires `boolMessages` and `date` categories | Add empty maps `{}` if not localizing these types |

---

## 15. Out of Scope (future)

- Nested object validator (`ValidateObject`)
- Cross-field / conditional validation (`.when()`)
- Input transformation / sanitization (`.transform()`)
- Validation caching / memoization
