import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('min()', () {
    test('passes when value >= min', () {
      expect(ValidateNumber().min(5).validate(10), isA<ValidationSuccess>());
    });

    test('fails when value < min', () {
      final result = ValidateNumber().min(18).validate(17);
      expect((result as ValidationFailure).code, ValidationCode.numberMin);
      expect(result.context['min'], 18);
    });

    test('passes for null', () {
      expect(ValidateNumber().min(5).validate(null), isA<ValidationSuccess>());
    });
  });

  group('max()', () {
    test('fails when value > max', () {
      final result = ValidateNumber().max(100).validate(200);
      expect((result as ValidationFailure).code, ValidationCode.numberMax);
    });
  });

  group('isInteger()', () {
    test('fails for decimal', () {
      final result = ValidateNumber().isInteger().validate(1.5);
      expect((result as ValidationFailure).code, ValidationCode.integer);
    });

    test('passes for whole number', () {
      expect(ValidateNumber().isInteger().validate(3), isA<ValidationSuccess>());
    });
  });

  group('isPositive()', () {
    test('fails for zero', () {
      expect(ValidateNumber().isPositive().validate(0), isA<ValidationFailure>());
    });

    test('passes for positive', () {
      expect(ValidateNumber().isPositive().validate(1), isA<ValidationSuccess>());
    });
  });

  group('between()', () {
    test('fails outside range', () {
      final result = ValidateNumber().between(1, 10).validate(0);
      expect((result as ValidationFailure).code, ValidationCode.between);
    });
  });

  group('toValidator() — string-parsing override', () {
    test('returns null for valid input', () {
      final fn = ValidateNumber().min(18).toValidator();
      expect(fn('20'), isNull);
    });

    test('returns parse error for non-numeric input', () {
      final fn = ValidateNumber().setLabel('나이').min(18).toValidator();
      expect(fn('abc'), contains('나이'));
    });

    test('returns validation error for out-of-range input', () {
      final fn = ValidateNumber().setLabel('나이').min(18).toValidator();
      expect(fn('17'), isNotNull);
    });

    test('passes null through to required check', () {
      final fn = ValidateNumber().required().toValidator();
      expect(fn(null), isNotNull);
    });
  });

  group('locale', () {
    test('uses locale message for numberMin', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.numberMin: (p) => '${p['name']} 최솟값 초과',
      }));
      final result = ValidateNumber().setLabel('나이').min(18).validate(10)
          as ValidationFailure;
      expect(result.message, '나이 최솟값 초과');
    });
  });
}
