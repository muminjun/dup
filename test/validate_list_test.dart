import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  // ---------------------------------------------------------------------------
  // isNotEmpty()
  // ---------------------------------------------------------------------------
  group('isNotEmpty()', () {
    test('passes for non-empty list', () {
      expect(
        ValidateList<int>().isNotEmpty().validate([1]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for list with multiple items', () {
      expect(
        ValidateList<int>().isNotEmpty().validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for empty list', () {
      final result = ValidateList<int>().setLabel('Items').isNotEmpty().validate([]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.listNotEmpty);
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateList<int>().isNotEmpty().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateList<int>()
              .setLabel('List')
              .isNotEmpty(messageFactory: (label, _) => '$label 비어있음')
              .validate([])
          as ValidationFailure;
      expect(result.message, 'List 비어있음');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.listNotEmpty: (p) => '${p['name']} 비어있으면 안됨',
        }),
      );
      final result =
          ValidateList<int>().setLabel('목록').isNotEmpty().validate([])
              as ValidationFailure;
      expect(result.message, '목록 비어있으면 안됨');
    });
  });

  // ---------------------------------------------------------------------------
  // isEmpty()
  // ---------------------------------------------------------------------------
  group('isEmpty()', () {
    test('passes for empty list', () {
      expect(
        ValidateList<int>().isEmpty().validate([]),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for non-empty list', () {
      final result = ValidateList<int>().setLabel('List').isEmpty().validate([1]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.listEmpty);
    });

    test('fails for list with multiple items', () {
      expect(
        ValidateList<int>().isEmpty().validate([1, 2, 3]),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateList<int>().isEmpty().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateList<int>()
              .setLabel('List')
              .isEmpty(messageFactory: (label, _) => '$label 비어야 함')
              .validate([1])
          as ValidationFailure;
      expect(result.message, 'List 비어야 함');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.listEmpty: (p) => '${p['name']} 비어야 함',
        }),
      );
      final result =
          ValidateList<int>().setLabel('목록').isEmpty().validate([1])
              as ValidationFailure;
      expect(result.message, '목록 비어야 함');
    });
  });

  // ---------------------------------------------------------------------------
  // minLength()
  // ---------------------------------------------------------------------------
  group('minLength()', () {
    test('passes when list has exactly min items (boundary)', () {
      expect(
        ValidateList<int>().minLength(3).validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes when list has more than min items', () {
      expect(
        ValidateList<int>().minLength(2).validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when list has fewer items than min', () {
      final result = ValidateList<int>().setLabel('Tags').minLength(3).validate([1, 2]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.listMin);
      expect(result.context['min'], 3);
    });

    test('fails for empty list when min > 0', () {
      expect(
        ValidateList<int>().minLength(1).validate([]),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateList<int>().minLength(3).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateList<int>()
              .setLabel('Tags')
              .minLength(3, messageFactory: (label, p) => '$label 최소 ${p['min']}개')
              .validate([1])
          as ValidationFailure;
      expect(result.message, 'Tags 최소 3개');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.listMin: (p) => '${p['name']} 아이템 부족',
        }),
      );
      final result =
          ValidateList<int>().setLabel('목록').minLength(3).validate([1])
              as ValidationFailure;
      expect(result.message, '목록 아이템 부족');
    });
  });

  // ---------------------------------------------------------------------------
  // maxLength()
  // ---------------------------------------------------------------------------
  group('maxLength()', () {
    test('passes when list has exactly max items (boundary)', () {
      expect(
        ValidateList<int>().maxLength(3).validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes when list has fewer items than max', () {
      expect(
        ValidateList<int>().maxLength(5).validate([1, 2]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty list', () {
      expect(
        ValidateList<int>().maxLength(5).validate([]),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when list has more items than max', () {
      final result = ValidateList<int>().setLabel('Tags').maxLength(2).validate([1, 2, 3]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.listMax);
      expect(result.context['max'], 2);
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateList<int>().maxLength(2).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateList<int>()
              .setLabel('Tags')
              .maxLength(
                2,
                messageFactory: (label, p) => '$label 최대 ${p['max']}개',
              )
              .validate([1, 2, 3])
          as ValidationFailure;
      expect(result.message, 'Tags 최대 2개');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.listMax: (p) => '${p['name']} 아이템 초과',
        }),
      );
      final result =
          ValidateList<int>().setLabel('목록').maxLength(2).validate([1, 2, 3])
              as ValidationFailure;
      expect(result.message, '목록 아이템 초과');
    });
  });

  // ---------------------------------------------------------------------------
  // lengthBetween()
  // ---------------------------------------------------------------------------
  group('lengthBetween()', () {
    test('passes when list length is within range', () {
      expect(
        ValidateList<int>().lengthBetween(2, 4).validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes when length == min (inclusive lower boundary)', () {
      expect(
        ValidateList<int>().lengthBetween(2, 4).validate([1, 2]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes when length == max (inclusive upper boundary)', () {
      expect(
        ValidateList<int>().lengthBetween(2, 4).validate([1, 2, 3, 4]),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when list has fewer items than min', () {
      final result = ValidateList<int>()
          .setLabel('List')
          .lengthBetween(2, 4)
          .validate([1]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.listLengthBetween);
    });

    test('fails when list has more items than max', () {
      expect(
        ValidateList<int>().lengthBetween(1, 3).validate([1, 2, 3, 4, 5]),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateList<int>().lengthBetween(1, 3).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateList<int>()
              .setLabel('List')
              .lengthBetween(
                2,
                4,
                messageFactory: (label, p) =>
                    '$label ${p['min']}~${p['max']}개',
              )
              .validate([1])
          as ValidationFailure;
      expect(result.message, 'List 2~4개');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.listLengthBetween: (p) => '${p['name']} 길이 범위 오류',
        }),
      );
      final result =
          ValidateList<int>().setLabel('목록').lengthBetween(2, 4).validate([1])
              as ValidationFailure;
      expect(result.message, '목록 길이 범위 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // hasLength()
  // ---------------------------------------------------------------------------
  group('hasLength()', () {
    test('passes when list has exactly the required length', () {
      expect(
        ValidateList<int>().hasLength(3).validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty list when required length is 0', () {
      expect(
        ValidateList<int>().hasLength(0).validate([]),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when list is shorter than required', () {
      final result = ValidateList<int>().setLabel('OTP').hasLength(6).validate([1, 2]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.listExactLength);
      expect(result.context['length'], 6);
    });

    test('fails when list is longer than required', () {
      expect(
        ValidateList<int>().hasLength(2).validate([1, 2, 3]),
        isA<ValidationFailure>(),
      );
    });

    test('fails for empty list when required length > 0', () {
      expect(
        ValidateList<int>().hasLength(1).validate([]),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateList<int>().hasLength(3).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateList<int>()
              .setLabel('OTP')
              .hasLength(
                6,
                messageFactory: (label, p) => '$label 정확히 ${p['length']}개',
              )
              .validate([1, 2])
          as ValidationFailure;
      expect(result.message, 'OTP 정확히 6개');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.listExactLength: (p) => '${p['name']} 정확한 길이 오류',
        }),
      );
      final result =
          ValidateList<int>().setLabel('OTP').hasLength(6).validate([1, 2])
              as ValidationFailure;
      expect(result.message, 'OTP 정확한 길이 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // contains()
  // ---------------------------------------------------------------------------
  group('contains()', () {
    test('passes when item is present in the list', () {
      expect(
        ValidateList<int>().contains(3).validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes when item is the only element', () {
      expect(
        ValidateList<int>().contains(1).validate([1]),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when item is absent', () {
      final result = ValidateList<int>().setLabel('List').contains(5).validate([1, 2, 3]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.contains);
    });

    test('fails for empty list', () {
      expect(
        ValidateList<int>().contains(1).validate([]),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateList<int>().contains(5).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('works with String list', () {
      expect(
        ValidateList<String>().contains('hello').validate(['hello', 'world']),
        isA<ValidationSuccess>(),
      );
      expect(
        ValidateList<String>().contains('missing').validate(['hello', 'world']),
        isA<ValidationFailure>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateList<int>()
              .setLabel('List')
              .contains(5, messageFactory: (label, _) => '$label 항목 없음')
              .validate([1, 2])
          as ValidationFailure;
      expect(result.message, 'List 항목 없음');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.contains: (p) => '${p['name']} 포함 오류',
        }),
      );
      final result =
          ValidateList<int>().setLabel('목록').contains(5).validate([1])
              as ValidationFailure;
      expect(result.message, '목록 포함 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // doesNotContain()
  // ---------------------------------------------------------------------------
  group('doesNotContain()', () {
    test('passes when item is absent', () {
      expect(
        ValidateList<int>().doesNotContain(5).validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty list', () {
      expect(
        ValidateList<int>().doesNotContain(5).validate([]),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when item is present', () {
      final result =
          ValidateList<int>().setLabel('List').doesNotContain(2).validate([1, 2, 3]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.doesNotContain);
    });

    test('fails when list contains only the forbidden item', () {
      expect(
        ValidateList<int>().doesNotContain(1).validate([1]),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateList<int>().doesNotContain(5).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateList<int>()
              .setLabel('List')
              .doesNotContain(1, messageFactory: (label, _) => '$label 금지된 항목')
              .validate([1, 2])
          as ValidationFailure;
      expect(result.message, 'List 금지된 항목');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.doesNotContain: (p) => '${p['name']} 포함 금지 오류',
        }),
      );
      final result =
          ValidateList<int>().setLabel('목록').doesNotContain(1).validate([1])
              as ValidationFailure;
      expect(result.message, '목록 포함 금지 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // all()
  // ---------------------------------------------------------------------------
  group('all()', () {
    test('passes when all items satisfy predicate', () {
      expect(
        ValidateList<int>().all((x) => x > 0).validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty list (vacuous truth)', () {
      expect(
        ValidateList<int>().all((x) => x > 0).validate([]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateList<int>().all((x) => x > 0).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when any item does not satisfy predicate', () {
      final result = ValidateList<int>()
          .setLabel('List')
          .all((x) => x > 0)
          .validate([1, -1, 3]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.all);
    });

    test('fails when first item fails', () {
      expect(
        ValidateList<int>().all((x) => x > 0).validate([-1, 2, 3]),
        isA<ValidationFailure>(),
      );
    });

    test('fails when last item fails', () {
      expect(
        ValidateList<int>().all((x) => x > 0).validate([1, 2, -3]),
        isA<ValidationFailure>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateList<int>()
              .setLabel('Scores')
              .all(
                (x) => x >= 0,
                messageFactory: (label, _) => '$label 모두 양수여야 함',
              )
              .validate([-1])
          as ValidationFailure;
      expect(result.message, 'Scores 모두 양수여야 함');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.all: (p) => '${p['name']} 전체 조건 오류',
        }),
      );
      final result =
          ValidateList<int>().setLabel('목록').all((x) => x > 0).validate([-1])
              as ValidationFailure;
      expect(result.message, '목록 전체 조건 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // any()
  // ---------------------------------------------------------------------------
  group('any()', () {
    test('passes when at least one item satisfies predicate', () {
      expect(
        ValidateList<int>().any((x) => x > 0).validate([-1, 2, -3]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes when all items satisfy predicate', () {
      expect(
        ValidateList<int>().any((x) => x > 0).validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('fails for empty list (no items satisfy)', () {
      final result = ValidateList<int>().setLabel('List').any((x) => x > 0).validate([]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.any);
    });

    test('fails when no items satisfy predicate', () {
      expect(
        ValidateList<int>().any((x) => x > 0).validate([-1, -2, -3]),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateList<int>().any((x) => x > 0).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateList<int>()
              .setLabel('List')
              .any(
                (x) => x > 0,
                messageFactory: (label, _) => '$label 하나 이상 양수',
              )
              .validate([-1])
          as ValidationFailure;
      expect(result.message, 'List 하나 이상 양수');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.any: (p) => '${p['name']} 하나 조건 오류',
        }),
      );
      final result =
          ValidateList<int>().setLabel('목록').any((x) => x > 0).validate([-1])
              as ValidationFailure;
      expect(result.message, '목록 하나 조건 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // none()
  // ---------------------------------------------------------------------------
  group('none()', () {
    test('passes when no items satisfy predicate', () {
      expect(
        ValidateList<int>().none((x) => x < 0).validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty list', () {
      expect(
        ValidateList<int>().none((x) => x < 0).validate([]),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when any item satisfies predicate', () {
      final result = ValidateList<int>()
          .setLabel('List')
          .none((x) => x < 0)
          .validate([1, -1, 3]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.none);
    });

    test('fails when all items satisfy predicate', () {
      expect(
        ValidateList<int>().none((x) => x < 0).validate([-1, -2, -3]),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateList<int>().none((x) => x < 0).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateList<int>()
              .setLabel('List')
              .none(
                (x) => x < 0,
                messageFactory: (label, _) => '$label 음수 불가',
              )
              .validate([-1])
          as ValidationFailure;
      expect(result.message, 'List 음수 불가');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.none: (p) => '${p['name']} 없음 조건 오류',
        }),
      );
      final result =
          ValidateList<int>().setLabel('목록').none((x) => x < 0).validate([-1])
              as ValidationFailure;
      expect(result.message, '목록 없음 조건 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // hasNoDuplicates()
  // ---------------------------------------------------------------------------
  group('hasNoDuplicates()', () {
    test('passes for list with unique items', () {
      expect(
        ValidateList<int>().hasNoDuplicates().validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for empty list', () {
      expect(
        ValidateList<int>().hasNoDuplicates().validate([]),
        isA<ValidationSuccess>(),
      );
    });

    test('passes for single-item list', () {
      expect(
        ValidateList<int>().hasNoDuplicates().validate([1]),
        isA<ValidationSuccess>(),
      );
    });

    test('fails when list contains duplicates', () {
      final result =
          ValidateList<int>().setLabel('IDs').hasNoDuplicates().validate([1, 1, 2]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.noDuplicates);
    });

    test('fails for all-duplicate list', () {
      expect(
        ValidateList<int>().hasNoDuplicates().validate([5, 5, 5]),
        isA<ValidationFailure>(),
      );
    });

    test('fails when duplicate is at the end', () {
      expect(
        ValidateList<String>().hasNoDuplicates().validate(['a', 'b', 'a']),
        isA<ValidationFailure>(),
      );
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateList<int>().hasNoDuplicates().validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory', () {
      final result = ValidateList<int>()
              .setLabel('IDs')
              .hasNoDuplicates(messageFactory: (label, _) => '$label 중복 금지')
              .validate([1, 1])
          as ValidationFailure;
      expect(result.message, 'IDs 중복 금지');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(
        ValidatorLocale({
          ValidationCode.noDuplicates: (p) => '${p['name']} 중복 오류',
        }),
      );
      final result =
          ValidateList<int>().setLabel('아이디').hasNoDuplicates().validate([1, 1])
              as ValidationFailure;
      expect(result.message, '아이디 중복 오류');
    });
  });

  // ---------------------------------------------------------------------------
  // eachItem()
  // ---------------------------------------------------------------------------
  group('eachItem()', () {
    test('passes when all items pass', () {
      final result = ValidateList<int>()
          .eachItem((item) => item < 0
              ? const ValidationFailure(code: ValidationCode.custom, message: 'neg')
              : null)
          .validate([1, 2, 3]);
      expect(result, isA<ValidationSuccess>());
    });

    test('passes for empty list', () {
      final result = ValidateList<int>()
          .eachItem((_) => null)
          .validate([]);
      expect(result, isA<ValidationSuccess>());
    });

    test('fails when first item fails and records index 0', () {
      final result = ValidateList<int>()
          .setLabel('List')
          .eachItem((item) => item < 0
              ? const ValidationFailure(
                  code: ValidationCode.custom,
                  message: 'negative',
                )
              : null)
          .validate([-1, 2, 3]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.eachItem);
      expect(result.context['index'], 0);
    });

    test('fails at correct index for middle item failure', () {
      final result = ValidateList<int>()
          .eachItem((item) => item < 0
              ? const ValidationFailure(
                  code: ValidationCode.custom,
                  message: 'neg',
                )
              : null)
          .validate([1, -1, 2]);
      expect((result as ValidationFailure).context['index'], 1);
    });

    test('stops at first failure (does not continue after first failed item)', () {
      var callCount = 0;
      ValidateList<int>()
          .eachItem((item) {
            callCount++;
            return item < 0
                ? const ValidationFailure(
                    code: ValidationCode.custom,
                    message: 'neg',
                  )
                : null;
          })
          .validate([-1, -2, -3]);
      expect(callCount, 1);
    });

    test('failure context contains innerFailure', () {
      final result = ValidateList<int>()
          .eachItem((item) => item < 0
              ? const ValidationFailure(
                  code: ValidationCode.custom,
                  message: 'negative item',
                )
              : null)
          .validate([1, -1]) as ValidationFailure;
      final inner = result.context['innerFailure'] as ValidationFailure;
      expect(inner.message, 'negative item');
    });

    test('passes for null (null-skip)', () {
      expect(
        ValidateList<int>().eachItem((_) => null).validate(null),
        isA<ValidationSuccess>(),
      );
    });

    test('uses messageFactory override', () {
      final result = ValidateList<int>()
              .setLabel('Items')
              .eachItem(
                (_) => const ValidationFailure(
                  code: ValidationCode.custom,
                  message: 'bad',
                ),
                messageFactory: (label, p) =>
                    '$label[${p['index']}]: ${p['error']}',
              )
              .validate([1])
          as ValidationFailure;
      expect(result.message, 'Items[0]: bad');
    });
  });

  // ---------------------------------------------------------------------------
  // 실제 유저 입력 패턴 — 태그 선택 (블로그/게시글)
  // ---------------------------------------------------------------------------
  group('실제 유저 입력 — 태그 선택', () {
    final tagValidator = ValidateList<String>()
        .setLabel('태그')
        .minLength(1)
        .maxLength(5)
        .hasNoDuplicates();

    test('태그 1개 선택 통과', () {
      expect(tagValidator.validate(['dart']), isA<ValidationSuccess>());
    });

    test('태그 5개 선택 통과 (상한 경계)', () {
      expect(
        tagValidator.validate(['dart', 'flutter', 'mobile', 'app', 'dev']),
        isA<ValidationSuccess>(),
      );
    });

    test('태그 0개 — 최소 1개 필요 실패', () {
      expect(tagValidator.validate([]), isA<ValidationFailure>());
    });

    test('태그 6개 — 최대 5개 초과 실패', () {
      expect(
        tagValidator.validate(['a', 'b', 'c', 'd', 'e', 'f']),
        isA<ValidationFailure>(),
      );
    });

    test('같은 태그 중복 입력 실패', () {
      expect(
        tagValidator.validate(['dart', 'flutter', 'dart']),
        isA<ValidationFailure>(),
      );
    });

    test('null이면 통과 (선택 사항일 때)', () {
      expect(tagValidator.validate(null), isA<ValidationSuccess>());
    });
  });

  // ---------------------------------------------------------------------------
  // 실제 유저 입력 패턴 — 관심사 선택 (최소 1개, 최대 3개)
  // ---------------------------------------------------------------------------
  group('실제 유저 입력 — 관심사 선택 (체크박스)', () {
    final interestValidator = ValidateList<String>()
        .setLabel('관심사')
        .minLength(1)
        .maxLength(3);

    test('관심사 1개 선택 통과', () {
      expect(interestValidator.validate(['스포츠']), isA<ValidationSuccess>());
    });

    test('관심사 3개 선택 통과 (상한 경계)', () {
      expect(
        interestValidator.validate(['스포츠', '음악', '여행']),
        isA<ValidationSuccess>(),
      );
    });

    test('아무것도 선택 안 하면 실패 (빈 배열)', () {
      expect(interestValidator.validate([]), isA<ValidationFailure>());
    });

    test('4개 선택하면 실패', () {
      expect(
        interestValidator.validate(['스포츠', '음악', '여행', '독서']),
        isA<ValidationFailure>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 실제 유저 입력 패턴 — 장바구니 상품 목록
  // ---------------------------------------------------------------------------
  group('실제 유저 입력 — 장바구니', () {
    final cartValidator = ValidateList<int>()
        .setLabel('장바구니')
        .isNotEmpty()
        .maxLength(20)
        .all((qty) => qty > 0);

    test('상품 1개 수량 1 통과', () {
      expect(cartValidator.validate([1]), isA<ValidationSuccess>());
    });

    test('여러 상품 정상 수량 통과', () {
      expect(cartValidator.validate([1, 2, 3]), isA<ValidationSuccess>());
    });

    test('장바구니 비어있으면 실패', () {
      expect(cartValidator.validate([]), isA<ValidationFailure>());
    });

    test('수량 0인 항목 있으면 실패', () {
      expect(cartValidator.validate([1, 0, 3]), isA<ValidationFailure>());
    });

    test('수량 음수인 항목 있으면 실패', () {
      expect(cartValidator.validate([1, -1, 3]), isA<ValidationFailure>());
    });

    test('21개 상품 담으면 실패 (상한 초과)', () {
      expect(
        cartValidator.validate(List.filled(21, 1)),
        isA<ValidationFailure>(),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 실제 유저 입력 패턴 — 필수 동의 항목 (eachItem 활용)
  // ---------------------------------------------------------------------------
  group('실제 유저 입력 — 필수 동의 목록 (eachItem)', () {
    final termsValidator = ValidateList<bool>()
        .setLabel('동의 항목')
        .hasLength(3)
        .eachItem(
          (agreed) => agreed
              ? null
              : const ValidationFailure(
                  code: ValidationCode.custom,
                  message: '필수 동의 항목입니다.',
                ),
        );

    test('3개 모두 동의하면 통과', () {
      expect(termsValidator.validate([true, true, true]), isA<ValidationSuccess>());
    });

    test('첫 번째 항목 미동의 실패 — index 0', () {
      final result = termsValidator.validate([false, true, true]) as ValidationFailure;
      expect(result.context['index'], 0);
    });

    test('두 번째 항목 미동의 실패 — index 1', () {
      final result = termsValidator.validate([true, false, true]) as ValidationFailure;
      expect(result.context['index'], 1);
    });

    test('항목 수가 3개가 아니면 실패', () {
      expect(termsValidator.validate([true, true]), isA<ValidationFailure>());
    });
  });

  // ---------------------------------------------------------------------------
  // Chaining / interaction
  // ---------------------------------------------------------------------------
  group('chaining validators', () {
    test('minLength + maxLength passes within range', () {
      expect(
        ValidateList<int>().minLength(2).maxLength(5).validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('isNotEmpty + hasNoDuplicates: empty list fails at isNotEmpty first', () {
      final v = ValidateList<int>().isNotEmpty().hasNoDuplicates();
      final result = v.validate([]) as ValidationFailure;
      expect(result.code, ValidationCode.listNotEmpty);
    });

    test('required + isNotEmpty: null fails at required', () {
      final v = ValidateList<int>().required().isNotEmpty();
      final result = v.validate(null) as ValidationFailure;
      expect(result.code, ValidationCode.required);
    });

    test('minLength + all: list with enough items that all pass', () {
      expect(
        ValidateList<int>().minLength(2).all((x) => x > 0).validate([1, 2, 3]),
        isA<ValidationSuccess>(),
      );
    });

    test('hasNoDuplicates + eachItem: duplicate detected before individual item check', () {
      var eachItemCalled = false;
      final v = ValidateList<int>()
          .hasNoDuplicates()
          .eachItem((item) {
            eachItemCalled = true;
            return null;
          });
      final result = v.validate([1, 1]);
      expect(result, isA<ValidationFailure>());
      expect(eachItemCalled, isFalse);
    });
  });

  group('containsAll()', () {
    test('passes when all required items present', () {
      expect(
        ValidateList<int>().containsAll([1, 2, 3]).validate([1, 2, 3, 4]),
        isA<ValidationSuccess>(),
      );
    });
    test('fails when one required item missing', () {
      final r = ValidateList<int>().setLabel('Roles').containsAll([1, 2, 3]).validate([1, 2]);
      expect(r, isA<ValidationFailure>());
      expect((r as ValidationFailure).code, ValidationCode.listContainsAll);
      expect(r.context['missing'], contains(3));
    });
    test('null passes', () {
      expect(ValidateList<int>().containsAll([1]).validate(null), isA<ValidationSuccess>());
    });
    test('empty required list always passes', () {
      expect(ValidateList<int>().containsAll([]).validate([]), isA<ValidationSuccess>());
    });
  });
}
