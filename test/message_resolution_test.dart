import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('3-level message priority', () {
    test('1st — messageFactory wins over locale and default', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.required: (_) => '로케일 메시지'}),
      );
      final result = ValidateString()
          .setLabel('Email')
          .required(messageFactory: (_, __) => '팩토리 메시지')
          .validate(null) as ValidationFailure;
      expect(result.message, '팩토리 메시지');
    });

    test('2nd — locale wins over default when no messageFactory', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.required: (p) => '${p['name']} 로케일'}),
      );
      final result = ValidateString()
          .setLabel('Email')
          .required()
          .validate(null) as ValidationFailure;
      expect(result.message, 'Email 로케일');
    });

    test('3rd — default used when no messageFactory and no locale', () {
      final result = ValidateString()
          .setLabel('Email')
          .required()
          .validate(null) as ValidationFailure;
      expect(result.message, 'Email is required.');
    });

    test('locale covers multiple codes independently', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.required: (_) => 'req',
          ValidationCode.emailInvalid: (_) => 'email bad',
        }),
      );

      final req = ValidateString().setLabel('E').required().validate(null)
          as ValidationFailure;
      final email = ValidateString().setLabel('E').email().validate('bad')
          as ValidationFailure;

      expect(req.message, 'req');
      expect(email.message, 'email bad');
    });

    test('unregistered code falls back to default', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.required: (_) => 'req only'}),
      );
      final result = ValidateString().setLabel('Email').email().validate('bad')
          as ValidationFailure;
      expect(result.message, 'Email is not a valid email address.');
    });
  });
}
