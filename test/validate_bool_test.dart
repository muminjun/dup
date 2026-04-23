import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('isTrue()', () {
    test('passes for true', () {
      expect(ValidateBool().isTrue().validate(true), isA<ValidationSuccess>());
    });

    test('fails for false', () {
      final result = ValidateBool().isTrue().validate(false);
      expect((result as ValidationFailure).code, ValidationCode.boolTrue);
    });

    test('passes for null', () {
      expect(ValidateBool().isTrue().validate(null), isA<ValidationSuccess>());
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.boolTrue: (p) => '${p['name']} 참이어야 합니다.',
      }));
      final result = ValidateBool().setLabel('동의').isTrue().validate(false)
          as ValidationFailure;
      expect(result.message, '동의 참이어야 합니다.');
    });
  });

  group('isFalse()', () {
    test('passes for false', () {
      expect(ValidateBool().isFalse().validate(false), isA<ValidationSuccess>());
    });

    test('fails for true', () {
      final result = ValidateBool().isFalse().validate(true);
      expect((result as ValidationFailure).code, ValidationCode.boolFalse);
    });
  });
}
