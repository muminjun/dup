import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  group('ValidateList.isNotEmpty / isEmpty', () {
    test('isNotEmpty passes for non-empty list', () {
      expect(ValidateList<int>().setLabel('L').isNotEmpty().validate([1]), isNull);
    });
    test('isNotEmpty fails for empty list', () {
      expect(ValidateList<int>().setLabel('L').isNotEmpty().validate([]), isNotNull);
    });
    test('isNotEmpty fails for null', () {
      expect(ValidateList<int>().setLabel('L').isNotEmpty().validate(null), isNotNull);
    });
    test('isEmpty passes for empty list', () {
      expect(ValidateList<int>().setLabel('L').isEmpty().validate([]), isNull);
    });
    test('isEmpty passes for null', () {
      expect(ValidateList<int>().setLabel('L').isEmpty().validate(null), isNull);
    });
    test('isEmpty fails for non-empty list', () {
      expect(ValidateList<int>().setLabel('L').isEmpty().validate([1]), isNotNull);
    });
  });

  group('ValidateList.minLength / maxLength', () {
    test('minLength passes when list is long enough', () {
      expect(ValidateList<int>().setLabel('L').minLength(2).validate([1, 2]), isNull);
    });
    test('minLength fails when too short', () {
      expect(ValidateList<int>().setLabel('L').minLength(3).validate([1, 2]), isNotNull);
    });
    test('minLength skips on null', () {
      expect(ValidateList<int>().setLabel('L').minLength(2).validate(null), isNull);
    });
    test('maxLength passes when within limit', () {
      expect(ValidateList<int>().setLabel('L').maxLength(3).validate([1, 2, 3]), isNull);
    });
    test('maxLength fails when too long', () {
      expect(ValidateList<int>().setLabel('L').maxLength(2).validate([1, 2, 3]), isNotNull);
    });
    test('maxLength passes on null', () {
      expect(ValidateList<int>().setLabel('L').maxLength(2).validate(null), isNull);
    });
  });

  group('ValidateList.lengthBetween', () {
    test('passes when within range', () {
      expect(ValidateList<int>().setLabel('L').lengthBetween(2, 4).validate([1, 2, 3]), isNull);
    });
    test('fails when too short', () {
      expect(ValidateList<int>().setLabel('L').lengthBetween(2, 4).validate([1]), isNotNull);
    });
    test('fails when too long', () {
      expect(ValidateList<int>().setLabel('L').lengthBetween(2, 4).validate([1, 2, 3, 4, 5]), isNotNull);
    });
    test('fails on null', () {
      expect(ValidateList<int>().setLabel('L').lengthBetween(2, 4).validate(null), isNotNull);
    });
  });

  group('ValidateList.hasLength', () {
    test('passes for exact length', () {
      expect(ValidateList<int>().setLabel('L').hasLength(3).validate([1, 2, 3]), isNull);
    });
    test('fails for wrong length', () {
      expect(ValidateList<int>().setLabel('L').hasLength(3).validate([1, 2]), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateList<int>().setLabel('L').hasLength(3).validate(null), isNull);
    });
  });

  group('ValidateList.contains / doesNotContain', () {
    test('contains passes when item present', () {
      expect(ValidateList<int>().setLabel('L').contains(5).validate([3, 5, 7]), isNull);
    });
    test('contains fails when item absent', () {
      expect(ValidateList<int>().setLabel('L').contains(5).validate([1, 2]), isNotNull);
    });
    test('contains fails on null', () {
      expect(ValidateList<int>().setLabel('L').contains(5).validate(null), isNotNull);
    });
    test('doesNotContain passes when item absent', () {
      expect(ValidateList<int>().setLabel('L').doesNotContain(5).validate([1, 2]), isNull);
    });
    test('doesNotContain fails when item present', () {
      expect(ValidateList<int>().setLabel('L').doesNotContain(5).validate([3, 5, 7]), isNotNull);
    });
    test('doesNotContain passes on null', () {
      expect(ValidateList<int>().setLabel('L').doesNotContain(5).validate(null), isNull);
    });
  });

  group('ValidateList.all / any', () {
    test('all passes when every item satisfies predicate', () {
      expect(ValidateList<int>().setLabel('L').all((x) => x > 0).validate([1, 2, 3]), isNull);
    });
    test('all fails when one item does not satisfy', () {
      expect(ValidateList<int>().setLabel('L').all((x) => x > 0).validate([1, -1, 3]), isNotNull);
    });
    test('all passes on null', () {
      expect(ValidateList<int>().setLabel('L').all((x) => x > 0).validate(null), isNull);
    });
    test('any passes when at least one satisfies', () {
      expect(ValidateList<int>().setLabel('L').any((x) => x > 10).validate([1, 2, 15]), isNull);
    });
    test('any fails when none satisfy', () {
      expect(ValidateList<int>().setLabel('L').any((x) => x > 10).validate([1, 2, 3]), isNotNull);
    });
    test('any skips on null', () {
      expect(ValidateList<int>().setLabel('L').any((x) => x > 0).validate(null), isNull);
    });
  });

  group('ValidateList.hasNoDuplicates', () {
    test('passes for list with unique items', () {
      expect(ValidateList<int>().setLabel('L').hasNoDuplicates().validate([1, 2, 3]), isNull);
    });
    test('fails for list with duplicates', () {
      expect(ValidateList<int>().setLabel('L').hasNoDuplicates().validate([1, 2, 2]), isNotNull);
    });
    test('passes on null', () {
      expect(ValidateList<int>().setLabel('L').hasNoDuplicates().validate(null), isNull);
    });
  });

  group('ValidateList.eachItem', () {
    test('passes when all items pass the per-item validator', () {
      final v = ValidateList<String>().setLabel('Tags').eachItem((s) => s.isEmpty ? 'empty' : null);
      expect(v.validate(['a', 'b', 'c']), isNull);
    });
    test('fails and reports the first failing item', () {
      final v = ValidateList<String>().setLabel('Tags').eachItem((s) => s.isEmpty ? 'cannot be empty' : null);
      final error = v.validate(['a', '', 'c']);
      expect(error, isNotNull);
      expect(error, contains('index 1'));
    });
    test('passes on null', () {
      final v = ValidateList<String>().setLabel('Tags').eachItem((s) => null);
      expect(v.validate(null), isNull);
    });
  });

  group('ValidateList — phase ordering', () {
    test('required fires before minLength', () {
      final v = ValidateList<int>().setLabel('L').minLength(2).required();
      expect(v.validate(null), equals('L is required.'));
    });
  });
}
