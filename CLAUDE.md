# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run all tests
flutter test

# Run a single test file
flutter test test/path/to/test_file.dart

# Analyze code
flutter analyze

# Get dependencies
flutter pub get

# Generate API docs
dart doc
```

## Architecture

This is a Dart/Flutter package — a schema-based validation library inspired by JavaScript's [yup](https://github.com/jquense/yup).

### Core class hierarchy

```
BaseValidator<T, V>          (lib/src/util/validator_base.dart)
  ├── ValidateString          (lib/src/util/validate_string.dart)
  ├── ValidateNumber          (lib/src/util/validate_number.dart)
  └── ValidateList            (lib/src/util/validate_list.dart)
```

`BaseValidator` is a generic abstract class parameterized by `<T, V>` where `T` is the value type and `V` is the subclass itself (F-bounded polymorphism), enabling fluent method chaining. Each validator holds a list of `String? Function(T?)` validators and runs them in order, returning the first error.

### Validation flow

1. User builds a `BaseValidatorSchema` (a `Map<String, BaseValidator>` wrapper).
2. Calls `useUiForm.validate(schema, request)` — the global `UiFormService` instance.
3. `UiFormService` iterates fields, calls `validator.validate(value)` on each, collects errors.
4. If any errors exist, throws `FormValidationException` containing `Map<String, String?>`.

### Error message resolution

Every built-in validator follows a 3-level priority:
1. `messageFactory` argument (per-call override)
2. `ValidatorLocale.current` singleton (global app-wide locale — set via `ValidatorLocale.setLocale()`)
3. Hardcoded default English message

Locale message keys are split by type: `mixed`, `string`, `number`, `array` in `ValidatorLocale`.

### Public API surface (`lib/dup.dart`)

All classes are re-exported from the single barrel file. Adding a new validator type requires:
- Creating the class in `lib/src/util/`
- Exporting it from `lib/dup.dart`
