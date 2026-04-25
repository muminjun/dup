import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  // ---------------------------------------------------------------------------
  // min()
  // ---------------------------------------------------------------------------
  group('min()', () {
    test('passes when value > min', () {
      expect(ValidateNumber().min(5).validate(10), isA<ValidationSuccess>());
    });

    test('passes when value == min (boundary)', () {
      expect(ValidateNumber().min(5).validate(5), isA<ValidationSuccess>());
    });

    test('fails when value < min', () {
      final result = ValidateNumber().setLabel('Age').min(18).validate(17);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.numberMin);
      expect(result.context['min'], 18);
    });

    test('passes for null (null-skip)', () {
      expect(ValidateNumber().min(5).validate(null), isA<ValidationSuccess>());
    });

    test('works with decimal min', () {
      expect(ValidateNumber().min(1.5).validate(1.4), isA<ValidationFailure>());
      expect(ValidateNumber().min(1.5).validate(1.5), isA<ValidationSuccess>());
    });

    test('works with negative min', () {
      expect(ValidateNumber().min(-5).validate(-10), isA<ValidationFailure>());
      expect(ValidateNumber().min(-5).validate(-5), isA<ValidationSuccess>());
      expect(ValidateNumber().min(-5).validate(0), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result = ValidateNumber()
              .setLabel('Age')
              .min(18, messageFactory: (label, p) => '$label 최소 ${p['min']}')
              .validate(17)
          as ValidationFailure;
      expect(result.message, 'Age 최소 18');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.numberMin: (p) => '${p['name']} 최솟값 초과',
        }),
      );
      final result = ValidateNumber().setLabel('나이').min(18).validate(10)
          as ValidationFailure;
      expect(result.message, '나이 최솟값 초과');
    });
  });

  // ---------------------------------------------------------------------------
  // max()
  // ---------------------------------------------------------------------------
  group('max()', () {
    test('passes when value < max', () {
      expect(ValidateNumber().max(100).validate(50), isA<ValidationSuccess>());
    });

    test('passes when value == max (boundary)', () {
      expect(ValidateNumber().max(100).validate(100), isA<ValidationSuccess>());
    });

    test('fails when value > max', () {
      final result = ValidateNumber().setLabel('Score').max(100).validate(200);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.numberMax);
      expect(result.context['max'], 100);
    });

    test('passes for null (null-skip)', () {
      expect(ValidateNumber().max(100).validate(null), isA<ValidationSuccess>());
    });

    test('works with negative max', () {
      expect(ValidateNumber().max(-1).validate(0), isA<ValidationFailure>());
      expect(ValidateNumber().max(-1).validate(-1), isA<ValidationSuccess>());
      expect(ValidateNumber().max(-1).validate(-2), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result = ValidateNumber()
              .setLabel('Score')
              .max(100, messageFactory: (label, p) => '$label 최대 ${p['max']}')
              .validate(200)
          as ValidationFailure;
      expect(result.message, 'Score 최대 100');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.numberMax: (p) => '${p['name']} 최댓값 초과',
        }),
      );
      final result = ValidateNumber().setLabel('점수').max(100).validate(200)
          as ValidationFailure;
      expect(result.message, '점수 최댓값 초과');
    });
  });

  // ---------------------------------------------------------------------------
  // isInteger()
  // ---------------------------------------------------------------------------
  group('isInteger()', () {
    test('passes for int literal', () {
      expect(ValidateNumber().isInteger().validate(3), isA<ValidationSuccess>());
    });

    test('passes for whole-number double (1.0)', () {
      expect(ValidateNumber().isInteger().validate(1.0), isA<ValidationSuccess>());
    });

    test('passes for zero', () {
      expect(ValidateNumber().isInteger().validate(0), isA<ValidationSuccess>());
    });

    test('passes for negative whole number', () {
      expect(ValidateNumber().isInteger().validate(-5), isA<ValidationSuccess>());
    });

    test('fails for decimal', () {
      final result = ValidateNumber().setLabel('Count').isInteger().validate(1.5);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.integer);
    });

    test('fails for small decimal', () {
      expect(ValidateNumber().isInteger().validate(1.001), isA<ValidationFailure>());
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateNumber().isInteger().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateNumber()
              .setLabel('Count')
              .isInteger(messageFactory: (label, _) => '$label 정수만 가능')
              .validate(1.5)
          as ValidationFailure;
      expect(result.message, 'Count 정수만 가능');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.integer: (p) => '${p['name']} 정수 오류',
        }),
      );
      final result = ValidateNumber().setLabel('수량').isInteger().validate(1.5)
          as ValidationFailure;
      expect(result.message, '수량 정수 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // isPositive()
  // ---------------------------------------------------------------------------
  group('isPositive()', () {
    test('passes for positive integer', () {
      expect(ValidateNumber().isPositive().validate(1), isA<ValidationSuccess>());
    });

    test('passes for small positive decimal', () {
      expect(
        ValidateNumber().isPositive().validate(0.001),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for zero', () {
      final result = ValidateNumber().setLabel('N').isPositive().validate(0);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.positive);
    });

    test('fails for negative number', () {
      expect(ValidateNumber().isPositive().validate(-1), isA<ValidationFailure>());
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateNumber().isPositive().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateNumber()
              .setLabel('Price')
              .isPositive(messageFactory: (label, _) => '$label 양수만 가능')
              .validate(-1)
          as ValidationFailure;
      expect(result.message, 'Price 양수만 가능');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.positive: (p) => '${p['name']} 양수 오류',
        }),
      );
      final result =
          ValidateNumber().setLabel('가격').isPositive().validate(-1) as ValidationFailure;
      expect(result.message, '가격 양수 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // isNegative()
  // ---------------------------------------------------------------------------
  group('isNegative()', () {
    test('passes for negative integer', () {
      expect(ValidateNumber().isNegative().validate(-1), isA<ValidationSuccess>());
    });

    test('passes for small negative decimal', () {
      expect(
        ValidateNumber().isNegative().validate(-0.001),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for zero', () {
      final result = ValidateNumber().setLabel('N').isNegative().validate(0);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.negative);
    });

    test('fails for positive number', () {
      expect(ValidateNumber().isNegative().validate(1), isA<ValidationFailure>());
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateNumber().isNegative().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateNumber()
              .setLabel('Delta')
              .isNegative(messageFactory: (label, _) => '$label 음수만 가능')
              .validate(1)
          as ValidationFailure;
      expect(result.message, 'Delta 음수만 가능');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.negative: (p) => '${p['name']} 음수 오류',
        }),
      );
      final result =
          ValidateNumber().setLabel('변화량').isNegative().validate(5) as ValidationFailure;
      expect(result.message, '변화량 음수 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // isNonNegative()
  // ---------------------------------------------------------------------------
  group('isNonNegative()', () {
    test('passes for positive number', () {
      expect(
        ValidateNumber().isNonNegative().validate(5),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for zero (zero is allowed)', () {
      expect(ValidateNumber().isNonNegative().validate(0), isA<ValidationSuccess>());
    });

    test('fails for negative integer', () {
      final result = ValidateNumber().setLabel('N').isNonNegative().validate(-1);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.nonNegative);
    });

    test('fails for small negative decimal', () {
      expect(
        ValidateNumber().isNonNegative().validate(-0.001),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateNumber().isNonNegative().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateNumber()
              .setLabel('Qty')
              .isNonNegative(messageFactory: (label, _) => '$label 0 이상')
              .validate(-1)
          as ValidationFailure;
      expect(result.message, 'Qty 0 이상');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.nonNegative: (p) => '${p['name']} 비음수 오류',
        }),
      );
      final result =
          ValidateNumber().setLabel('수량').isNonNegative().validate(-1)
              as ValidationFailure;
      expect(result.message, '수량 비음수 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // isNonPositive()
  // ---------------------------------------------------------------------------
  group('isNonPositive()', () {
    test('passes for negative number', () {
      expect(
        ValidateNumber().isNonPositive().validate(-5),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for zero (zero is allowed)', () {
      expect(ValidateNumber().isNonPositive().validate(0), isA<ValidationSuccess>());
    });

    test('fails for positive integer', () {
      final result = ValidateNumber().setLabel('N').isNonPositive().validate(1);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.nonPositive);
    });

    test('fails for small positive decimal', () {
      expect(
        ValidateNumber().isNonPositive().validate(0.001),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateNumber().isNonPositive().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateNumber()
              .setLabel('Offset')
              .isNonPositive(messageFactory: (label, _) => '$label 0 이하')
              .validate(1)
          as ValidationFailure;
      expect(result.message, 'Offset 0 이하');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.nonPositive: (p) => '${p['name']} 비양수 오류',
        }),
      );
      final result =
          ValidateNumber().setLabel('오프셋').isNonPositive().validate(1)
              as ValidationFailure;
      expect(result.message, '오프셋 비양수 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // between()
  // ---------------------------------------------------------------------------
  group('between()', () {
    test('passes when value == min (inclusive lower boundary)', () {
      expect(
        ValidateNumber().between(1, 10).validate(1),
        isA<ValidationSuccess>(),
      );
    });

    test('passes when value == max (inclusive upper boundary)', () {
      expect(
        ValidateNumber().between(1, 10).validate(10),
        isA<ValidationSuccess>(),
      );
    });

    test('passes when value is within range', () {
      expect(
        ValidateNumber().between(1, 10).validate(5),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when value < min', () {
      final result = ValidateNumber().setLabel('N').between(1, 10).validate(0);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.between);
      expect(result.context['min'], 1);
      expect(result.context['max'], 10);
    });

    test('fails when value > max', () {
      expect(
        ValidateNumber().between(1, 10).validate(11),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateNumber().between(1, 10).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('works with decimal range', () {
      expect(
        ValidateNumber().between(0.5, 1.5).validate(1.0),
        isA<ValidationSuccess>(),
      );
      expect(
        ValidateNumber().between(0.5, 1.5).validate(0.4),
        isA<ValidationFailure>(),
      );
    });

    test('works with negative range', () {
      expect(
        ValidateNumber().between(-10, -1).validate(-5),
        isA<ValidationSuccess>(),
      );
      expect(
        ValidateNumber().between(-10, -1).validate(0),
        isA<ValidationFailure>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateNumber()
              .setLabel('Score')
              .between(
                1,
                100,
                messageFactory: (label, p) =>
                    '$label ${p['min']}~${p['max']} 사이',
              )
              .validate(0)
          as ValidationFailure;
      expect(result.message, 'Score 1~100 사이');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.between: (p) => '${p['name']} 범위 오류',
        }),
      );
      final result = ValidateNumber().setLabel('점수').between(1, 10).validate(0)
          as ValidationFailure;
      expect(result.message, '점수 범위 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // isEven()
  // ---------------------------------------------------------------------------
  group('isEven()', () {
    test('passes for even positive integer', () {
      expect(ValidateNumber().isEven().validate(4), isA<ValidationSuccess>());
    });

    test('passes for zero (even)', () {
      expect(ValidateNumber().isEven().validate(0), isA<ValidationSuccess>());
    });

    test('passes for even negative integer', () {
      expect(ValidateNumber().isEven().validate(-4), isA<ValidationSuccess>());
    });

    test('fails for odd number', () {
      final result = ValidateNumber().setLabel('N').isEven().validate(3);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.even);
    });

    test('fails for odd negative number', () {
      expect(ValidateNumber().isEven().validate(-3), isA<ValidationFailure>());
    });

    test('fails for non-integer (e.g. 2.5)', () {
      expect(ValidateNumber().isEven().validate(2.5), isA<ValidationFailure>());
    });

    test('fails for non-integer (e.g. 3.5)', () {
      expect(ValidateNumber().isEven().validate(3.5), isA<ValidationFailure>());
    });

    test('passes for null (null-skip)', () {
      expect(ValidateNumber().isEven().validate(null), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result = ValidateNumber()
              .setLabel('N')
              .isEven(messageFactory: (label, _) => '$label 짝수만 가능')
              .validate(3)
          as ValidationFailure;
      expect(result.message, 'N 짝수만 가능');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.even: (p) => '${p['name']} 짝수 오류'}),
      );
      final result =
          ValidateNumber().setLabel('숫자').isEven().validate(3) as ValidationFailure;
      expect(result.message, '숫자 짝수 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // isOdd()
  // ---------------------------------------------------------------------------
  group('isOdd()', () {
    test('passes for odd positive integer', () {
      expect(ValidateNumber().isOdd().validate(3), isA<ValidationSuccess>());
    });

    test('passes for odd negative integer', () {
      expect(ValidateNumber().isOdd().validate(-3), isA<ValidationSuccess>());
    });

    test('fails for even number', () {
      final result = ValidateNumber().setLabel('N').isOdd().validate(4);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.odd);
    });

    test('fails for zero', () {
      expect(ValidateNumber().isOdd().validate(0), isA<ValidationFailure>());
    });

    test('fails for even negative number', () {
      expect(ValidateNumber().isOdd().validate(-4), isA<ValidationFailure>());
    });

    test('fails for non-integer (e.g. 2.5)', () {
      expect(ValidateNumber().isOdd().validate(2.5), isA<ValidationFailure>());
    });

    test('fails for non-integer (e.g. 3.5)', () {
      expect(ValidateNumber().isOdd().validate(3.5), isA<ValidationFailure>());
    });

    test('passes for null (null-skip)', () {
      expect(ValidateNumber().isOdd().validate(null), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result = ValidateNumber()
              .setLabel('N')
              .isOdd(messageFactory: (label, _) => '$label 홀수만 가능')
              .validate(4)
          as ValidationFailure;
      expect(result.message, 'N 홀수만 가능');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.odd: (p) => '${p['name']} 홀수 오류'}),
      );
      final result =
          ValidateNumber().setLabel('숫자').isOdd().validate(4) as ValidationFailure;
      expect(result.message, '숫자 홀수 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // isMultipleOf()
  // ---------------------------------------------------------------------------
  group('isMultipleOf()', () {
    test('passes when value is a multiple of factor', () {
      expect(
        ValidateNumber().isMultipleOf(5).validate(10),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for zero (0 is a multiple of anything)', () {
      expect(ValidateNumber().isMultipleOf(5).validate(0), isA<ValidationSuccess>());
    });

    test('passes for negative multiples', () {
      expect(
        ValidateNumber().isMultipleOf(5).validate(-10),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when value is not a multiple', () {
      final result = ValidateNumber().setLabel('N').isMultipleOf(5).validate(7);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.multipleOf);
      expect(result.context['factor'], 5);
    });

    test('fails for partial multiple', () {
      expect(
        ValidateNumber().isMultipleOf(3).validate(4),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateNumber().isMultipleOf(5).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateNumber()
              .setLabel('N')
              .isMultipleOf(
                3,
                messageFactory: (label, p) => '$label ${p['factor']}의 배수',
              )
              .validate(7)
          as ValidationFailure;
      expect(result.message, 'N 3의 배수');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.multipleOf: (p) => '${p['name']} 배수 오류',
        }),
      );
      final result = ValidateNumber().setLabel('숫자').isMultipleOf(5).validate(7)
          as ValidationFailure;
      expect(result.message, '숫자 배수 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // toValidator() — string-parsing override
  // ---------------------------------------------------------------------------
  group('toValidator() — string-parsing override', () {
    test('returns null for valid numeric string that passes validation', () {
      expect(ValidateNumber().min(18).toValidator()('20'), isNull);
    });

    test('returns parse error for non-numeric input', () {
      final fn = ValidateNumber().setLabel('나이').min(18).toValidator();
      expect(fn('abc'), contains('나이'));
    });

    test('returns custom parse error message when provided', () {
      final fn = ValidateNumber()
          .setLabel('나이')
          .min(18)
          .toValidator(parseErrorMessage: '숫자를 입력하세요');
      expect(fn('abc'), '숫자를 입력하세요');
    });

    test('returns validation error for out-of-range input', () {
      final fn = ValidateNumber().setLabel('나이').min(18).toValidator();
      expect(fn('17'), isNotNull);
    });

    test('passes null through to required check', () {
      final fn = ValidateNumber().required().toValidator();
      expect(fn(null), isNotNull);
    });

    test('passes empty string through to required check', () {
      final fn = ValidateNumber().required().toValidator();
      expect(fn(''), isNotNull);
    });

    test('returns null for valid number at boundary', () {
      expect(ValidateNumber().min(18).toValidator()('18'), isNull);
    });

    test('correctly parses integer string', () {
      expect(ValidateNumber().isInteger().toValidator()('5'), isNull);
    });

    test('correctly parses decimal string and detects non-integer', () {
      expect(ValidateNumber().isInteger().toValidator()('1.5'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // locale
  // ---------------------------------------------------------------------------
  group('locale', () {
    test('uses locale message for numberMin', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.numberMin: (p) => '${p['name']} 최솟값 초과',
        }),
      );
      final result = ValidateNumber().setLabel('나이').min(18).validate(10)
          as ValidationFailure;
      expect(result.message, '나이 최솟값 초과');
    });
  });

  // ---------------------------------------------------------------------------
  // 실제 유저 입력 패턴 — 나이(age) 필드
  // ---------------------------------------------------------------------------
  group('real user input — age field', () {
    final ageValidator = ValidateNumber().setLabel('나이').min(0).max(150).isInteger();

    test('age 25 — passes', () {
      expect(ageValidator.validate(25), isA<ValidationSuccess>());
    });

    test('age 18 — passes', () {
      expect(ageValidator.validate(18), isA<ValidationSuccess>());
    });

    test('age 0 (newborn) — passes', () {
      expect(ageValidator.validate(0), isA<ValidationSuccess>());
    });

    test('age -1 — fails', () {
      expect(ageValidator.validate(-1), isA<ValidationFailure>());
    });

    test('age 17.5 (fractional) — fails', () {
      expect(ageValidator.validate(17.5), isA<ValidationFailure>());
    });

    test('age 200 (unrealistic) — fails', () {
      expect(ageValidator.validate(200), isA<ValidationFailure>());
    });

    test('null — passes when not required', () {
      expect(ageValidator.validate(null), isA<ValidationSuccess>());
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — price field
  // ---------------------------------------------------------------------------
  group('real user input — price field', () {
    final priceValidator = ValidateNumber().setLabel('가격').min(0);

    test('10000 — passes', () {
      expect(priceValidator.validate(10000), isA<ValidationSuccess>());
    });

    test('0 (free) — passes', () {
      expect(priceValidator.validate(0), isA<ValidationSuccess>());
    });

    test('-1000 (negative) — fails', () {
      expect(priceValidator.validate(-1000), isA<ValidationFailure>());
    });

    test('1.99 (decimal price) — passes', () {
      expect(priceValidator.validate(1.99), isA<ValidationSuccess>());
    });

    test('99999999 (large amount) — passes', () {
      expect(priceValidator.validate(99999999), isA<ValidationSuccess>());
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — quantity field
  // ---------------------------------------------------------------------------
  group('real user input — quantity field', () {
    final qtyValidator =
        ValidateNumber().setLabel('수량').isInteger().isPositive().max(999);

    test('quantity 1 — passes', () {
      expect(qtyValidator.validate(1), isA<ValidationSuccess>());
    });

    test('quantity 999 — passes (upper boundary)', () {
      expect(qtyValidator.validate(999), isA<ValidationSuccess>());
    });

    test('quantity 0 — fails (not positive)', () {
      expect(qtyValidator.validate(0), isA<ValidationFailure>());
    });

    test('quantity -1 — fails (negative)', () {
      expect(qtyValidator.validate(-1), isA<ValidationFailure>());
    });

    test('quantity 1000 — fails (exceeds max)', () {
      expect(qtyValidator.validate(1000), isA<ValidationFailure>());
    });

    test('quantity 1.5 (fractional) — fails', () {
      expect(qtyValidator.validate(1.5), isA<ValidationFailure>());
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — rating field
  // ---------------------------------------------------------------------------
  group('real user input — rating field', () {
    final ratingValidator =
        ValidateNumber().setLabel('별점').between(1, 5).isInteger();

    test('rating 5 — passes', () {
      expect(ratingValidator.validate(5), isA<ValidationSuccess>());
    });

    test('rating 1 — passes (lower boundary)', () {
      expect(ratingValidator.validate(1), isA<ValidationSuccess>());
    });

    test('rating 3 — passes (mid-range)', () {
      expect(ratingValidator.validate(3), isA<ValidationSuccess>());
    });

    test('rating 0 — fails (out of range)', () {
      expect(ratingValidator.validate(0), isA<ValidationFailure>());
    });

    test('rating 6 — fails (exceeds max)', () {
      expect(ratingValidator.validate(6), isA<ValidationFailure>());
    });

    test('rating 2.5 — fails (not integer)', () {
      expect(ratingValidator.validate(2.5), isA<ValidationFailure>());
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — percentage (discount rate) field
  // ---------------------------------------------------------------------------
  group('real user input — discount rate field', () {
    final discountValidator = ValidateNumber().setLabel('할인율').between(0, 100);

    test('50% discount — passes', () {
      expect(discountValidator.validate(50), isA<ValidationSuccess>());
    });

    test('0% (no discount) — passes', () {
      expect(discountValidator.validate(0), isA<ValidationSuccess>());
    });

    test('100% (fully free) — passes', () {
      expect(discountValidator.validate(100), isA<ValidationSuccess>());
    });

    test('-1% — fails', () {
      expect(discountValidator.validate(-1), isA<ValidationFailure>());
    });

    test('101% — fails', () {
      expect(discountValidator.validate(101), isA<ValidationFailure>());
    });

    test('99.9% (decimal) — passes', () {
      expect(discountValidator.validate(99.9), isA<ValidationSuccess>());
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — string parsing via toValidator() (TextFormField)
  // ---------------------------------------------------------------------------
  group('real user input — string parsing (TextFormField)', () {
    test('"25" string input — passes', () {
      final fn = ValidateNumber().setLabel('나이').min(0).max(150).toValidator();
      expect(fn('25'), isNull);
    });

    test('"abc" string input — parse error', () {
      final fn = ValidateNumber().setLabel('나이').min(0).max(150).toValidator();
      expect(fn('abc'), isNotNull);
    });

    test('"" empty string + required — error', () {
      final fn = ValidateNumber().setLabel('나이').required().toValidator();
      expect(fn(''), isNotNull);
    });

    test('"1,000" with comma — parse error (not supported)', () {
      final fn = ValidateNumber().setLabel('금액').min(0).toValidator();
      expect(fn('1,000'), isNotNull);
    });

    test('"17세" with unit suffix — parse error', () {
      final fn = ValidateNumber().setLabel('나이').min(18).toValidator();
      expect(fn('17세'), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // Chaining / interaction
  // ---------------------------------------------------------------------------
  group('chaining validators', () {
    test('isInteger + min: non-integer checked at phase 1 before min at phase 2', () {
      final v = ValidateNumber().setLabel('Count').isInteger().min(5);
      final result = v.validate(1.5) as ValidationFailure;
      expect(result.code, ValidationCode.integer);
    });

    test('isInteger + min: integer that is below min fails at min', () {
      final v = ValidateNumber().setLabel('Count').isInteger().min(5);
      final result = v.validate(3) as ValidationFailure;
      expect(result.code, ValidationCode.numberMin);
    });

    test('min + max + isPositive: fails required if null', () {
      final v = ValidateNumber().required().min(1).max(100);
      expect(v.validate(null), isA<ValidationFailure>());
    });

    test('isPositive + isEven: negative fails at isPositive', () {
      final v = ValidateNumber().isPositive().isEven();
      final result = v.validate(-4) as ValidationFailure;
      expect(result.code, ValidationCode.positive);
    });

    test('between + isEven: passes when value in range and even', () {
      expect(
        ValidateNumber().between(1, 10).isEven().validate(4),
        isA<ValidationSuccess>(),
      );
    });
  });

  group('isPrecision()', () {
    test('passes when precision within limit', () {
      expect(ValidateNumber().isPrecision(2).validate(1.23), isA<ValidationSuccess>());
    });
    test('passes integer', () {
      expect(ValidateNumber().isPrecision(2).validate(5), isA<ValidationSuccess>());
    });
    test('fails when too many decimal places', () {
      final r = ValidateNumber().isPrecision(2).validate(1.234);
      expect(r, isA<ValidationFailure>());
      expect((r as ValidationFailure).code, ValidationCode.numberPrecision);
    });
    test('null passes', () {
      expect(ValidateNumber().isPrecision(2).validate(null), isA<ValidationSuccess>());
    });
  });

  group('isPort()', () {
    test('passes port 0', () {
      expect(ValidateNumber().isPort().validate(0), isA<ValidationSuccess>());
    });
    test('passes port 65535', () {
      expect(ValidateNumber().isPort().validate(65535), isA<ValidationSuccess>());
    });
    test('fails negative', () {
      expect(ValidateNumber().isPort().validate(-1), isA<ValidationFailure>());
    });
    test('fails above 65535', () {
      expect(ValidateNumber().isPort().validate(65536), isA<ValidationFailure>());
    });
    test('fails float (e.g. 80.5)', () {
      final r = ValidateNumber().isPort().validate(80.5);
      expect(r, isA<ValidationFailure>());
      expect((r as ValidationFailure).code, ValidationCode.isPort);
    });
    test('null passes', () {
      expect(ValidateNumber().isPort().validate(null), isA<ValidationSuccess>());
    });
  });
}
