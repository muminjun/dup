import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  final past = DateTime(2000);
  final future = DateTime(2099);
  final now = DateTime.now();

  group('isBefore()', () {
    test('passes when value is before target', () {
      expect(ValidateDateTime().isBefore(future).validate(now),
          isA<ValidationSuccess>());
    });

    test('fails when value is after target', () {
      final result = ValidateDateTime().isBefore(past).validate(now);
      expect((result as ValidationFailure).code, ValidationCode.dateBefore);
    });

    test('passes for null', () {
      expect(ValidateDateTime().isBefore(future).validate(null),
          isA<ValidationSuccess>());
    });
  });

  group('isAfter()', () {
    test('fails when value is before target', () {
      final result = ValidateDateTime().isAfter(future).validate(now);
      expect((result as ValidationFailure).code, ValidationCode.dateAfter);
    });
  });

  group('min()', () {
    test('fails when value is before min', () {
      final result = ValidateDateTime().min(future).validate(now);
      expect((result as ValidationFailure).code, ValidationCode.dateMin);
    });
  });

  group('max()', () {
    test('fails when value is after max', () {
      final result = ValidateDateTime().max(past).validate(now);
      expect((result as ValidationFailure).code, ValidationCode.dateMax);
    });
  });

  group('isInFuture()', () {
    test('fails for past date', () {
      final result = ValidateDateTime().isInFuture().validate(past);
      expect((result as ValidationFailure).code, ValidationCode.dateInFuture);
    });
  });

  group('isInPast()', () {
    test('fails for future date', () {
      final result = ValidateDateTime().isInPast().validate(future);
      expect((result as ValidationFailure).code, ValidationCode.dateInPast);
    });
  });

  group('between()', () {
    test('fails outside range', () {
      final result = ValidateDateTime()
          .between(DateTime(2020), DateTime(2021))
          .validate(DateTime(2022));
      expect((result as ValidationFailure).code, ValidationCode.dateBetween);
    });
  });

  group('locale', () {
    test('uses locale message for dateBefore', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.dateBefore: (p) => '${p['name']} 날짜 오류',
      }));
      final result = ValidateDateTime()
          .setLabel('날짜')
          .isBefore(past)
          .validate(now) as ValidationFailure;
      expect(result.message, '날짜 날짜 오류');
    });
  });
}
