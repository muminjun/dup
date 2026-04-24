// test/validation_result_test.dart
import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationSuccess', () {
    test('is a ValidationResult', () {
      const result = ValidationSuccess();
      expect(result, isA<ValidationResult>());
    });

    test('equality', () {
      expect(const ValidationSuccess(), equals(const ValidationSuccess()));
    });
  });

  group('ValidationFailure', () {
    test('stores code, message, context', () {
      const f = ValidationFailure(
        code: ValidationCode.required,
        message: 'Field is required.',
        context: {'name': 'Email'},
      );
      expect(f.code, ValidationCode.required);
      expect(f.message, 'Field is required.');
      expect(f.context['name'], 'Email');
    });

    test('customCode defaults to null', () {
      const f = ValidationFailure(
        code: ValidationCode.custom,
        message: 'Custom error.',
      );
      expect(f.customCode, isNull);
    });

    test('customCode can be set', () {
      const f = ValidationFailure(
        code: ValidationCode.custom,
        customCode: 'myTag',
        message: 'Custom error.',
      );
      expect(f.customCode, 'myTag');
    });

    test('context defaults to empty map', () {
      const f = ValidationFailure(
        code: ValidationCode.emailInvalid,
        message: 'Bad email.',
      );
      expect(f.context, isEmpty);
    });

    test('is a ValidationResult', () {
      const f = ValidationFailure(
        code: ValidationCode.required,
        message: 'req',
      );
      expect(f, isA<ValidationResult>());
    });
  });

  group('switch exhaustiveness', () {
    test('sealed class switch covers both cases', () {
      ValidationResult result = const ValidationSuccess();
      final output = switch (result) {
        ValidationSuccess() => 'ok',
        ValidationFailure(:final message) => message,
      };
      expect(output, 'ok');
    });
  });
}
