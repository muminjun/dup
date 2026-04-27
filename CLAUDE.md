# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run all tests
dart test

# Run a single test file
dart test test/validate_string_test.dart

# Run tests matching a name pattern
dart test --name "email"

# Analyze code
dart analyze

# Get dependencies
dart pub get

# Generate API docs
dart doc
```

## Architecture

Pure Dart validation library (no Flutter dependency). Entry point is `lib/dup.dart` — a barrel file that re-exports everything.

### Class hierarchy

```
BaseValidator<T, V>           lib/src/util/validator_base.dart
  ├── ValidateString          lib/src/util/validate_string.dart
  ├── ValidateNumber          lib/src/util/validate_number.dart
  ├── ValidateList<T>         lib/src/util/validate_list.dart
  ├── ValidateBool            lib/src/util/validate_bool.dart
  ├── ValidateDateTime        lib/src/util/validate_date_time.dart
  ├── ValidateObject          lib/src/util/validate_object.dart
  └── ValidateMap<V>          lib/src/util/validate_map.dart
```

`BaseValidator<T, V>` uses F-bounded polymorphism (`V extends BaseValidator<T, V>`) so subclass methods return the concrete subclass type, enabling fluent chaining.

### Phase-based execution (zod-style)

Every validator is registered with an explicit phase via `addPhaseValidator(phase, fn)`. When `validate()` is called, entries are sorted by phase before execution — so chain order never affects which validator fires first.

| Phase | Purpose |
|---|---|
| 0 | `required` |
| 1 | Format checks (`email`, `isInteger`, `isBefore`, …) |
| 2 | Constraint checks (`min`, `max`, `between`, …) |
| 3 | Custom (`addValidator`, `satisfy`, `equalTo`, …) |
| 4 | Async (`addAsyncValidator`) |

`validateAsync()` runs all sync phases first, then async entries in order.

### Null contract

All validators skip silently when the value is `null`, **except** phase 0 (`required`). Never add implicit null checks inside validators — let the phase system handle it.

### Error message resolution (3-level priority)

1. `messageFactory` argument on the specific call
2. `ValidatorLocale.current` singleton (set via `ValidatorLocale.setLocale()`)
3. Hardcoded English default in the validator body

Locale maps are keyed by `ValidationCode` enum values (defined in `validation_code.dart`).

### Validation flow

1. Caller builds a `DupSchema` (`Map<String, BaseValidator>` with optional `labels` and `crossValidate`).
2. Calls `await schema.validate(data)` — returns a `FormValidationResult` sealed class.
3. `DupSchema` iterates all fields, calls `validator.validateAsync(value)` on each, collects all errors.
4. If any fields failed, returns `FormValidationFailure(Map<String, ValidationFailure>)`.
5. If all fields passed and a `crossValidate` function is set, it runs and may return additional errors.
6. On success, returns `FormValidationSuccess()`.

Pattern-match on the result:
```dart
switch (result) {
  case FormValidationSuccess(): // proceed
  case FormValidationFailure(): print(result('fieldName')?.message);
}
```

### Adding a new validator type

1. Create `lib/src/util/validate_<type>.dart` extending `BaseValidator<T, ValidateX>`.
2. Register all methods with `addPhaseValidator(phase, fn)` at the appropriate phase.
3. Follow the null-skip pattern: `if (value == null) return null;` at the top of each phase-1+ validator.
4. Add new `ValidationCode` values to `validation_code.dart` and locale entries to `ValidatorLocale` if needed.
5. Export the new class from `lib/dup.dart`.

### Test isolation

`ValidatorLocale` is a global singleton. Tests that set a custom locale must call `ValidatorLocale.resetLocale()` in `tearDown` to avoid leaking state across tests.
