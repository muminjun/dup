import 'package:dup/dup.dart';
import 'package:test/test.dart';

ValidationFailure expectFailure(ValidationResult result) {
  expect(result, isA<ValidationFailure>());
  return result as ValidationFailure;
}

void expectSuccess(ValidationResult result) {
  expect(result, isA<ValidationSuccess>());
}

Future<ValidationFailure> expectAsyncFailure(
  Future<ValidationResult> result,
) async {
  final resolved = await result;
  expect(resolved, isA<ValidationFailure>());
  return resolved as ValidationFailure;
}

Future<void> expectAsyncSuccess(Future<ValidationResult> result) async {
  expect(await result, isA<ValidationSuccess>());
}

void main() {
  group('ValidateString edge cases', () {
    test('required does not treat whitespace-only string as blank', () {
      expectFailure(ValidateString().setLabel('X').required().validate(''));
      expectSuccess(ValidateString().setLabel('X').required().validate('   '));
    });

    test('notBlank catches whitespace-only input and skips null', () {
      expectFailure(ValidateString().setLabel('X').notBlank().validate('   '));
      expectFailure(ValidateString().setLabel('X').notBlank().validate('\t\n'));
      expectSuccess(ValidateString().setLabel('X').notBlank().validate(null));
    });

    test('required + notBlank catches null, empty, and whitespace', () {
      final validator = ValidateString().setLabel('X').required().notBlank();
      expectFailure(validator.validate(null));
      expectFailure(validator.validate(''));
      expectFailure(validator.validate('   '));
      expectSuccess(validator.validate('hi'));
    });

    test('notBlank message wins before later phase validators', () {
      final failure = expectFailure(
        ValidateString().setLabel('X').email().notBlank().validate('   '),
      );
      expect(failure.message, contains('blank'));
    });

    test('min/max use trimmed length', () {
      expectFailure(ValidateString().setLabel('X').min(3).validate('  ab  '));
      expectSuccess(ValidateString().setLabel('X').max(3).validate('  hi  '));
      expectSuccess(ValidateString().setLabel('X').min(5).validate('hello'));
      expectSuccess(ValidateString().setLabel('X').max(5).validate('hello'));
    });

    test('email handles common valid and invalid patterns', () {
      expectSuccess(
        ValidateString().setLabel('E').email().validate('user+tag@example.com'),
      );
      expectSuccess(
        ValidateString().setLabel('E').email().validate(' user@example.com '),
      );
      expectSuccess(ValidateString().setLabel('E').email().validate(''));
      expectFailure(
        ValidateString().setLabel('E').email().validate('user@@example.com'),
      );
      expectFailure(
        ValidateString().setLabel('E').email().validate('user@example'),
      );
    });

    test('password skips blank but enforces minimum when present', () {
      expectSuccess(
        ValidateString().setLabel('PW').password().validate('    '),
      );
      expectSuccess(
        ValidateString()
            .setLabel('PW')
            .password(minLength: 8)
            .validate('12345678'),
      );
      expectFailure(
        ValidateString()
            .setLabel('PW')
            .password(minLength: 8)
            .validate('1234567'),
      );
    });

    test('emoji validator only rejects actual emoji', () {
      expectSuccess(ValidateString().setLabel('X').emoji().validate('abc123'));
      expectSuccess(
        ValidateString().setLabel('X').emoji().validate('hello#world'),
      );
      expectFailure(ValidateString().setLabel('X').emoji().validate('hello😀'));
      expectFailure(ValidateString().setLabel('X').emoji().validate('🎉'));
    });

    test('alpha, alphanumeric, and numeric preserve null-skip behavior', () {
      expectSuccess(
        ValidateString().setLabel('X').alpha().validate('HelloWorld'),
      );
      expectFailure(ValidateString().setLabel('X').alpha().validate('Hello1'));
      expectSuccess(ValidateString().setLabel('X').alpha().validate(null));

      expectSuccess(
        ValidateString().setLabel('X').alphanumeric().validate('Hello123'),
      );
      expectFailure(
        ValidateString().setLabel('X').alphanumeric().validate('Hello_123'),
      );
      expectSuccess(ValidateString().setLabel('X').alphanumeric().validate(''));

      expectSuccess(ValidateString().setLabel('X').numeric().validate('12345'));
      expectFailure(ValidateString().setLabel('X').numeric().validate('12.5'));
      expectSuccess(ValidateString().setLabel('X').numeric().validate(null));
    });

    test('mobile, url, and uuid enforce stricter formats', () {
      expectSuccess(
        ValidateString().setLabel('P').koMobile().validate('010-1234-5678'),
      );
      expectFailure(
        ValidateString().setLabel('P').koMobile().validate('01012345678'),
      );

      expectSuccess(
        ValidateString()
            .setLabel('U')
            .url()
            .validate('https://example.com:8080'),
      );
      expectFailure(
        ValidateString().setLabel('U').url().validate('ftp://example.com'),
      );

      expectSuccess(
        ValidateString()
            .setLabel('ID')
            .uuid()
            .validate('550e8400-e29b-41d4-a716-446655440000'),
      );
      expectFailure(
        ValidateString()
            .setLabel('ID')
            .uuid()
            .validate('550e8400-e29b-11d4-a716-446655440000'),
      );
      expectSuccess(ValidateString().setLabel('ID').uuid().validate(''));
    });
  });

  group('ValidateNumber edge cases', () {
    test('min/max and integer boundaries', () {
      expectFailure(ValidateNumber().setLabel('N').min(5).validate(4.99));
      expectSuccess(ValidateNumber().setLabel('N').min(5).validate(5.01));
      expectFailure(ValidateNumber().setLabel('N').max(10).validate(10.01));
      expectSuccess(ValidateNumber().setLabel('N').isInteger().validate(1.0));
      expectFailure(ValidateNumber().setLabel('N').isInteger().validate(1.5));
    });

    test('positive/negative and between rules respect boundaries', () {
      expectFailure(ValidateNumber().setLabel('N').isPositive().validate(0));
      expectSuccess(
        ValidateNumber().setLabel('N').isPositive().validate(0.001),
      );
      expectFailure(ValidateNumber().setLabel('N').isNegative().validate(0));
      expectSuccess(
        ValidateNumber().setLabel('N').isNegative().validate(-0.001),
      );

      expectSuccess(ValidateNumber().setLabel('N').between(1, 10).validate(1));
      expectSuccess(ValidateNumber().setLabel('N').between(1, 10).validate(10));
      expectFailure(ValidateNumber().setLabel('N').between(1, 10).validate(11));
      expectSuccess(
        ValidateNumber().setLabel('N').between(1, 10).validate(null),
      );
    });

    test('even/odd and multipleOf skip null', () {
      expectSuccess(ValidateNumber().setLabel('N').isEven().validate(4));
      expectFailure(ValidateNumber().setLabel('N').isEven().validate(3));
      expectFailure(ValidateNumber().setLabel('N').isOdd().validate(0));
      expectSuccess(
        ValidateNumber().setLabel('N').isMultipleOf(5).validate(-10),
      );
      expectSuccess(
        ValidateNumber().setLabel('N').isMultipleOf(5).validate(null),
      );
    });
  });

  group('ValidateDateTime edge cases', () {
    test('millisecond precision and UTC/local comparisons', () {
      final base = DateTime(2024, 6, 15, 12, 0, 0, 0);
      final oneMsBefore = base.subtract(const Duration(milliseconds: 1));
      final oneMsAfter = base.add(const Duration(milliseconds: 1));
      expectSuccess(
        ValidateDateTime().setLabel('D').isBefore(base).validate(oneMsBefore),
      );
      expectSuccess(
        ValidateDateTime().setLabel('D').isAfter(base).validate(oneMsAfter),
      );

      final local = DateTime(2024, 6, 15, 12, 0, 0);
      final utc = local.toUtc();
      expectFailure(
        ValidateDateTime().setLabel('D').isBefore(utc).validate(local),
      );
    });

    test('future/past validators skip null and enforce direction', () {
      final future = DateTime.now().add(const Duration(days: 365));
      final past = DateTime.now().subtract(const Duration(days: 1));
      expectSuccess(
        ValidateDateTime().setLabel('D').isInFuture().validate(future),
      );
      expectFailure(
        ValidateDateTime().setLabel('D').isInFuture().validate(past),
      );
      expectSuccess(ValidateDateTime().setLabel('D').isInPast().validate(past));
      expectFailure(
        ValidateDateTime().setLabel('D').isInPast().validate(future),
      );
      expectSuccess(
        ValidateDateTime().setLabel('D').isInFuture().validate(null),
      );
      expectSuccess(ValidateDateTime().setLabel('D').isInPast().validate(null));
    });
  });

  group('ValidateList edge cases', () {
    test('length-based rules keep null-skip semantics', () {
      expectSuccess(
        ValidateList<int>().setLabel('L').lengthBetween(1, 3).validate(null),
      );
      expectFailure(
        ValidateList<int>().setLabel('L').lengthBetween(2, 4).validate([1]),
      );
      expectFailure(
        ValidateList<int>().setLabel('L').lengthBetween(2, 4).validate([
          1,
          2,
          3,
          4,
          5,
        ]),
      );
    });

    test('all/any/none semantics match iterable behavior', () {
      expectSuccess(
        ValidateList<int>().setLabel('L').all((x) => x > 0).validate([]),
      );
      expectSuccess(
        ValidateList<int>().setLabel('L').all((x) => x > 0).validate(null),
      );
      expectFailure(
        ValidateList<int>().setLabel('L').any((x) => x > 0).validate([]),
      );
      expectSuccess(
        ValidateList<int>().setLabel('L').none((x) => x < 0).validate([]),
      );
      expectFailure(
        ValidateList<int>().setLabel('L').none((x) => x < 0).validate([
          1,
          -1,
          3,
        ]),
      );
    });

    test('duplicate and eachItem checks return structured failures', () {
      expectSuccess(
        ValidateList<String>().setLabel('L').hasNoDuplicates().validate([
          'a',
          'b',
          'c',
        ]),
      );
      expectFailure(
        ValidateList<String>().setLabel('L').hasNoDuplicates().validate([
          'a',
          'b',
          'a',
        ]),
      );

      final validator = ValidateList<String>().setLabel('L').eachItem((s) {
        return s.isEmpty
            ? const ValidationFailure(
              code: ValidationCode.custom,
              message: 'empty',
            )
            : null;
      });
      expectSuccess(validator.validate([]));
      final failure = expectFailure(validator.validate(['ok', 'ok', '']));
      expect(failure.message, contains('index 2'));
    });

    test('contains now skips null; doesNotContain still skips null', () {
      expectSuccess(
        ValidateList<int>().setLabel('L').contains(5).validate(null),
      );
      expectSuccess(
        ValidateList<int>().setLabel('L').doesNotContain(5).validate(null),
      );
    });
  });

  group('BaseValidator shared edge cases', () {
    test('equalTo, includedIn, excludedFrom, satisfy preserve null-skip', () {
      expectSuccess(
        ValidateString().setLabel('X').equalTo('target').validate(null),
      );
      expectFailure(
        ValidateString().setLabel('X').equalTo('target').validate('other'),
      );
      expectSuccess(
        ValidateString().setLabel('X').includedIn(['a', 'b']).validate('a'),
      );
      expectFailure(
        ValidateString().setLabel('X').includedIn([]).validate('any'),
      );
      expectSuccess(
        ValidateString().setLabel('X').excludedFrom(['bad']).validate(null),
      );
      expectSuccess(
        ValidateNumber().setLabel('N').satisfy((v) => v! > 0).validate(null),
      );
      expectFailure(
        ValidateNumber().setLabel('N').satisfy((v) => v! > 0).validate(-5),
      );
    });

    test('first-failure semantics are preserved', () {
      final validator = ValidateString()
          .setLabel('Email')
          .required()
          .email()
          .min(20);
      expect(
        expectFailure(validator.validate(null)).message,
        contains('required'),
      );
      expect(
        expectFailure(validator.validate('bad')).message,
        contains('not a valid email'),
      );
    });

    test(
      'custom sync and async validators now return ValidationFailure',
      () async {
        final syncValidator = ValidateString()
            .setLabel('X')
            .min(3)
            .addValidator(
              (s) =>
                  s == 'reserved'
                      ? const ValidationFailure(
                        code: ValidationCode.custom,
                        message: 'That value is reserved.',
                      )
                      : null,
            );
        expectFailure(syncValidator.validate('ok'));
        expect(
          expectFailure(syncValidator.validate('reserved')).message,
          'That value is reserved.',
        );
        expectSuccess(syncValidator.validate('hello'));

        final asyncValidator = ValidateString()
            .setLabel('X')
            .required()
            .addAsyncValidator((s) async {
              await Future<void>.delayed(Duration.zero);
              return s == 'taken'
                  ? const ValidationFailure(
                    code: ValidationCode.custom,
                    message: 'Username is already taken.',
                  )
                  : null;
            });
        await expectAsyncFailure(asyncValidator.validateAsync(null));
        expect(
          (await expectAsyncFailure(
            asyncValidator.validateAsync('taken'),
          )).message,
          'Username is already taken.',
        );
        await expectAsyncSuccess(asyncValidator.validateAsync('available'));
      },
    );
  });
}
