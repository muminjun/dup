import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  late DupSchema addressSchema;

  setUp(() {
    addressSchema = DupSchema({
      'street': ValidateString().required(),
      'city':   ValidateString().required(),
      'zip':    ValidateString().required().koPostalCode(),
    });
  });

  group('ValidateObject — direct call path', () {
    test('passes for valid map', () async {
      final v = ValidateObject(addressSchema);
      final result = await v.validateAsync({
        'street': '123 Main St',
        'city': 'Seoul',
        'zip': '06000',
      });
      expect(result, isA<ValidationSuccess>());
    });

    test('null passes when required() not set', () async {
      final result = await ValidateObject(addressSchema).validateAsync(null);
      expect(result, isA<ValidationSuccess>());
    });

    test('null fails when required() set', () async {
      final result = await ValidateObject(addressSchema).required().validateAsync(null);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.required);
    });

    test('inner failure returns nestedFailed code', () async {
      final v = ValidateObject(addressSchema);
      final result = await v.validateAsync({'street': null, 'city': 'Seoul', 'zip': '06000'});
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.nestedFailed);
    });

    test('sync path works when inner schema has no async validators', () {
      final v = ValidateObject(addressSchema);
      final result = v.validate({'street': 'A', 'city': 'B', 'zip': '06000'});
      expect(result, isA<ValidationSuccess>());
    });
  });

  group('ValidateObject — via DupSchema (nested flattening)', () {
    late DupSchema orderSchema;

    setUp(() {
      orderSchema = DupSchema({
        'id':      ValidateString().required(),
        'address': ValidateObject(addressSchema).required(),
      });
    });

    test('flattens nested errors with dot notation', () async {
      final result = await orderSchema.validate({
        'id': 'order1',
        'address': {'street': null, 'city': 'Seoul', 'zip': '06000'},
      });
      expect(result, isA<FormValidationFailure>());
      final failure = result as FormValidationFailure;
      expect(failure('address.street'), isNotNull);
      expect(failure('address.street')!.code, ValidationCode.required);
    });

    test('outer required fires as normal field error', () async {
      final result = await orderSchema.validate({'id': 'order1', 'address': null});
      expect(result, isA<FormValidationFailure>());
      final failure = result as FormValidationFailure;
      expect(failure('address'), isNotNull);
      expect(failure('address')!.code, ValidationCode.required);
      expect(failure('address.street'), isNull);
    });

    test('passes when all nested fields valid', () async {
      final result = await orderSchema.validate({
        'id': 'order1',
        'address': {'street': '1 Main', 'city': 'Seoul', 'zip': '06000'},
      });
      expect(result, isA<FormValidationSuccess>());
    });
  });

  group('ValidateObject — hasAsyncValidators', () {
    test('true when inner schema has async validator', () {
      final asyncSchema = DupSchema({
        'x': ValidateString().addAsyncValidator((_) async => null),
      });
      expect(ValidateObject(asyncSchema).hasAsyncValidators, isTrue);
    });

    test('false when no async anywhere', () {
      expect(ValidateObject(addressSchema).hasAsyncValidators, isFalse);
    });
  });
}
