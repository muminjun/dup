// test/dup_schema_test.dart
import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('DupSchema — label assignment', () {
    test('schema key is used as label', () async {
      final schema = DupSchema({'email': ValidateString().required()});
      final result = await schema.validate({'email': null});
      final failure = result as FormValidationFailure;
      expect(failure('email')!.message, contains('email'));
    });

    test('labels map overrides key as label', () async {
      final schema = DupSchema(
        {'passwordConfirm': ValidateString().required()},
        labels: {'passwordConfirm': '비밀번호 확인'},
      );
      final result = await schema.validate({'passwordConfirm': null});
      final failure = result as FormValidationFailure;
      expect(failure('passwordConfirm')!.message, contains('비밀번호 확인'));
    });
  });

  group('DupSchema.validate()', () {
    late DupSchema schema;

    setUp(() {
      schema = DupSchema({
        'email': ValidateString().email().required(),
        'age': ValidateNumber().min(18).required(),
      });
    });

    test('returns FormValidationSuccess when all fields pass', () async {
      final result = await schema.validate({'email': 'a@b.com', 'age': 20});
      expect(result, isA<FormValidationSuccess>());
    });

    test('returns FormValidationFailure with field errors', () async {
      final result = await schema.validate({'email': 'bad', 'age': 10});
      expect(result, isA<FormValidationFailure>());
      final failure = result as FormValidationFailure;
      expect(failure.hasError('email'), isTrue);
      expect(failure.hasError('age'), isTrue);
    });

    test('missing field treated as null', () async {
      final result = await schema.validate({});
      expect((result as FormValidationFailure).hasError('email'), isTrue);
    });
  });

  group('DupSchema.validateSync()', () {
    test('returns success for valid data', () {
      final schema = DupSchema({'name': ValidateString().required()});
      expect(schema.validateSync({'name': 'Alice'}), isA<FormValidationSuccess>());
    });

    test('returns failure for invalid data', () {
      final schema = DupSchema({'name': ValidateString().required()});
      expect(schema.validateSync({'name': null}), isA<FormValidationFailure>());
    });

    test('asserts in debug mode when async validators present', () {
      final schema = DupSchema({
        'email': ValidateString()
          ..addAsyncValidator((_) async => null),
      });
      expect(() => schema.validateSync({}), throwsA(isA<AssertionError>()));
    });
  });

  group('DupSchema.validateField()', () {
    test('returns ValidationSuccess for valid field value', () async {
      final schema = DupSchema({'email': ValidateString().email()});
      expect(await schema.validateField('email', 'a@b.com'), isA<ValidationSuccess>());
    });

    test('returns ValidationFailure for invalid field value', () async {
      final schema = DupSchema({'email': ValidateString().email()});
      expect(await schema.validateField('email', 'bad'), isA<ValidationFailure>());
    });

    test('returns ValidationSuccess for unknown field', () async {
      final schema = DupSchema({});
      expect(await schema.validateField('unknown', 'x'), isA<ValidationSuccess>());
    });
  });

  group('DupSchema.crossValidate()', () {
    late DupSchema schema;

    setUp(() {
      schema = DupSchema({
        'password': ValidateString().min(8).required(),
        'passwordConfirm': ValidateString().required(),
      }).crossValidate((fields) {
        if (fields['password'] != fields['passwordConfirm']) {
          return {
            'passwordConfirm': const ValidationFailure(
              code: ValidationCode.custom,
              message: 'Passwords do not match.',
            ),
          };
        }
        return null;
      });
    });

    test('cross-field error returned when passwords differ', () async {
      final result = await schema.validate({
        'password': 'secret123',
        'passwordConfirm': 'different',
      });
      final failure = result as FormValidationFailure;
      expect(failure.hasError('passwordConfirm'), isTrue);
      expect(failure('passwordConfirm')!.message, 'Passwords do not match.');
    });

    test('succeeds when passwords match', () async {
      final result = await schema.validate({
        'password': 'secret123',
        'passwordConfirm': 'secret123',
      });
      expect(result, isA<FormValidationSuccess>());
    });

    test('crossValidate skipped when field-level errors exist', () async {
      // password fails required → crossValidate must not run
      final result = await schema.validate({
        'password': null,
        'passwordConfirm': 'anything',
      });
      final failure = result as FormValidationFailure;
      // Only field-level error, not the cross-field mismatch error
      expect(failure.hasError('password'), isTrue);
      expect(failure.hasError('passwordConfirm'), isFalse);
    });
  });

  group('DupSchema.hasAsyncValidators', () {
    test('false when no async validators', () {
      final schema = DupSchema({'name': ValidateString().required()});
      expect(schema.hasAsyncValidators, isFalse);
    });

    test('true when any field has async validator', () {
      final schema = DupSchema({
        'email': ValidateString()..addAsyncValidator((_) async => null),
      });
      expect(schema.hasAsyncValidators, isTrue);
    });
  });

  group('DupSchema.partial()', () {
    late DupSchema schema;

    setUp(() {
      schema = DupSchema({
        'name':  ValidateString().required().notBlank(),
        'email': ValidateString().required().email(),
      });
    });

    test('null passes for all fields', () async {
      final result = await schema.partial().validate({'name': null, 'email': null});
      expect(result, isA<FormValidationSuccess>());
    });

    test('absent fields pass (treated as null)', () async {
      final result = await schema.partial().validate({});
      expect(result, isA<FormValidationSuccess>());
    });

    test('format errors still fire', () async {
      final result = await schema.partial().validate({'email': 'bad'});
      expect(result, isA<FormValidationFailure>());
      expect((result as FormValidationFailure)('email')!.code, ValidationCode.emailInvalid);
    });

    test('notBlank still fires for submitted blank value', () async {
      final result = await schema.partial().validate({'name': '   '});
      expect(result, isA<FormValidationFailure>());
      expect((result as FormValidationFailure)('name')!.code, ValidationCode.notBlank);
    });

    test('original schema is unaffected', () async {
      schema.partial();
      final result = await schema.validate({'name': null, 'email': null});
      expect(result, isA<FormValidationFailure>());
    });

    test('partial().validateSync() works', () {
      final result = schema.partial().validateSync({'name': null});
      expect(result, isA<FormValidationSuccess>());
    });
  });

  group('DupSchema.pick()', () {
    late DupSchema schema;

    setUp(() {
      schema = DupSchema(
        {
          'name':     ValidateString().required(),
          'email':    ValidateString().required().email(),
          'password': ValidateString().required().min(8),
        },
        labels: {'email': 'Email Address'},
      );
    });

    test('keeps only specified fields', () async {
      final login = schema.pick(['email', 'password']);
      final result = await login.validate({'email': 'a@b.com', 'password': 'secret12'});
      expect(result, isA<FormValidationSuccess>());
    });

    test('excluded fields are not validated', () async {
      final login = schema.pick(['email', 'password']);
      final result = await login.validate({'email': 'a@b.com', 'password': 'secret12', 'name': null});
      expect(result, isA<FormValidationSuccess>());
    });

    test('custom label is preserved in derived schema', () async {
      final login = schema.pick(['email']);
      final result = await login.validate({'email': null});
      final failure = result as FormValidationFailure;
      expect(failure('email')!.message, contains('Email Address'));
    });

    test('original schema is unaffected', () async {
      schema.pick(['email']);
      final result = await schema.validate({'name': null, 'email': null, 'password': null});
      expect(result, isA<FormValidationFailure>());
    });

    test('unknown field names are silently ignored', () {
      expect(() => schema.pick(['nonexistent', 'email']), returnsNormally);
    });
  });

  group('DupSchema.omit()', () {
    late DupSchema schema;

    setUp(() {
      schema = DupSchema({
        'name':     ValidateString().required(),
        'email':    ValidateString().required().email(),
        'password': ValidateString().required().min(8),
      });
    });

    test('excluded field is not validated', () async {
      final profile = schema.omit(['password']);
      final result = await profile.validate({'name': 'Jane', 'email': 'j@b.com'});
      expect(result, isA<FormValidationSuccess>());
    });

    test('remaining fields still validated', () async {
      final profile = schema.omit(['password']);
      final result = await profile.validate({'name': null, 'email': 'j@b.com'});
      expect(result, isA<FormValidationFailure>());
    });
  });

  group('DupSchema.when()', () {
    late DupSchema schema;

    setUp(() {
      schema = DupSchema({
        'paymentType': ValidateString().required().includedIn(['card', 'bank']),
        'cardNumber':  ValidateString(),
        'bankAccount': ValidateString(),
      })
      .when(
        field: 'paymentType',
        condition: (dynamic v) => v == 'card',
        then: {'cardNumber': ValidateString().required().min(16)},
      )
      .when(
        field: 'paymentType',
        condition: (dynamic v) => v == 'bank',
        then: {'bankAccount': ValidateString().required()},
      );
    });

    test('then validators apply when condition matches', () async {
      final result = await schema.validate({'paymentType': 'card', 'cardNumber': null, 'bankAccount': null});
      expect(result, isA<FormValidationFailure>());
      expect((result as FormValidationFailure)('cardNumber')!.code, ValidationCode.required);
    });

    test('then validators are skipped when condition does not match', () async {
      final result = await schema.validate({'paymentType': 'bank', 'cardNumber': null, 'bankAccount': 'ACC123'});
      expect(result, isA<FormValidationSuccess>());
    });

    test('base validators still apply regardless of condition', () async {
      final result = await schema.validate({'paymentType': null, 'cardNumber': null, 'bankAccount': null});
      expect(result, isA<FormValidationFailure>());
      expect((result as FormValidationFailure)('paymentType')!.code, ValidationCode.required);
    });

    test('when().then validators skipped in partial mode', () async {
      final partial = schema.partial();
      final result = await partial.validate({'paymentType': 'card', 'cardNumber': null});
      expect(result, isA<FormValidationSuccess>());
    });

    test('hasAsyncValidators includes then-branch validators', () async {
      final s = DupSchema({'x': ValidateString()})
        .when(
          field: 'x',
          condition: (dynamic v) => v == 'y',
          then: {'x': ValidateString().addAsyncValidator((_) async => null)},
        );
      expect(s.hasAsyncValidators, isTrue);
    });

    test('validateSync() works when no async in any branch', () {
      final result = schema.validateSync({
        'paymentType': 'card',
        'cardNumber': '1234567890123456',
        'bankAccount': null,
      });
      expect(result, isA<FormValidationSuccess>());
    });
  });
}
