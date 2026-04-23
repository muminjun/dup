import 'package:test/test.dart';
import 'package:dup/dup.dart';

// Minimal concrete BaseValidator for testing phase ordering directly
class _TV extends BaseValidator<String, _TV> {
  _TV phaseValidator(int phase, String? Function(String?) fn) =>
      addPhaseValidator(phase, fn);
}

void main() {
  group('BaseValidator — phase ordering', () {
    test('phase 0 fires before phase 1 regardless of chain order', () {
      final v = _TV()
          .setLabel('X')
          .phaseValidator(1, (val) => val != null ? 'format-error' : null)
          .phaseValidator(0, (val) => val == null ? 'required-error' : null);

      expect(v.validate(null), equals('required-error'));
    });

    test('phase 1 fires before phase 2', () {
      final v = _TV()
          .setLabel('X')
          .phaseValidator(2, (val) => 'constraint-error')
          .phaseValidator(1, (val) => val != null ? 'format-error' : null);

      expect(v.validate('anything'), equals('format-error'));
    });

    test('phase 2 fires before phase 3', () {
      final v = _TV()
          .setLabel('X')
          .phaseValidator(3, (val) => 'custom-error')
          .phaseValidator(2, (val) => val != null ? 'constraint-error' : null);

      expect(v.validate('anything'), equals('constraint-error'));
    });

    test('same phase runs in insertion order', () {
      final v = _TV()
          .setLabel('X')
          .phaseValidator(1, (val) => 'first')
          .phaseValidator(1, (val) => 'second');

      expect(v.validate('x'), equals('first'));
    });
  });

  group('BaseValidator — required() is phase 0', () {
    test('required fires before addValidator (phase 3) regardless of chain order', () {
      final v = ValidateString()
          .setLabel('Name')
          .addValidator((_) => 'custom-error')
          .required();

      expect(v.validate(null), equals('Name is required.'));
    });

    test('required fires on empty string', () {
      expect(ValidateString().setLabel('X').required().validate(''), equals('X is required.'));
    });

    test('required passes for non-empty string', () {
      expect(ValidateString().setLabel('X').required().validate('hello'), isNull);
    });
  });

  group('BaseValidator — null contract', () {
    test('satisfy skips on null', () {
      expect(ValidateString().setLabel('X').satisfy((_) => false).validate(null), isNull);
    });

    test('satisfy fails when condition returns false', () {
      expect(
        ValidateString().setLabel('Code').satisfy((v) => v == 'ok').validate('bad'),
        equals('Code does not satisfy the condition.'),
      );
    });

    test('satisfy passes when condition returns true', () {
      expect(ValidateString().setLabel('Code').satisfy((v) => v == 'ok').validate('ok'), isNull);
    });

    test('equalTo skips on null', () {
      expect(ValidateString().setLabel('X').equalTo('hello').validate(null), isNull);
    });

    test('notEqualTo skips on null', () {
      expect(ValidateString().setLabel('X').notEqualTo('hello').validate(null), isNull);
    });

    test('includedIn skips on null', () {
      expect(ValidateString().setLabel('X').includedIn(['a', 'b']).validate(null), isNull);
    });

    test('excludedFrom skips on null', () {
      expect(ValidateString().setLabel('X').excludedFrom(['a', 'b']).validate(null), isNull);
    });
  });

  group('BaseValidator — addValidator (custom phase 3)', () {
    test('addValidator receives value and returns error', () {
      final v = ValidateString()
          .setLabel('X')
          .addValidator((val) => val == 'bad' ? 'bad value' : null);
      expect(v.validate('bad'), equals('bad value'));
      expect(v.validate('good'), isNull);
    });
  });

  group('BaseValidator — addAsyncValidator', () {
    test('validateAsync runs async validator after sync passes', () async {
      final v = ValidateString()
          .setLabel('X')
          .addValidator((_) => null)
          .addAsyncValidator((val) async => 'async-error');

      expect(await v.validateAsync('hello'), equals('async-error'));
    });

    test('validateAsync returns sync error without running async', () async {
      bool asyncCalled = false;
      final v = ValidateString()
          .setLabel('X')
          .required()
          .addAsyncValidator((val) async {
            asyncCalled = true;
            return null;
          });

      expect(await v.validateAsync(null), equals('X is required.'));
      expect(asyncCalled, isFalse);
    });

    test('validateAsync returns null when both sync and async pass', () async {
      final v = ValidateString()
          .setLabel('X')
          .addAsyncValidator((val) async => null);

      expect(await v.validateAsync('hello'), isNull);
    });

    test('validate() (sync) does NOT run async validators', () {
      final v = ValidateString()
          .setLabel('X')
          .addAsyncValidator((val) async => 'async-error');

      expect(v.validate('hello'), isNull);
    });

    test('multiple async validators stop at first error', () async {
      bool secondCalled = false;
      final v = ValidateString()
          .setLabel('X')
          .addAsyncValidator((val) async => 'first-error')
          .addAsyncValidator((val) async {
            secondCalled = true;
            return 'second-error';
          });

      expect(await v.validateAsync('hello'), equals('first-error'));
      expect(secondCalled, isFalse);
    });
  });

  group('BaseValidator — includedIn / excludedFrom', () {
    test('includedIn passes for allowed value', () {
      expect(ValidateString().setLabel('Role').includedIn(['admin', 'user']).validate('admin'), isNull);
    });

    test('includedIn fails for disallowed value', () {
      expect(ValidateString().setLabel('Role').includedIn(['admin', 'user']).validate('guest'), isNotNull);
    });

    test('excludedFrom passes when not in list', () {
      expect(ValidateString().setLabel('Name').excludedFrom(['root']).validate('alice'), isNull);
    });

    test('excludedFrom fails when in list', () {
      expect(ValidateString().setLabel('Name').excludedFrom(['root']).validate('root'), isNotNull);
    });
  });

  group('BaseValidator — equalTo / notEqualTo', () {
    test('equalTo passes when values match', () {
      expect(ValidateString().setLabel('X').equalTo('hello').validate('hello'), isNull);
    });

    test('equalTo fails when values differ', () {
      expect(ValidateString().setLabel('X').equalTo('hello').validate('world'), isNotNull);
    });

    test('notEqualTo passes when values differ', () {
      expect(ValidateString().setLabel('X').notEqualTo('forbidden').validate('allowed'), isNull);
    });

    test('notEqualTo fails when values match', () {
      expect(ValidateString().setLabel('X').notEqualTo('forbidden').validate('forbidden'), isNotNull);
    });
  });
}
