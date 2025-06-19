# dup

A powerful, flexible validation library for Dart and Flutter, inspired by
JavaScript's [yup](https://github.com/jquense/yup)[1].

## Features

- Schema-based validation for forms and data models
- Chainable, composable validation rules
- Customizable error messages and labels
- Exception-based error handling
- Easy localization (multi-language support)
- Supports Korean postpositions and number formatting
- Easy integration with Flutter

---

## Usage

dup enables you to define validation rules for your data using a schema-based approach, making your
validation logic clean, reusable, and maintainable[2].

### 1. Define a validation schema

```dart
import 'package:dup/dup.dart';

final BaseValidatorSchema schema = BaseValidatorSchema({
  'email': ValidateString()
      .email()
      .required()
      .setLabel('Email'),
  'password': ValidateString()
      .password()
      .required()
      .setLabel('Password'),
  'age': ValidateNumber()
      .min(18)
      .max(99)
      .setLabel('Age'),
  'tags': ValidateList()
      .minLength(1)
      .maxLength(5)
      .hasNoDuplicates()
      .setLabel('Tags'),
  'categories': ValidateList()
      .isNotEmpty()
      .contains('general')
      .setLabel('Categories'),
});
```

- `email` must be a valid email address and is required.
- `password` must meet your password rule and is required.
- `age` must be between 18 and 99.
- `tags` must have 1-5 items with no duplicates.
- `categories` must not be empty and must contain 'general'.

---

### 2. Prepare request data

```dart

final request = {
  'email': 'test@example.com',
  'password': '1234',
  'age': 20,
  'tags': ['flutter', 'dart', 'mobile'],
  'categories': ['general', 'programming'],
};
```

---

### 3. Validate

Call `useUiForm.validate()` to validate your data against the schema.  
If validation fails, a `FormValidationException` will be thrown with a map of error messages.

```dart
try {
  await useUiForm.validate(schema, request);
  // Validation passed!
} catch (e) {
  print(e.toString()); // Example: 'Email is not a valid email address.'
}
```

---

## Validation Types

### String Validation

```dart
ValidateString()
    .min(2)
    .max(50)
    .email()
    .password()
    .matches(RegExp(r'^[a-zA-Z]+$'))
    .setLabel('Username')
    .required()
```

### Number Validation

```dart
ValidateNumber()
    .min(0)
    .max(100)
    .isInteger()
    .setLabel('Score')
    .required()
```

### List Validation

```dart
ValidateList()
    .isNotEmpty()                    // List must not be empty
    .minLength(2)                    // At least 2 items
    .maxLength(10)                   // At most 10 items
    .lengthBetween(2, 10)           // Between 2-10 items
    .hasLength(5)                    // Exactly 5 items
    .contains('required_item')       // Must contain specific item
    .doesNotContain('forbidden')     // Must not contain specific item
    .hasNoDuplicates()              // No duplicate items allowed
    .all((item) => item.isNotEmpty) // All items must satisfy condition
    .any((item) => item.startsWith('prefix')) // At least one item must satisfy condition
    .eachItem((item) => item.length > 2 ? null : 'Item too short') // Custom validation for each item
    .setLabel('Items')
    .required()
```

**List Validation Methods:**

- **`isNotEmpty()`**: Validates that the list contains at least one item
- **`isEmpty()`**: Validates that the list is empty
- **`minLength(int min)`**: Validates minimum number of items
- **`maxLength(int max)`**: Validates maximum number of items
- **`lengthBetween(int min, int max)`**: Validates item count within range
- **`hasLength(int length)`**: Validates exact number of items
- **`contains(T item)`**: Validates that list contains a specific item
- **`doesNotContain(T item)`**: Validates that list does not contain a specific item
- **`hasNoDuplicates()`**: Validates that all items in the list are unique
- **`all(bool Function(T) predicate)`**: Validates that all items satisfy a condition
- **`any(bool Function(T) predicate)`**: Validates that at least one item satisfies a condition
- **`eachItem(String? Function(T) validator)`**: Applies custom validation to each item individually

---

## Example: Validating a request object

You can encapsulate validation logic inside your data classes for better structure and reusability.

```dart
class RequestObject {
  String? title;
  String? contents;
  List? tags;

  RequestObject({this.title, this.contents, this.tags});

  /// Validates the request fields using dup's schema-based validation.
  Future validate() async {
    final BaseValidatorSchema schema = BaseValidatorSchema({
      'title': ValidateString()
          .min(2)
          .setLabel('Title')
          .required(),
      'contents': ValidateString()
          .min(2)
          .setLabel('Contents')
          .required(),
      'tags': ValidateList()
          .minLength(1)
          .maxLength(10)
          .eachItem((tag) => tag.trim().isEmpty ? 'Tag cannot be empty' : null)
          .setLabel('Tags')
          .required(),
    });
    await useUiForm.validate(schema, {
      'title': title,
      'contents': contents,
      'tags': tags,
    });
  }
}
```

---

## Custom Validation

dup allows you to easily add your own validation logic, either inline or as reusable extensions[2].

### Inline Custom Validator

```dart

final validator = ValidateString()
    .setLabel('Nickname')
    .required()
    .addValidator((value) {
  if (value != null && value.contains('admin')) {
    return 'Nickname cannot contain the word "admin".';
  }
  return null;
});
```

### Custom Extension Validator

You can define your own extension methods for custom validation rules:

```dart
extension CustomStringValidator on ValidateString {
  /// Disallow special characters in the string.
  ValidateString noSpecialChars({String? message}) {
    return addValidator((value) {
      if (value != null && RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(value)) {
        return message ?? '$label cannot contain special characters.';
      }
      return null;
    });
  }
}

// Usage
final validator = ValidateString()
    .setLabel('Nickname')
    .noSpecialChars(message: 'Nickname cannot contain special characters!');
```

### Custom List Validators

```dart
extension CustomListValidator on ValidateList {
  /// Validates that list contains only unique values based on a key selector
  ValidateList uniqueBy(K Function(T) keySelector, {String? message}) {
    return addValidator((value) {
      if (value != null) {
        final keys = value.map(keySelector).toList();
        final uniqueKeys = keys.toSet();
        if (keys.length != uniqueKeys.length) {
          return message ?? '$label must contain unique items';
        }
      }
      return null;
    });
  }
}

// Usage
final validator = ValidateList()
    .setLabel('Users')
    .uniqueBy((user) => user.email, message: 'Users must have unique email addresses');
```

---

## Customizing Error Messages

dup lets you easily override the default error messages for any validation rule[2].  
You can do this in two ways:

### 1. Per-Validator Custom Message

You can provide a custom message for a specific validation rule using the `messageFactory`
parameter:

```dart

final validator = ValidateString()
    .setLabel('Username')
    .min(
    4, messageFactory: (label, args) => '$label must be at least ${args['min']} characters long.');

final listValidator = ValidateList()
    .setLabel('Items')
    .minLength(
    2, messageFactory: (label, args) => '$label must contain at least ${args['min']} items.');
```

- The `messageFactory` is a function that receives the field label and arguments (like `min`, `max`,
  etc.).
- This custom message will be used only for this validation rule.

### 2. Global Custom Messages

You can globally override error messages for your entire app by registering a custom message
factory:

```dart
ValidatorLocale.setLocale(
  ValidatorLocale(
    mixed: {
      'required': (args) => '${args['name']} is required.',
      // ...other global messages
    },
    string: {
      'min': (args) => '${args['name']} must be at least ${args['min']} characters long.',
      // ...other string messages
    },
    array: {
      'notEmpty': (args) => '${args['name']} cannot be empty.',
      'min': (args) => '${args['name']} must have at least ${args['min']} items.',
      'max': (args) => '${args['name']} cannot have more than ${args['max']} items.',
      'noDuplicates': (args) => '${args['name']} must not contain duplicate items.',
      // ...other array messages
    },
    // ...number, etc.
  ),
);
```

- This will apply your custom messages to all validators of the corresponding type and rule.
- You can still override these global messages per-validator using the `messageFactory` parameter if
  needed.

---

### 3. Localization File Customization

If you use localization (e.g., with `easy_localization`), you can also edit your language JSON files
to change the default messages for each key.

---

**Summary:**

- Use `messageFactory` in your validator for per-field custom messages.
- Use `ValidatorLocale.setLocale()` for app-wide global custom messages.
- Edit your localization files for language-specific message customization.

---

## API Overview

- `BaseValidator`: Abstract base class for validators
- `ValidateString`: String validation (min, max, email, password, etc.)
- `ValidateNumber`: Number validation (min, max, isInteger, etc.)
- `ValidateList`: List/Array validation (length, contents, uniqueness, etc.)
- `BaseValidatorSchema`: Schema for form validation
- `UiFormService`: Service for validating schemas and handling errors
- `FormValidationException`: Exception thrown on validation failure

---

## Links

- [API Reference](https://pub.dev/documentation/dup/latest/)
- [GitHub Repository](https://github.com/muminjun/dup)

---

## License

MIT

[1] https://github.com/jquense/yup
[2] programming.data_validation