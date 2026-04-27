import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  // ---------------------------------------------------------------------------
  // min()
  // ---------------------------------------------------------------------------
  group('min()', () {
    test('passes when length == min (boundary)', () {
      expect(ValidateString().min(3).validate('abc'), isA<ValidationSuccess>());
    });

    test('passes when length > min', () {
      expect(
        ValidateString().min(3).validate('abcd'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when length < min', () {
      final result = ValidateString().setLabel('Name').min(3).validate('ab');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.stringMin);
      expect(result.context['min'], 3);
    });

    test('trims before measuring — leading/trailing spaces ignored', () {
      expect(
        ValidateString().min(3).validate('  a  '),
        isA<ValidationFailure>(),
      );
      expect(
        ValidateString().min(3).validate('  abc  '),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().min(3).validate(null), isA<ValidationSuccess>());
    });

    test('fails for empty string', () {
      expect(ValidateString().min(1).validate(''), isA<ValidationFailure>());
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('이름')
                  .min(
                    3,
                    messageFactory: (label, p) => '$label 최소 ${p['min']}자',
                  )
                  .validate('ab')
              as ValidationFailure;
      expect(result.message, '이름 최소 3자');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.stringMin: (p) => '${p['name']} 짧음'}),
      );
      final result =
          ValidateString().setLabel('비번').min(8).validate('abc')
              as ValidationFailure;
      expect(result.message, '비번 짧음');
    });

    test('default message contains label and min', () {
      final result =
          ValidateString().setLabel('Password').min(8).validate('hi')
              as ValidationFailure;
      expect(result.message, contains('Password'));
      expect(result.message, contains('8'));
    });
  });

  // ---------------------------------------------------------------------------
  // max()
  // ---------------------------------------------------------------------------
  group('max()', () {
    test('passes when length < max', () {
      expect(ValidateString().max(5).validate('ab'), isA<ValidationSuccess>());
    });

    test('passes when length == max (boundary)', () {
      expect(ValidateString().max(3).validate('abc'), isA<ValidationSuccess>());
    });

    test('fails when length > max', () {
      final result = ValidateString().setLabel('Tag').max(2).validate('abc');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.stringMax);
      expect(result.context['max'], 2);
    });

    test('trims before measuring', () {
      expect(
        ValidateString().max(3).validate('  a  '),
        isA<ValidationSuccess>(),
      );
      expect(
        ValidateString().max(2).validate('  abc  '),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().max(5).validate(null), isA<ValidationSuccess>());
    });

    test('passes for empty string', () {
      expect(ValidateString().max(5).validate(''), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('Tag')
                  .max(
                    3,
                    messageFactory: (label, p) => '$label 최대 ${p['max']}자',
                  )
                  .validate('toolong')
              as ValidationFailure;
      expect(result.message, 'Tag 최대 3자');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.stringMax: (p) => '${p['name']} 너무 김'}),
      );
      final result =
          ValidateString().setLabel('제목').max(5).validate('toolong')
              as ValidationFailure;
      expect(result.message, '제목 너무 김');
    });
  });

  // ---------------------------------------------------------------------------
  // matches()
  // ---------------------------------------------------------------------------
  group('matches()', () {
    test('passes when value matches regex', () {
      expect(
        ValidateString().matches(RegExp(r'^\d+$')).validate('12345'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when value does not match regex', () {
      final result = ValidateString()
          .setLabel('Code')
          .matches(RegExp(r'^\d+$'))
          .validate('abc');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.matches);
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateString().matches(RegExp(r'^\d+$')).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for empty string when regex requires content', () {
      expect(
        ValidateString().matches(RegExp(r'^\d+$')).validate(''),
        isA<ValidationFailure>(),
      );
    });

    test('passes for empty string when regex allows it', () {
      expect(
        ValidateString().matches(RegExp(r'^\d*$')).validate(''),
        isA<ValidationSuccess>(),
      );
    });

    test('trims before matching', () {
      expect(
        ValidateString().matches(RegExp(r'^\d+$')).validate('  123  '),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('Code')
                  .matches(
                    RegExp(r'^\d+$'),
                    messageFactory: (label, _) => '$label 형식 오류',
                  )
                  .validate('abc')
              as ValidationFailure;
      expect(result.message, 'Code 형식 오류');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.matches: (p) => '${p['name']} 패턴 불일치'}),
      );
      final result =
          ValidateString()
                  .setLabel('코드')
                  .matches(RegExp(r'^\d+$'))
                  .validate('abc')
              as ValidationFailure;
      expect(result.message, '코드 패턴 불일치');
    });
  });

  // ---------------------------------------------------------------------------
  // email()
  // ---------------------------------------------------------------------------
  group('email()', () {
    test('passes for simple valid email', () {
      expect(
        ValidateString().email().validate('a@b.com'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for email with plus sign', () {
      expect(
        ValidateString().email().validate('user+tag@example.com'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for email with subdomain', () {
      expect(
        ValidateString().email().validate('user@mail.example.co.uk'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for email with leading/trailing spaces (trimmed)', () {
      expect(
        ValidateString().email().validate('  user@example.com  '),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for missing @ symbol', () {
      final result = ValidateString().email().validate('notanemail');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.emailInvalid);
    });

    test('fails for double @', () {
      expect(
        ValidateString().email().validate('user@@example.com'),
        isA<ValidationFailure>(),
      );
    });

    test('fails for missing TLD', () {
      expect(
        ValidateString().email().validate('user@example'),
        isA<ValidationFailure>(),
      );
    });

    test('fails for no local part', () {
      expect(
        ValidateString().email().validate('@example.com'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().email().validate(null), isA<ValidationSuccess>());
    });

    test('passes for empty string', () {
      expect(ValidateString().email().validate(''), isA<ValidationSuccess>());
    });

    test('passes for whitespace-only string (treated as empty)', () {
      expect(
        ValidateString().email().validate('   '),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('Email')
                  .email(messageFactory: (label, _) => '$label 이메일 오류')
                  .validate('bad')
              as ValidationFailure;
      expect(result.message, 'Email 이메일 오류');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.emailInvalid: (p) => '${p['name']} 유효하지 않은 이메일',
        }),
      );
      final result =
          ValidateString().setLabel('이메일').email().validate('bad')
              as ValidationFailure;
      expect(result.message, '이메일 유효하지 않은 이메일');
    });
  });

  // ---------------------------------------------------------------------------
  // password()
  // ---------------------------------------------------------------------------
  group('password()', () {
    test('passes when length >= minLength', () {
      expect(
        ValidateString().password(minLength: 4).validate('abcd'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes when using default minLength of 4', () {
      expect(
        ValidateString().password().validate('abcd'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when length < minLength', () {
      final result = ValidateString()
          .setLabel('PW')
          .password(minLength: 8)
          .validate('short');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.passwordMin);
      expect(result.context['minLength'], 8);
    });

    test('fails when below default minLength', () {
      expect(
        ValidateString().password().validate('abc'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateString().password(minLength: 8).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for whitespace-only string (treated as blank)', () {
      expect(
        ValidateString().password(minLength: 8).validate('        '),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty string (null-skip semantics)', () {
      expect(
        ValidateString().password(minLength: 4).validate(''),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('PW')
                  .password(
                    minLength: 8,
                    messageFactory:
                        (label, p) => '$label 최소 ${p['minLength']}자 필요',
                  )
                  .validate('short')
              as ValidationFailure;
      expect(result.message, 'PW 최소 8자 필요');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.passwordMin: (p) => '${p['name']} 비밀번호 짧음',
        }),
      );
      final result =
          ValidateString().setLabel('비번').password(minLength: 8).validate('hi')
              as ValidationFailure;
      expect(result.message, '비번 비밀번호 짧음');
    });
  });

  // ---------------------------------------------------------------------------
  // emoji()
  // ---------------------------------------------------------------------------
  group('emoji()', () {
    test('passes for plain text without emoji', () {
      expect(
        ValidateString().emoji().validate('hello world'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for alphanumeric text', () {
      expect(
        ValidateString().emoji().validate('abc123'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for text with special characters but no emoji', () {
      expect(
        ValidateString().emoji().validate('hello#world!'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when text contains emoji', () {
      final result = ValidateString()
          .setLabel('Name')
          .emoji()
          .validate('hello😀');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.emoji);
    });

    test('fails for pure emoji', () {
      expect(ValidateString().emoji().validate('🎉'), isA<ValidationFailure>());
    });

    test('fails for emoji mixed with text', () {
      expect(
        ValidateString().emoji().validate('Hi 👋 there'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().emoji().validate(null), isA<ValidationSuccess>());
    });

    test('passes for empty string', () {
      expect(ValidateString().emoji().validate(''), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('Bio')
                  .emoji(messageFactory: (label, _) => '$label 이모지 불가')
                  .validate('hi😀')
              as ValidationFailure;
      expect(result.message, 'Bio 이모지 불가');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.emoji: (p) => '${p['name']} 이모지 포함 불가',
        }),
      );
      final result =
          ValidateString().setLabel('닉네임').emoji().validate('hi😊')
              as ValidationFailure;
      expect(result.message, '닉네임 이모지 포함 불가');
    });
  });

  // ---------------------------------------------------------------------------
  // notBlank()
  // ---------------------------------------------------------------------------
  group('notBlank()', () {
    test('passes for non-empty string', () {
      expect(
        ValidateString().notBlank().validate('hello'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for string with non-space content', () {
      expect(
        ValidateString().notBlank().validate('  a  '),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for whitespace-only string (spaces)', () {
      final result = ValidateString()
          .setLabel('Name')
          .notBlank()
          .validate('   ');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.notBlank);
    });

    test('fails for tab-only string', () {
      expect(
        ValidateString().notBlank().validate('\t\t'),
        isA<ValidationFailure>(),
      );
    });

    test('fails for newline-only string', () {
      expect(
        ValidateString().notBlank().validate('\n\n'),
        isA<ValidationFailure>(),
      );
    });

    test('fails for empty string', () {
      expect(
        ValidateString().notBlank().validate(''),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateString().notBlank().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('Field')
                  .notBlank(messageFactory: (label, _) => '$label 공백 불가')
                  .validate('   ')
              as ValidationFailure;
      expect(result.message, 'Field 공백 불가');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.notBlank: (p) => '${p['name']} 빈 값 불가',
        }),
      );
      final result =
          ValidateString().setLabel('내용').notBlank().validate('  ')
              as ValidationFailure;
      expect(result.message, '내용 빈 값 불가');
    });
  });

  // ---------------------------------------------------------------------------
  // alpha()
  // ---------------------------------------------------------------------------
  group('alpha()', () {
    test('passes for pure alphabetic string', () {
      expect(
        ValidateString().alpha().validate('HelloWorld'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for single letter', () {
      expect(ValidateString().alpha().validate('A'), isA<ValidationSuccess>());
    });

    test('fails when string contains digits', () {
      final result = ValidateString()
          .setLabel('Name')
          .alpha()
          .validate('Hello1');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.alpha);
    });

    test('fails when string contains spaces', () {
      expect(
        ValidateString().alpha().validate('Hello World'),
        isA<ValidationFailure>(),
      );
    });

    test('fails when string contains special characters', () {
      expect(
        ValidateString().alpha().validate('abc!'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().alpha().validate(null), isA<ValidationSuccess>());
    });

    test('passes for empty string (null-skip semantics)', () {
      expect(ValidateString().alpha().validate(''), isA<ValidationSuccess>());
    });

    test('passes for whitespace-only string (trims to empty)', () {
      expect(
        ValidateString().alpha().validate('   '),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('Name')
                  .alpha(messageFactory: (label, _) => '$label 알파벳만 가능')
                  .validate('abc123')
              as ValidationFailure;
      expect(result.message, 'Name 알파벳만 가능');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.alpha: (p) => '${p['name']} 문자만 입력'}),
      );
      final result =
          ValidateString().setLabel('이름').alpha().validate('abc1')
              as ValidationFailure;
      expect(result.message, '이름 문자만 입력');
    });
  });

  // ---------------------------------------------------------------------------
  // alphanumeric()
  // ---------------------------------------------------------------------------
  group('alphanumeric()', () {
    test('passes for alphanumeric string', () {
      expect(
        ValidateString().alphanumeric().validate('Hello123'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for letters only', () {
      expect(
        ValidateString().alphanumeric().validate('Hello'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for digits only', () {
      expect(
        ValidateString().alphanumeric().validate('12345'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for underscore', () {
      final result = ValidateString()
          .setLabel('ID')
          .alphanumeric()
          .validate('hello_world');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.alphanumeric);
    });

    test('fails for hyphen', () {
      expect(
        ValidateString().alphanumeric().validate('hello-world'),
        isA<ValidationFailure>(),
      );
    });

    test('fails for special characters', () {
      expect(
        ValidateString().alphanumeric().validate('abc@123'),
        isA<ValidationFailure>(),
      );
    });

    test('fails for spaces', () {
      expect(
        ValidateString().alphanumeric().validate('hello world'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateString().alphanumeric().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty string', () {
      expect(
        ValidateString().alphanumeric().validate(''),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('ID')
                  .alphanumeric(messageFactory: (label, _) => '$label 영숫자만 가능')
                  .validate('hello!')
              as ValidationFailure;
      expect(result.message, 'ID 영숫자만 가능');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.alphanumeric: (p) => '${p['name']} 영숫자 오류',
        }),
      );
      final result =
          ValidateString().setLabel('아이디').alphanumeric().validate('hello!')
              as ValidationFailure;
      expect(result.message, '아이디 영숫자 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // numeric()
  // ---------------------------------------------------------------------------
  group('numeric()', () {
    test('passes for digit-only string', () {
      expect(
        ValidateString().numeric().validate('12345'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for string with letters', () {
      final result = ValidateString()
          .setLabel('Zip')
          .numeric()
          .validate('123ab');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.numeric);
    });

    test('fails for string with decimal point', () {
      expect(
        ValidateString().numeric().validate('12.34'),
        isA<ValidationFailure>(),
      );
    });

    test('fails for string with negative sign', () {
      expect(
        ValidateString().numeric().validate('-123'),
        isA<ValidationFailure>(),
      );
    });

    test('fails for string with spaces', () {
      expect(
        ValidateString().numeric().validate('12 34'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateString().numeric().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty string', () {
      expect(ValidateString().numeric().validate(''), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('Zip')
                  .numeric(messageFactory: (label, _) => '$label 숫자만 가능')
                  .validate('abc')
              as ValidationFailure;
      expect(result.message, 'Zip 숫자만 가능');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.numeric: (p) => '${p['name']} 숫자 오류'}),
      );
      final result =
          ValidateString().setLabel('우편번호').numeric().validate('abc')
              as ValidationFailure;
      expect(result.message, '우편번호 숫자 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // koMobile()
  // ---------------------------------------------------------------------------
  group('koMobile()', () {
    test('passes for valid 010 format', () {
      expect(
        ValidateString().koMobile().validate('010-1234-5678'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for valid 011 format', () {
      expect(
        ValidateString().koMobile().validate('011-123-4567'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for missing dashes', () {
      final result = ValidateString()
          .setLabel('Phone')
          .koMobile()
          .validate('01012345678');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.mobileInvalid);
    });

    test('fails for wrong format', () {
      expect(
        ValidateString().koMobile().validate('010-12-34567'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateString().koMobile().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty string', () {
      expect(ValidateString().koMobile().validate(''), isA<ValidationSuccess>());
    });

    test('uses custom regex', () {
      final customRegex = RegExp(r'^\d{10}$');
      expect(
        ValidateString()
            .koMobile(customRegex: customRegex)
            .validate('0101234567'),
        isA<ValidationSuccess>(),
      );
      expect(
        ValidateString()
            .koMobile(customRegex: customRegex)
            .validate('010-1234-5678'),
        isA<ValidationFailure>(),
      );
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('Mobile')
                  .koMobile(messageFactory: (label, _) => '$label 형식 오류')
                  .validate('bad')
              as ValidationFailure;
      expect(result.message, 'Mobile 형식 오류');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.mobileInvalid: (p) => '${p['name']} 번호 오류',
        }),
      );
      final result =
          ValidateString().setLabel('전화번호').koMobile().validate('bad')
              as ValidationFailure;
      expect(result.message, '전화번호 번호 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // koPhone()
  // ---------------------------------------------------------------------------
  group('koPhone()', () {
    test('passes for valid Seoul landline', () {
      expect(
        ValidateString().koPhone().validate('02-1234-5678'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for valid 3-digit area code', () {
      expect(
        ValidateString().koPhone().validate('031-123-4567'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for invalid format', () {
      final result = ValidateString()
          .setLabel('Phone')
          .koPhone()
          .validate('02-12-5678');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.phoneInvalid);
    });

    test('fails for mobile number format', () {
      expect(
        ValidateString().koPhone().validate('010-1234-5678'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().koPhone().validate(null), isA<ValidationSuccess>());
    });

    test('passes for empty string', () {
      expect(ValidateString().koPhone().validate(''), isA<ValidationSuccess>());
    });

    test('uses custom regex', () {
      final customRegex = RegExp(r'^\d{3}-\d{4}$');
      expect(
        ValidateString().koPhone(customRegex: customRegex).validate('010-1234'),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('Phone')
                  .koPhone(messageFactory: (label, _) => '$label 유선전화 오류')
                  .validate('bad')
              as ValidationFailure;
      expect(result.message, 'Phone 유선전화 오류');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.phoneInvalid: (p) => '${p['name']} 유선 번호 오류',
        }),
      );
      final result =
          ValidateString().setLabel('유선').koPhone().validate('bad')
              as ValidationFailure;
      expect(result.message, '유선 유선 번호 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // bizno()
  // ---------------------------------------------------------------------------
  group('bizno()', () {
    test('passes for valid business number', () {
      expect(
        ValidateString().bizno().validate('123-45-67890'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for invalid format', () {
      final result = ValidateString()
          .setLabel('Bizno')
          .bizno()
          .validate('1234567890');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.biznoInvalid);
    });

    test('fails for wrong separator format', () {
      expect(
        ValidateString().bizno().validate('123.45.67890'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().bizno().validate(null), isA<ValidationSuccess>());
    });

    test('passes for empty string', () {
      expect(ValidateString().bizno().validate(''), isA<ValidationSuccess>());
    });

    test('uses custom regex', () {
      final customRegex = RegExp(r'^\d{10}$');
      expect(
        ValidateString().bizno(customRegex: customRegex).validate('1234567890'),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('Bizno')
                  .bizno(messageFactory: (label, _) => '$label 사업자번호 오류')
                  .validate('bad')
              as ValidationFailure;
      expect(result.message, 'Bizno 사업자번호 오류');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.biznoInvalid: (p) => '${p['name']} 사업자 오류',
        }),
      );
      final result =
          ValidateString().setLabel('사업자번호').bizno().validate('bad')
              as ValidationFailure;
      expect(result.message, '사업자번호 사업자 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // url()
  // ---------------------------------------------------------------------------
  group('url()', () {
    test('passes for valid https URL', () {
      expect(
        ValidateString().url().validate('https://example.com'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for valid http URL', () {
      expect(
        ValidateString().url().validate('http://example.com'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for URL with port', () {
      expect(
        ValidateString().url().validate('https://example.com:8080'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for URL with path', () {
      expect(
        ValidateString().url().validate('https://example.com/path/to/page'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for URL with query string', () {
      expect(
        ValidateString().url().validate('https://example.com?q=hello'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for ftp protocol', () {
      final result = ValidateString()
          .setLabel('URL')
          .url()
          .validate('ftp://example.com');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.url);
    });

    test('fails for no protocol', () {
      expect(
        ValidateString().url().validate('example.com'),
        isA<ValidationFailure>(),
      );
    });

    test('fails for plain text', () {
      expect(
        ValidateString().url().validate('not a url'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().url().validate(null), isA<ValidationSuccess>());
    });

    test('passes for empty string', () {
      expect(ValidateString().url().validate(''), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('URL')
                  .url(messageFactory: (label, _) => '$label URL 오류')
                  .validate('bad')
              as ValidationFailure;
      expect(result.message, 'URL URL 오류');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.url: (p) => '${p['name']} 주소 오류'}),
      );
      final result =
          ValidateString().setLabel('웹주소').url().validate('bad')
              as ValidationFailure;
      expect(result.message, '웹주소 주소 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // uuid()
  // ---------------------------------------------------------------------------
  group('uuid()', () {
    test('passes for valid UUID v4', () {
      expect(
        ValidateString().uuid().validate(
          '550e8400-e29b-41d4-a716-446655440000',
        ),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for uppercase UUID v4 (case-insensitive)', () {
      expect(
        ValidateString().uuid().validate(
          '550E8400-E29B-41D4-A716-446655440000',
        ),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for mixed-case UUID v4', () {
      expect(
        ValidateString().uuid().validate(
          '550e8400-E29B-41d4-A716-446655440000',
        ),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for UUID v1 (version digit is 1)', () {
      final result = ValidateString()
          .setLabel('ID')
          .uuid()
          .validate('550e8400-e29b-11d4-a716-446655440000');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.uuid);
    });

    test('fails for malformed UUID (wrong segment lengths)', () {
      expect(
        ValidateString().uuid().validate('550e8400-e29b-41d4-a716'),
        isA<ValidationFailure>(),
      );
    });

    test('fails for plain string', () {
      expect(
        ValidateString().uuid().validate('not-a-uuid'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().uuid().validate(null), isA<ValidationSuccess>());
    });

    test('passes for empty string', () {
      expect(ValidateString().uuid().validate(''), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result =
          ValidateString()
                  .setLabel('ID')
                  .uuid(messageFactory: (label, _) => '$label UUID 오류')
                  .validate('bad')
              as ValidationFailure;
      expect(result.message, 'ID UUID 오류');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({ValidationCode.uuid: (p) => '${p['name']} 식별자 오류'}),
      );
      final result =
          ValidateString().setLabel('식별자').uuid().validate('bad')
              as ValidationFailure;
      expect(result.message, '식별자 식별자 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // required()
  // ---------------------------------------------------------------------------
  group('required()', () {
    test('fails for null', () {
      final result = ValidateString().required().validate(null);
      expect((result as ValidationFailure).code, ValidationCode.required);
    });

    test('fails for empty string', () {
      expect(
        ValidateString().required().validate(''),
        isA<ValidationFailure>(),
      );
    });

    test('passes for non-empty string', () {
      expect(
        ValidateString().required().validate('hello'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for whitespace-only string (not empty)', () {
      expect(
        ValidateString().required().validate('   '),
        isA<ValidationSuccess>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // toValidator()
  // ---------------------------------------------------------------------------
  group('toValidator()', () {
    test('returns null on success', () {
      expect(ValidateString().email().toValidator()('a@b.com'), isNull);
    });

    test('returns message string on failure', () {
      final fn = ValidateString().setLabel('Email').email().toValidator();
      expect(fn('bad'), isNotNull);
      expect(fn('bad'), contains('Email'));
    });

    test('returns null for null input when not required', () {
      expect(ValidateString().email().toValidator()(null), isNull);
    });

    test('returns error for null input when required', () {
      expect(ValidateString().required().toValidator()(null), isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — email patterns
  // ---------------------------------------------------------------------------
  group('real user email input patterns', () {
    test('uppercase email is valid', () {
      expect(
        ValidateString().email().validate('USER@EXAMPLE.COM'),
        isA<ValidationSuccess>(),
      );
    });

    test('space before @ — fails', () {
      expect(
        ValidateString().email().validate('user @example.com'),
        isA<ValidationFailure>(),
      );
    });

    test('space after @ — fails', () {
      expect(
        ValidateString().email().validate('user@ example.com'),
        isA<ValidationFailure>(),
      );
    });

    test('consecutive dots in domain — fails', () {
      expect(
        ValidateString().email().validate('user@example..com'),
        isA<ValidationFailure>(),
      );
    });

    test('domain only without @ — fails', () {
      expect(
        ValidateString().email().validate('example.com'),
        isA<ValidationFailure>(),
      );
    });

    test('alphanumeric mixed email is valid', () {
      expect(
        ValidateString().email().validate('hong123@naver.com'),
        isA<ValidationSuccess>(),
      );
    });

    test('dot in local part is valid', () {
      expect(
        ValidateString().email().validate('hong.gildong@company.co.kr'),
        isA<ValidationSuccess>(),
      );
    });

    test('plus-tag email is valid (gmail style)', () {
      expect(
        ValidateString().email().validate('hong+work@gmail.com'),
        isA<ValidationSuccess>(),
      );
    });

    test('domain without TLD — fails (common mistake)', () {
      expect(
        ValidateString().email().validate('user@localhost'),
        isA<ValidationFailure>(),
      );
    });

    test('leading/trailing spaces are trimmed — valid', () {
      expect(
        ValidateString().email().validate('  hong@naver.com  '),
        isA<ValidationSuccess>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — mobile number patterns
  // ---------------------------------------------------------------------------
  group('real user mobile input patterns', () {
    test('010-1234-5678 — valid format', () {
      expect(
        ValidateString().koMobile().validate('010-1234-5678'),
        isA<ValidationSuccess>(),
      );
    });

    test('space-separated (010 1234 5678) — fails', () {
      expect(
        ValidateString().koMobile().validate('010 1234 5678'),
        isA<ValidationFailure>(),
      );
    });

    test('no hyphens (01012345678) — fails', () {
      expect(
        ValidateString().koMobile().validate('01012345678'),
        isA<ValidationFailure>(),
      );
    });

    test('extra digit (010-1234-56789) — fails', () {
      expect(
        ValidateString().koMobile().validate('010-1234-56789'),
        isA<ValidationFailure>(),
      );
    });

    test('short middle segment (010-12-5678) — fails', () {
      expect(
        ValidateString().koMobile().validate('010-12-5678'),
        isA<ValidationFailure>(),
      );
    });

    test(
      'international format (+82-10-1234-5678) — fails (not in default regex)',
      () {
        expect(
          ValidateString().koMobile().validate('+82-10-1234-5678'),
          isA<ValidationFailure>(),
        );
      },
    );

    test('parenthesis format (010)1234-5678 — fails', () {
      expect(
        ValidateString().koMobile().validate('010)1234-5678'),
        isA<ValidationFailure>(),
      );
    });

    test('legacy 011 number (011-123-4567) — valid', () {
      expect(
        ValidateString().koMobile().validate('011-123-4567'),
        isA<ValidationSuccess>(),
      );
    });

    test('empty string — passes (not required)', () {
      expect(ValidateString().koMobile().validate(''), isA<ValidationSuccess>());
    });

    test('null — passes (not required)', () {
      expect(
        ValidateString().koMobile().validate(null),
        isA<ValidationSuccess>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — password patterns
  // ---------------------------------------------------------------------------
  group('real user password input patterns', () {
    test('1234 — passes (default minLength is 4)', () {
      expect(
        ValidateString().password().validate('1234'),
        isA<ValidationSuccess>(),
      );
    });

    test('123 — fails (below default minLength of 4)', () {
      expect(
        ValidateString().password().validate('123'),
        isA<ValidationFailure>(),
      );
    });

    test('password123 with minLength:8 — passes', () {
      expect(
        ValidateString().password(minLength: 8).validate('password123'),
        isA<ValidationSuccess>(),
      );
    });

    test('qwerty (6 chars) with minLength:8 — fails', () {
      expect(
        ValidateString().password(minLength: 8).validate('qwerty'),
        isA<ValidationFailure>(),
      );
    });

    test('exactly 8 chars — passes (boundary)', () {
      expect(
        ValidateString().password(minLength: 8).validate('abcdefgh'),
        isA<ValidationSuccess>(),
      );
    });

    test('7 chars — fails (boundary - 1)', () {
      expect(
        ValidateString().password(minLength: 8).validate('abcdefg'),
        isA<ValidationFailure>(),
      );
    });

    test('whitespace-only — passes (blank skip)', () {
      expect(
        ValidateString().password(minLength: 8).validate('        '),
        isA<ValidationSuccess>(),
      );
    });

    test('password with special chars — passes', () {
      expect(
        ValidateString().password(minLength: 8).validate('P@ssw0rd!'),
        isA<ValidationSuccess>(),
      );
    });

    test('password with Korean characters — passes (length-only check)', () {
      expect(
        ValidateString().password(minLength: 4).validate('비밀번호1234'),
        isA<ValidationSuccess>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — URL patterns
  // ---------------------------------------------------------------------------
  group('real user URL input patterns', () {
    test('https URL — passes', () {
      expect(
        ValidateString().url().validate('https://naver.com'),
        isA<ValidationSuccess>(),
      );
    });

    test('http URL — passes', () {
      expect(
        ValidateString().url().validate('http://naver.com'),
        isA<ValidationSuccess>(),
      );
    });

    test('www without protocol — fails', () {
      expect(
        ValidateString().url().validate('www.naver.com'),
        isA<ValidationFailure>(),
      );
    });

    test('domain only without protocol — fails', () {
      expect(
        ValidateString().url().validate('naver.com'),
        isA<ValidationFailure>(),
      );
    });

    test('http:// with no host — fails', () {
      expect(
        ValidateString().url().validate('http://'),
        isA<ValidationFailure>(),
      );
    });

    test('https:// with no host — fails', () {
      expect(
        ValidateString().url().validate('https://'),
        isA<ValidationFailure>(),
      );
    });

    test('ftp:// protocol — fails', () {
      expect(
        ValidateString().url().validate('ftp://files.example.com'),
        isA<ValidationFailure>(),
      );
    });

    test('URL with query string — passes', () {
      expect(
        ValidateString().url().validate(
          'https://search.naver.com/search.naver?query=dart',
        ),
        isA<ValidationSuccess>(),
      );
    });

    test('URL with port number — passes', () {
      expect(
        ValidateString().url().validate('http://localhost:8080'),
        isA<ValidationSuccess>(),
      );
    });
    test('URL with single-char host — passes', () {
      expect(
        ValidateString().url().validate('http://a'),
        isA<ValidationSuccess>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — business registration number patterns
  // ---------------------------------------------------------------------------
  group('real user business number input patterns', () {
    test('123-45-67890 — valid format', () {
      expect(
        ValidateString().bizno().validate('123-45-67890'),
        isA<ValidationSuccess>(),
      );
    });

    test('1234567890 without hyphens — fails', () {
      expect(
        ValidateString().bizno().validate('1234567890'),
        isA<ValidationFailure>(),
      );
    });

    test('123 45 67890 space-separated — fails', () {
      expect(
        ValidateString().bizno().validate('123 45 67890'),
        isA<ValidationFailure>(),
      );
    });

    test('insufficient digits (123-45-6789) — fails', () {
      expect(
        ValidateString().bizno().validate('123-45-6789'),
        isA<ValidationFailure>(),
      );
    });

    test('123.45.67890 dot-separated — fails', () {
      expect(
        ValidateString().bizno().validate('123.45.67890'),
        isA<ValidationFailure>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // real user input — landline phone patterns
  // ---------------------------------------------------------------------------
  group('real user landline input patterns', () {
    test('02-1234-5678 (Seoul) — passes', () {
      expect(
        ValidateString().koPhone().validate('02-1234-5678'),
        isA<ValidationSuccess>(),
      );
    });

    test('031-123-4567 (Gyeonggi) — passes', () {
      expect(
        ValidateString().koPhone().validate('031-123-4567'),
        isA<ValidationSuccess>(),
      );
    });

    test('mobile 010-1234-5678 as landline — fails', () {
      expect(
        ValidateString().koPhone().validate('010-1234-5678'),
        isA<ValidationFailure>(),
      );
    });

    test('wrong digit count (02-12-5678) — fails', () {
      expect(
        ValidateString().koPhone().validate('02-12-5678'),
        isA<ValidationFailure>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Chaining / interaction tests
  // ---------------------------------------------------------------------------
  group('chaining validators', () {
    test('required + email: null fails at required', () {
      final v = ValidateString().setLabel('Email').required().email();
      final result = v.validate(null) as ValidationFailure;
      expect(result.code, ValidationCode.required);
    });

    test('required + email: invalid email fails at email', () {
      final v = ValidateString().setLabel('Email').required().email();
      final result = v.validate('bad') as ValidationFailure;
      expect(result.code, ValidationCode.emailInvalid);
    });

    test('email + min: min fails even if email passes', () {
      final v = ValidateString().setLabel('Email').email().min(20);
      final result = v.validate('a@b.com') as ValidationFailure;
      expect(result.code, ValidationCode.stringMin);
    });

    test('notBlank + min: notBlank fires first for blank string', () {
      final v = ValidateString().setLabel('X').notBlank().min(10);
      final result = v.validate('   ') as ValidationFailure;
      expect(result.code, ValidationCode.notBlank);
    });

    test('notBlank().required(): required fires first for null input', () {
      final v = ValidateString().setLabel('X').notBlank().required();
      final result = v.validate(null) as ValidationFailure;
      expect(result.code, ValidationCode.required);
    });

    test(
      'required().notBlank(): required fires first for null input regardless of chain order',
      () {
        final v = ValidateString().setLabel('X').required().notBlank();
        final result = v.validate(null) as ValidationFailure;
        expect(result.code, ValidationCode.required);
      },
    );

    test('min + max: passes when within range', () {
      expect(
        ValidateString().min(2).max(5).validate('abc'),
        isA<ValidationSuccess>(),
      );
    });

    test('min + max: fails when below min', () {
      expect(
        ValidateString().min(2).max(5).validate('a'),
        isA<ValidationFailure>(),
      );
    });

    test('min + max: fails when above max', () {
      expect(
        ValidateString().min(2).max(5).validate('toolong'),
        isA<ValidationFailure>(),
      );
    });

    test('alpha + min: short alpha string fails min', () {
      final v = ValidateString().setLabel('Name').alpha().min(5);
      expect(v.validate('ab'), isA<ValidationFailure>());
    });
  });

  group('startsWith()', () {
    test('passes when trimmed value starts with prefix', () {
      expect(
        ValidateString().startsWith('https://').validate('https://example.com'),
        isA<ValidationSuccess>(),
      );
    });
    test('passes when trimmed after leading space starts with prefix', () {
      expect(
        ValidateString()
            .startsWith('https://')
            .validate('  https://example.com'),
        isA<ValidationSuccess>(),
      );
    });
    test('fails when value does not start with prefix', () {
      final r = ValidateString()
          .startsWith('https://')
          .validate('http://example.com');
      expect(r, isA<ValidationFailure>());
      expect((r as ValidationFailure).code, ValidationCode.startsWith);
    });
    test('null passes', () {
      expect(
        ValidateString().startsWith('x').validate(null),
        isA<ValidationSuccess>(),
      );
    });
    test('empty string passes', () {
      expect(
        ValidateString().startsWith('https://').validate(''),
        isA<ValidationSuccess>(),
      );
    });
  });

  group('endsWith()', () {
    test('passes when trimmed value ends with suffix', () {
      expect(
        ValidateString().endsWith('.pdf').validate('report.pdf'),
        isA<ValidationSuccess>(),
      );
    });
    test('fails when value does not end with suffix', () {
      expect(
        ValidateString().endsWith('.pdf').validate('report.doc'),
        isA<ValidationFailure>(),
      );
    });
    test('null passes', () {
      expect(
        ValidateString().endsWith('.pdf').validate(null),
        isA<ValidationSuccess>(),
      );
    });
    test('empty string passes', () {
      expect(
        ValidateString().endsWith('.pdf').validate(''),
        isA<ValidationSuccess>(),
      );
    });
  });

  group('contains()', () {
    test('passes when value contains substring', () {
      expect(
        ValidateString().contains('@').validate('a@b.com'),
        isA<ValidationSuccess>(),
      );
    });
    test('fails when substring absent', () {
      final r = ValidateString().contains('@').validate('notanemail');
      expect(r, isA<ValidationFailure>());
      expect((r as ValidationFailure).code, ValidationCode.stringContains);
    });
    test('does not trim before checking', () {
      expect(
        ValidateString().contains(' word').validate('a word'),
        isA<ValidationSuccess>(),
      );
    });
    test('null passes', () {
      expect(
        ValidateString().contains('@').validate(null),
        isA<ValidationSuccess>(),
      );
    });
    test('empty string passes', () {
      expect(
        ValidateString().contains('@').validate(''),
        isA<ValidationSuccess>(),
      );
    });
  });

  group('ipAddress()', () {
    test('passes valid IPv4', () {
      expect(
        ValidateString().ipAddress().validate('192.168.1.1'),
        isA<ValidationSuccess>(),
      );
    });
    test('passes valid IPv6', () {
      expect(
        ValidateString().ipAddress().validate('::1'),
        isA<ValidationSuccess>(),
      );
    });
    test('fails invalid IP', () {
      final r = ValidateString().ipAddress().validate('999.999.999.999');
      expect(r, isA<ValidationFailure>());
      expect((r as ValidationFailure).code, ValidationCode.ipAddress);
    });
    test('fails IPv4 with leading zeros in octet', () {
      expect(
        ValidateString().ipAddress().validate('192.168.01.1'),
        isA<ValidationFailure>(),
      );
    });
    test('fails IPv4 with all-zero-padded octets', () {
      expect(
        ValidateString().ipAddress().validate('01.001.000.001'),
        isA<ValidationFailure>(),
      );
    });
    test('passes IPv4 with zero octet (0 itself is valid)', () {
      expect(
        ValidateString().ipAddress().validate('0.0.0.0'),
        isA<ValidationSuccess>(),
      );
    });
  });

  group('hexColor()', () {
    test('passes #RGB', () {
      expect(
        ValidateString().hexColor().validate('#FFF'),
        isA<ValidationSuccess>(),
      );
    });
    test('passes #RRGGBB', () {
      expect(
        ValidateString().hexColor().validate('#FF5733'),
        isA<ValidationSuccess>(),
      );
    });
    test('fails without hash', () {
      expect(
        ValidateString().hexColor().validate('FF5733'),
        isA<ValidationFailure>(),
      );
    });
    test('fails invalid length', () {
      expect(
        ValidateString().hexColor().validate('#FF573'),
        isA<ValidationFailure>(),
      );
    });
  });

  group('base64()', () {
    test('passes valid Base64', () {
      expect(
        ValidateString().base64().validate('SGVsbG8='),
        isA<ValidationSuccess>(),
      );
    });

    test('passes valid Base64 with double padding', () {
      expect(
        ValidateString().base64().validate('Zm9v'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes empty string (null-skip equivalent)', () {
      expect(ValidateString().base64().validate(''), isA<ValidationSuccess>());
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().base64().validate(null), isA<ValidationSuccess>());
    });

    test('fails invalid Base64', () {
      expect(
        ValidateString().base64().validate('not base64!!!'),
        isA<ValidationFailure>(),
      );
    });

    test('fails Base64 with invalid character (URL-safe - not supported by default)', () {
      expect(
        ValidateString().base64().validate('SGVs-G8='),
        isA<ValidationFailure>(),
      );
    });

    test('fails Base64 with incorrect padding length', () {
      expect(
        ValidateString().base64().validate('SGVsbG'),
        isA<ValidationFailure>(),
      );
    });

    test('fails Base64 with valid chars but wrong padding position', () {
      expect(
        ValidateString().base64().validate('=SGVsbG8'),
        isA<ValidationFailure>(),
      );
    });
  });

  group('json()', () {
    test('passes valid JSON object', () {
      expect(
        ValidateString().json().validate('{"key":"value"}'),
        isA<ValidationSuccess>(),
      );
    });
    test('passes valid JSON array', () {
      expect(
        ValidateString().json().validate('[1,2,3]'),
        isA<ValidationSuccess>(),
      );
    });
    test('passes primitive JSON ("null", "42", "true")', () {
      expect(
        ValidateString().json().validate('null'),
        isA<ValidationSuccess>(),
      );
      expect(ValidateString().json().validate('42'), isA<ValidationSuccess>());
      expect(
        ValidateString().json().validate('true'),
        isA<ValidationSuccess>(),
      );
    });
    test('fails invalid JSON', () {
      final r = ValidateString().json().validate('{bad json}');
      expect(r, isA<ValidationFailure>());
      expect((r as ValidationFailure).code, ValidationCode.json);
    });
  });

  group('creditCard()', () {
    test('passes valid Visa number (Luhn valid)', () {
      expect(
        ValidateString().creditCard().validate('4532015112830366'),
        isA<ValidationSuccess>(),
      );
    });
    test('fails invalid Luhn number', () {
      expect(
        ValidateString().creditCard().validate('1234567890123456'),
        isA<ValidationFailure>(),
      );
    });
    test('strips spaces before checking', () {
      expect(
        ValidateString().creditCard().validate('4532 0151 1283 0366'),
        isA<ValidationSuccess>(),
      );
    });
  });

  group('koPostalCode()', () {
    test('passes 5-digit Korean postal code', () {
      expect(
        ValidateString().koPostalCode().validate('06000'),
        isA<ValidationSuccess>(),
      );
    });
    test('fails 4-digit code', () {
      expect(
        ValidateString().koPostalCode().validate('0600'),
        isA<ValidationFailure>(),
      );
    });
    test('fails 6-digit code', () {
      expect(
        ValidateString().koPostalCode().validate('060000'),
        isA<ValidationFailure>(),
      );
    });
    test('fails non-digit characters', () {
      final r = ValidateString().koPostalCode().validate('0600A');
      expect(r, isA<ValidationFailure>());
      expect((r as ValidationFailure).code, ValidationCode.koPostalCode);
    });
  });
}
