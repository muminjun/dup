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
      expect(ValidateString().min(3).validate('  a  '), isA<ValidationFailure>());
      expect(ValidateString().min(3).validate('  abc  '), isA<ValidationSuccess>());
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().min(3).validate(null), isA<ValidationSuccess>());
    });

    test('fails for empty string', () {
      expect(ValidateString().min(1).validate(''), isA<ValidationFailure>());
    });

    test('uses messageFactory', () {
      final result = ValidateString()
              .setLabel('이름')
              .min(3, messageFactory: (label, p) => '$label 최소 ${p['min']}자')
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
      expect(
        ValidateString().max(3).validate('abc'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when length > max', () {
      final result = ValidateString().setLabel('Tag').max(2).validate('abc');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.stringMax);
      expect(result.context['max'], 2);
    });

    test('trims before measuring', () {
      expect(ValidateString().max(3).validate('  a  '), isA<ValidationSuccess>());
      expect(ValidateString().max(2).validate('  abc  '), isA<ValidationFailure>());
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().max(5).validate(null), isA<ValidationSuccess>());
    });

    test('passes for empty string', () {
      expect(ValidateString().max(5).validate(''), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result = ValidateString()
              .setLabel('Tag')
              .max(3, messageFactory: (label, p) => '$label 최대 ${p['max']}자')
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
      final result = ValidateString()
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
          ValidateString().setLabel('코드').matches(RegExp(r'^\d+$')).validate('abc')
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
      expect(ValidateString().email().validate('   '), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result = ValidateString()
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
      final result =
          ValidateString().setLabel('PW').password(minLength: 8).validate('short');
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
      final result = ValidateString()
              .setLabel('PW')
              .password(
                minLength: 8,
                messageFactory: (label, p) => '$label 최소 ${p['minLength']}자 필요',
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
      final result = ValidateString().setLabel('Name').emoji().validate('hello😀');
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
      final result = ValidateString()
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
      final result = ValidateString().setLabel('Name').notBlank().validate('   ');
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
      final result = ValidateString()
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
      final result = ValidateString().setLabel('Name').alpha().validate('Hello1');
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
      expect(ValidateString().alpha().validate('   '), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result = ValidateString()
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
      final result =
          ValidateString().setLabel('ID').alphanumeric().validate('hello_world');
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
      final result = ValidateString()
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
      final result = ValidateString().setLabel('Zip').numeric().validate('123ab');
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
      expect(
        ValidateString().numeric().validate(''),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateString()
              .setLabel('Zip')
              .numeric(messageFactory: (label, _) => '$label 숫자만 가능')
              .validate('abc')
          as ValidationFailure;
      expect(result.message, 'Zip 숫자만 가능');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.numeric: (p) => '${p['name']} 숫자 오류',
        }),
      );
      final result =
          ValidateString().setLabel('우편번호').numeric().validate('abc')
              as ValidationFailure;
      expect(result.message, '우편번호 숫자 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // mobile()
  // ---------------------------------------------------------------------------
  group('mobile()', () {
    test('passes for valid 010 format', () {
      expect(
        ValidateString().mobile().validate('010-1234-5678'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for valid 011 format', () {
      expect(
        ValidateString().mobile().validate('011-123-4567'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for missing dashes', () {
      final result =
          ValidateString().setLabel('Phone').mobile().validate('01012345678');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.mobileInvalid);
    });

    test('fails for wrong format', () {
      expect(
        ValidateString().mobile().validate('010-12-34567'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateString().mobile().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty string', () {
      expect(
        ValidateString().mobile().validate(''),
        isA<ValidationSuccess>(),
      );
    });

    test('uses custom regex', () {
      final customRegex = RegExp(r'^\d{10}$');
      expect(
        ValidateString().mobile(customRegex: customRegex).validate('0101234567'),
        isA<ValidationSuccess>(),
      );
      expect(
        ValidateString()
            .mobile(customRegex: customRegex)
            .validate('010-1234-5678'),
        isA<ValidationFailure>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateString()
              .setLabel('Mobile')
              .mobile(messageFactory: (label, _) => '$label 형식 오류')
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
          ValidateString().setLabel('전화번호').mobile().validate('bad')
              as ValidationFailure;
      expect(result.message, '전화번호 번호 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // phone()
  // ---------------------------------------------------------------------------
  group('phone()', () {
    test('passes for valid Seoul landline', () {
      expect(
        ValidateString().phone().validate('02-1234-5678'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for valid 3-digit area code', () {
      expect(
        ValidateString().phone().validate('031-123-4567'),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for invalid format', () {
      final result = ValidateString().setLabel('Phone').phone().validate('02-12-5678');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.phoneInvalid);
    });

    test('fails for mobile number format', () {
      expect(
        ValidateString().phone().validate('010-1234-5678'),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateString().phone().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty string', () {
      expect(
        ValidateString().phone().validate(''),
        isA<ValidationSuccess>(),
      );
    });

    test('uses custom regex', () {
      final customRegex = RegExp(r'^\d{3}-\d{4}$');
      expect(
        ValidateString().phone(customRegex: customRegex).validate('010-1234'),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateString()
              .setLabel('Phone')
              .phone(messageFactory: (label, _) => '$label 유선전화 오류')
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
          ValidateString().setLabel('유선').phone().validate('bad')
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
      final result =
          ValidateString().setLabel('Bizno').bizno().validate('1234567890');
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
      expect(
        ValidateString().bizno().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty string', () {
      expect(
        ValidateString().bizno().validate(''),
        isA<ValidationSuccess>(),
      );
    });

    test('uses custom regex', () {
      final customRegex = RegExp(r'^\d{10}$');
      expect(
        ValidateString().bizno(customRegex: customRegex).validate('1234567890'),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateString()
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
      final result = ValidateString().setLabel('URL').url().validate('ftp://example.com');
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
      final result = ValidateString()
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
        ValidateString().uuid().validate('550e8400-e29b-41d4-a716-446655440000'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for uppercase UUID v4 (case-insensitive)', () {
      expect(
        ValidateString().uuid().validate('550E8400-E29B-41D4-A716-446655440000'),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for mixed-case UUID v4', () {
      expect(
        ValidateString()
            .uuid()
            .validate('550e8400-E29B-41d4-A716-446655440000'),
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
      final result = ValidateString()
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
  // 실제 유저 입력 패턴 — 이메일
  // ---------------------------------------------------------------------------
  group('실제 유저 이메일 입력 패턴', () {
    test('대문자 이메일도 유효하다', () {
      expect(
        ValidateString().email().validate('USER@EXAMPLE.COM'),
        isA<ValidationSuccess>(),
      );
    });

    test('@앞에 공백이 있으면 실패', () {
      expect(
        ValidateString().email().validate('user @example.com'),
        isA<ValidationFailure>(),
      );
    });

    test('@뒤에 공백이 있으면 실패', () {
      expect(
        ValidateString().email().validate('user@ example.com'),
        isA<ValidationFailure>(),
      );
    });

    test('도메인에 점이 연속이면 실패', () {
      expect(
        ValidateString().email().validate('user@example..com'),
        isA<ValidationFailure>(),
      );
    });

    test('@없이 도메인만 입력하면 실패', () {
      expect(
        ValidateString().email().validate('example.com'),
        isA<ValidationFailure>(),
      );
    });

    test('숫자+문자 혼합 이메일은 유효하다', () {
      expect(
        ValidateString().email().validate('hong123@naver.com'),
        isA<ValidationSuccess>(),
      );
    });

    test('점이 포함된 이름도 유효하다', () {
      expect(
        ValidateString().email().validate('hong.gildong@company.co.kr'),
        isA<ValidationSuccess>(),
      );
    });

    test('플러스 태그 이메일도 유효하다 (gmail 등)', () {
      expect(
        ValidateString().email().validate('hong+work@gmail.com'),
        isA<ValidationSuccess>(),
      );
    });

    test('TLD 없이 도메인만 입력하면 실패 (흔한 실수)', () {
      expect(
        ValidateString().email().validate('user@localhost'),
        isA<ValidationFailure>(),
      );
    });

    test('앞뒤 공백은 trim되어 유효하다', () {
      expect(
        ValidateString().email().validate('  hong@naver.com  '),
        isA<ValidationSuccess>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 실제 유저 입력 패턴 — 휴대폰 번호
  // ---------------------------------------------------------------------------
  group('실제 유저 휴대폰 입력 패턴', () {
    test('010-1234-5678 정상 형식', () {
      expect(
        ValidateString().mobile().validate('010-1234-5678'),
        isA<ValidationSuccess>(),
      );
    });

    test('공백으로 구분하면 실패 (010 1234 5678)', () {
      expect(
        ValidateString().mobile().validate('010 1234 5678'),
        isA<ValidationFailure>(),
      );
    });

    test('하이픈 없이 붙여쓰면 실패 (01012345678)', () {
      expect(
        ValidateString().mobile().validate('01012345678'),
        isA<ValidationFailure>(),
      );
    });

    test('마지막 자리 하나 더 입력하면 실패 (010-1234-56789)', () {
      expect(
        ValidateString().mobile().validate('010-1234-56789'),
        isA<ValidationFailure>(),
      );
    });

    test('중간 자리 짧으면 실패 (010-12-5678)', () {
      expect(
        ValidateString().mobile().validate('010-12-5678'),
        isA<ValidationFailure>(),
      );
    });

    test('국제 번호 형식은 기본 정규식 불일치 (+82-10-1234-5678)', () {
      expect(
        ValidateString().mobile().validate('+82-10-1234-5678'),
        isA<ValidationFailure>(),
      );
    });

    test('괄호 사용하면 실패 (010)1234-5678', () {
      expect(
        ValidateString().mobile().validate('010)1234-5678'),
        isA<ValidationFailure>(),
      );
    });

    test('011 구형 번호도 유효하다 (011-123-4567)', () {
      expect(
        ValidateString().mobile().validate('011-123-4567'),
        isA<ValidationSuccess>(),
      );
    });

    test('빈 문자열은 통과 (필수 아닐 때)', () {
      expect(
        ValidateString().mobile().validate(''),
        isA<ValidationSuccess>(),
      );
    });

    test('null도 통과 (필수 아닐 때)', () {
      expect(
        ValidateString().mobile().validate(null),
        isA<ValidationSuccess>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 실제 유저 입력 패턴 — 비밀번호
  // ---------------------------------------------------------------------------
  group('실제 유저 비밀번호 입력 패턴', () {
    test('1234 — 너무 짧음 (기본 최소 4자)', () {
      // 기본 minLength=4이므로 1234는 통과
      expect(
        ValidateString().password().validate('1234'),
        isA<ValidationSuccess>(),
      );
    });

    test('123 — 기본 minLength=4 미만이면 실패', () {
      expect(
        ValidateString().password().validate('123'),
        isA<ValidationFailure>(),
      );
    });

    test('minLength:8 설정 시 password123 통과', () {
      expect(
        ValidateString().password(minLength: 8).validate('password123'),
        isA<ValidationSuccess>(),
      );
    });

    test('minLength:8 설정 시 qwerty 실패 (6자)', () {
      expect(
        ValidateString().password(minLength: 8).validate('qwerty'),
        isA<ValidationFailure>(),
      );
    });

    test('정확히 8자인 경우 통과 (경계값)', () {
      expect(
        ValidateString().password(minLength: 8).validate('abcdefgh'),
        isA<ValidationSuccess>(),
      );
    });

    test('7자인 경우 실패 (경계값 - 1)', () {
      expect(
        ValidateString().password(minLength: 8).validate('abcdefg'),
        isA<ValidationFailure>(),
      );
    });

    test('공백만 있는 비밀번호는 통과 (blank skip)', () {
      expect(
        ValidateString().password(minLength: 8).validate('        '),
        isA<ValidationSuccess>(),
      );
    });

    test('특수문자 포함 비밀번호 통과', () {
      expect(
        ValidateString().password(minLength: 8).validate('P@ssw0rd!'),
        isA<ValidationSuccess>(),
      );
    });

    test('한글 포함 비밀번호 통과 (길이만 검사)', () {
      expect(
        ValidateString().password(minLength: 4).validate('비밀번호1234'),
        isA<ValidationSuccess>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 실제 유저 입력 패턴 — URL
  // ---------------------------------------------------------------------------
  group('실제 유저 URL 입력 패턴', () {
    test('https://naver.com 정상 통과', () {
      expect(
        ValidateString().url().validate('https://naver.com'),
        isA<ValidationSuccess>(),
      );
    });

    test('http://naver.com 정상 통과', () {
      expect(
        ValidateString().url().validate('http://naver.com'),
        isA<ValidationSuccess>(),
      );
    });

    test('프로토콜 없이 www.naver.com 입력하면 실패', () {
      expect(
        ValidateString().url().validate('www.naver.com'),
        isA<ValidationFailure>(),
      );
    });

    test('도메인만 naver.com 입력하면 실패', () {
      expect(
        ValidateString().url().validate('naver.com'),
        isA<ValidationFailure>(),
      );
    });

    test('http:// 만 입력하면 실패', () {
      expect(
        ValidateString().url().validate('http://'),
        isA<ValidationFailure>(),
      );
    });

    test('https:// 만 입력하면 실패', () {
      expect(
        ValidateString().url().validate('https://'),
        isA<ValidationFailure>(),
      );
    });

    test('ftp:// 프로토콜은 실패', () {
      expect(
        ValidateString().url().validate('ftp://files.example.com'),
        isA<ValidationFailure>(),
      );
    });

    test('쿼리스트링 포함 URL 통과', () {
      expect(
        ValidateString().url().validate('https://search.naver.com/search.naver?query=dart'),
        isA<ValidationSuccess>(),
      );
    });

    test('포트 번호 포함 URL 통과', () {
      expect(
        ValidateString().url().validate('http://localhost:8080'),
        isA<ValidationSuccess>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 실제 유저 입력 패턴 — 사업자등록번호
  // ---------------------------------------------------------------------------
  group('실제 유저 사업자등록번호 입력 패턴', () {
    test('123-45-67890 정상 형식 통과', () {
      expect(
        ValidateString().bizno().validate('123-45-67890'),
        isA<ValidationSuccess>(),
      );
    });

    test('하이픈 없이 1234567890 입력하면 실패', () {
      expect(
        ValidateString().bizno().validate('1234567890'),
        isA<ValidationFailure>(),
      );
    });

    test('공백으로 123 45 67890 입력하면 실패', () {
      expect(
        ValidateString().bizno().validate('123 45 67890'),
        isA<ValidationFailure>(),
      );
    });

    test('자릿수 부족하면 실패 (123-45-6789)', () {
      expect(
        ValidateString().bizno().validate('123-45-6789'),
        isA<ValidationFailure>(),
      );
    });

    test('점으로 123.45.67890 입력하면 실패', () {
      expect(
        ValidateString().bizno().validate('123.45.67890'),
        isA<ValidationFailure>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 실제 유저 입력 패턴 — 유선전화
  // ---------------------------------------------------------------------------
  group('실제 유저 유선전화 입력 패턴', () {
    test('02-1234-5678 서울 번호 통과', () {
      expect(
        ValidateString().phone().validate('02-1234-5678'),
        isA<ValidationSuccess>(),
      );
    });

    test('031-123-4567 경기 번호 통과', () {
      expect(
        ValidateString().phone().validate('031-123-4567'),
        isA<ValidationSuccess>(),
      );
    });

    test('휴대폰 번호 010-1234-5678 유선전화 검증 실패', () {
      expect(
        ValidateString().phone().validate('010-1234-5678'),
        isA<ValidationFailure>(),
      );
    });

    test('자릿수 틀리면 실패 (02-12-5678)', () {
      expect(
        ValidateString().phone().validate('02-12-5678'),
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
}
