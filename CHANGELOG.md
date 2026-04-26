# Changelog

## [2.0.0] - 2026-04-24

### Breaking Changes

- **`BaseValidatorSchema` removed** — replaced by `DupSchema`, which unifies schema
  definition and validation into a single class (no more `useUiForm` global service).
- **`useUiForm` removed** — call `schema.validate(data)` directly.
- **`FormValidationException` removed** — validation no longer throws; `schema.validate()`
  returns `FormValidationResult` (either `FormValidationSuccess` or `FormValidationFailure`).
- **`addValidator` callback return type changed** from `String?` to `ValidationFailure?`.
- **`ValidatorLocale` constructor redesigned** — takes a single
  `Map<ValidationCode, MessageFactory>` instead of `mixed:`, `number:`, `string:`, `array:`
  named parameters with plain-string keys.
- **`ValidateNumber.moreThan()` / `lessThan()` removed** — use `min()` / `max()` or
  `satisfy()` for strict comparisons.

See [MIGRATING.md](MIGRATING.md) for a complete before/after guide.

### Added

- `DupSchema` — replaces `BaseValidatorSchema` + `useUiForm` pair; supports
  `validate()` (async), `validateSync()`, `validateField()`, and `crossValidate()`.
- `DupSchema.when()` — conditional validation; replaces base validators when a
  field satisfies a predicate at validation time.
- `DupSchema.pick(fields)` / `omit(fields)` — derive a sub-schema from an
  existing one without duplicating validator definitions.
- `DupSchema.partial()` — returns a new schema that skips all `required` checks;
  useful for PATCH-style partial updates.
- `FormValidationResult` sealed class (`FormValidationSuccess`, `FormValidationFailure`)
  returned from `DupSchema.validate()` and `DupSchema.validateSync()`.
- `FormValidationFailure` — call operator, `hasError()`, `fields`, `firstField`.
- `ValidationCode` enum — type-safe key for every built-in rule; stored in
  `ValidationFailure.code` and used as locale map keys.
- `ValidationResult` sealed class (`ValidationSuccess`, `ValidationFailure`) returned
  from every single-field `validate()` / `validateAsync()` call.
- `ValidateBool` — new validator type with `isTrue()` and `isFalse()`.
- `ValidateDateTime` — new validator type with `isBefore()`, `isAfter()`, `min()`,
  `max()`, `between()`, `isInFuture()`, `isInPast()`, `isWeekday()`, `isWeekend()`,
  `isSameDay()`, `isToday()`, `isWithin()`.
- `ValidateObject` — nested object validator; errors are flattened with dot notation
  (`result('address.city')`).
- `ValidateMap<V>` — map validator with `keyValidator()`, `valueValidator()`,
  `minSize()`, `maxSize()`; errors are flattened with bracket notation
  (`result('scores[math]')`).
- `ValidateNumber.toValidator({parseErrorMessage})` — parses a string input as a number
  before validating; returns a parse error for non-numeric input (e.g. `"abc"`, `"17세"`);
  directly usable as `TextFormField.validator`.
- `ValidateNumber` additions: `isPositive()`, `isNegative()`, `isNonNegative()`,
  `isNonPositive()`, `isEven()`, `isOdd()`, `isMultipleOf()`, `between()`,
  `isPrecision(digits)`, `isPort()`.
- `ValidateList` additions: `hasLength()`, `all()`, `any()`, `none()`,
  `hasNoDuplicates()`, `eachItem()`, `containsAll()`.
- `ValidateString` additions: `startsWith()`, `endsWith()`, `contains()`,
  `ipAddress()`, `hexColor()`, `base64()`, `json()`, `creditCard()`, `koPostalCode()`.
- `DupSchema.crossValidate()` — cross-field validation called only when all
  individual fields pass.
- Phase-based execution (0 = required, 1 = format, 2 = constraint, 3 = custom,
  4 = async) — chain order never affects which rule fires first.

---

## [1.0.4] - 2025-06-19

### Added
- **ValidateList**: Comprehensive list/array validation support[1][2]
  - Length validation methods: `minLength()`, `maxLength()`, `lengthBetween()`, `hasLength()`
  - Content validation: `contains()`, `doesNotContain()`, `hasNoDuplicates()`
  - State validation: `isNotEmpty()`, `isEmpty()`
  - Conditional validation: `all()`, `any()`, `eachItem()`
- Global localization support for list validation messages
- Enhanced documentation with detailed ValidateList examples and usage patterns
- Custom extension validator examples for lists

### Changed
- Updated README with comprehensive ValidateList documentation and examples
- Improved API consistency across all validator types
- Enhanced error message customization for array/list validations

### Fixed
- Corrected property name reference from `list` to `array` in ValidatorLocale integration

---

## [1.0.3] - 2025-05-20

### Added
- Improved documentation and README.
- Added a complete example project for easier usage reference.
- Extension method support for custom validators.
- Global and per-field custom error message customization.
- Localization and multi-language message support.

### Changed
- Refined schema-based validation API for better usability.
- Enhanced error handling and message customization logic.

### Fixed
- Minor bug fixes in validation logic.

---

## [0.0.1] - 2025-05-10

### Added
- Initial release.
- Schema-based validation for strings, numbers, and lists.
- Custom error messages and labels.
- Form validation service with exception handling.