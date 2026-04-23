import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('isNotEmpty()', () {
    test('fails for empty list', () {
      final result = ValidateList<int>().isNotEmpty().validate([]);
      expect((result as ValidationFailure).code, ValidationCode.listNotEmpty);
    });

    test('passes for non-empty list', () {
      expect(ValidateList<int>().isNotEmpty().validate([1]), isA<ValidationSuccess>());
    });

    test('passes for null', () {
      expect(ValidateList<int>().isNotEmpty().validate(null), isA<ValidationSuccess>());
    });
  });

  group('isEmpty()', () {
    test('fails for non-empty list', () {
      final result = ValidateList<int>().isEmpty().validate([1]);
      expect((result as ValidationFailure).code, ValidationCode.listEmpty);
    });
  });

  group('minLength()', () {
    test('fails when list has fewer items', () {
      final result = ValidateList<int>().minLength(3).validate([1, 2]);
      expect((result as ValidationFailure).code, ValidationCode.listMin);
      expect(result.context['min'], 3);
    });
  });

  group('maxLength()', () {
    test('fails when list has more items', () {
      final result = ValidateList<int>().maxLength(2).validate([1, 2, 3]);
      expect((result as ValidationFailure).code, ValidationCode.listMax);
    });
  });

  group('contains()', () {
    test('fails when item is absent', () {
      final result = ValidateList<int>().contains(5).validate([1, 2, 3]);
      expect((result as ValidationFailure).code, ValidationCode.contains);
    });
  });

  group('hasNoDuplicates()', () {
    test('fails for duplicate items', () {
      final result = ValidateList<int>().hasNoDuplicates().validate([1, 1, 2]);
      expect((result as ValidationFailure).code, ValidationCode.noDuplicates);
    });
  });

  group('eachItem()', () {
    test('fails when an item fails the item validator', () {
      final result = ValidateList<int>().eachItem((item) {
        if (item < 0) {
          return const ValidationFailure(
              code: ValidationCode.custom, message: 'must be positive');
        }
        return null;
      }).validate([1, -1, 2]);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.eachItem);
      expect(result.context['index'], 1);
    });

    test('passes when all items pass', () {
      final result = ValidateList<int>().eachItem((item) {
        return item < 0
            ? const ValidationFailure(
                code: ValidationCode.custom, message: 'neg')
            : null;
      }).validate([1, 2, 3]);
      expect(result, isA<ValidationSuccess>());
    });
  });

  group('locale', () {
    test('uses locale message for listMin', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.listMin: (p) => '${p['name']} 아이템 부족',
      }));
      final result = ValidateList<int>().setLabel('목록').minLength(3).validate([1])
          as ValidationFailure;
      expect(result.message, '목록 아이템 부족');
    });
  });
}
