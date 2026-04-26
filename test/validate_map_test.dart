import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  group('ValidateMap — size constraints', () {
    test('minSize passes when enough entries', () {
      expect(
        ValidateMap<String>().minSize(1).validate({'a': 'x'}),
        isA<ValidationSuccess>(),
      );
    });

    test('minSize fails when too few entries', () {
      final result = ValidateMap<String>().setLabel('Tags').minSize(2).validate(
        {'a': 'x'},
      );
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.mapMinSize);
    });

    test('maxSize fails when too many entries', () {
      final result = ValidateMap<String>().maxSize(1).validate({
        'a': 'x',
        'b': 'y',
      });
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.mapMaxSize);
    });

    test('null passes (null-skip)', () {
      expect(
        ValidateMap<String>().minSize(1).validate(null),
        isA<ValidationSuccess>(),
      );
    });
  });

  group('ValidateMap — via DupSchema (nested flattening)', () {
    late DupSchema schema;

    setUp(() {
      schema = DupSchema({
        'scores': ValidateMap<num>()
            .required()
            .minSize(1)
            .valueValidator(ValidateNumber().min(0).max(100)),
      });
    });

    test('value error flattened with bracket notation', () async {
      final result = await schema.validate({
        'scores': {'math': 150},
      });
      expect(result, isA<FormValidationFailure>());
      final failure = result as FormValidationFailure;
      expect(failure('scores[math]'), isNotNull);
      expect(failure('scores[math]')!.code, ValidationCode.numberMax);
    });

    test('key error flattened with bracket notation', () async {
      final s = DupSchema({
        'tags': ValidateMap<String>().keyValidator(ValidateString().alpha()),
      });
      final result = await s.validate({
        'tags': {'bad key!': 'value'},
      });
      expect(result, isA<FormValidationFailure>());
      expect((result as FormValidationFailure)('tags[bad key!]'), isNotNull);
    });

    test('passes for valid map', () async {
      final result = await schema.validate({
        'scores': {'math': 95, 'english': 88},
      });
      expect(result, isA<FormValidationSuccess>());
    });

    test('outer required fires as normal field error', () async {
      final result = await schema.validate({'scores': null});
      expect(result, isA<FormValidationFailure>());
      expect(
        (result as FormValidationFailure)('scores')!.code,
        ValidationCode.required,
      );
    });
  });

  group('ValidateMap — hasAsyncValidators', () {
    test('true when valueValidator has async', () {
      final v = ValidateMap<String>().valueValidator(
        ValidateString().addAsyncValidator((_) async => null),
      );
      expect(v.hasAsyncValidators, isTrue);
    });
  });

  group('ValidateMap — standalone validate()', () {
    test('validate() runs keyValidator when used standalone', () {
      final v = ValidateMap<String>().keyValidator(ValidateString().alpha());
      final result = v.validate({'123': 'x'});
      expect(result, isA<ValidationFailure>());
    });

    test('validate() runs valueValidator when used standalone', () {
      final v = ValidateMap<num>().valueValidator(ValidateNumber().min(0));
      final result = v.validate({'score': -1});
      expect(result, isA<ValidationFailure>());
    });

    test('validate() returns success when all entries pass', () {
      final v = ValidateMap<String>()
          .keyValidator(ValidateString().alpha())
          .valueValidator(ValidateString().min(1));
      final result = v.validate({'name': 'Alice'});
      expect(result, isA<ValidationSuccess>());
    });

    test('validateAsync() runs keyValidator when used standalone', () async {
      final v = ValidateMap<String>().keyValidator(ValidateString().alpha());
      final result = await v.validateAsync({'123': 'x'});
      expect(result, isA<ValidationFailure>());
    });

    test('validate() passes null when not required', () {
      final v = ValidateMap<String>().keyValidator(ValidateString().alpha());
      expect(v.validate(null), isA<ValidationSuccess>());
    });

    test('validateAsync() passes null when not required', () async {
      final v = ValidateMap<String>().keyValidator(ValidateString().alpha());
      expect(await v.validateAsync(null), isA<ValidationSuccess>());
    });
  });
}
