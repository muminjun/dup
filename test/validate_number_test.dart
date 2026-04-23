import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  group('ValidateNumber.min / max', () {
    test('min passes when value is sufficient', () {
      expect(ValidateNumber().setLabel('N').min(5).validate(5), isNull);
      expect(ValidateNumber().setLabel('N').min(5).validate(10), isNull);
    });
    test('min fails when value is too small', () {
      expect(ValidateNumber().setLabel('N').min(5).validate(4), isNotNull);
    });
    test('max passes when within limit', () {
      expect(ValidateNumber().setLabel('N').max(10).validate(10), isNull);
      expect(ValidateNumber().setLabel('N').max(10).validate(5), isNull);
    });
    test('max fails when too large', () {
      expect(ValidateNumber().setLabel('N').max(10).validate(11), isNotNull);
    });
    test('min skips on null', () {
      expect(ValidateNumber().setLabel('N').min(5).validate(null), isNull);
    });
    test('max skips on null', () {
      expect(ValidateNumber().setLabel('N').max(10).validate(null), isNull);
    });
  });

  group('ValidateNumber.isInteger', () {
    test('passes for integer value', () {
      expect(ValidateNumber().setLabel('N').isInteger().validate(5), isNull);
      expect(ValidateNumber().setLabel('N').isInteger().validate(0), isNull);
    });
    test('fails for float', () {
      expect(ValidateNumber().setLabel('N').isInteger().validate(5.5), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateNumber().setLabel('N').isInteger().validate(null), isNull);
    });
  });

  group('ValidateNumber.isPositive', () {
    test('passes for positive value', () {
      expect(ValidateNumber().setLabel('N').isPositive().validate(1), isNull);
      expect(ValidateNumber().setLabel('N').isPositive().validate(0.1), isNull);
    });
    test('fails for zero', () {
      expect(ValidateNumber().setLabel('N').isPositive().validate(0), isNotNull);
    });
    test('fails for negative', () {
      expect(ValidateNumber().setLabel('N').isPositive().validate(-1), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateNumber().setLabel('N').isPositive().validate(null), isNull);
    });
  });

  group('ValidateNumber.isNegative', () {
    test('passes for negative value', () {
      expect(ValidateNumber().setLabel('N').isNegative().validate(-1), isNull);
    });
    test('fails for zero', () {
      expect(ValidateNumber().setLabel('N').isNegative().validate(0), isNotNull);
    });
    test('fails for positive', () {
      expect(ValidateNumber().setLabel('N').isNegative().validate(1), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateNumber().setLabel('N').isNegative().validate(null), isNull);
    });
  });

  group('ValidateNumber.isNonNegative', () {
    test('passes for zero', () {
      expect(ValidateNumber().setLabel('N').isNonNegative().validate(0), isNull);
    });
    test('passes for positive', () {
      expect(ValidateNumber().setLabel('N').isNonNegative().validate(5), isNull);
    });
    test('fails for negative', () {
      expect(ValidateNumber().setLabel('N').isNonNegative().validate(-1), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateNumber().setLabel('N').isNonNegative().validate(null), isNull);
    });
  });

  group('ValidateNumber.isNonPositive', () {
    test('passes for zero', () {
      expect(ValidateNumber().setLabel('N').isNonPositive().validate(0), isNull);
    });
    test('passes for negative', () {
      expect(ValidateNumber().setLabel('N').isNonPositive().validate(-5), isNull);
    });
    test('fails for positive', () {
      expect(ValidateNumber().setLabel('N').isNonPositive().validate(1), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateNumber().setLabel('N').isNonPositive().validate(null), isNull);
    });
  });

  group('ValidateNumber — phase ordering', () {
    test('required fires before isPositive regardless of chain order', () {
      final v = ValidateNumber().setLabel('N').isPositive().required();
      expect(v.validate(null), equals('N is required.'));
    });

    test('isInteger (phase 1) fires before min (phase 2)', () {
      final v = ValidateNumber().setLabel('N').min(100).isInteger();
      expect(v.validate(5.5), contains('integer'));
    });
  });
}
