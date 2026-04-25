import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  final past = DateTime(2000);
  final future = DateTime(2099);
  final now = DateTime.now();
  final base = DateTime(2024, 6, 15, 12, 0, 0, 0);

  // ---------------------------------------------------------------------------
  // isBefore()
  // ---------------------------------------------------------------------------
  group('isBefore()', () {
    test('passes when value is before target', () {
      expect(
        ValidateDateTime().isBefore(future).validate(now),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when value is equal to target (not strictly before)', () {
      expect(
        ValidateDateTime().isBefore(base).validate(base),
        isA<ValidationFailure>(),
      );
    });

    test('fails when value is after target', () {
      final result = ValidateDateTime().setLabel('Date').isBefore(past).validate(now);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.dateBefore);
    });

    test('passes for 1ms before target', () {
      final oneMsBefore = base.subtract(const Duration(milliseconds: 1));
      expect(
        ValidateDateTime().isBefore(base).validate(oneMsBefore),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for 1ms after target', () {
      final oneMsAfter = base.add(const Duration(milliseconds: 1));
      expect(
        ValidateDateTime().isBefore(base).validate(oneMsAfter),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateDateTime().isBefore(future).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('UTC vs local: local time != UTC time causes failure', () {
      final local = DateTime(2024, 6, 15, 12, 0, 0);
      final utc = local.toUtc();
      expect(
        ValidateDateTime().isBefore(utc).validate(local),
        isA<ValidationFailure>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateDateTime()
              .setLabel('Date')
              .isBefore(
                past,
                messageFactory: (label, _) => '$label 이전 날짜여야 함',
              )
              .validate(now)
          as ValidationFailure;
      expect(result.message, 'Date 이전 날짜여야 함');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.dateBefore: (p) => '${p['name']} 날짜 오류',
        }),
      );
      final result = ValidateDateTime().setLabel('날짜').isBefore(past).validate(now)
          as ValidationFailure;
      expect(result.message, '날짜 날짜 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // isAfter()
  // ---------------------------------------------------------------------------
  group('isAfter()', () {
    test('passes when value is after target', () {
      expect(
        ValidateDateTime().isAfter(past).validate(now),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when value is equal to target (not strictly after)', () {
      expect(
        ValidateDateTime().isAfter(base).validate(base),
        isA<ValidationFailure>(),
      );
    });

    test('fails when value is before target', () {
      final result = ValidateDateTime().setLabel('Date').isAfter(future).validate(now);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.dateAfter);
    });

    test('passes for 1ms after target', () {
      final oneMsAfter = base.add(const Duration(milliseconds: 1));
      expect(
        ValidateDateTime().isAfter(base).validate(oneMsAfter),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for 1ms before target', () {
      final oneMsBefore = base.subtract(const Duration(milliseconds: 1));
      expect(
        ValidateDateTime().isAfter(base).validate(oneMsBefore),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateDateTime().isAfter(past).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateDateTime()
              .setLabel('Date')
              .isAfter(
                future,
                messageFactory: (label, _) => '$label 이후 날짜여야 함',
              )
              .validate(now)
          as ValidationFailure;
      expect(result.message, 'Date 이후 날짜여야 함');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.dateAfter: (p) => '${p['name']} 이후 오류',
        }),
      );
      final result =
          ValidateDateTime().setLabel('날짜').isAfter(future).validate(now)
              as ValidationFailure;
      expect(result.message, '날짜 이후 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // min()
  // ---------------------------------------------------------------------------
  group('min()', () {
    test('passes when value is after min (on or after)', () {
      expect(
        ValidateDateTime().min(past).validate(now),
        isA<ValidationSuccess>(),
      );
    });

    test('passes when value == min (boundary: exact match allowed)', () {
      expect(
        ValidateDateTime().min(base).validate(base),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when value is before min', () {
      final result = ValidateDateTime().setLabel('Date').min(future).validate(now);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.dateMin);
    });

    test('fails for 1ms before min', () {
      final oneMsBefore = base.subtract(const Duration(milliseconds: 1));
      expect(
        ValidateDateTime().min(base).validate(oneMsBefore),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateDateTime().min(future).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateDateTime()
              .setLabel('Date')
              .min(future, messageFactory: (label, _) => '$label 최소 날짜 오류')
              .validate(now)
          as ValidationFailure;
      expect(result.message, 'Date 최소 날짜 오류');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.dateMin: (p) => '${p['name']} 날짜 하한 오류',
        }),
      );
      final result =
          ValidateDateTime().setLabel('날짜').min(future).validate(now)
              as ValidationFailure;
      expect(result.message, '날짜 날짜 하한 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // max()
  // ---------------------------------------------------------------------------
  group('max()', () {
    test('passes when value is before max (on or before)', () {
      expect(
        ValidateDateTime().max(future).validate(now),
        isA<ValidationSuccess>(),
      );
    });

    test('passes when value == max (boundary: exact match allowed)', () {
      expect(
        ValidateDateTime().max(base).validate(base),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when value is after max', () {
      final result = ValidateDateTime().setLabel('Date').max(past).validate(now);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.dateMax);
    });

    test('fails for 1ms after max', () {
      final oneMsAfter = base.add(const Duration(milliseconds: 1));
      expect(
        ValidateDateTime().max(base).validate(oneMsAfter),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateDateTime().max(past).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateDateTime()
              .setLabel('Date')
              .max(past, messageFactory: (label, _) => '$label 최대 날짜 오류')
              .validate(now)
          as ValidationFailure;
      expect(result.message, 'Date 최대 날짜 오류');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.dateMax: (p) => '${p['name']} 날짜 상한 오류',
        }),
      );
      final result =
          ValidateDateTime().setLabel('날짜').max(past).validate(now)
              as ValidationFailure;
      expect(result.message, '날짜 날짜 상한 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // between()
  // ---------------------------------------------------------------------------
  group('between()', () {
    final rangeStart = DateTime(2020);
    final rangeEnd = DateTime(2025);
    final inRange = DateTime(2022);
    final beforeRange = DateTime(2019);
    final afterRange = DateTime(2026);

    test('passes when value is within range', () {
      expect(
        ValidateDateTime().between(rangeStart, rangeEnd).validate(inRange),
        isA<ValidationSuccess>(),
      );
    });

    test('passes when value == rangeStart (inclusive lower boundary)', () {
      expect(
        ValidateDateTime().between(rangeStart, rangeEnd).validate(rangeStart),
        isA<ValidationSuccess>(),
      );
    });

    test('passes when value == rangeEnd (inclusive upper boundary)', () {
      expect(
        ValidateDateTime().between(rangeStart, rangeEnd).validate(rangeEnd),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when value is before range', () {
      final result = ValidateDateTime()
          .setLabel('Date')
          .between(rangeStart, rangeEnd)
          .validate(beforeRange);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.dateBetween);
    });

    test('fails when value is after range', () {
      expect(
        ValidateDateTime().between(rangeStart, rangeEnd).validate(afterRange),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateDateTime().between(rangeStart, rangeEnd).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateDateTime()
              .setLabel('Date')
              .between(
                rangeStart,
                rangeEnd,
                messageFactory: (label, _) => '$label 날짜 범위 오류',
              )
              .validate(beforeRange)
          as ValidationFailure;
      expect(result.message, 'Date 날짜 범위 오류');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.dateBetween: (p) => '${p['name']} 범위 오류',
        }),
      );
      final result = ValidateDateTime()
          .setLabel('날짜')
          .between(rangeStart, rangeEnd)
          .validate(beforeRange) as ValidationFailure;
      expect(result.message, '날짜 범위 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // isInFuture()
  // ---------------------------------------------------------------------------
  group('isInFuture()', () {
    test('passes for a date far in the future', () {
      expect(
        ValidateDateTime().isInFuture().validate(future),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for a date 1 year from now', () {
      final oneYear = DateTime.now().add(const Duration(days: 365));
      expect(
        ValidateDateTime().isInFuture().validate(oneYear),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for a date in the past', () {
      final result = ValidateDateTime().setLabel('Date').isInFuture().validate(past);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.dateInFuture);
    });

    test('fails for a date 1 day ago', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(
        ValidateDateTime().isInFuture().validate(yesterday),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateDateTime().isInFuture().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateDateTime()
              .setLabel('Date')
              .isInFuture(messageFactory: (label, _) => '$label 미래여야 함')
              .validate(past)
          as ValidationFailure;
      expect(result.message, 'Date 미래여야 함');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.dateInFuture: (p) => '${p['name']} 미래 날짜 오류',
        }),
      );
      final result =
          ValidateDateTime().setLabel('날짜').isInFuture().validate(past)
              as ValidationFailure;
      expect(result.message, '날짜 미래 날짜 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // isInPast()
  // ---------------------------------------------------------------------------
  group('isInPast()', () {
    test('passes for a date in the past', () {
      expect(
        ValidateDateTime().isInPast().validate(past),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for a date 1 day ago', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(
        ValidateDateTime().isInPast().validate(yesterday),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for a date far in the future', () {
      final result = ValidateDateTime().setLabel('Date').isInPast().validate(future);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.dateInPast);
    });

    test('fails for a date 1 year from now', () {
      final oneYear = DateTime.now().add(const Duration(days: 365));
      expect(
        ValidateDateTime().isInPast().validate(oneYear),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateDateTime().isInPast().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateDateTime()
              .setLabel('Date')
              .isInPast(messageFactory: (label, _) => '$label 과거여야 함')
              .validate(future)
          as ValidationFailure;
      expect(result.message, 'Date 과거여야 함');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.dateInPast: (p) => '${p['name']} 과거 날짜 오류',
        }),
      );
      final result =
          ValidateDateTime().setLabel('날짜').isInPast().validate(future)
              as ValidationFailure;
      expect(result.message, '날짜 과거 날짜 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — date of birth
  // ---------------------------------------------------------------------------
  group('real user input — date of birth', () {
    final today = DateTime.now();
    final birthdayValidator = ValidateDateTime()
        .setLabel('생년월일')
        .min(DateTime(1900))
        .isInPast();

    test('born in 1990 — passes', () {
      expect(
        birthdayValidator.validate(DateTime(1990, 5, 15)),
        isA<ValidationSuccess>(),
      );
    });

    test('future date as birthday — fails (not yet born)', () {
      final future = today.add(const Duration(days: 365));
      expect(birthdayValidator.validate(future), isA<ValidationFailure>());
    });

    test('tomorrow as birthday — fails', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(birthdayValidator.validate(tomorrow), isA<ValidationFailure>());
    });

    test('born in 1899 — fails (below min(1900))', () {
      expect(
        birthdayValidator.validate(DateTime(1899, 12, 31)),
        isA<ValidationFailure>(),
      );
    });

    test('1900-01-01 — passes (exactly at min boundary)', () {
      expect(
        birthdayValidator.validate(DateTime(1900)),
        isA<ValidationSuccess>(),
      );
    });

    test('null — passes (optional field)', () {
      expect(birthdayValidator.validate(null), isA<ValidationSuccess>());
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — adult age verification (19+)
  // ---------------------------------------------------------------------------
  group('real user input — adult age verification', () {
    final adultCutoff = DateTime(
      DateTime.now().year - 19,
      DateTime.now().month,
      DateTime.now().day,
    );

    final adultValidator = ValidateDateTime()
        .setLabel('생년월일')
        .max(adultCutoff);

    test('born 20 years ago — passes', () {
      final born20 = DateTime(DateTime.now().year - 20, 1, 1);
      expect(adultValidator.validate(born20), isA<ValidationSuccess>());
    });

    test('born 18 years ago — fails', () {
      final born18 = DateTime(DateTime.now().year - 18, 1, 1);
      expect(adultValidator.validate(born18), isA<ValidationFailure>());
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — reservation date
  // ---------------------------------------------------------------------------
  group('real user input — reservation date', () {
    final reservationValidator = ValidateDateTime()
        .setLabel('예약 날짜')
        .isInFuture()
        .max(DateTime.now().add(const Duration(days: 365)));

    test('tomorrow — passes', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      expect(reservationValidator.validate(tomorrow), isA<ValidationSuccess>());
    });

    test('next week — passes', () {
      final nextWeek = DateTime.now().add(const Duration(days: 7));
      expect(reservationValidator.validate(nextWeek), isA<ValidationSuccess>());
    });

    test('yesterday — fails', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(reservationValidator.validate(yesterday), isA<ValidationFailure>());
    });

    test('400 days ahead — fails (beyond 1-year max)', () {
      final tooFar = DateTime.now().add(const Duration(days: 400));
      expect(reservationValidator.validate(tooFar), isA<ValidationFailure>());
    });

    test('null — passes (date not yet selected)', () {
      expect(reservationValidator.validate(null), isA<ValidationSuccess>());
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — event period (start ~ end)
  // ---------------------------------------------------------------------------
  group('real user input — event period validity', () {
    test('end date after start date — passes', () {
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 12, 31);
      final endValidator = ValidateDateTime().setLabel('종료일').isAfter(start);
      expect(endValidator.validate(end), isA<ValidationSuccess>());
    });

    test('end date same as start date — fails (strictly after)', () {
      final start = DateTime(2025, 6, 1);
      final endValidator = ValidateDateTime().setLabel('종료일').isAfter(start);
      expect(endValidator.validate(start), isA<ValidationFailure>());
    });

    test('end date before start date — fails', () {
      final start = DateTime(2025, 6, 1);
      final beforeStart = DateTime(2025, 5, 31);
      final endValidator = ValidateDateTime().setLabel('종료일').isAfter(start);
      expect(endValidator.validate(beforeStart), isA<ValidationFailure>());
    });
  });

  // ---------------------------------------------------------------------------
  // Chaining / interaction
  // ---------------------------------------------------------------------------
  group('chaining validators', () {
    test('required + isInFuture: null fails at required', () {
      final v = ValidateDateTime().setLabel('Date').required().isInFuture();
      final result = v.validate(null) as ValidationFailure;
      expect(result.code, ValidationCode.required);
    });

    test('isBefore + isAfter: value passes both when within window', () {
      final windowStart = DateTime(2023);
      final windowEnd = DateTime(2025);
      final inWindow = DateTime(2024);
      expect(
        ValidateDateTime()
            .isAfter(windowStart)
            .isBefore(windowEnd)
            .validate(inWindow),
        isA<ValidationSuccess>(),
      );
    });

    test('min + max acts like between for dates on boundary', () {
      expect(
        ValidateDateTime().min(base).max(future).validate(base),
        isA<ValidationSuccess>(),
      );
    });

    test('isInPast + required: past date passes', () {
      expect(
        ValidateDateTime().required().isInPast().validate(past),
        isA<ValidationSuccess>(),
      );
    });
  });

  group('isWeekday()', () {
    test('passes Monday', () {
      final monday = DateTime(2025, 1, 6);
      expect(ValidateDateTime().isWeekday().validate(monday), isA<ValidationSuccess>());
    });
    test('fails Saturday', () {
      final saturday = DateTime(2025, 1, 4);
      final r = ValidateDateTime().isWeekday().validate(saturday);
      expect(r, isA<ValidationFailure>());
      expect((r as ValidationFailure).code, ValidationCode.isWeekday);
    });
    test('null passes', () {
      expect(ValidateDateTime().isWeekday().validate(null), isA<ValidationSuccess>());
    });
  });

  group('isWeekend()', () {
    test('passes Saturday', () {
      final saturday = DateTime(2025, 1, 4);
      expect(ValidateDateTime().isWeekend().validate(saturday), isA<ValidationSuccess>());
    });
    test('fails Monday', () {
      final monday = DateTime(2025, 1, 6);
      expect(ValidateDateTime().isWeekend().validate(monday), isA<ValidationFailure>());
    });
  });

  group('isSameDay()', () {
    test('passes same calendar day', () {
      final d = DateTime(2025, 3, 15, 10, 0);
      final target = DateTime(2025, 3, 15, 22, 0);
      expect(ValidateDateTime().isSameDay(target).validate(d), isA<ValidationSuccess>());
    });
    test('fails different day', () {
      final d = DateTime(2025, 3, 14);
      final target = DateTime(2025, 3, 15);
      final r = ValidateDateTime().isSameDay(target).validate(d);
      expect(r, isA<ValidationFailure>());
      expect((r as ValidationFailure).code, ValidationCode.isSameDay);
    });
    test('null passes', () {
      expect(ValidateDateTime().isSameDay(DateTime.now()).validate(null), isA<ValidationSuccess>());
    });
  });

  group('isToday()', () {
    test('passes for today', () {
      final now = DateTime.now();
      expect(ValidateDateTime().isToday().validate(now), isA<ValidationSuccess>());
    });
    test('fails for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final r = ValidateDateTime().isToday().validate(yesterday);
      expect(r, isA<ValidationFailure>());
      expect((r as ValidationFailure).code, ValidationCode.isToday);
    });
  });

  group('isWithin()', () {
    test('passes when within duration', () {
      final now = DateTime.now();
      final recent = now.subtract(const Duration(hours: 1));
      expect(
        ValidateDateTime().isWithin(const Duration(hours: 2)).validate(recent),
        isA<ValidationSuccess>(),
      );
    });
    test('fails when outside duration', () {
      final now = DateTime.now();
      final old = now.subtract(const Duration(days: 10));
      final r = ValidateDateTime().isWithin(const Duration(days: 7)).validate(old);
      expect(r, isA<ValidationFailure>());
      expect((r as ValidationFailure).code, ValidationCode.isWithin);
    });
    test('custom from parameter', () {
      final anchor = DateTime(2025, 1, 1);
      final target = DateTime(2025, 1, 3);
      expect(
        ValidateDateTime()
          .isWithin(const Duration(days: 7), from: anchor)
          .validate(target),
        isA<ValidationSuccess>(),
      );
    });
    test('null passes', () {
      expect(
        ValidateDateTime().isWithin(const Duration(days: 1)).validate(null),
        isA<ValidationSuccess>(),
      );
    });
  });
}
