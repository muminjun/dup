import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  group('ValidateBool.isTrue', () {
    test('passes when value is true', () {
      expect(ValidateBool().setLabel('Flag').isTrue().validate(true), isNull);
    });
    test('fails when value is false', () {
      expect(ValidateBool().setLabel('Flag').isTrue().validate(false), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateBool().setLabel('Flag').isTrue().validate(null), isNull);
    });
  });

  group('ValidateBool.isFalse', () {
    test('passes when value is false', () {
      expect(ValidateBool().setLabel('Flag').isFalse().validate(false), isNull);
    });
    test('fails when value is true', () {
      expect(ValidateBool().setLabel('Flag').isFalse().validate(true), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateBool().setLabel('Flag').isFalse().validate(null), isNull);
    });
  });

  group('ValidateBool — phase ordering', () {
    test('required fires before isTrue regardless of chain order', () {
      final v = ValidateBool().setLabel('Agreed').isTrue().required();
      expect(v.validate(null), equals('Agreed is required.'));
    });
  });
}
