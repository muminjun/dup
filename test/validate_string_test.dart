import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('min()', () {
    test('passes when length >= min', () {
      expect(ValidateString().min(3).validate('abc'), isA<ValidationSuccess>());
    });

    test('fails when length < min', () {
      final result = ValidateString().setLabel('Name').min(3).validate('ab');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.stringMin);
      expect(result.context['min'], 3);
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().min(3).validate(null), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result = ValidateString().setLabel('이름').min(3,
          messageFactory: (label, p) => '$label 최소 ${p['min']}자').validate('ab')
          as ValidationFailure;
      expect(result.message, '이름 최소 3자');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.stringMin: (p) => '${p['name']} 짧음',
      }));
      final result = ValidateString().setLabel('비번').min(8).validate('abc')
          as ValidationFailure;
      expect(result.message, '비번 짧음');
    });
  });

  group('email()', () {
    test('passes for valid email', () {
      expect(ValidateString().email().validate('a@b.com'), isA<ValidationSuccess>());
    });

    test('fails for invalid email', () {
      final result = ValidateString().email().validate('notanemail');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.emailInvalid);
    });

    test('passes for null', () {
      expect(ValidateString().email().validate(null), isA<ValidationSuccess>());
    });

    test('passes for empty string', () {
      expect(ValidateString().email().validate(''), isA<ValidationSuccess>());
    });
  });

  group('required()', () {
    test('fails for null', () {
      final result = ValidateString().required().validate(null);
      expect((result as ValidationFailure).code, ValidationCode.required);
    });

    test('fails for empty string', () {
      expect(ValidateString().required().validate(''), isA<ValidationFailure>());
    });
  });

  group('notBlank()', () {
    test('fails for whitespace-only string', () {
      final result = ValidateString().notBlank().validate('   ');
      expect((result as ValidationFailure).code, ValidationCode.notBlank);
    });

    test('passes for null', () {
      expect(ValidateString().notBlank().validate(null), isA<ValidationSuccess>());
    });
  });

  group('max()', () {
    test('fails when length > max', () {
      final result = ValidateString().max(2).validate('abc');
      expect((result as ValidationFailure).code, ValidationCode.stringMax);
    });
  });

  group('matches()', () {
    test('fails when regex does not match', () {
      final result = ValidateString().matches(RegExp(r'^\d+$')).validate('abc');
      expect((result as ValidationFailure).code, ValidationCode.matches);
    });
  });

  group('password()', () {
    test('fails when too short', () {
      final result = ValidateString().password(minLength: 8).validate('short');
      expect((result as ValidationFailure).code, ValidationCode.passwordMin);
    });
  });

  group('alpha()', () {
    test('fails for non-alpha string', () {
      final result = ValidateString().alpha().validate('abc123');
      expect((result as ValidationFailure).code, ValidationCode.alpha);
    });
  });

  group('toValidator()', () {
    test('returns null on success', () {
      expect(ValidateString().email().toValidator()('a@b.com'), isNull);
    });

    test('returns message string on failure', () {
      final fn = ValidateString().setLabel('Email').email().toValidator();
      expect(fn('bad'), isNotNull);
    });
  });
}
