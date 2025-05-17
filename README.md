# dup

A powerful, flexible validation library for Dart and Flutter, inspired by JavaScript's [yup](https://github.com/jquense/yup).

## Features

- Schema-based validation for forms and data models
- Chainable, composable validation rules
- Customizable error messages and labels
- Exception-based error handling
- Easy integration with Flutter

## Installation

Add `dup` to your `pubspec.yaml`:

```
dependencies:
dup: ^1.0.0
```

Then run:

```
dart pub get
```
---
아래는 dup 패키지의 실제 클래스 구조와 동작 방식에 맞춰,  
**README.md의 Usage와 Example 섹션을 상세하고 정확하게** 다시 작성한 예시입니다.  
(실제 내부 구현 및 타입, 예외 처리 방식, 서비스 구조를 모두 반영합니다.)

---

## Usage

dup enables you to define validation rules for your data using a schema-based approach, making your validation logic clean, reusable, and maintainable.

### 1. Define a validation schema

First, define a schema that describes the validation rules for each field.  
Each field uses a validator instance (e.g., `ValidateString`, `ValidateNumber`).

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
});
```

- `email` must be a valid email address and is required.
- `password` must meet your password rule and is required.
- `age` must be between 18 and 99.

### 2. Prepare request data

Create a `Map` containing the values you want to validate.

```dart
final request = {
  'email': 'test@example.com',
  'password': '1234',
  'age': 20,
};
```

### 3. Validate

Call `useUiForm.validate()` to validate your data against the schema.  
If validation fails, a `FormValidationException` will be thrown with a map of error messages.

```dart
try {
  await useUiForm.validate(schema, request);
  // Validation passed!
} catch (e) {
  print(e.toString); // Example: 'Invalid email format.'
}
```

---

## Example: Validating a request object

You can encapsulate validation logic inside your data classes for better structure and reusability.

### 1. Define your request class

```dart
import 'package:dup/dup.dart';

class RequestObject {
  String? title;
  String? contents;

  RequestObject({this.title, this.contents});

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
    });
    await useUiForm.validate(schema, {
      'title': title,
      'contents': contents,
    });
  }
}
```

- `title` is required and must be at least 2 characters long.
- `contents` is required and must be at least 2 characters long.

### 2. Use your request class and handle validation

```dart
void main() async {
  final RequestObject params = RequestObject(title: 'Hello', contents: 'W');
  try {
    await params.validate();
    print('Validation passed!');
  } catch (e) {
    print(e.toString); // 'Contents must be at least 2 characters long.'
  }
}
```


---

## How it works

- **BaseValidator**: Abstract class for creating custom validators.
- **ValidateString / ValidateNumber / ValidateList**: Built-in validator classes for strings, numbers, and lists.
- **BaseValidatorSchema**: Holds the schema definition (map of field names to validators).
- **UiFormService**: Provides the `validate()` method to check a schema and request map, and throws `FormValidationException` on failure.
- **FormValidationException**: Contains a map of field names to error messages.


## Tips

- You can chain multiple validation rules for each field.
- Use `.setLabel()` to customize error messages with a user-friendly field name.

## API Overview

- `BaseValidator`: Abstract base class for validators
- `ValidateString`: String validation (min, max, email, password, etc.)
- `ValidateNumber`: Number validation (min, max, isInteger, etc.)
- `ValidateList`: List validation
- `BaseValidatorSchema`: Schema for form validation
- `UiFormService`: Service for validating schemas and handling errors
- `FormValidationException`: Exception thrown on validation failure

## Links

- [API Reference](https://pub.dev/documentation/dup/latest/)
- [GitHub Repository](https://github.com/muminjun/dup)
