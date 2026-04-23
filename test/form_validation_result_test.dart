// test/form_validation_result_test.dart
import 'package:dup/dup.dart';
import 'package:test/test.dart';

const _emailFailure = ValidationFailure(
  code: ValidationCode.emailInvalid,
  message: 'Invalid email.',
);
const _requiredFailure = ValidationFailure(
  code: ValidationCode.required,
  message: 'Password is required.',
);

void main() {
  group('FormValidationSuccess', () {
    test('is a FormValidationResult', () {
      expect(const FormValidationSuccess(), isA<FormValidationResult>());
    });
  });

  group('FormValidationFailure', () {
    late FormValidationFailure failure;

    setUp(() {
      failure = FormValidationFailure({
        'email': _emailFailure,
        'password': _requiredFailure,
      });
    });

    test('is a FormValidationResult', () {
      expect(failure, isA<FormValidationResult>());
    });

    test('call() returns failure for a field', () {
      expect(failure('email'), _emailFailure);
    });

    test('call() returns null for unknown field', () {
      expect(failure('age'), isNull);
    });

    test('hasError() true for failing field', () {
      expect(failure.hasError('email'), isTrue);
    });

    test('hasError() false for unknown field', () {
      expect(failure.hasError('age'), isFalse);
    });

    test('fields returns all failing field names', () {
      expect(failure.fields, containsAll(['email', 'password']));
    });

    test('firstField returns first failing field', () {
      expect(failure.firstField, isNotNull);
      expect(['email', 'password'], contains(failure.firstField));
    });
  });

  group('switch exhaustiveness', () {
    test('sealed FormValidationResult switch', () {
      final FormValidationResult result = const FormValidationSuccess();
      final output = switch (result) {
        FormValidationSuccess() => 'ok',
        FormValidationFailure() => 'fail',
      };
      expect(output, 'ok');
    });
  });
}
