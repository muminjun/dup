import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  group('FormValidationException', () {
    test('stores errors as Map<String, String> (non-nullable values)', () {
      final ex = FormValidationException({'email': 'Invalid email.'});
      final String error = ex.errors['email']!;
      expect(error, equals('Invalid email.'));
    });

    test('toString returns first non-empty error message', () {
      final ex = FormValidationException({
        'email': 'Invalid email.',
        'name': 'Name is required.',
      });
      expect(ex.toString(), equals('Invalid email.'));
    });

    test('toString returns fallbackMessage when errors map is empty', () {
      final ex = FormValidationException({}, fallbackMessage: 'Form is invalid.');
      expect(ex.toString(), equals('Form is invalid.'));
    });

    test('default fallbackMessage is "Invalid form."', () {
      final ex = FormValidationException({});
      expect(ex.toString(), equals('Invalid form.'));
    });

    test('errors map keys are accessible', () {
      final ex = FormValidationException({
        'email': 'bad email',
        'age': 'too young',
      });
      expect(ex.errors.containsKey('email'), isTrue);
      expect(ex.errors.containsKey('age'), isTrue);
      expect(ex.errors.containsKey('name'), isFalse);
    });

    test('is an Exception', () {
      expect(FormValidationException({'x': 'err'}), isA<Exception>());
    });
  });
}
