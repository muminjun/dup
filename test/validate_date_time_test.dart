import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  final base = DateTime(2024, 6, 15);
  final before = DateTime(2024, 6, 10);
  final after = DateTime(2024, 6, 20);

  group('ValidateDateTime.isBefore', () {
    test('passes when value is before target', () {
      expect(ValidateDateTime().setLabel('D').isBefore(base).validate(before), isNull);
    });
    test('fails when value equals target', () {
      expect(ValidateDateTime().setLabel('D').isBefore(base).validate(base), isNotNull);
    });
    test('fails when value is after target', () {
      expect(ValidateDateTime().setLabel('D').isBefore(base).validate(after), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateDateTime().setLabel('D').isBefore(base).validate(null), isNull);
    });
  });

  group('ValidateDateTime.isAfter', () {
    test('passes when value is after target', () {
      expect(ValidateDateTime().setLabel('D').isAfter(base).validate(after), isNull);
    });
    test('fails when value equals target', () {
      expect(ValidateDateTime().setLabel('D').isAfter(base).validate(base), isNotNull);
    });
    test('fails when value is before target', () {
      expect(ValidateDateTime().setLabel('D').isAfter(base).validate(before), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateDateTime().setLabel('D').isAfter(base).validate(null), isNull);
    });
  });

  group('ValidateDateTime.min', () {
    test('passes when value is on the min boundary', () {
      expect(ValidateDateTime().setLabel('D').min(base).validate(base), isNull);
    });
    test('passes when value is after min', () {
      expect(ValidateDateTime().setLabel('D').min(base).validate(after), isNull);
    });
    test('fails when value is before min', () {
      expect(ValidateDateTime().setLabel('D').min(base).validate(before), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateDateTime().setLabel('D').min(base).validate(null), isNull);
    });
  });

  group('ValidateDateTime.max', () {
    test('passes when value is on the max boundary', () {
      expect(ValidateDateTime().setLabel('D').max(base).validate(base), isNull);
    });
    test('passes when value is before max', () {
      expect(ValidateDateTime().setLabel('D').max(base).validate(before), isNull);
    });
    test('fails when value is after max', () {
      expect(ValidateDateTime().setLabel('D').max(base).validate(after), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateDateTime().setLabel('D').max(base).validate(null), isNull);
    });
  });

  group('ValidateDateTime.between', () {
    test('passes when value is within range', () {
      expect(ValidateDateTime().setLabel('D').between(before, after).validate(base), isNull);
    });
    test('passes on lower boundary', () {
      expect(ValidateDateTime().setLabel('D').between(before, after).validate(before), isNull);
    });
    test('passes on upper boundary', () {
      expect(ValidateDateTime().setLabel('D').between(before, after).validate(after), isNull);
    });
    test('fails when value is outside range', () {
      final wayBefore = DateTime(2024, 1, 1);
      expect(ValidateDateTime().setLabel('D').between(before, after).validate(wayBefore), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateDateTime().setLabel('D').between(before, after).validate(null), isNull);
    });
  });

  group('ValidateDateTime — phase ordering', () {
    test('required fires before isBefore regardless of chain order', () {
      final v = ValidateDateTime().setLabel('D').isBefore(base).required();
      expect(v.validate(null), equals('D is required.'));
    });

    test('isBefore (phase 1) fires before min (phase 2)', () {
      final v = ValidateDateTime().setLabel('D').min(before).isBefore(before);
      expect(v.validate(after), contains('before'));
    });
  });
}
