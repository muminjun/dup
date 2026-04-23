import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('ValidatorLocale — set and reset', () {
    test('current is null by default', () {
      expect(ValidatorLocale.current, isNull);
    });

    test('setLocale makes locale available via current', () {
      final locale = ValidatorLocale(
        mixed: {}, string: {}, number: {}, array: {},
      );
      ValidatorLocale.setLocale(locale);
      expect(ValidatorLocale.current, same(locale));
    });

    test('resetLocale sets current back to null', () {
      ValidatorLocale.setLocale(
        ValidatorLocale(mixed: {}, string: {}, number: {}, array: {}),
      );
      ValidatorLocale.resetLocale();
      expect(ValidatorLocale.current, isNull);
    });
  });

  group('ValidatorLocale — boolMessages and date categories', () {
    test('boolMessages defaults to empty map when not provided', () {
      final locale = ValidatorLocale(
        mixed: {}, string: {}, number: {}, array: {},
      );
      expect(locale.boolMessages, isEmpty);
    });

    test('date defaults to empty map when not provided', () {
      final locale = ValidatorLocale(
        mixed: {}, string: {}, number: {}, array: {},
      );
      expect(locale.date, isEmpty);
    });

    test('boolMessages can be set and accessed', () {
      final locale = ValidatorLocale(
        mixed: {}, string: {}, number: {}, array: {},
        boolMessages: {'isTrue': (args) => '${args['name']} must be checked'},
      );
      ValidatorLocale.setLocale(locale);
      expect(ValidatorLocale.current?.boolMessages['isTrue'], isNotNull);
    });

    test('date messages can be set and accessed', () {
      final locale = ValidatorLocale(
        mixed: {}, string: {}, number: {}, array: {},
        date: {'after': (args) => '${args['name']} too early'},
      );
      ValidatorLocale.setLocale(locale);
      expect(ValidatorLocale.current?.date['after'], isNotNull);
    });
  });

  group('ValidatorLocale — mixed locale overrides default messages', () {
    test('required message uses locale when set', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {
          'required': (args) => '${args['name']} 필수 입력',
        },
        string: {}, number: {}, array: {},
      ));

      final v = ValidateString().setLabel('이름').required();
      expect(v.validate(null), equals('이름 필수 입력'));
    });
  });

  group('ValidatorLocaleKeys — constants', () {
    test('required key is correct', () {
      expect(ValidatorLocaleKeys.required, equals('required'));
    });
    test('equal key is correct', () {
      expect(ValidatorLocaleKeys.equal, equals('equal'));
    });
    test('stringEmail key is correct', () {
      expect(ValidatorLocaleKeys.stringEmail, equals('emailInvalid'));
    });
    test('numberPositive key is correct', () {
      expect(ValidatorLocaleKeys.numberPositive, equals('positive'));
    });
    test('arrayNotEmpty key is correct', () {
      expect(ValidatorLocaleKeys.arrayNotEmpty, equals('notEmpty'));
    });
    test('boolTrue key is correct', () {
      expect(ValidatorLocaleKeys.boolTrue, equals('isTrue'));
    });
    test('dateAfter key is correct', () {
      expect(ValidatorLocaleKeys.dateAfter, equals('after'));
    });
    test('dateBetween key is correct', () {
      expect(ValidatorLocaleKeys.dateBetween, equals('between'));
    });
  });
}
