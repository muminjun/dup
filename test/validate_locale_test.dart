import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('ValidatorLocale', () {
    test('current is null by default', () {
      expect(ValidatorLocale.current, isNull);
    });

    test('setLocale sets current', () {
      final locale = ValidatorLocale({
        ValidationCode.required: (p) => '${p['name']}은(는) 필수입니다.',
      });
      ValidatorLocale.setLocale(locale);
      expect(ValidatorLocale.current, same(locale));
    });

    test('resetLocale sets current back to null', () {
      ValidatorLocale.setLocale(ValidatorLocale({}));
      ValidatorLocale.resetLocale();
      expect(ValidatorLocale.current, isNull);
    });

    test('messages map is accessible', () {
      final locale = ValidatorLocale({
        ValidationCode.required: (p) => 'required: ${p['name']}',
        ValidationCode.emailInvalid: (_) => '이메일 형식 오류',
      });
      expect(
        locale.messages[ValidationCode.required]?.call({'name': 'Email'}),
        'required: Email',
      );
      expect(
        locale.messages[ValidationCode.emailInvalid]?.call({}),
        '이메일 형식 오류',
      );
    });

    test('unspecified code returns null (falls through to default)', () {
      final locale = ValidatorLocale({ValidationCode.required: (_) => '필수'});
      expect(locale.messages[ValidationCode.emailInvalid], isNull);
    });
  });

  group('ValidatorLocale.base', () {
    test('base contains required code', () {
      expect(ValidatorLocale.base.messages[ValidationCode.required], isNotNull);
    });

    test('base required message uses name parameter', () {
      final msg = ValidatorLocale.base.messages[ValidationCode.required]!({
        'name': 'Email',
      });
      expect(msg, contains('Email'));
    });

    test('base covers every ValidationCode value', () {
      final missing =
          ValidationCode.values
              .where((c) => !ValidatorLocale.base.messages.containsKey(c))
              .toList();
      expect(
        missing,
        isEmpty,
        reason:
            'ValidatorLocale.base is missing entries for: '
            '${missing.map((c) => c.name).join(', ')}',
      );
    });
  });

  group('ValidatorLocale.merge()', () {
    tearDown(() => ValidatorLocale.resetLocale());

    test('merge overrides specified codes', () {
      final custom = ValidatorLocale.base.merge({
        ValidationCode.required: (_) => 'custom required',
      });
      expect(
        custom.messages[ValidationCode.required]!({}),
        equals('custom required'),
      );
    });

    test('merge preserves unspecified codes from receiver', () {
      final custom = ValidatorLocale.base.merge({
        ValidationCode.required: (_) => 'custom',
      });
      expect(custom.messages[ValidationCode.emailInvalid], isNotNull);
    });

    test('merge does not mutate receiver', () {
      final original = ValidatorLocale.base;
      original.merge({ValidationCode.required: (_) => 'x'});
      expect(
        original.messages[ValidationCode.required]!({'name': 'F'}),
        isNot(equals('x')),
      );
    });
  });
}
