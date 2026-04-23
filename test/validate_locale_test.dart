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
      final locale = ValidatorLocale({
        ValidationCode.required: (_) => '필수',
      });
      expect(locale.messages[ValidationCode.emailInvalid], isNull);
    });
  });
}
