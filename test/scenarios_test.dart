/// 실제 앱 폼 시나리오 기반 통합 테스트
///
/// 개별 validator API 검증이 아닌, 실제 유저가 폼을 채울 때
/// 발생하는 케이스들을 시나리오 단위로 검증합니다.
library;

import 'package:dup/dup.dart';
import 'package:test/test.dart';

// 각 시나리오에서 공통으로 쓰는 헬퍼
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
  // 시나리오 1: 회원가입 폼
  // =========================================================================
  group('시나리오 — 회원가입 폼', () {
    final nameValidator = ValidateString().setLabel('이름').required().min(2).max(20);
    final emailValidator = ValidateString().setLabel('이메일').required().email();
    final passwordValidator =
        ValidateString().setLabel('비밀번호').required().password(minLength: 8);
    final mobileValidator = ValidateString().setLabel('휴대폰').required().mobile();
    final agreeValidator = ValidateBool().setLabel('이용약관').required().isTrue();

    group('정상 가입 케이스', () {
      test('모든 필드 정상 입력 — 전부 통과', () {
        expectSuccess(nameValidator.validate('홍길동'));
        expectSuccess(emailValidator.validate('hong@example.com'));
        expectSuccess(passwordValidator.validate('myP@ssw0rd'));
        expectSuccess(mobileValidator.validate('010-1234-5678'));
        expectSuccess(agreeValidator.validate(true));
      });

      test('이름 2자(최소) — 통과', () {
        expectSuccess(nameValidator.validate('김철'));
      });

      test('이름 20자(최대) — 통과', () {
        expectSuccess(nameValidator.validate('a' * 20));
      });

      test('영문 이름 — 통과', () {
        expectSuccess(nameValidator.validate('John Doe'));
      });
    });

    group('이름 필드 오류 케이스', () {
      test('이름 공백만 — required 통과, min 실패 (공백은 required 통과)', () {
        // required는 빈 문자열만 실패, 공백은 통과
        // min(2)는 trim 후 길이 검사 → 공백은 1자 미만
        expectFailure(nameValidator.validate('   '));
      });

      test('이름 1자 — min(2) 실패', () {
        expectFailure(nameValidator.validate('김'));
      });

      test('이름 21자 초과 — max(20) 실패', () {
        expectFailure(nameValidator.validate('a' * 21));
      });

      test('이름 null — required 실패', () {
        final f = expectFailure(nameValidator.validate(null));
        expect(f.code, ValidationCode.required);
      });

      test('이름 빈 문자열 — required 실패', () {
        final f = expectFailure(nameValidator.validate(''));
        expect(f.code, ValidationCode.required);
      });
    });

    group('이메일 필드 오류 케이스', () {
      test('이메일 null — required 실패', () {
        final f = expectFailure(emailValidator.validate(null));
        expect(f.code, ValidationCode.required);
      });

      test('@없는 이메일 — 실패', () {
        expectFailure(emailValidator.validate('hongexample.com'));
      });

      test('@앞 공백 포함 — 실패', () {
        expectFailure(emailValidator.validate('hong @example.com'));
      });

      test('TLD 없는 이메일 — 실패', () {
        expectFailure(emailValidator.validate('hong@example'));
      });

      test('대문자 이메일 — 통과', () {
        expectSuccess(emailValidator.validate('HONG@EXAMPLE.COM'));
      });
    });

    group('비밀번호 필드 오류 케이스', () {
      test('7자 비밀번호 — min(8) 실패', () {
        expectFailure(passwordValidator.validate('abcdefg'));
      });

      test('8자 비밀번호 — 통과 (경계값)', () {
        expectSuccess(passwordValidator.validate('abcdefgh'));
      });

      test('공백만 있는 비밀번호 — blank skip이라 통과, required 없으면', () {
        // passwordValidator에 required가 있으므로:
        // required는 빈 문자열만 막음 — 공백 문자는 통과
        // password()는 blank skip이라 공백 통과
        expectSuccess(passwordValidator.validate('        '));
      });

      test('null 비밀번호 — required 실패', () {
        final f = expectFailure(passwordValidator.validate(null));
        expect(f.code, ValidationCode.required);
      });

      test('빈 문자열 비밀번호 — required 실패', () {
        final f = expectFailure(passwordValidator.validate(''));
        expect(f.code, ValidationCode.required);
      });
    });

    group('휴대폰 필드 오류 케이스', () {
      test('하이픈 없는 번호 — 실패', () {
        expectFailure(mobileValidator.validate('01012345678'));
      });

      test('공백 구분 번호 — 실패', () {
        expectFailure(mobileValidator.validate('010 1234 5678'));
      });

      test('null 번호 — required 실패', () {
        final f = expectFailure(mobileValidator.validate(null));
        expect(f.code, ValidationCode.required);
      });

      test('빈 문자열 번호 — required 실패', () {
        final f = expectFailure(mobileValidator.validate(''));
        expect(f.code, ValidationCode.required);
      });
    });

    group('이용약관 동의 케이스', () {
      test('동의하지 않음(false) — isTrue 실패', () {
        final f = expectFailure(agreeValidator.validate(false));
        expect(f.code, ValidationCode.boolTrue);
      });

      test('체크 안 함(null) — required 실패', () {
        final f = expectFailure(agreeValidator.validate(null));
        expect(f.code, ValidationCode.required);
      });
    });
  });

  // =========================================================================
  // 시나리오 2: 상품 리뷰 작성 폼
  // =========================================================================
  group('시나리오 — 상품 리뷰 작성', () {
    final titleValidator =
        ValidateString().setLabel('제목').required().min(5).max(50);
    final contentValidator =
        ValidateString().setLabel('내용').required().min(10).max(500);
    final ratingValidator =
        ValidateNumber().setLabel('별점').required().between(1, 5).isInteger();
    final tagValidator =
        ValidateList<String>().setLabel('태그').maxLength(3).hasNoDuplicates();

    group('정상 리뷰 케이스', () {
      test('모든 필드 정상 — 전부 통과', () {
        expectSuccess(titleValidator.validate('정말 좋은 상품입니다'));
        expectSuccess(contentValidator.validate('배송도 빠르고 품질도 훌륭해요. 재구매 의사 있습니다.'));
        expectSuccess(ratingValidator.validate(5));
        expectSuccess(tagValidator.validate(['배송', '품질']));
      });

      test('태그 없이도 통과 (선택 항목)', () {
        expectSuccess(tagValidator.validate([]));
      });

      test('태그 null도 통과 (선택 항목)', () {
        expectSuccess(tagValidator.validate(null));
      });
    });

    group('리뷰 제목 오류 케이스', () {
      test('제목 4자 — min(5) 실패', () {
        expectFailure(titleValidator.validate('좋아요'));
      });

      test('제목 null — required 실패', () {
        expectFailure(titleValidator.validate(null));
      });

      test('제목 51자 초과 — max(50) 실패', () {
        expectFailure(titleValidator.validate('가' * 51));
      });
    });

    group('별점 오류 케이스', () {
      test('별점 0점 — between(1,5) 실패', () {
        expectFailure(ratingValidator.validate(0));
      });

      test('별점 6점 — between(1,5) 실패', () {
        expectFailure(ratingValidator.validate(6));
      });

      test('별점 2.5점 — isInteger 실패', () {
        expectFailure(ratingValidator.validate(2.5));
      });

      test('별점 null — required 실패', () {
        expectFailure(ratingValidator.validate(null));
      });
    });

    group('태그 오류 케이스', () {
      test('태그 4개 입력 — maxLength(3) 실패', () {
        expectFailure(tagValidator.validate(['a', 'b', 'c', 'd']));
      });

      test('중복 태그 입력 — 실패', () {
        expectFailure(tagValidator.validate(['배송', '품질', '배송']));
      });
    });
  });

  // =========================================================================
  // 시나리오 3: 식당 예약 폼
  // =========================================================================
  group('시나리오 — 식당 예약 폼', () {
    final reservationDateValidator = ValidateDateTime()
        .setLabel('예약 날짜')
        .required()
        .isInFuture()
        .max(DateTime.now().add(const Duration(days: 30)));
    final guestCountValidator =
        ValidateNumber().setLabel('인원').required().between(1, 20).isInteger();
    final contactValidator =
        ValidateString().setLabel('연락처').required().mobile();
    final requestValidator =
        ValidateString().setLabel('요청사항').max(200);

    group('정상 예약 케이스', () {
      test('내일 날짜, 4명, 정상 연락처 — 전부 통과', () {
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        expectSuccess(reservationDateValidator.validate(tomorrow));
        expectSuccess(guestCountValidator.validate(4));
        expectSuccess(contactValidator.validate('010-9999-8888'));
        expectSuccess(requestValidator.validate('창가 자리 부탁드립니다.'));
      });

      test('요청사항 null이어도 통과 (선택 항목)', () {
        expectSuccess(requestValidator.validate(null));
      });

      test('요청사항 빈 문자열도 통과', () {
        expectSuccess(requestValidator.validate(''));
      });
    });

    group('예약 날짜 오류 케이스', () {
      test('어제 날짜 예약 — 실패', () {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        expectFailure(reservationDateValidator.validate(yesterday));
      });

      test('31일 후 예약 — max(30일) 실패', () {
        final tooFar = DateTime.now().add(const Duration(days: 31));
        expectFailure(reservationDateValidator.validate(tooFar));
      });

      test('날짜 null — required 실패', () {
        expectFailure(reservationDateValidator.validate(null));
      });
    });

    group('인원 오류 케이스', () {
      test('0명 — between(1,20) 실패', () {
        expectFailure(guestCountValidator.validate(0));
      });

      test('21명 — between(1,20) 실패', () {
        expectFailure(guestCountValidator.validate(21));
      });

      test('소수 인원 1.5명 — isInteger 실패', () {
        expectFailure(guestCountValidator.validate(1.5));
      });

      test('null — required 실패', () {
        expectFailure(guestCountValidator.validate(null));
      });
    });

    group('요청사항 오류 케이스', () {
      test('201자 이상 요청사항 — max(200) 실패', () {
        expectFailure(requestValidator.validate('가' * 201));
      });

      test('200자 요청사항 — 경계값 통과', () {
        expectSuccess(requestValidator.validate('가' * 200));
      });
    });
  });

  // =========================================================================
  // 시나리오 4: 사업자 등록 폼
  // =========================================================================
  group('시나리오 — 사업자 등록 폼', () {
    final companyNameValidator =
        ValidateString().setLabel('상호명').required().min(2).max(30);
    final biznoValidator =
        ValidateString().setLabel('사업자등록번호').required().bizno();
    final phoneValidator =
        ValidateString().setLabel('대표 전화').required().phone();
    final foundedDateValidator = ValidateDateTime()
        .setLabel('설립일')
        .required()
        .isInPast();

    group('정상 등록 케이스', () {
      test('모든 필드 정상 — 전부 통과', () {
        expectSuccess(companyNameValidator.validate('홍길동주식회사'));
        expectSuccess(biznoValidator.validate('123-45-67890'));
        expectSuccess(phoneValidator.validate('02-1234-5678'));
        expectSuccess(foundedDateValidator.validate(DateTime(2020, 3, 15)));
      });
    });

    group('사업자등록번호 오류 케이스', () {
      test('하이픈 없이 입력 — 실패', () {
        expectFailure(biznoValidator.validate('1234567890'));
      });

      test('공백으로 구분 — 실패', () {
        expectFailure(biznoValidator.validate('123 45 67890'));
      });

      test('점으로 구분 — 실패', () {
        expectFailure(biznoValidator.validate('123.45.67890'));
      });

      test('자릿수 부족 — 실패', () {
        expectFailure(biznoValidator.validate('123-45-6789'));
      });

      test('null — required 실패', () {
        expectFailure(biznoValidator.validate(null));
      });
    });

    group('설립일 오류 케이스', () {
      test('미래 설립일 — isInPast 실패', () {
        final future = DateTime.now().add(const Duration(days: 365));
        expectFailure(foundedDateValidator.validate(future));
      });

      test('null — required 실패', () {
        expectFailure(foundedDateValidator.validate(null));
      });
    });
  });

  // =========================================================================
  // 시나리오 5: 상품 등록 폼 (판매자)
  // =========================================================================
  group('시나리오 — 상품 등록 폼', () {
    final productNameValidator =
        ValidateString().setLabel('상품명').required().min(2).max(100);
    final priceValidator =
        ValidateNumber().setLabel('판매가').required().isPositive();
    final stockValidator =
        ValidateNumber().setLabel('재고').required().isNonNegative().isInteger();
    final categoryValidator = ValidateList<String>()
        .setLabel('카테고리')
        .minLength(1)
        .maxLength(3);
    final descriptionValidator =
        ValidateString().setLabel('상품 설명').required().min(10).max(2000);

    group('정상 등록 케이스', () {
      test('정상 상품 정보 — 전부 통과', () {
        expectSuccess(productNameValidator.validate('프리미엄 무선 이어폰'));
        expectSuccess(priceValidator.validate(59900));
        expectSuccess(stockValidator.validate(100));
        expectSuccess(categoryValidator.validate(['전자기기', '음향기기']));
        expectSuccess(descriptionValidator.validate('최고 품질의 무선 이어폰입니다. 노이즈 캔슬링 지원.'));
      });

      test('재고 0개 — 품절 상태 통과 (isNonNegative: 0 허용)', () {
        expectSuccess(stockValidator.validate(0));
      });

      test('카테고리 1개만 선택 — 통과', () {
        expectSuccess(categoryValidator.validate(['전자기기']));
      });
    });

    group('상품명 오류 케이스', () {
      test('1자 상품명 — min(2) 실패', () {
        expectFailure(productNameValidator.validate('A'));
      });

      test('null 상품명 — required 실패', () {
        expectFailure(productNameValidator.validate(null));
      });
    });

    group('가격 오류 케이스', () {
      test('가격 0원 — isPositive 실패 (0 미허용)', () {
        expectFailure(priceValidator.validate(0));
      });

      test('음수 가격 — isPositive 실패', () {
        expectFailure(priceValidator.validate(-1));
      });

      test('null 가격 — required 실패', () {
        expectFailure(priceValidator.validate(null));
      });
    });

    group('재고 오류 케이스', () {
      test('재고 -1 — isNonNegative 실패', () {
        expectFailure(stockValidator.validate(-1));
      });

      test('소수 재고 1.5 — isInteger 실패', () {
        expectFailure(stockValidator.validate(1.5));
      });

      test('null 재고 — required 실패', () {
        expectFailure(stockValidator.validate(null));
      });
    });

    group('카테고리 오류 케이스', () {
      test('카테고리 없음 — minLength(1) 실패', () {
        expectFailure(categoryValidator.validate([]));
      });

      test('카테고리 4개 — maxLength(3) 실패', () {
        expectFailure(categoryValidator.validate(['a', 'b', 'c', 'd']));
      });
    });
  });

  // =========================================================================
  // 시나리오 6: 비밀번호 변경 폼
  // =========================================================================
  group('시나리오 — 비밀번호 변경', () {
    final newPwValidator =
        ValidateString().setLabel('새 비밀번호').required().password(minLength: 8);
    const forbiddenPasswords = ['12345678', 'password', 'qwerty123', '00000000'];
    final notCommonValidator =
        ValidateString().setLabel('새 비밀번호').excludedFrom(forbiddenPasswords);

    group('정상 변경 케이스', () {
      test('충분한 길이의 새 비밀번호 — 통과', () {
        expectSuccess(newPwValidator.validate('Secur3P@ss'));
      });

      test('일반적이지 않은 비밀번호 — excludedFrom 통과', () {
        expectSuccess(notCommonValidator.validate('Secur3P@ss'));
      });
    });

    group('오류 케이스', () {
      test('7자 비밀번호 — 실패', () {
        expectFailure(newPwValidator.validate('abc1234'));
      });

      test('null — required 실패', () {
        expectFailure(newPwValidator.validate(null));
      });

      test('흔한 비밀번호 "password" — excludedFrom 실패', () {
        final f = expectFailure(notCommonValidator.validate('password'));
        expect(f.code, ValidationCode.notOneOf);
      });

      test('흔한 비밀번호 "12345678" — excludedFrom 실패', () {
        expectFailure(notCommonValidator.validate('12345678'));
      });
    });
  });

  // =========================================================================
  // 시나리오 7: async 유저명 중복 검사
  // =========================================================================
  group('시나리오 — 유저명 중복 검사 (async)', () {
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

    test('사용 가능한 유저명 — 통과', () async {
      final result = await buildUsernameValidator().validateAsync('hong123');
      expect(result, isA<ValidationSuccess>());
    });

    test('이미 사용 중인 "admin" — async 실패', () async {
      final result = await buildUsernameValidator().validateAsync('admin');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).message, '이미 사용 중인 유저명입니다.');
    });

    test('이미 사용 중인 "user123" — async 실패', () async {
      final result = await buildUsernameValidator().validateAsync('user123');
      expect(result, isA<ValidationFailure>());
    });

    test('null 유저명 — sync required 실패 (async까지 가지 않음)', () async {
      final result = await buildUsernameValidator().validateAsync(null);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.required);
    });

    test('2자 유저명 — sync min(3) 실패 (async까지 가지 않음)', () async {
      final result = await buildUsernameValidator().validateAsync('hi');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.stringMin);
    });

    test('특수문자 포함 유저명 — sync alphanumeric 실패', () async {
      final result = await buildUsernameValidator().validateAsync('hong!');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.alphanumeric);
    });
  });

  // =========================================================================
  // 시나리오 8: 다국어 로케일 (한국어 메시지)
  // =========================================================================
  group('시나리오 — 한국어 에러 메시지 (ValidatorLocale)', () {
    setUp(() {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.required: (p) => '${p['name']}은(는) 필수 입력 항목입니다.',
          ValidationCode.emailInvalid: (p) => '${p['name']} 형식이 올바르지 않습니다.',
          ValidationCode.stringMin: (p) =>
              '${p['name']}은(는) 최소 ${p['min']}자 이상 입력해야 합니다.',
          ValidationCode.stringMax: (p) =>
              '${p['name']}은(는) 최대 ${p['max']}자까지 입력할 수 있습니다.',
          ValidationCode.numberMin: (p) =>
              '${p['name']}은(는) ${p['min']} 이상이어야 합니다.',
          ValidationCode.passwordMin: (p) =>
              '${p['name']}은(는) ${p['minLength']}자 이상이어야 합니다.',
          ValidationCode.mobileInvalid: (p) => '${p['name']} 형식이 올바르지 않습니다. (예: 010-1234-5678)',
          ValidationCode.boolTrue: (p) => '${p['name']}에 동의해 주세요.',
        }),
      );
    });

    test('이메일 미입력 — 한국어 required 메시지', () {
      final result = ValidateString()
              .setLabel('이메일')
              .required()
              .validate(null) as ValidationFailure;
      expect(result.message, '이메일은(는) 필수 입력 항목입니다.');
    });

    test('이메일 형식 오류 — 한국어 emailInvalid 메시지', () {
      final result = ValidateString()
              .setLabel('이메일')
              .email()
              .validate('bad') as ValidationFailure;
      expect(result.message, '이메일 형식이 올바르지 않습니다.');
    });

    test('이름 너무 짧음 — 한국어 stringMin 메시지', () {
      final result = ValidateString()
              .setLabel('이름')
              .min(2)
              .validate('A') as ValidationFailure;
      expect(result.message, '이름은(는) 최소 2자 이상 입력해야 합니다.');
    });

    test('비밀번호 너무 짧음 — 한국어 passwordMin 메시지', () {
      final result = ValidateString()
              .setLabel('비밀번호')
              .password(minLength: 8)
              .validate('abc') as ValidationFailure;
      expect(result.message, '비밀번호은(는) 8자 이상이어야 합니다.');
    });

    test('이용약관 미동의 — 한국어 boolTrue 메시지', () {
      final result = ValidateBool()
              .setLabel('이용약관')
              .isTrue()
              .validate(false) as ValidationFailure;
      expect(result.message, '이용약관에 동의해 주세요.');
    });

    test('휴대폰 형식 오류 — 한국어 mobileInvalid 메시지 + 예시 포함', () {
      final result = ValidateString()
              .setLabel('휴대폰')
              .mobile()
              .validate('01012345678') as ValidationFailure;
      expect(result.message, contains('010-1234-5678'));
    });

    test('나이 범위 오류 — 한국어 numberMin 메시지', () {
      final result = ValidateNumber()
              .setLabel('나이')
              .min(0)
              .validate(-1) as ValidationFailure;
      expect(result.message, '나이은(는) 0 이상이어야 합니다.');
    });

    test('로케일 초기화 후 영문 기본 메시지 복원', () {
      ValidatorLocale.resetLocale();
      final result = ValidateString()
              .setLabel('Email')
              .required()
              .validate(null) as ValidationFailure;
      expect(result.message, 'Email is required.');
    });
  });
}
