import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  // ---------------------------------------------------------------------------
  // isTrue()
  // ---------------------------------------------------------------------------
  group('isTrue()', () {
    test('passes for true', () {
      expect(ValidateBool().isTrue().validate(true), isA<ValidationSuccess>());
    });

    test('fails for false', () {
      final result = ValidateBool().setLabel('Agreed').isTrue().validate(false);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.boolTrue);
    });

    test('passes for null (null-skip)', () {
      expect(ValidateBool().isTrue().validate(null), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result = ValidateBool()
              .setLabel('Terms')
              .isTrue(messageFactory: (label, _) => '$label 동의 필요')
              .validate(false)
          as ValidationFailure;
      expect(result.message, 'Terms 동의 필요');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.boolTrue: (p) => '${p['name']} 참이어야 합니다.',
        }),
      );
      final result =
          ValidateBool().setLabel('동의').isTrue().validate(false) as ValidationFailure;
      expect(result.message, '동의 참이어야 합니다.');
    });

    test('default message contains label', () {
      final result =
          ValidateBool().setLabel('Consent').isTrue().validate(false) as ValidationFailure;
      expect(result.message, contains('Consent'));
    });

    test('combined with required: null fails at required', () {
      final v = ValidateBool().setLabel('Terms').required().isTrue();
      final result = v.validate(null) as ValidationFailure;
      expect(result.code, ValidationCode.required);
    });

    test('combined with required: false fails at isTrue', () {
      final v = ValidateBool().setLabel('Terms').required().isTrue();
      final result = v.validate(false) as ValidationFailure;
      expect(result.code, ValidationCode.boolTrue);
    });

    test('combined with required: true passes', () {
      expect(
        ValidateBool().setLabel('Terms').required().isTrue().validate(true),
        isA<ValidationSuccess>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // isFalse()
  // ---------------------------------------------------------------------------
  group('isFalse()', () {
    test('passes for false', () {
      expect(
        ValidateBool().isFalse().validate(false),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for true', () {
      final result = ValidateBool().setLabel('Flag').isFalse().validate(true);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.boolFalse);
    });

    test('passes for null (null-skip)', () {
      expect(ValidateBool().isFalse().validate(null), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result = ValidateBool()
              .setLabel('Flag')
              .isFalse(messageFactory: (label, _) => '$label 거짓이어야 함')
              .validate(true)
          as ValidationFailure;
      expect(result.message, 'Flag 거짓이어야 함');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.boolFalse: (p) => '${p['name']} 거짓이어야 합니다.',
        }),
      );
      final result =
          ValidateBool().setLabel('플래그').isFalse().validate(true) as ValidationFailure;
      expect(result.message, '플래그 거짓이어야 합니다.');
    });

    test('default message contains label', () {
      final result =
          ValidateBool().setLabel('Lock').isFalse().validate(true) as ValidationFailure;
      expect(result.message, contains('Lock'));
    });

    test('combined with required: null fails at required', () {
      final v = ValidateBool().setLabel('Lock').required().isFalse();
      final result = v.validate(null) as ValidationFailure;
      expect(result.code, ValidationCode.required);
    });

    test('combined with required: true fails at isFalse', () {
      final v = ValidateBool().setLabel('Lock').required().isFalse();
      final result = v.validate(true) as ValidationFailure;
      expect(result.code, ValidationCode.boolFalse);
    });

    test('combined with required: false passes', () {
      expect(
        ValidateBool().setLabel('Lock').required().isFalse().validate(false),
        isA<ValidationSuccess>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 실제 유저 입력 패턴 — 이용약관 동의
  // ---------------------------------------------------------------------------
  group('real user input — terms of service agreement', () {
    final termsValidator = ValidateBool().setLabel('이용약관').required().isTrue();

    test('agreed (true) — passes', () {
      expect(termsValidator.validate(true), isA<ValidationSuccess>());
    });

    test('not agreed (false) — fails', () {
      final result = termsValidator.validate(false) as ValidationFailure;
      expect(result.code, ValidationCode.boolTrue);
    });

    test('unchecked (null) — required fails', () {
      final result = termsValidator.validate(null) as ValidationFailure;
      expect(result.code, ValidationCode.required);
    });

    test('error message contains field label', () {
      final result = termsValidator.validate(false) as ValidationFailure;
      expect(result.message, contains('이용약관'));
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — optional consent (e.g. marketing emails)
  // ---------------------------------------------------------------------------
  group('real user input — optional consent (marketing)', () {
    final optionalValidator = ValidateBool().setLabel('광고 수신 동의').isTrue();

    test('agreed (true) — passes', () {
      expect(optionalValidator.validate(true), isA<ValidationSuccess>());
    });

    test('not agreed (false) — fails (optional but must be true when set)', () {
      expect(optionalValidator.validate(false), isA<ValidationFailure>());
    });

    test('null — passes (null-skip for optional field)', () {
      expect(optionalValidator.validate(null), isA<ValidationSuccess>());
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — account lock check (isFalse scenario)
  // ---------------------------------------------------------------------------
  group('real user input — account lock status', () {
    final lockValidator = ValidateBool().setLabel('계정 잠금').isFalse();

    test('unlocked (false) — passes', () {
      expect(lockValidator.validate(false), isA<ValidationSuccess>());
    });

    test('locked (true) — fails', () {
      final result = lockValidator.validate(true) as ValidationFailure;
      expect(result.code, ValidationCode.boolFalse);
    });

    test('null — passes (null-skip)', () {
      expect(lockValidator.validate(null), isA<ValidationSuccess>());
    });
  });

  // ---------------------------------------------------------------------------
  // toValidator()
  // ---------------------------------------------------------------------------
  group('toValidator()', () {
    test('returns null on success (isTrue with true)', () {
      expect(ValidateBool().isTrue().toValidator()(true), isNull);
    });

    test('returns message on failure (isTrue with false)', () {
      final fn = ValidateBool().setLabel('Agreed').isTrue().toValidator();
      expect(fn(false), isNotNull);
      expect(fn(false), contains('Agreed'));
    });

    test('returns null when null and not required', () {
      expect(ValidateBool().isTrue().toValidator()(null), isNull);
    });
  });
}
