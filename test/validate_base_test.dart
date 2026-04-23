import 'package:dup/dup.dart';
import 'package:test/test.dart';

// Minimal concrete subclass for testing BaseValidator directly.
class _StringValidator extends BaseValidator<String, _StringValidator> {}

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('validate() returns ValidationResult', () {
    test('returns ValidationSuccess when no validators registered', () {
      final v = _StringValidator();
      expect(v.validate('hello'), isA<ValidationSuccess>());
    });

    test('returns ValidationFailure when validator fails', () {
      final v = _StringValidator()
        ..addPhaseValidator(1, (value) => value == null
            ? null
            : const ValidationFailure(
                code: ValidationCode.custom, message: 'bad'));
      final result = v.validate('x');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).message, 'bad');
    });

    test('returns ValidationSuccess when validator passes', () {
      final v = _StringValidator()
        ..addPhaseValidator(1, (_) => null);
      expect(v.validate('x'), isA<ValidationSuccess>());
    });
  });

  group('validateAsync() returns Future<ValidationResult>', () {
    test('async validator failure is returned', () async {
      final v = _StringValidator()
        ..addAsyncValidator((_) async => const ValidationFailure(
              code: ValidationCode.custom, message: 'async fail'));
      final result = await v.validateAsync('x');
      expect(result, isA<ValidationFailure>());
    });

    test('sync failure short-circuits async', () async {
      var asyncCalled = false;
      final v = _StringValidator()
        ..addPhaseValidator(1, (_) => const ValidationFailure(
              code: ValidationCode.custom, message: 'sync'))
        ..addAsyncValidator((_) async {
          asyncCalled = true;
          return null;
        });
      await v.validateAsync('x');
      expect(asyncCalled, isFalse);
    });
  });

  group('hasAsyncValidators', () {
    test('false when no async validators', () {
      expect(_StringValidator().hasAsyncValidators, isFalse);
    });

    test('true when async validator added', () {
      final v = _StringValidator()..addAsyncValidator((_) async => null);
      expect(v.hasAsyncValidators, isTrue);
    });
  });

  group('toValidator()', () {
    test('returns null on success', () {
      final fn = _StringValidator().toValidator();
      expect(fn('hello'), isNull);
    });

    test('returns message string on failure', () {
      final v = _StringValidator()
        ..addPhaseValidator(1, (_) => const ValidationFailure(
              code: ValidationCode.custom, message: 'err'));
      expect(v.toValidator()('x'), 'err');
    });
  });

  group('required()', () {
    test('fails for null', () {
      final result = _StringValidator().required().validate(null);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.required);
    });

    test('fails for empty string', () {
      final result = _StringValidator().required().validate('');
      expect(result, isA<ValidationFailure>());
    });

    test('passes for non-empty string', () {
      expect(_StringValidator().required().validate('x'), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final v = _StringValidator().setLabel('Email').required(
            messageFactory: (label, _) => '$label 필수',
          );
      final result = v.validate(null) as ValidationFailure;
      expect(result.message, 'Email 필수');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.required: (p) => '${p['name']} 필수',
      }));
      final result = _StringValidator().setLabel('이메일').required().validate(null)
          as ValidationFailure;
      expect(result.message, '이메일 필수');
    });
  });

  group('addValidator()', () {
    test('custom ValidationFailure is returned', () {
      final v = _StringValidator().addValidator((value) {
        if (value == 'bad') {
          return const ValidationFailure(
              code: ValidationCode.custom, message: 'not allowed');
        }
        return null;
      });
      expect(v.validate('bad'), isA<ValidationFailure>());
      expect(v.validate('ok'), isA<ValidationSuccess>());
    });
  });

  group('phase ordering', () {
    test('phase 0 runs before phase 1', () {
      final log = <int>[];
      final v = _StringValidator()
        ..addPhaseValidator(1, (_) { log.add(1); return null; })
        ..addPhaseValidator(0, (_) { log.add(0); return null; });
      v.validate('x');
      expect(log, [0, 1]);
    });
  });
}
