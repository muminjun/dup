import 'package:dup/dup.dart';
import 'package:test/test.dart';

class _StringValidator extends BaseValidator<String, _StringValidator> {}

class _NumValidator extends BaseValidator<num, _NumValidator> {}

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  // ---------------------------------------------------------------------------
  // validate() — basic sync flow
  // ---------------------------------------------------------------------------
  group('validate() returns ValidationResult', () {
    test('returns ValidationSuccess when no validators registered', () {
      expect(_StringValidator().validate('hello'), isA<ValidationSuccess>());
    });

    test('returns ValidationSuccess for null when no validators', () {
      expect(_StringValidator().validate(null), isA<ValidationSuccess>());
    });

    test('returns ValidationFailure when validator fails', () {
      final v =
          _StringValidator()..addPhaseValidator(
            1,
            (value) =>
                value == null
                    ? null
                    : const ValidationFailure(
                      code: ValidationCode.custom,
                      message: 'bad',
                    ),
          );
      final result = v.validate('x');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).message, 'bad');
    });

    test('returns ValidationSuccess when validator passes', () {
      final v = _StringValidator()..addPhaseValidator(1, (_) => null);
      expect(v.validate('x'), isA<ValidationSuccess>());
    });

    test('stops at first failure and does not run subsequent validators', () {
      var secondCalled = false;
      final v =
          _StringValidator()
            ..addPhaseValidator(
              1,
              (_) => const ValidationFailure(
                code: ValidationCode.custom,
                message: 'first',
              ),
            )
            ..addPhaseValidator(2, (_) {
              secondCalled = true;
              return null;
            });
      v.validate('x');
      expect(secondCalled, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // validateAsync()
  // ---------------------------------------------------------------------------
  group('validateAsync() returns Future<ValidationResult>', () {
    test('returns ValidationSuccess when no validators registered', () async {
      final result = await _StringValidator().validateAsync('hello');
      expect(result, isA<ValidationSuccess>());
    });

    test('returns ValidationSuccess for null when no validators', () async {
      final result = await _StringValidator().validateAsync(null);
      expect(result, isA<ValidationSuccess>());
    });

    test('async validator failure is returned', () async {
      final v =
          _StringValidator()..addAsyncValidator(
            (_) async => const ValidationFailure(
              code: ValidationCode.custom,
              message: 'async fail',
            ),
          );
      final result = await v.validateAsync('x');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).message, 'async fail');
    });

    test('async validator success returns ValidationSuccess', () async {
      final v = _StringValidator()..addAsyncValidator((_) async => null);
      final result = await v.validateAsync('x');
      expect(result, isA<ValidationSuccess>());
    });

    test('sync failure short-circuits async', () async {
      var asyncCalled = false;
      final v =
          _StringValidator()
            ..addPhaseValidator(
              1,
              (_) => const ValidationFailure(
                code: ValidationCode.custom,
                message: 'sync',
              ),
            )
            ..addAsyncValidator((_) async {
              asyncCalled = true;
              return null;
            });
      await v.validateAsync('x');
      expect(asyncCalled, isFalse);
    });

    test('async validators run in registration order', () async {
      final log = <int>[];
      final v =
          _StringValidator()
            ..addAsyncValidator((_) async {
              log.add(1);
              return null;
            })
            ..addAsyncValidator((_) async {
              log.add(2);
              return null;
            });
      await v.validateAsync('x');
      expect(log, [1, 2]);
    });

    test('passes null through to async validators', () async {
      String? received;
      final v =
          _StringValidator()..addAsyncValidator((value) async {
            received = value;
            return null;
          });
      await v.validateAsync(null);
      expect(received, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // hasAsyncValidators
  // ---------------------------------------------------------------------------
  group('hasAsyncValidators', () {
    test('false when no async validators', () {
      expect(_StringValidator().hasAsyncValidators, isFalse);
    });

    test('true when async validator added', () {
      final v = _StringValidator()..addAsyncValidator((_) async => null);
      expect(v.hasAsyncValidators, isTrue);
    });

    test('false even when sync validators are added', () {
      final v = _StringValidator()..addPhaseValidator(1, (_) => null);
      expect(v.hasAsyncValidators, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // toValidator()
  // ---------------------------------------------------------------------------
  group('toValidator()', () {
    test('returns null on success', () {
      expect(_StringValidator().toValidator()('hello'), isNull);
    });

    test('returns null for null when not required', () {
      expect(_StringValidator().toValidator()(null), isNull);
    });

    test('returns message string on failure', () {
      final v =
          _StringValidator()..addPhaseValidator(
            1,
            (_) => const ValidationFailure(
              code: ValidationCode.custom,
              message: 'err',
            ),
          );
      expect(v.toValidator()('x'), 'err');
    });

    test('returns required error for null when required', () {
      final v = _StringValidator().setLabel('Field').required();
      expect(v.toValidator()(null), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // toAsyncValidator()
  // ---------------------------------------------------------------------------
  group('toAsyncValidator()', () {
    test('returns null on success', () async {
      final fn = _StringValidator().toAsyncValidator();
      expect(await fn('hello'), isNull);
    });

    test('returns null for null when not required', () async {
      final fn = _StringValidator().toAsyncValidator();
      expect(await fn(null), isNull);
    });

    test('returns message string on sync failure', () async {
      final v = _StringValidator().setLabel('X').required();
      final fn = v.toAsyncValidator();
      expect(await fn(null), isNotNull);
    });

    test('returns message string on async failure', () async {
      final v =
          _StringValidator()..addAsyncValidator(
            (_) async => const ValidationFailure(
              code: ValidationCode.custom,
              message: 'async err',
            ),
          );
      final fn = v.toAsyncValidator();
      expect(await fn('x'), 'async err');
    });

    test('returns null on async success', () async {
      final v = _StringValidator()..addAsyncValidator((_) async => null);
      final fn = v.toAsyncValidator();
      expect(await fn('x'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // required()
  // ---------------------------------------------------------------------------
  group('required()', () {
    test('fails for null', () {
      final result = _StringValidator().required().validate(null);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.required);
    });

    test('fails for empty string', () {
      expect(
        _StringValidator().required().validate(''),
        isA<ValidationFailure>(),
      );
    });

    test('passes for non-empty string', () {
      expect(
        _StringValidator().required().validate('x'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for whitespace-only (not empty, not null)', () {
      expect(
        _StringValidator().required().validate('   '),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final v = _StringValidator()
          .setLabel('Email')
          .required(messageFactory: (label, _) => '$label 필수');
      final result = v.validate(null) as ValidationFailure;
      expect(result.message, 'Email 필수');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.required: (p) => '${p['name']} 필수'}),
      );
      final result =
          _StringValidator().setLabel('이메일').required().validate(null)
              as ValidationFailure;
      expect(result.message, '이메일 필수');
    });

    test('default message contains label', () {
      final result =
          _StringValidator().setLabel('Name').required().validate(null)
              as ValidationFailure;
      expect(result.message, contains('Name'));
    });
  });

  // ---------------------------------------------------------------------------
  // equalTo()
  // ---------------------------------------------------------------------------
  group('equalTo()', () {
    test('passes when value equals target', () {
      expect(
        _StringValidator().equalTo('hello').validate('hello'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when value does not equal target', () {
      final result = _StringValidator()
          .setLabel('PW')
          .equalTo('abc')
          .validate('xyz');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.equal);
    });

    test('passes for null (null-skip)', () {
      expect(
        _StringValidator().equalTo('target').validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('works for numeric equality', () {
      expect(_NumValidator().equalTo(5).validate(5), isA<ValidationSuccess>());
      expect(_NumValidator().equalTo(5).validate(6), isA<ValidationFailure>());
    });

    test('uses messageFactory', () {
      final result =
          _StringValidator()
                  .setLabel('Confirm')
                  .equalTo('abc', messageFactory: (label, _) => '$label 불일치')
                  .validate('xyz')
              as ValidationFailure;
      expect(result.message, 'Confirm 불일치');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.equal: (p) => '${p['name']} 동일해야 함'}),
      );
      final result =
          _StringValidator().setLabel('확인').equalTo('abc').validate('xyz')
              as ValidationFailure;
      expect(result.message, '확인 동일해야 함');
    });
  });

  // ---------------------------------------------------------------------------
  // notEqualTo()
  // ---------------------------------------------------------------------------
  group('notEqualTo()', () {
    test('passes when value does not equal target', () {
      expect(
        _StringValidator().notEqualTo('reserved').validate('hello'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when value equals target', () {
      final result = _StringValidator()
          .setLabel('Username')
          .notEqualTo('admin')
          .validate('admin');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.notEqual);
    });

    test('passes for null (null-skip)', () {
      expect(
        _StringValidator().notEqualTo('admin').validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('works for numeric inequality', () {
      expect(
        _NumValidator().notEqualTo(0).validate(1),
        isA<ValidationSuccess>(),
      );
      expect(
        _NumValidator().notEqualTo(0).validate(0),
        isA<ValidationFailure>(),
      );
    });

    test('uses messageFactory', () {
      final result =
          _StringValidator()
                  .setLabel('Username')
                  .notEqualTo(
                    'admin',
                    messageFactory: (label, _) => '$label 금지된 값',
                  )
                  .validate('admin')
              as ValidationFailure;
      expect(result.message, 'Username 금지된 값');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.notEqual: (p) => '${p['name']} 사용 불가'}),
      );
      final result =
          _StringValidator()
                  .setLabel('아이디')
                  .notEqualTo('admin')
                  .validate('admin')
              as ValidationFailure;
      expect(result.message, '아이디 사용 불가');
    });
  });

  // ---------------------------------------------------------------------------
  // includedIn()
  // ---------------------------------------------------------------------------
  group('includedIn()', () {
    test('passes when value is in allowed list', () {
      expect(
        _StringValidator().includedIn(['a', 'b', 'c']).validate('b'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when value is not in allowed list', () {
      final result = _StringValidator()
          .setLabel('Role')
          .includedIn(['admin', 'user'])
          .validate('guest');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.oneOf);
    });

    test('fails for empty allowed list', () {
      expect(
        _StringValidator().includedIn([]).validate('any'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        _StringValidator().includedIn(['a', 'b']).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('context contains options string', () {
      final result =
          _StringValidator().includedIn(['x', 'y']).validate('z')
              as ValidationFailure;
      expect(result.context['options'], contains('x'));
    });

    test('uses messageFactory', () {
      final result =
          _StringValidator()
                  .setLabel('Role')
                  .includedIn(
                    ['admin', 'user'],
                    messageFactory:
                        (label, p) => '$label 허용 값: ${p['options']}',
                  )
                  .validate('guest')
              as ValidationFailure;
      expect(result.message, contains('Role'));
      expect(result.message, contains('admin'));
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.oneOf: (p) => '${p['name']} 허용 목록 오류'}),
      );
      final result =
          _StringValidator().setLabel('역할').includedIn(['a']).validate('b')
              as ValidationFailure;
      expect(result.message, '역할 허용 목록 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // excludedFrom()
  // ---------------------------------------------------------------------------
  group('excludedFrom()', () {
    test('passes when value is not in forbidden list', () {
      expect(
        _StringValidator().excludedFrom(['bad', 'evil']).validate('good'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty forbidden list', () {
      expect(
        _StringValidator().excludedFrom([]).validate('anything'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when value is in forbidden list', () {
      final result = _StringValidator()
          .setLabel('Word')
          .excludedFrom(['spam'])
          .validate('spam');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.notOneOf);
    });

    test('passes for null (null-skip)', () {
      expect(
        _StringValidator().excludedFrom(['bad']).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result =
          _StringValidator()
                  .setLabel('Word')
                  .excludedFrom([
                    'spam',
                  ], messageFactory: (label, _) => '$label 금지어 포함')
                  .validate('spam')
              as ValidationFailure;
      expect(result.message, 'Word 금지어 포함');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.notOneOf: (p) => '${p['name']} 금지 목록 오류',
        }),
      );
      final result =
          _StringValidator()
                  .setLabel('단어')
                  .excludedFrom(['spam'])
                  .validate('spam')
              as ValidationFailure;
      expect(result.message, '단어 금지 목록 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // satisfy()
  // ---------------------------------------------------------------------------
  group('satisfy()', () {
    test('passes when condition returns true', () {
      expect(
        _NumValidator().satisfy((v) => v! > 0).validate(5),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when condition returns false', () {
      final result = _NumValidator()
          .setLabel('N')
          .satisfy((v) => v! > 0)
          .validate(-5);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.condition);
    });

    test('passes for null (null-skip)', () {
      expect(
        _NumValidator().satisfy((v) => v! > 0).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result =
          _NumValidator()
                  .setLabel('Score')
                  .satisfy(
                    (v) => v! >= 60,
                    messageFactory: (label, _) => '$label 60점 이상이어야 함',
                  )
                  .validate(50)
              as ValidationFailure;
      expect(result.message, 'Score 60점 이상이어야 함');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.condition: (p) => '${p['name']} 조건 불만족',
        }),
      );
      final result =
          _NumValidator().setLabel('점수').satisfy((v) => v! > 0).validate(-1)
              as ValidationFailure;
      expect(result.message, '점수 조건 불만족');
    });
  });

  // ---------------------------------------------------------------------------
  // addValidator()
  // ---------------------------------------------------------------------------
  group('addValidator()', () {
    test('custom ValidationFailure is returned on failure', () {
      final v = _StringValidator().addValidator((value) {
        if (value == 'bad') {
          return const ValidationFailure(
            code: ValidationCode.custom,
            message: 'not allowed',
          );
        }
        return null;
      });
      expect(v.validate('bad'), isA<ValidationFailure>());
      expect((v.validate('bad') as ValidationFailure).message, 'not allowed');
    });

    test('returns success when custom validator passes', () {
      final v = _StringValidator().addValidator((_) => null);
      expect(v.validate('ok'), isA<ValidationSuccess>());
    });

    test('runs at phase 3 (after phase 1 and 2)', () {
      final log = <int>[];
      final v =
          _StringValidator()
            ..addValidator((_) {
              log.add(3);
              return null;
            })
            ..addPhaseValidator(1, (_) {
              log.add(1);
              return null;
            })
            ..addPhaseValidator(2, (_) {
              log.add(2);
              return null;
            });
      v.validate('x');
      expect(log, [1, 2, 3]);
    });
  });

  // ---------------------------------------------------------------------------
  // Phase ordering
  // ---------------------------------------------------------------------------
  group('phase ordering', () {
    test('phase 0 runs before phase 1', () {
      final log = <int>[];
      final v =
          _StringValidator()
            ..addPhaseValidator(1, (_) {
              log.add(1);
              return null;
            })
            ..addPhaseValidator(0, (_) {
              log.add(0);
              return null;
            });
      v.validate('x');
      expect(log, [0, 1]);
    });

    test('all phases run in order 0, 1, 2, 3', () {
      final log = <int>[];
      final v =
          _StringValidator()
            ..addPhaseValidator(3, (_) {
              log.add(3);
              return null;
            })
            ..addPhaseValidator(1, (_) {
              log.add(1);
              return null;
            })
            ..addPhaseValidator(0, (_) {
              log.add(0);
              return null;
            })
            ..addPhaseValidator(2, (_) {
              log.add(2);
              return null;
            });
      v.validate('x');
      expect(log, [0, 1, 2, 3]);
    });

    test('registration order preserved within the same phase', () {
      final log = <String>[];
      final v =
          _StringValidator()
            ..addPhaseValidator(1, (_) {
              log.add('first');
              return null;
            })
            ..addPhaseValidator(1, (_) {
              log.add('second');
              return null;
            });
      v.validate('x');
      expect(log, ['first', 'second']);
    });

    test('phase 0 failure prevents phase 1 validators from running', () {
      var phase1Called = false;
      final v =
          _StringValidator()
            ..addPhaseValidator(
              0,
              (_) => const ValidationFailure(
                code: ValidationCode.required,
                message: 'required',
              ),
            )
            ..addPhaseValidator(1, (_) {
              phase1Called = true;
              return null;
            });
      v.validate(null);
      expect(phase1Called, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // setLabel()
  // ---------------------------------------------------------------------------
  group('setLabel()', () {
    test('label is used in default error messages', () {
      final result =
          _StringValidator().setLabel('Email').required().validate(null)
              as ValidationFailure;
      expect(result.message, contains('Email'));
    });

    test('label is accessible on the validator', () {
      final v = _StringValidator().setLabel('Username');
      expect(v.label, 'Username');
    });

    test('default label is empty string', () {
      expect(_StringValidator().label, '');
    });

    test('setLabel returns the same validator instance for chaining', () {
      final v = _StringValidator();
      final returned = v.setLabel('Test');
      expect(identical(v, returned), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // Error message context
  // ---------------------------------------------------------------------------
  group('error message context', () {
    test('required failure context contains name key', () {
      final result =
          _StringValidator().setLabel('Email').required().validate(null)
              as ValidationFailure;
      expect(result.context['name'], 'Email');
    });

    test('ValidationFailure code is preserved', () {
      final result =
          _StringValidator().required().validate(null) as ValidationFailure;
      expect(result.code, ValidationCode.required);
    });

    test('custom ValidationFailure context is preserved', () {
      final v = _StringValidator().addValidator(
        (_) => const ValidationFailure(
          code: ValidationCode.custom,
          message: 'msg',
          context: {'key': 'value'},
        ),
      );
      final result = v.validate('x') as ValidationFailure;
      expect(result.context['key'], 'value');
    });
  });

  // ---------------------------------------------------------------------------
  // Message priority (3-level)
  // ---------------------------------------------------------------------------
  group('message priority', () {
    test('messageFactory wins over locale and default', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.required: (_) => 'locale msg'}),
      );
      final result =
          _StringValidator()
                  .setLabel('X')
                  .required(messageFactory: (_, __) => 'factory msg')
                  .validate(null)
              as ValidationFailure;
      expect(result.message, 'factory msg');
    });

    test('locale wins over default when no messageFactory', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.required: (_) => 'locale msg'}),
      );
      final result =
          _StringValidator().required().validate(null) as ValidationFailure;
      expect(result.message, 'locale msg');
    });

    test('default used when no messageFactory and no locale', () {
      final result =
          _StringValidator().setLabel('Field').required().validate(null)
              as ValidationFailure;
      expect(result.message, 'Field is required.');
    });
  });

  // ---------------------------------------------------------------------------
  // Async + sync combined
  // ---------------------------------------------------------------------------
  group('async + sync combined', () {
    test(
      'sync validator runs before async, sync failure short-circuits',
      () async {
        var asyncCalled = false;
        final v =
            _StringValidator()
              ..addPhaseValidator(
                0,
                (_) => const ValidationFailure(
                  code: ValidationCode.required,
                  message: 'required',
                ),
              )
              ..addAsyncValidator((_) async {
                asyncCalled = true;
                return null;
              });
        await v.validateAsync(null);
        expect(asyncCalled, isFalse);
      },
    );

    test('async validator runs after all sync phases pass', () async {
      var asyncCalled = false;
      final v =
          _StringValidator()
            ..addPhaseValidator(1, (_) => null)
            ..addAsyncValidator((_) async {
              asyncCalled = true;
              return null;
            });
      await v.validateAsync('x');
      expect(asyncCalled, isTrue);
    });

    test('multiple async validators: first failure stops the chain', () async {
      var secondCalled = false;
      final v =
          _StringValidator()
            ..addAsyncValidator(
              (_) async => const ValidationFailure(
                code: ValidationCode.custom,
                message: 'async first fail',
              ),
            )
            ..addAsyncValidator((_) async {
              secondCalled = true;
              return null;
            });
      await v.validateAsync('x');
      expect(secondCalled, isFalse);
    });
  });

  group('partial / isPresence', () {
    test('required() registers as presence validator', () {
      final v = ValidateString().required();
      expect(v.validate(null, skipPresence: true), isA<ValidationSuccess>());
      expect(v.validate(null), isA<ValidationFailure>());
    });

    test('non-presence validators still run when skipPresence:true', () {
      final v = ValidateString().required().email();
      expect(v.validate('bad', skipPresence: true), isA<ValidationFailure>());
    });

    test('validateAsync respects skipPresence', () async {
      final v = ValidateString().required();
      expect(
        await v.validateAsync(null, skipPresence: true),
        isA<ValidationSuccess>(),
      );
    });
  });
}
