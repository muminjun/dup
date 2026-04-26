/// Integration tests based on real app form scenarios.
///
/// These tests verify scenario-level behavior — what a real user filling out
/// a form experiences — not individual validator API contracts.
library;

import 'package:dup/dup.dart';
import 'package:test/test.dart';

// Shared helpers used across all scenarios.
ValidationSuccess expectSuccess(ValidationResult r) {
  expect(r, isA<ValidationSuccess>());
  return r as ValidationSuccess;
}

ValidationFailure expectFailure(ValidationResult r) {
  expect(r, isA<ValidationFailure>());
  return r as ValidationFailure;
}

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  // =========================================================================
  // Scenario 1: Sign-up form
  // =========================================================================
  group('Scenario — sign-up form', () {
    final nameValidator = ValidateString()
        .setLabel('이름')
        .required()
        .min(2)
        .max(20);
    final emailValidator = ValidateString().setLabel('이메일').required().email();
    final passwordValidator = ValidateString()
        .setLabel('비밀번호')
        .required()
        .password(minLength: 8);
    final mobileValidator =
        ValidateString().setLabel('휴대폰').required().mobile();
    final agreeValidator = ValidateBool().setLabel('이용약관').required().isTrue();

    group('valid sign-up cases', () {
      test('all fields valid — all pass', () {
        expectSuccess(nameValidator.validate('홍길동'));
        expectSuccess(emailValidator.validate('hong@example.com'));
        expectSuccess(passwordValidator.validate('myP@ssw0rd'));
        expectSuccess(mobileValidator.validate('010-1234-5678'));
        expectSuccess(agreeValidator.validate(true));
      });

      test('name 2 chars (min boundary) — passes', () {
        expectSuccess(nameValidator.validate('김철'));
      });

      test('name 20 chars (max boundary) — passes', () {
        expectSuccess(nameValidator.validate('a' * 20));
      });

      test('English name — passes', () {
        expectSuccess(nameValidator.validate('John Doe'));
      });
    });

    group('name field error cases', () {
      test(
        'whitespace-only name — required passes, min fails (spaces pass required)',
        () {
          // required only blocks empty string; whitespace passes.
          // min(2) measures trimmed length — whitespace trims to 0 chars.
          expectFailure(nameValidator.validate('   '));
        },
      );

      test('name 1 char — min(2) fails', () {
        expectFailure(nameValidator.validate('김'));
      });

      test('name over 21 chars — max(20) fails', () {
        expectFailure(nameValidator.validate('a' * 21));
      });

      test('null name — required fails', () {
        final f = expectFailure(nameValidator.validate(null));
        expect(f.code, ValidationCode.required);
      });

      test('empty string name — required fails', () {
        final f = expectFailure(nameValidator.validate(''));
        expect(f.code, ValidationCode.required);
      });
    });

    group('email field error cases', () {
      test('null email — required fails', () {
        final f = expectFailure(emailValidator.validate(null));
        expect(f.code, ValidationCode.required);
      });

      test('email without @ — fails', () {
        expectFailure(emailValidator.validate('hongexample.com'));
      });

      test('email with space before @ — fails', () {
        expectFailure(emailValidator.validate('hong @example.com'));
      });

      test('email without TLD — fails', () {
        expectFailure(emailValidator.validate('hong@example'));
      });

      test('uppercase email — passes', () {
        expectSuccess(emailValidator.validate('HONG@EXAMPLE.COM'));
      });
    });

    group('password field error cases', () {
      test('7-char password — min(8) fails', () {
        expectFailure(passwordValidator.validate('abcdefg'));
      });

      test('8-char password — passes (boundary)', () {
        expectSuccess(passwordValidator.validate('abcdefgh'));
      });

      test(
        'whitespace-only password — passes (blank skip; required only blocks empty string)',
        () {
          // required blocks empty string only — spaces pass.
          // password() blank-skips whitespace-only strings.
          expectSuccess(passwordValidator.validate('        '));
        },
      );

      test('null password — required fails', () {
        final f = expectFailure(passwordValidator.validate(null));
        expect(f.code, ValidationCode.required);
      });

      test('empty string password — required fails', () {
        final f = expectFailure(passwordValidator.validate(''));
        expect(f.code, ValidationCode.required);
      });
    });

    group('phone field error cases', () {
      test('number without hyphens — fails', () {
        expectFailure(mobileValidator.validate('01012345678'));
      });

      test('space-separated number — fails', () {
        expectFailure(mobileValidator.validate('010 1234 5678'));
      });

      test('null number — required fails', () {
        final f = expectFailure(mobileValidator.validate(null));
        expect(f.code, ValidationCode.required);
      });

      test('empty string number — required fails', () {
        final f = expectFailure(mobileValidator.validate(''));
        expect(f.code, ValidationCode.required);
      });
    });

    group('terms agreement cases', () {
      test('not agreed (false) — isTrue fails', () {
        final f = expectFailure(agreeValidator.validate(false));
        expect(f.code, ValidationCode.boolTrue);
      });

      test('unchecked (null) — required fails', () {
        final f = expectFailure(agreeValidator.validate(null));
        expect(f.code, ValidationCode.required);
      });
    });
  });

  // =========================================================================
  // Scenario 2: Product review form
  // =========================================================================
  group('Scenario — product review form', () {
    final titleValidator = ValidateString()
        .setLabel('제목')
        .required()
        .min(5)
        .max(50);
    final contentValidator = ValidateString()
        .setLabel('내용')
        .required()
        .min(10)
        .max(500);
    final ratingValidator =
        ValidateNumber().setLabel('별점').required().between(1, 5).isInteger();
    final tagValidator =
        ValidateList<String>().setLabel('태그').maxLength(3).hasNoDuplicates();

    group('valid review cases', () {
      test('all fields valid — all pass', () {
        expectSuccess(titleValidator.validate('정말 좋은 상품입니다'));
        expectSuccess(
          contentValidator.validate('배송도 빠르고 품질도 훌륭해요. 재구매 의사 있습니다.'),
        );
        expectSuccess(ratingValidator.validate(5));
        expectSuccess(tagValidator.validate(['배송', '품질']));
      });

      test('no tags — passes (optional field)', () {
        expectSuccess(tagValidator.validate([]));
      });

      test('null tags — passes (optional field)', () {
        expectSuccess(tagValidator.validate(null));
      });
    });

    group('review title error cases', () {
      test('4-char title — min(5) fails', () {
        expectFailure(titleValidator.validate('좋아요'));
      });

      test('null title — required fails', () {
        expectFailure(titleValidator.validate(null));
      });

      test('title over 51 chars — max(50) fails', () {
        expectFailure(titleValidator.validate('가' * 51));
      });
    });

    group('rating error cases', () {
      test('rating 0 — between(1,5) fails', () {
        expectFailure(ratingValidator.validate(0));
      });

      test('rating 6 — between(1,5) fails', () {
        expectFailure(ratingValidator.validate(6));
      });

      test('rating 2.5 — isInteger fails', () {
        expectFailure(ratingValidator.validate(2.5));
      });

      test('null rating — required fails', () {
        expectFailure(ratingValidator.validate(null));
      });
    });

    group('tag error cases', () {
      test('4 tags — maxLength(3) fails', () {
        expectFailure(tagValidator.validate(['a', 'b', 'c', 'd']));
      });

      test('duplicate tags — fails', () {
        expectFailure(tagValidator.validate(['배송', '품질', '배송']));
      });
    });
  });

  // =========================================================================
  // Scenario 3: Restaurant reservation form
  // =========================================================================
  group('Scenario — restaurant reservation form', () {
    final reservationDateValidator = ValidateDateTime()
        .setLabel('예약 날짜')
        .required()
        .isInFuture()
        .max(DateTime.now().add(const Duration(days: 30)));
    final guestCountValidator =
        ValidateNumber().setLabel('인원').required().between(1, 20).isInteger();
    final contactValidator =
        ValidateString().setLabel('연락처').required().mobile();
    final requestValidator = ValidateString().setLabel('요청사항').max(200);

    group('valid reservation cases', () {
      test('tomorrow, 4 guests, valid contact — all pass', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expectSuccess(reservationDateValidator.validate(tomorrow));
        expectSuccess(guestCountValidator.validate(4));
        expectSuccess(contactValidator.validate('010-9999-8888'));
        expectSuccess(requestValidator.validate('창가 자리 부탁드립니다.'));
      });

      test('null special request — passes (optional field)', () {
        expectSuccess(requestValidator.validate(null));
      });

      test('empty special request — passes', () {
        expectSuccess(requestValidator.validate(''));
      });
    });

    group('reservation date error cases', () {
      test('yesterday date — fails', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expectFailure(reservationDateValidator.validate(yesterday));
      });

      test('31 days ahead — max(30 days) fails', () {
        final tooFar = DateTime.now().add(const Duration(days: 31));
        expectFailure(reservationDateValidator.validate(tooFar));
      });

      test('null date — required fails', () {
        expectFailure(reservationDateValidator.validate(null));
      });
    });

    group('guest count error cases', () {
      test('0 guests — between(1,20) fails', () {
        expectFailure(guestCountValidator.validate(0));
      });

      test('21 guests — between(1,20) fails', () {
        expectFailure(guestCountValidator.validate(21));
      });

      test('fractional guest count 1.5 — isInteger fails', () {
        expectFailure(guestCountValidator.validate(1.5));
      });

      test('null — required fails', () {
        expectFailure(guestCountValidator.validate(null));
      });
    });

    group('special request error cases', () {
      test('over 201 chars — max(200) fails', () {
        expectFailure(requestValidator.validate('가' * 201));
      });

      test('200 chars — boundary passes', () {
        expectSuccess(requestValidator.validate('가' * 200));
      });
    });
  });

  // =========================================================================
  // Scenario 4: Business registration form
  // =========================================================================
  group('Scenario — business registration form', () {
    final companyNameValidator = ValidateString()
        .setLabel('상호명')
        .required()
        .min(2)
        .max(30);
    final biznoValidator =
        ValidateString().setLabel('사업자등록번호').required().bizno();
    final phoneValidator =
        ValidateString().setLabel('대표 전화').required().phone();
    final foundedDateValidator =
        ValidateDateTime().setLabel('설립일').required().isInPast();

    group('valid registration cases', () {
      test('all fields valid — all pass', () {
        expectSuccess(companyNameValidator.validate('홍길동주식회사'));
        expectSuccess(biznoValidator.validate('123-45-67890'));
        expectSuccess(phoneValidator.validate('02-1234-5678'));
        expectSuccess(foundedDateValidator.validate(DateTime(2020, 3, 15)));
      });
    });

    group('business number error cases', () {
      test('no hyphens — fails', () {
        expectFailure(biznoValidator.validate('1234567890'));
      });

      test('space-separated — fails', () {
        expectFailure(biznoValidator.validate('123 45 67890'));
      });

      test('dot-separated — fails', () {
        expectFailure(biznoValidator.validate('123.45.67890'));
      });

      test('insufficient digits — fails', () {
        expectFailure(biznoValidator.validate('123-45-6789'));
      });

      test('null — required fails', () {
        expectFailure(biznoValidator.validate(null));
      });
    });

    group('founding date error cases', () {
      test('future founding date — isInPast fails', () {
        final future = DateTime.now().add(const Duration(days: 365));
        expectFailure(foundedDateValidator.validate(future));
      });

      test('null — required fails', () {
        expectFailure(foundedDateValidator.validate(null));
      });
    });
  });

  // =========================================================================
  // Scenario 5: Product listing form (seller)
  // =========================================================================
  group('Scenario — product listing form', () {
    final productNameValidator = ValidateString()
        .setLabel('상품명')
        .required()
        .min(2)
        .max(100);
    final priceValidator =
        ValidateNumber().setLabel('판매가').required().isPositive();
    final stockValidator =
        ValidateNumber().setLabel('재고').required().isNonNegative().isInteger();
    final categoryValidator = ValidateList<String>()
        .setLabel('카테고리')
        .minLength(1)
        .maxLength(3);
    final descriptionValidator = ValidateString()
        .setLabel('상품 설명')
        .required()
        .min(10)
        .max(2000);

    group('valid listing cases', () {
      test('all fields valid — all pass', () {
        expectSuccess(productNameValidator.validate('프리미엄 무선 이어폰'));
        expectSuccess(priceValidator.validate(59900));
        expectSuccess(stockValidator.validate(100));
        expectSuccess(categoryValidator.validate(['전자기기', '음향기기']));
        expectSuccess(
          descriptionValidator.validate('최고 품질의 무선 이어폰입니다. 노이즈 캔슬링 지원.'),
        );
      });

      test('stock 0 — passes (out-of-stock; isNonNegative allows 0)', () {
        expectSuccess(stockValidator.validate(0));
      });

      test('single category — passes', () {
        expectSuccess(categoryValidator.validate(['전자기기']));
      });
    });

    group('product name error cases', () {
      test('1-char product name — min(2) fails', () {
        expectFailure(productNameValidator.validate('A'));
      });

      test('null product name — required fails', () {
        expectFailure(productNameValidator.validate(null));
      });
    });

    group('price error cases', () {
      test('price 0 — isPositive fails (0 not allowed)', () {
        expectFailure(priceValidator.validate(0));
      });

      test('negative price — isPositive fails', () {
        expectFailure(priceValidator.validate(-1));
      });

      test('null price — required fails', () {
        expectFailure(priceValidator.validate(null));
      });
    });

    group('stock error cases', () {
      test('stock -1 — isNonNegative fails', () {
        expectFailure(stockValidator.validate(-1));
      });

      test('fractional stock 1.5 — isInteger fails', () {
        expectFailure(stockValidator.validate(1.5));
      });

      test('null stock — required fails', () {
        expectFailure(stockValidator.validate(null));
      });
    });

    group('category error cases', () {
      test('no categories — minLength(1) fails', () {
        expectFailure(categoryValidator.validate([]));
      });

      test('4 categories — maxLength(3) fails', () {
        expectFailure(categoryValidator.validate(['a', 'b', 'c', 'd']));
      });
    });
  });

  // =========================================================================
  // Scenario 6: Password change form
  // =========================================================================
  group('Scenario — password change form', () {
    final newPwValidator = ValidateString()
        .setLabel('새 비밀번호')
        .required()
        .password(minLength: 8);
    const forbiddenPasswords = [
      '12345678',
      'password',
      'qwerty123',
      '00000000',
    ];
    final notCommonValidator = ValidateString()
        .setLabel('새 비밀번호')
        .excludedFrom(forbiddenPasswords);

    group('valid change cases', () {
      test('sufficient-length new password — passes', () {
        expectSuccess(newPwValidator.validate('Secur3P@ss'));
      });

      test('uncommon password — excludedFrom passes', () {
        expectSuccess(notCommonValidator.validate('Secur3P@ss'));
      });
    });

    group('error cases', () {
      test('7-char password — fails', () {
        expectFailure(newPwValidator.validate('abc1234'));
      });

      test('null — required fails', () {
        expectFailure(newPwValidator.validate(null));
      });

      test('common password "password" — excludedFrom fails', () {
        final f = expectFailure(notCommonValidator.validate('password'));
        expect(f.code, ValidationCode.notOneOf);
      });

      test('common password "12345678" — excludedFrom fails', () {
        expectFailure(notCommonValidator.validate('12345678'));
      });
    });
  });

  // =========================================================================
  // Scenario 7: Async username uniqueness check
  // =========================================================================
  group('Scenario — username uniqueness check (async)', () {
    const takenUsernames = ['admin', 'test', 'user123'];

    ValidateString buildUsernameValidator() => ValidateString()
        .setLabel('유저명')
        .required()
        .min(3)
        .max(20)
        .alphanumeric()
        .addAsyncValidator((username) async {
          await Future<void>.delayed(Duration.zero);
          if (username != null && takenUsernames.contains(username)) {
            return const ValidationFailure(
              code: ValidationCode.custom,
              message: '이미 사용 중인 유저명입니다.',
            );
          }
          return null;
        });

    test('available username — passes', () async {
      final result = await buildUsernameValidator().validateAsync('hong123');
      expect(result, isA<ValidationSuccess>());
    });

    test('already taken "admin" — async fails', () async {
      final result = await buildUsernameValidator().validateAsync('admin');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).message, '이미 사용 중인 유저명입니다.');
    });

    test('already taken "user123" — async fails', () async {
      final result = await buildUsernameValidator().validateAsync('user123');
      expect(result, isA<ValidationFailure>());
    });

    test(
      'null username — sync required fails (does not reach async)',
      () async {
        final result = await buildUsernameValidator().validateAsync(null);
        expect(result, isA<ValidationFailure>());
        expect((result as ValidationFailure).code, ValidationCode.required);
      },
    );

    test(
      '2-char username — sync min(3) fails (does not reach async)',
      () async {
        final result = await buildUsernameValidator().validateAsync('hi');
        expect(result, isA<ValidationFailure>());
        expect((result as ValidationFailure).code, ValidationCode.stringMin);
      },
    );

    test('username with special chars — sync alphanumeric fails', () async {
      final result = await buildUsernameValidator().validateAsync('hong!');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.alphanumeric);
    });
  });

  // =========================================================================
  // Scenario 8: Korean locale error messages
  // =========================================================================
  group('Scenario — Korean locale error messages (ValidatorLocale)', () {
    setUp(() {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.required: (p) => '${p['name']}은(는) 필수 입력 항목입니다.',
          ValidationCode.emailInvalid: (p) => '${p['name']} 형식이 올바르지 않습니다.',
          ValidationCode.stringMin:
              (p) => '${p['name']}은(는) 최소 ${p['min']}자 이상 입력해야 합니다.',
          ValidationCode.stringMax:
              (p) => '${p['name']}은(는) 최대 ${p['max']}자까지 입력할 수 있습니다.',
          ValidationCode.numberMin:
              (p) => '${p['name']}은(는) ${p['min']} 이상이어야 합니다.',
          ValidationCode.passwordMin:
              (p) => '${p['name']}은(는) ${p['minLength']}자 이상이어야 합니다.',
          ValidationCode.mobileInvalid:
              (p) => '${p['name']} 형식이 올바르지 않습니다. (예: 010-1234-5678)',
          ValidationCode.boolTrue: (p) => '${p['name']}에 동의해 주세요.',
        }),
      );
    });

    test('email not entered — Korean required message', () {
      final result =
          ValidateString().setLabel('이메일').required().validate(null)
              as ValidationFailure;
      expect(result.message, '이메일은(는) 필수 입력 항목입니다.');
    });

    test('invalid email format — Korean emailInvalid message', () {
      final result =
          ValidateString().setLabel('이메일').email().validate('bad')
              as ValidationFailure;
      expect(result.message, '이메일 형식이 올바르지 않습니다.');
    });

    test('name too short — Korean stringMin message', () {
      final result =
          ValidateString().setLabel('이름').min(2).validate('A')
              as ValidationFailure;
      expect(result.message, '이름은(는) 최소 2자 이상 입력해야 합니다.');
    });

    test('password too short — Korean passwordMin message', () {
      final result =
          ValidateString()
                  .setLabel('비밀번호')
                  .password(minLength: 8)
                  .validate('abc')
              as ValidationFailure;
      expect(result.message, '비밀번호은(는) 8자 이상이어야 합니다.');
    });

    test('terms not agreed — Korean boolTrue message', () {
      final result =
          ValidateBool().setLabel('이용약관').isTrue().validate(false)
              as ValidationFailure;
      expect(result.message, '이용약관에 동의해 주세요.');
    });

    test(
      'invalid mobile format — Korean mobileInvalid message with example',
      () {
        final result =
            ValidateString().setLabel('휴대폰').mobile().validate('01012345678')
                as ValidationFailure;
        expect(result.message, contains('010-1234-5678'));
      },
    );

    test('age out of range — Korean numberMin message', () {
      final result =
          ValidateNumber().setLabel('나이').min(0).validate(-1)
              as ValidationFailure;
      expect(result.message, '나이은(는) 0 이상이어야 합니다.');
    });

    test('after locale reset — English default message restored', () {
      ValidatorLocale.resetLocale();
      final result =
          ValidateString().setLabel('Email').required().validate(null)
              as ValidationFailure;
      expect(result.message, 'Email is required.');
    });
  });
}
