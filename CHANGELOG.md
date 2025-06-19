# Changelog
=======
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

[1] programming.data_validation
[2] programming.smart_notices