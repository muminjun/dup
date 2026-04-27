# Repository Guidelines

## Project Structure & Module Organization
`lib/dup.dart` is the public barrel export for the package. Core validators and services live under `lib/src/util/`, while schema and message models live under `lib/src/model/`. Tests are in `test/` and generally mirror validator or service names, for example `test/validate_string_test.dart`. Example usage lives in `example/main.dart`. Design notes and implementation plans are kept in `docs/superpowers/`. Generated outputs include `coverage/` and `doc/api/`; update them only when the related workflow is part of the change.

## Build, Test, and Development Commands
Run `dart pub get` after dependency changes. Use `dart analyze` to apply the repository lint rules from `analysis_options.yaml`. Format touched files with `dart format lib test example`. Run `dart test` for the full suite, or scope work with `dart test test/validate_string_test.dart` or `dart test --name "email"`. Generate API docs with `dart doc` when public APIs or examples change.

## Coding Style & Naming Conventions
Follow standard Dart style: 2-space indentation, trailing commas where formatter-friendly, and clear null handling. This repo uses `package:lints/recommended.yaml`, so keep analyzer warnings at zero. Use `UpperCamelCase` for types (`ValidateString`), `lowerCamelCase` for members, and snake_case for file names such as `validate_date_time.dart`. Export new public APIs through `lib/dup.dart`.

## Testing Guidelines
Tests use the `package:test` framework. Add or update focused tests alongside each behavior change, especially for validator phase ordering, locale resolution, and null-skip behavior. Name test files `<feature>_test.dart`. If a test sets a custom `ValidatorLocale`, call `ValidatorLocale.resetLocale()` in `tearDown` to avoid leaking global state.

## Commit & Pull Request Guidelines
Recent history follows short Conventional Commit subjects such as `chore: ...`, `docs: ...`, and `test: ...`; continue that format. Keep commits scoped to one concern. Pull requests should explain the user-visible behavior change, list any public API additions, and note test coverage. Include example snippets or screenshots only when docs or example output changes.

## Architecture Notes
This package is a pure Dart validation library. `BaseValidator` drives fluent validators such as `ValidateString`, `ValidateNumber`, `ValidateList`, `ValidateBool`, and `ValidateDateTime`, and `UiFormService` coordinates schema validation. Preserve the phase-based execution model: `required` runs first, sync validators run before async validators, and non-required validators should silently skip `null`. When adding a validator type, update locale keys, barrel exports, and tests in the same change.
