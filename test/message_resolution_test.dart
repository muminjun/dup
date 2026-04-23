// Tests for the 3-level error message priority system:
//   1. messageFactory argument (per-call override)
//   2. ValidatorLocale.current (global locale)
//   3. Hardcoded default English message
//
// Every validator method that accepts messageFactory has an inline locale
// lookup, so each must be exercised in both override modes to reach 100%
// line coverage.

import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  // ─── BaseValidator — getErrorMessage() branches ──────────────────────────

  group('BaseValidator.satisfy — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateString()
          .setLabel('X')
          .satisfy((s) => s == 'ok',
              messageFactory: (label, _) => 'custom: $label failed');
      expect(v.validate('bad'), equals('custom: X failed'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {'condition': (args) => '${args['name']} 조건 불일치'},
        string: {}, number: {}, array: {},
      ));
      expect(
        ValidateString().setLabel('X').satisfy((s) => false).validate('x'),
        equals('X 조건 불일치'),
      );
    });
  });

  group('BaseValidator.required — messageFactory', () {
    test('messageFactory override', () {
      final v = ValidateString()
          .setLabel('이름')
          .required(messageFactory: (label, _) => '$label을 입력하세요');
      expect(v.validate(null), equals('이름을 입력하세요'));
    });
  });

  // ─── ValidateString ───────────────────────────────────────────────────────

  group('ValidateString.min — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateString().setLabel('X').min(5,
          messageFactory: (label, args) => 'factory: ${args['min']}');
      expect(v.validate('ab'), equals('factory: 5'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {'min': (args) => '${args['name']} 최소 ${args['min']}자'},
        number: {}, array: {},
      ));
      expect(ValidateString().setLabel('X').min(5).validate('ab'), contains('최소'));
    });
  });

  group('ValidateString.max — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateString().setLabel('X').max(2,
          messageFactory: (label, args) => 'factory: ${args['max']}');
      expect(v.validate('toolong'), equals('factory: 2'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {'max': (args) => '최대 ${args['max']}자'},
        number: {}, array: {},
      ));
      expect(ValidateString().setLabel('X').max(2).validate('toolong'), contains('최대'));
    });
  });

  group('ValidateString.matches — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateString().setLabel('X').matches(RegExp(r'^\d+$'),
          messageFactory: (label, _) => 'factory: invalid');
      expect(v.validate('abc'), equals('factory: invalid'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {'matches': (args) => '형식 불일치'},
        number: {}, array: {},
      ));
      expect(
          ValidateString().setLabel('X').matches(RegExp(r'^\d+$')).validate('abc'),
          equals('형식 불일치'));
    });
  });

  group('ValidateString.email — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateString()
          .setLabel('Email')
          .email(messageFactory: (label, _) => 'factory: bad email');
      expect(v.validate('not-email'), equals('factory: bad email'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {'emailInvalid': (args) => '이메일 형식 오류'},
        number: {}, array: {},
      ));
      expect(ValidateString().setLabel('Email').email().validate('bad'), equals('이메일 형식 오류'));
    });
  });

  group('ValidateString.password — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateString().setLabel('PW').password(
          minLength: 8, messageFactory: (label, args) => 'factory: ${args['minLength']}');
      expect(v.validate('short'), equals('factory: 8'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {'passwordMin': (args) => '비밀번호 최소 ${args['minLength']}자'},
        number: {}, array: {},
      ));
      expect(
          ValidateString().setLabel('PW').password(minLength: 8).validate('short'),
          contains('비밀번호'));
    });
  });

  group('ValidateString.emoji — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateString()
          .setLabel('X')
          .emoji(messageFactory: (label, _) => 'factory: no emoji');
      expect(v.validate('hi 😀'), equals('factory: no emoji'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {'emoji': (args) => '이모지 사용 불가'},
        number: {}, array: {},
      ));
      expect(ValidateString().setLabel('X').emoji().validate('hi 😀'), equals('이모지 사용 불가'));
    });
  });

  group('ValidateString.mobile — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateString()
          .setLabel('Phone')
          .mobile(messageFactory: (label, _) => 'factory: bad mobile');
      expect(v.validate('12345'), equals('factory: bad mobile'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {'mobileInvalid': (args) => '휴대폰 형식 오류'},
        number: {}, array: {},
      ));
      expect(ValidateString().setLabel('Phone').mobile().validate('12345'), equals('휴대폰 형식 오류'));
    });
  });

  group('ValidateString.phone — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateString()
          .setLabel('Phone')
          .phone(messageFactory: (label, _) => 'factory: bad phone');
      expect(v.validate('12345'), equals('factory: bad phone'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {'phoneInvalid': (args) => '전화 형식 오류'},
        number: {}, array: {},
      ));
      expect(ValidateString().setLabel('Phone').phone().validate('12345'), equals('전화 형식 오류'));
    });
  });

  group('ValidateString.bizno — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateString()
          .setLabel('BRN')
          .bizno(messageFactory: (label, _) => 'factory: bad bizno');
      expect(v.validate('12345'), equals('factory: bad bizno'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {'biznoInvalid': (args) => '사업자번호 형식 오류'},
        number: {}, array: {},
      ));
      expect(ValidateString().setLabel('BRN').bizno().validate('12345'), equals('사업자번호 형식 오류'));
    });
  });

  group('ValidateString.url — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateString()
          .setLabel('URL')
          .url(messageFactory: (label, _) => 'factory: bad url');
      expect(v.validate('not-a-url'), equals('factory: bad url'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {'url': (args) => 'URL 형식 오류'},
        number: {}, array: {},
      ));
      expect(ValidateString().setLabel('URL').url().validate('not-a-url'), equals('URL 형식 오류'));
    });
  });

  group('ValidateString.uuid — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateString()
          .setLabel('ID')
          .uuid(messageFactory: (label, _) => 'factory: bad uuid');
      expect(v.validate('not-uuid'), equals('factory: bad uuid'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {'uuid': (args) => 'UUID 형식 오류'},
        number: {}, array: {},
      ));
      expect(ValidateString().setLabel('ID').uuid().validate('not-uuid'), equals('UUID 형식 오류'));
    });
  });

  // ─── ValidateNumber ───────────────────────────────────────────────────────

  group('ValidateNumber.min — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateNumber().setLabel('N').min(5,
          messageFactory: (label, args) => 'factory: ${args['min']}');
      expect(v.validate(1), equals('factory: 5'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {'min': (args) => '최소 ${args['min']}'},
        array: {},
      ));
      expect(ValidateNumber().setLabel('N').min(5).validate(1), contains('최소'));
    });
  });

  group('ValidateNumber.max — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateNumber().setLabel('N').max(5,
          messageFactory: (label, args) => 'factory: ${args['max']}');
      expect(v.validate(10), equals('factory: 5'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {'max': (args) => '최대 ${args['max']}'},
        array: {},
      ));
      expect(ValidateNumber().setLabel('N').max(5).validate(10), contains('최대'));
    });
  });

  group('ValidateNumber.isInteger — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateNumber()
          .setLabel('N')
          .isInteger(messageFactory: (label, _) => 'factory: not int');
      expect(v.validate(1.5), equals('factory: not int'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {'integer': (args) => '정수만 허용'},
        array: {},
      ));
      expect(ValidateNumber().setLabel('N').isInteger().validate(1.5), equals('정수만 허용'));
    });
  });

  group('ValidateNumber.isPositive — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateNumber()
          .setLabel('N')
          .isPositive(messageFactory: (label, _) => 'factory: must be positive');
      expect(v.validate(0), equals('factory: must be positive'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {'positive': (args) => '양수 입력 필요'},
        array: {},
      ));
      expect(ValidateNumber().setLabel('N').isPositive().validate(0), equals('양수 입력 필요'));
    });
  });

  group('ValidateNumber.isNegative — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateNumber()
          .setLabel('N')
          .isNegative(messageFactory: (label, _) => 'factory: must be negative');
      expect(v.validate(1), equals('factory: must be negative'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {'negative': (args) => '음수 입력 필요'},
        array: {},
      ));
      expect(ValidateNumber().setLabel('N').isNegative().validate(1), equals('음수 입력 필요'));
    });
  });

  group('ValidateNumber.isNonNegative — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateNumber()
          .setLabel('N')
          .isNonNegative(messageFactory: (label, _) => 'factory: non-negative');
      expect(v.validate(-1), equals('factory: non-negative'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {'nonNegative': (args) => '0 이상 입력'},
        array: {},
      ));
      expect(ValidateNumber().setLabel('N').isNonNegative().validate(-1), equals('0 이상 입력'));
    });
  });

  group('ValidateNumber.isNonPositive — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateNumber()
          .setLabel('N')
          .isNonPositive(messageFactory: (label, _) => 'factory: non-positive');
      expect(v.validate(1), equals('factory: non-positive'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {'nonPositive': (args) => '0 이하 입력'},
        array: {},
      ));
      expect(ValidateNumber().setLabel('N').isNonPositive().validate(1), equals('0 이하 입력'));
    });
  });

  // ─── ValidateList ─────────────────────────────────────────────────────────

  group('ValidateList.isNotEmpty — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateList<int>().setLabel('L')
          .isNotEmpty(messageFactory: (label, _) => 'factory: empty');
      expect(v.validate([]), equals('factory: empty'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {},
        array: {'notEmpty': (args) => '비어있음 안됨'},
      ));
      expect(ValidateList<int>().setLabel('L').isNotEmpty().validate([]), equals('비어있음 안됨'));
    });
  });

  group('ValidateList.isEmpty — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateList<int>().setLabel('L')
          .isEmpty(messageFactory: (label, _) => 'factory: not empty');
      expect(v.validate([1]), equals('factory: not empty'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {},
        array: {'empty': (args) => '비어야 함'},
      ));
      expect(ValidateList<int>().setLabel('L').isEmpty().validate([1]), equals('비어야 함'));
    });
  });

  group('ValidateList.minLength — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateList<int>().setLabel('L').minLength(3,
          messageFactory: (label, args) => 'factory: ${args['min']}');
      expect(v.validate([1]), equals('factory: 3'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {},
        array: {'min': (args) => '최소 ${args['min']}개'},
      ));
      expect(ValidateList<int>().setLabel('L').minLength(3).validate([1]), contains('최소'));
    });
  });

  group('ValidateList.maxLength — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateList<int>().setLabel('L').maxLength(1,
          messageFactory: (label, args) => 'factory: ${args['max']}');
      expect(v.validate([1, 2, 3]), equals('factory: 1'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {},
        array: {'max': (args) => '최대 ${args['max']}개'},
      ));
      expect(ValidateList<int>().setLabel('L').maxLength(1).validate([1, 2, 3]), contains('최대'));
    });
  });

  group('ValidateList.lengthBetween — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateList<int>().setLabel('L').lengthBetween(2, 4,
          messageFactory: (label, args) => 'factory: ${args['min']}-${args['max']}');
      expect(v.validate([1]), equals('factory: 2-4'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {},
        array: {'lengthBetween': (args) => '${args['min']}~${args['max']}개'},
      ));
      expect(
          ValidateList<int>().setLabel('L').lengthBetween(2, 4).validate([1]), contains('~'));
    });
  });

  group('ValidateList.hasLength — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateList<int>().setLabel('L').hasLength(3,
          messageFactory: (label, args) => 'factory: ${args['length']}');
      expect(v.validate([1]), equals('factory: 3'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {},
        array: {'exactLength': (args) => '정확히 ${args['length']}개'},
      ));
      expect(ValidateList<int>().setLabel('L').hasLength(3).validate([1]), contains('정확히'));
    });
  });

  group('ValidateList.contains — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateList<int>().setLabel('L').contains(5,
          messageFactory: (label, args) => 'factory: ${args['item']}');
      expect(v.validate([1, 2]), equals('factory: 5'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {},
        array: {'contains': (args) => '${args['item']} 포함 필요'},
      ));
      expect(ValidateList<int>().setLabel('L').contains(5).validate([1]), contains('포함'));
    });
  });

  group('ValidateList.doesNotContain — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateList<int>().setLabel('L').doesNotContain(5,
          messageFactory: (label, args) => 'factory: ${args['item']}');
      expect(v.validate([5, 6]), equals('factory: 5'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {},
        array: {'doesNotContain': (args) => '${args['item']} 포함 불가'},
      ));
      expect(
          ValidateList<int>().setLabel('L').doesNotContain(5).validate([5]), contains('포함 불가'));
    });
  });

  group('ValidateList.all — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateList<int>().setLabel('L')
          .all((x) => x > 0, messageFactory: (label, _) => 'factory: all fail');
      expect(v.validate([1, -1]), equals('factory: all fail'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {},
        array: {'allCondition': (args) => '모든 항목 조건 불일치'},
      ));
      expect(
          ValidateList<int>().setLabel('L').all((x) => x > 0).validate([1, -1]),
          equals('모든 항목 조건 불일치'));
    });
  });

  group('ValidateList.any — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateList<int>().setLabel('L')
          .any((x) => x > 10, messageFactory: (label, _) => 'factory: any fail');
      expect(v.validate([1, 2]), equals('factory: any fail'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {},
        array: {'anyCondition': (args) => '조건 만족 항목 없음'},
      ));
      expect(
          ValidateList<int>().setLabel('L').any((x) => x > 10).validate([1, 2]),
          equals('조건 만족 항목 없음'));
    });
  });

  group('ValidateList.hasNoDuplicates — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateList<int>().setLabel('L')
          .hasNoDuplicates(messageFactory: (label, _) => 'factory: duplicates');
      expect(v.validate([1, 1]), equals('factory: duplicates'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {},
        array: {'noDuplicates': (args) => '중복 불가'},
      ));
      expect(ValidateList<int>().setLabel('L').hasNoDuplicates().validate([1, 1]), equals('중복 불가'));
    });
  });

  group('ValidateList.eachItem — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateList<int>().setLabel('L').eachItem(
        (x) => x < 0 ? 'negative' : null,
        messageFactory: (label, args) => 'factory: index ${args['index']}',
      );
      expect(v.validate([1, -1]), equals('factory: index 1'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {},
        array: {'eachItem': (args) => '항목 ${args['index']} 오류: ${args['error']}'},
      ));
      final v = ValidateList<int>().setLabel('L').eachItem((x) => x < 0 ? 'neg' : null);
      expect(v.validate([1, -1]), contains('항목 1'));
    });
  });

  // ─── ValidateBool ─────────────────────────────────────────────────────────

  group('ValidateBool.isTrue — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateBool()
          .setLabel('Flag')
          .isTrue(messageFactory: (label, _) => 'factory: must be true');
      expect(v.validate(false), equals('factory: must be true'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {}, array: {},
        boolMessages: {'isTrue': (args) => '${args['name']} 체크 필요'},
      ));
      expect(ValidateBool().setLabel('동의').isTrue().validate(false), equals('동의 체크 필요'));
    });
  });

  group('ValidateBool.isFalse — messageFactory and locale', () {
    test('messageFactory override', () {
      final v = ValidateBool()
          .setLabel('Flag')
          .isFalse(messageFactory: (label, _) => 'factory: must be false');
      expect(v.validate(true), equals('factory: must be false'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {}, array: {},
        boolMessages: {'isFalse': (args) => '${args['name']} false 필요'},
      ));
      expect(ValidateBool().setLabel('Flag').isFalse().validate(true), equals('Flag false 필요'));
    });
  });

  // ─── ValidateDateTime ─────────────────────────────────────────────────────

  group('ValidateDateTime.isBefore — messageFactory and locale', () {
    final target = DateTime(2024, 6, 15);

    test('messageFactory override', () {
      final v = ValidateDateTime().setLabel('D')
          .isBefore(target, messageFactory: (label, _) => 'factory: too late');
      expect(v.validate(DateTime(2024, 6, 20)), equals('factory: too late'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {}, array: {},
        date: {'before': (args) => '${args['name']} 이전이어야 함'},
      ));
      expect(
          ValidateDateTime().setLabel('날짜').isBefore(target).validate(DateTime(2024, 6, 20)),
          equals('날짜 이전이어야 함'));
    });
  });

  group('ValidateDateTime.isAfter — messageFactory and locale', () {
    final target = DateTime(2024, 6, 15);

    test('messageFactory override', () {
      final v = ValidateDateTime().setLabel('D')
          .isAfter(target, messageFactory: (label, _) => 'factory: too early');
      expect(v.validate(DateTime(2024, 6, 10)), equals('factory: too early'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {}, array: {},
        date: {'after': (args) => '${args['name']} 이후이어야 함'},
      ));
      expect(
          ValidateDateTime().setLabel('날짜').isAfter(target).validate(DateTime(2024, 6, 10)),
          equals('날짜 이후이어야 함'));
    });
  });

  group('ValidateDateTime.min — messageFactory and locale', () {
    final min = DateTime(2024, 6, 15);

    test('messageFactory override', () {
      final v = ValidateDateTime().setLabel('D')
          .min(min, messageFactory: (label, _) => 'factory: too early');
      expect(v.validate(DateTime(2024, 6, 10)), equals('factory: too early'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {}, array: {},
        date: {'min': (args) => '${args['name']} 최소일 오류'},
      ));
      expect(
          ValidateDateTime().setLabel('날짜').min(min).validate(DateTime(2024, 6, 10)),
          equals('날짜 최소일 오류'));
    });
  });

  group('ValidateDateTime.max — messageFactory and locale', () {
    final max = DateTime(2024, 6, 15);

    test('messageFactory override', () {
      final v = ValidateDateTime().setLabel('D')
          .max(max, messageFactory: (label, _) => 'factory: too late');
      expect(v.validate(DateTime(2024, 6, 20)), equals('factory: too late'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {}, array: {},
        date: {'max': (args) => '${args['name']} 최대일 오류'},
      ));
      expect(
          ValidateDateTime().setLabel('날짜').max(max).validate(DateTime(2024, 6, 20)),
          equals('날짜 최대일 오류'));
    });
  });

  group('ValidateDateTime.between — messageFactory and locale', () {
    final min = DateTime(2024, 6, 10);
    final max = DateTime(2024, 6, 20);

    test('messageFactory override', () {
      final v = ValidateDateTime().setLabel('D')
          .between(min, max, messageFactory: (label, _) => 'factory: out of range');
      expect(v.validate(DateTime(2024, 1, 1)), equals('factory: out of range'));
    });

    test('locale override', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {}, array: {},
        date: {'between': (args) => '${args['name']} 범위 벗어남'},
      ));
      expect(
          ValidateDateTime().setLabel('날짜').between(min, max).validate(DateTime(2024, 1, 1)),
          equals('날짜 범위 벗어남'));
    });
  });
}
