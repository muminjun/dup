import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  group('UiFormService.validate', () {
    test('passes when all fields are valid', () async {
      final schema = BaseValidatorSchema({
        'email': ValidateString().setLabel('Email').email().required(),
        'age': ValidateNumber().setLabel('Age').min(0).required(),
      });
      await expectLater(
        useUiForm.validate(schema, {'email': 'user@example.com', 'age': 25}),
        completes,
      );
    });

    test('throws FormValidationException when a field is invalid', () async {
      final schema = BaseValidatorSchema({
        'email': ValidateString().setLabel('Email').email().required(),
      });
      await expectLater(
        useUiForm.validate(schema, {'email': 'bad-email'}),
        throwsA(isA<FormValidationException>()),
      );
    });

    test('collects all errors when abortEarly is false (default)', () async {
      final schema = BaseValidatorSchema({
        'name': ValidateString().setLabel('Name').required(),
        'email': ValidateString().setLabel('Email').email().required(),
      });
      try {
        await useUiForm.validate(schema, {'name': null, 'email': 'bad'});
        fail('Expected FormValidationException');
      } on FormValidationException catch (e) {
        expect(e.errors.length, equals(2));
      }
    });

    test('abortEarly stops at first error', () async {
      final schema = BaseValidatorSchema({
        'name': ValidateString().setLabel('Name').required(),
        'email': ValidateString().setLabel('Email').email().required(),
      });
      try {
        await useUiForm.validate(schema, {'name': null, 'email': 'bad'}, abortEarly: true);
        fail('Expected FormValidationException');
      } on FormValidationException catch (e) {
        expect(e.errors.length, equals(1));
      }
    });

    test('uses fallbackMessage in exception toString', () async {
      final schema = BaseValidatorSchema({
        'x': ValidateString().setLabel('X').required(),
      });
      try {
        await useUiForm.validate(schema, {'x': null}, fallbackMessage: 'Custom error');
        fail('Expected FormValidationException');
      } on FormValidationException catch (e) {
        expect(e.fallbackMessage, equals('Custom error'));
      }
    });
  });

  group('UiFormService.hasError', () {
    test('returns false when error is null', () {
      expect(useUiForm.hasError('email', null), isFalse);
    });

    test('returns true when path has an error', () {
      final ex = FormValidationException({'email': 'Email is required.'});
      expect(useUiForm.hasError('email', ex), isTrue);
    });

    test('returns false when path has no error', () {
      final ex = FormValidationException({'email': 'Email is required.'});
      expect(useUiForm.hasError('name', ex), isFalse);
    });
  });

  group('UiFormService.getError', () {
    test('returns null when error is null', () {
      expect(useUiForm.getError('email', null), isNull);
    });

    test('returns the error message for a failing field', () {
      final ex = FormValidationException({'email': 'Email is required.'});
      expect(useUiForm.getError('email', ex), equals('Email is required.'));
    });

    test('returns null for a field not in the error map', () {
      final ex = FormValidationException({'email': 'Email is required.'});
      expect(useUiForm.getError('name', ex), isNull);
    });
  });

  group('UiFormService — async validators', () {
    test('runs async validators after sync ones', () async {
      final v = ValidateString().setLabel('Username').required()
        ..addAsyncValidator((value) async {
          await Future.delayed(Duration.zero);
          if (value == 'taken') return 'Username is already taken.';
          return null;
        });

      final schema = BaseValidatorSchema({'username': v});

      await expectLater(
        useUiForm.validate(schema, {'username': 'available'}),
        completes,
      );

      await expectLater(
        useUiForm.validate(schema, {'username': 'taken'}),
        throwsA(isA<FormValidationException>()),
      );
    });

    test('sync error short-circuits async validators', () async {
      var asyncCalled = false;
      final v = ValidateString().setLabel('Username').required()
        ..addAsyncValidator((value) async {
          asyncCalled = true;
          return null;
        });

      final schema = BaseValidatorSchema({'username': v});

      try {
        await useUiForm.validate(schema, {'username': null});
      } on FormValidationException {
        // expected
      }

      expect(asyncCalled, isFalse);
    });
  });
}
