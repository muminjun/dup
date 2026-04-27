# dup v2.0.0 API Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `String?`-based validation with a sealed `ValidationResult` type, redesign `ValidatorLocale` to use `ValidationCode` enum keys, and replace `useUiForm` / `FormValidationException` / `BaseValidatorSchema` with a single `DupSchema` class.

**Architecture:** Core types (`ValidationCode`, `ValidationResult`, `FormValidationResult`) are added first. `ValidatorLocale` is replaced with a flat `Map<ValidationCode, LocaleMessage>`. `BaseValidator` is refactored so every internal phase function returns `ValidationFailure?` and `validate()` / `validateAsync()` return `ValidationResult`. All five validator classes are updated in parallel. `DupSchema` replaces the old form-level API. Old files (`form_validate_exception.dart`, `ui_form_service.dart`, `base_validator_schema.dart`) are deleted last.

**Tech Stack:** Dart 3.7+, `test: ^1.25.0`, `lints: ^5.0.0`. Test runner: `dart test`.

---

## File Map

| Action | Path | Responsibility |
|---|---|---|
| Create | `lib/src/model/validation_code.dart` | `ValidationCode` enum — all built-in codes + `custom` |
| Create | `lib/src/model/validation_result.dart` | `ValidationResult` sealed class, `ValidationSuccess`, `ValidationFailure` |
| Create | `lib/src/model/form_validation_result.dart` | `FormValidationResult` sealed class, `FormValidationSuccess`, `FormValidationFailure` |
| Create | `lib/src/util/dup_schema.dart` | `DupSchema` — replaces `BaseValidatorSchema` + `UiFormService` |
| Modify | `lib/src/util/validate_locale.dart` | Flat `Map<ValidationCode, LocaleMessage>`, remove string-keyed maps |
| Modify | `lib/src/util/validator_base.dart` | Return `ValidationResult`, add `toValidator()`, `hasAsyncValidators` |
| Modify | `lib/src/util/validate_string.dart` | Use `ValidationCode`, return `ValidationFailure?` |
| Modify | `lib/src/util/validate_number.dart` | Same + string-parsing `toValidator()` override |
| Modify | `lib/src/util/validate_list.dart` | Same + `eachItem` accepts `ValidationFailure? Function(T)` |
| Modify | `lib/src/util/validate_bool.dart` | Use `ValidationCode.boolTrue` / `.boolFalse` |
| Modify | `lib/src/util/validate_date_time.dart` | Use `ValidationCode.dateXxx` |
| Modify | `lib/dup.dart` | Export new types, remove old |
| Delete | `lib/src/model/base_validator_schema.dart` | Replaced by `DupSchema` |
| Delete | `lib/src/util/form_validate_exception.dart` | Replaced by `FormValidationResult` |
| Delete | `lib/src/util/ui_form_service.dart` | Replaced by `DupSchema` |
| Create | `test/validation_result_test.dart` | Tests for `ValidationSuccess` / `ValidationFailure` |
| Create | `test/form_validation_result_test.dart` | Tests for `FormValidationSuccess` / `FormValidationFailure` |
| Create | `test/dup_schema_test.dart` | Tests for `DupSchema` |
| Replace | `test/validate_locale_test.dart` | Updated for enum-key locale |
| Replace | `test/validate_base_test.dart` | Updated for `ValidationResult` return type |
| Replace | `test/validate_string_test.dart` | Updated |
| Replace | `test/validate_number_test.dart` | Updated |
| Replace | `test/validate_list_test.dart` | Updated |
| Replace | `test/validate_bool_test.dart` | Updated |
| Replace | `test/validate_date_time_test.dart` | Updated |
| Delete | `test/form_validate_exception_test.dart` | No longer relevant |
| Delete | `test/ui_form_service_test.dart` | No longer relevant |
| Update | `test/message_resolution_test.dart` | Update for new locale API |

---

## Task 1: Core types — `ValidationCode`, `ValidationResult`, `ValidationFailure`

**Files:**
- Create: `lib/src/model/validation_code.dart`
- Create: `lib/src/model/validation_result.dart`
- Create: `test/validation_result_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/validation_result_test.dart
import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  group('ValidationSuccess', () {
    test('is a ValidationResult', () {
      const result = ValidationSuccess();
      expect(result, isA<ValidationResult>());
    });

    test('equality', () {
      expect(const ValidationSuccess(), equals(const ValidationSuccess()));
    });
  });

  group('ValidationFailure', () {
    test('stores code, message, context', () {
      const f = ValidationFailure(
        code: ValidationCode.required,
        message: 'Field is required.',
        context: {'name': 'Email'},
      );
      expect(f.code, ValidationCode.required);
      expect(f.message, 'Field is required.');
      expect(f.context['name'], 'Email');
    });

    test('customCode defaults to null', () {
      const f = ValidationFailure(
        code: ValidationCode.custom,
        message: 'Custom error.',
      );
      expect(f.customCode, isNull);
    });

    test('customCode can be set', () {
      const f = ValidationFailure(
        code: ValidationCode.custom,
        customCode: 'myTag',
        message: 'Custom error.',
      );
      expect(f.customCode, 'myTag');
    });

    test('context defaults to empty map', () {
      const f = ValidationFailure(
        code: ValidationCode.emailInvalid,
        message: 'Bad email.',
      );
      expect(f.context, isEmpty);
    });

    test('is a ValidationResult', () {
      const f = ValidationFailure(code: ValidationCode.required, message: 'req');
      expect(f, isA<ValidationResult>());
    });
  });

  group('switch exhaustiveness', () {
    test('sealed class switch covers both cases', () {
      ValidationResult result = const ValidationSuccess();
      final output = switch (result) {
        ValidationSuccess() => 'ok',
        ValidationFailure(:final message) => message,
      };
      expect(output, 'ok');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
dart test test/validation_result_test.dart
```

Expected: compilation error — `ValidationCode`, `ValidationResult`, `ValidationSuccess`, `ValidationFailure` not defined.

- [ ] **Step 3: Create `lib/src/model/validation_code.dart`**

```dart
enum ValidationCode {
  // shared
  required, notBlank, equal, notEqual, oneOf, notOneOf, condition, custom,

  // string
  stringMin, stringMax, matches, emailInvalid, passwordMin, emoji,
  mobileInvalid, phoneInvalid, biznoInvalid, url, uuid,
  alpha, alphanumeric, numeric,

  // number
  numberMin, numberMax, integer, positive, negative,
  nonNegative, nonPositive, between, even, odd, multipleOf,

  // list
  listNotEmpty, listEmpty, listMin, listMax, listLengthBetween,
  listExactLength, contains, doesNotContain, all, any, none,
  noDuplicates, eachItem,

  // datetime
  dateMin, dateMax, dateBefore, dateAfter, dateBetween,
  dateInFuture, dateInPast,

  // bool
  boolTrue, boolFalse,
}
```

- [ ] **Step 4: Create `lib/src/model/validation_result.dart`**

```dart
import 'validation_code.dart';

sealed class ValidationResult {
  const ValidationResult();
}

class ValidationSuccess extends ValidationResult {
  const ValidationSuccess();
}

class ValidationFailure extends ValidationResult {
  final ValidationCode code;

  /// Optional tag for user-defined validators using [ValidationCode.custom].
  final String? customCode;

  /// Resolved message string — snapshot at validation time.
  final String message;

  /// Parameters used to build [message] (e.g. {name: 'Email', min: 3}).
  final Map<String, dynamic> context;

  const ValidationFailure({
    required this.code,
    this.customCode,
    required this.message,
    this.context = const {},
  });
}
```

- [ ] **Step 5: Export from `lib/dup.dart` (add only the new lines; do not remove anything yet)**

Open `lib/dup.dart` and add after `library;`:

```dart
export 'src/model/validation_code.dart';
export 'src/model/validation_result.dart';
```

- [ ] **Step 6: Run test to verify it passes**

```
dart test test/validation_result_test.dart
```

Expected: All tests pass.

- [ ] **Step 7: Commit**

```bash
git add lib/src/model/validation_code.dart \
        lib/src/model/validation_result.dart \
        lib/dup.dart \
        test/validation_result_test.dart
git commit -m "feat: add ValidationCode enum and ValidationResult sealed class"
```

---

## Task 2: `FormValidationResult` sealed class

**Files:**
- Create: `lib/src/model/form_validation_result.dart`
- Create: `test/form_validation_result_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
// test/form_validation_result_test.dart
import 'package:dup/dup.dart';
import 'package:test/test.dart';

const _emailFailure = ValidationFailure(
  code: ValidationCode.emailInvalid,
  message: 'Invalid email.',
);
const _requiredFailure = ValidationFailure(
  code: ValidationCode.required,
  message: 'Password is required.',
);

void main() {
  group('FormValidationSuccess', () {
    test('is a FormValidationResult', () {
      expect(const FormValidationSuccess(), isA<FormValidationResult>());
    });
  });

  group('FormValidationFailure', () {
    late FormValidationFailure failure;

    setUp(() {
      failure = FormValidationFailure({
        'email': _emailFailure,
        'password': _requiredFailure,
      });
    });

    test('is a FormValidationResult', () {
      expect(failure, isA<FormValidationResult>());
    });

    test('call() returns failure for a field', () {
      expect(failure('email'), _emailFailure);
    });

    test('call() returns null for unknown field', () {
      expect(failure('age'), isNull);
    });

    test('hasError() true for failing field', () {
      expect(failure.hasError('email'), isTrue);
    });

    test('hasError() false for unknown field', () {
      expect(failure.hasError('age'), isFalse);
    });

    test('fields returns all failing field names', () {
      expect(failure.fields, containsAll(['email', 'password']));
    });

    test('firstField returns first failing field', () {
      expect(failure.firstField, isNotNull);
      expect(['email', 'password'], contains(failure.firstField));
    });
  });

  group('switch exhaustiveness', () {
    test('sealed FormValidationResult switch', () {
      final FormValidationResult result = const FormValidationSuccess();
      final output = switch (result) {
        FormValidationSuccess() => 'ok',
        FormValidationFailure() => 'fail',
      };
      expect(output, 'ok');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
dart test test/form_validation_result_test.dart
```

Expected: compilation error — `FormValidationResult`, `FormValidationSuccess`, `FormValidationFailure` not defined.

- [ ] **Step 3: Create `lib/src/model/form_validation_result.dart`**

```dart
import 'validation_result.dart';

sealed class FormValidationResult {
  const FormValidationResult();
}

class FormValidationSuccess extends FormValidationResult {
  const FormValidationSuccess();
}

class FormValidationFailure extends FormValidationResult {
  final Map<String, ValidationFailure> errors;

  const FormValidationFailure(this.errors);

  ValidationFailure? call(String field) => errors[field];

  bool hasError(String field) => errors.containsKey(field);

  List<String> get fields => errors.keys.toList();

  String? get firstField => errors.keys.firstOrNull;
}
```

- [ ] **Step 4: Export from `lib/dup.dart`**

Add to `lib/dup.dart`:

```dart
export 'src/model/form_validation_result.dart';
```

- [ ] **Step 5: Run test to verify it passes**

```
dart test test/form_validation_result_test.dart
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/src/model/form_validation_result.dart \
        lib/dup.dart \
        test/form_validation_result_test.dart
git commit -m "feat: add FormValidationResult sealed class"
```

---

## Task 3: Redesign `ValidatorLocale`

Replace six category maps (`mixed`, `number`, `string`, `array`, `boolMessages`, `date`) with a single flat `Map<ValidationCode, LocaleMessage>`. Remove `ValidatorLocaleKeys`.

**Files:**
- Modify: `lib/src/util/validate_locale.dart`
- Replace: `test/validate_locale_test.dart`

- [ ] **Step 1: Write the failing test**

Overwrite `test/validate_locale_test.dart`:

```dart
import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('ValidatorLocale', () {
    test('current is null by default', () {
      expect(ValidatorLocale.current, isNull);
    });

    test('setLocale sets current', () {
      final locale = ValidatorLocale({
        ValidationCode.required: (p) => '${p['name']}은(는) 필수입니다.',
      });
      ValidatorLocale.setLocale(locale);
      expect(ValidatorLocale.current, same(locale));
    });

    test('resetLocale sets current back to null', () {
      ValidatorLocale.setLocale(ValidatorLocale({}));
      ValidatorLocale.resetLocale();
      expect(ValidatorLocale.current, isNull);
    });

    test('messages map is accessible', () {
      final locale = ValidatorLocale({
        ValidationCode.required: (p) => 'required: ${p['name']}',
        ValidationCode.emailInvalid: (_) => '이메일 형식 오류',
      });
      expect(
        locale.messages[ValidationCode.required]?.call({'name': 'Email'}),
        'required: Email',
      );
      expect(
        locale.messages[ValidationCode.emailInvalid]?.call({}),
        '이메일 형식 오류',
      );
    });

    test('unspecified code returns null (falls through to default)', () {
      final locale = ValidatorLocale({
        ValidationCode.required: (_) => '필수',
      });
      expect(locale.messages[ValidationCode.emailInvalid], isNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
dart test test/validate_locale_test.dart
```

Expected: Tests fail because `ValidatorLocale` currently has separate category maps and no `messages` field.

- [ ] **Step 3: Rewrite `lib/src/util/validate_locale.dart`**

```dart
import '../model/locale_message.dart';
import '../model/validation_code.dart';

class ValidatorLocale {
  static ValidatorLocale? _current;

  final Map<ValidationCode, LocaleMessage> messages;

  const ValidatorLocale(this.messages);

  static void setLocale(ValidatorLocale locale) => _current = locale;
  static void resetLocale() => _current = null;
  static ValidatorLocale? get current => _current;
}
```

- [ ] **Step 4: Run test to verify it passes**

```
dart test test/validate_locale_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Run full suite to see what broke**

```
dart test
```

Expected: Failures in `validate_string_test.dart`, `validate_number_test.dart`, `validate_list_test.dart`, `validate_bool_test.dart`, `validate_date_time_test.dart`, `validate_base_test.dart`, `message_resolution_test.dart` — because those validators still reference `ValidatorLocale.current?.string[...]` etc. These will be fixed in Tasks 4–9.

- [ ] **Step 6: Commit**

```bash
git add lib/src/util/validate_locale.dart test/validate_locale_test.dart
git commit -m "feat: redesign ValidatorLocale to use ValidationCode enum keys"
```

---

## Task 4: Refactor `BaseValidator`

Change all internal phase functions to return `ValidationFailure?`. Change `validate()` to return `ValidationResult`. Add `hasAsyncValidators`, `toValidator()`, `toAsyncValidator()`. Replace `getErrorMessage` with `getFailure`.

**Files:**
- Modify: `lib/src/util/validator_base.dart`
- Replace: `test/validate_base_test.dart`

- [ ] **Step 1: Write the failing test**

Overwrite `test/validate_base_test.dart`:

```dart
import 'package:dup/dup.dart';
import 'package:test/test.dart';

// Minimal concrete subclass for testing BaseValidator directly.
class _StringValidator extends BaseValidator<String, _StringValidator> {}

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('validate() returns ValidationResult', () {
    test('returns ValidationSuccess when no validators registered', () {
      final v = _StringValidator();
      expect(v.validate('hello'), isA<ValidationSuccess>());
    });

    test('returns ValidationFailure when validator fails', () {
      final v = _StringValidator()
        ..addPhaseValidator(1, (value) => value == null
            ? null
            : const ValidationFailure(
                code: ValidationCode.custom, message: 'bad'));
      final result = v.validate('x');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).message, 'bad');
    });

    test('returns ValidationSuccess when validator passes', () {
      final v = _StringValidator()
        ..addPhaseValidator(1, (_) => null);
      expect(v.validate('x'), isA<ValidationSuccess>());
    });
  });

  group('validateAsync() returns Future<ValidationResult>', () {
    test('async validator failure is returned', () async {
      final v = _StringValidator()
        ..addAsyncValidator((_) async => const ValidationFailure(
              code: ValidationCode.custom, message: 'async fail'));
      final result = await v.validateAsync('x');
      expect(result, isA<ValidationFailure>());
    });

    test('sync failure short-circuits async', () async {
      var asyncCalled = false;
      final v = _StringValidator()
        ..addPhaseValidator(1, (_) => const ValidationFailure(
              code: ValidationCode.custom, message: 'sync'))
        ..addAsyncValidator((_) async {
          asyncCalled = true;
          return null;
        });
      await v.validateAsync('x');
      expect(asyncCalled, isFalse);
    });
  });

  group('hasAsyncValidators', () {
    test('false when no async validators', () {
      expect(_StringValidator().hasAsyncValidators, isFalse);
    });

    test('true when async validator added', () {
      final v = _StringValidator()..addAsyncValidator((_) async => null);
      expect(v.hasAsyncValidators, isTrue);
    });
  });

  group('toValidator()', () {
    test('returns null on success', () {
      final fn = _StringValidator().toValidator();
      expect(fn('hello'), isNull);
    });

    test('returns message string on failure', () {
      final v = _StringValidator()
        ..addPhaseValidator(1, (_) => const ValidationFailure(
              code: ValidationCode.custom, message: 'err'));
      expect(v.toValidator()('x'), 'err');
    });
  });

  group('required()', () {
    test('fails for null', () {
      final result = _StringValidator().required().validate(null);
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.required);
    });

    test('fails for empty string', () {
      final result = _StringValidator().required().validate('');
      expect(result, isA<ValidationFailure>());
    });

    test('passes for non-empty string', () {
      expect(_StringValidator().required().validate('x'), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final v = _StringValidator().setLabel('Email').required(
            messageFactory: (label, _) => '$label 필수',
          );
      final result = v.validate(null) as ValidationFailure;
      expect(result.message, 'Email 필수');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.required: (p) => '${p['name']} 필수',
      }));
      final result = _StringValidator().setLabel('이메일').required().validate(null)
          as ValidationFailure;
      expect(result.message, '이메일 필수');
    });
  });

  group('addValidator()', () {
    test('custom ValidationFailure is returned', () {
      final v = _StringValidator().addValidator((value) {
        if (value == 'bad') {
          return const ValidationFailure(
              code: ValidationCode.custom, message: 'not allowed');
        }
        return null;
      });
      expect(v.validate('bad'), isA<ValidationFailure>());
      expect(v.validate('ok'), isA<ValidationSuccess>());
    });
  });

  group('phase ordering', () {
    test('phase 0 runs before phase 1', () {
      final log = <int>[];
      final v = _StringValidator()
        ..addPhaseValidator(1, (_) { log.add(1); return null; })
        ..addPhaseValidator(0, (_) { log.add(0); return null; });
      v.validate('x');
      expect(log, [0, 1]);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
dart test test/validate_base_test.dart
```

Expected: failures because `validate()` still returns `String?` and `hasAsyncValidators` / `toValidator()` don't exist.

- [ ] **Step 3: Rewrite `lib/src/util/validator_base.dart`**

```dart
import '../model/locale_message.dart';
import '../model/message_factory.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'validate_locale.dart';

class _ValidatorEntry<T> {
  final int phase;
  final ValidationFailure? Function(T?) fn;
  const _ValidatorEntry(this.phase, this.fn);
}

abstract class BaseValidator<T, V extends BaseValidator<T, V>> {
  final List<_ValidatorEntry<T>> _entries = [];
  final List<Future<ValidationFailure?> Function(T?)> _asyncEntries = [];

  String label = '';

  V setLabel(String text) {
    label = text;
    return this as V;
  }

  bool get hasAsyncValidators => _asyncEntries.isNotEmpty;

  V addPhaseValidator(int phase, ValidationFailure? Function(T?) fn) {
    _entries.add(_ValidatorEntry(phase, fn));
    return this as V;
  }

  V addValidator(ValidationFailure? Function(T?) fn) => addPhaseValidator(3, fn);

  V addAsyncValidator(Future<ValidationFailure?> Function(T?) fn) {
    _asyncEntries.add(fn);
    return this as V;
  }

  V required({MessageFactory? messageFactory}) {
    return addPhaseValidator(0, (value) {
      if (value == null || (value is String && value.isEmpty)) {
        return getFailure(
          messageFactory,
          ValidationCode.required,
          {'name': label},
          '$label is required.',
        );
      }
      return null;
    });
  }

  V equalTo(T target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && value != target) {
        return getFailure(
          messageFactory,
          ValidationCode.equal,
          {'name': label},
          '$label does not match.',
        );
      }
      return null;
    });
  }

  V notEqualTo(T target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && value == target) {
        return getFailure(
          messageFactory,
          ValidationCode.notEqual,
          {'name': label},
          '$label is not allowed.',
        );
      }
      return null;
    });
  }

  V includedIn(List<T> allowedValues, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && !allowedValues.contains(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.oneOf,
          {'name': label, 'options': allowedValues.join(', ')},
          '$label must be one of: ${allowedValues.join(', ')}.',
        );
      }
      return null;
    });
  }

  V excludedFrom(List<T> forbiddenValues, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && forbiddenValues.contains(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.notOneOf,
          {'name': label, 'options': forbiddenValues.join(', ')},
          '$label must not be one of: ${forbiddenValues.join(', ')}.',
        );
      }
      return null;
    });
  }

  V satisfy(bool Function(T?) condition, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value == null) return null;
      if (!condition(value)) {
        return getFailure(
          messageFactory,
          ValidationCode.condition,
          {'name': label},
          '$label does not satisfy the condition.',
        );
      }
      return null;
    });
  }

  ValidationResult validate(T? value) {
    final sorted = List<_ValidatorEntry<T>>.from(_entries)
      ..sort((a, b) => a.phase.compareTo(b.phase));
    for (final entry in sorted) {
      final failure = entry.fn(value);
      if (failure != null) return failure;
    }
    return const ValidationSuccess();
  }

  Future<ValidationResult> validateAsync(T? value) async {
    final syncResult = validate(value);
    if (syncResult is ValidationFailure) return syncResult;
    for (final fn in _asyncEntries) {
      final failure = await fn(value);
      if (failure != null) return failure;
    }
    return const ValidationSuccess();
  }

  /// Returns a sync adapter compatible with Flutter's TextFormField.validator.
  String? Function(T?) toValidator() {
    return (value) {
      final result = validate(value);
      return result is ValidationFailure ? result.message : null;
    };
  }

  /// Returns an async adapter for non-Flutter async contexts.
  /// NOT compatible with TextFormField.validator (which is synchronous).
  Future<String?> Function(T?) toAsyncValidator() {
    return (value) async {
      final result = await validateAsync(value);
      return result is ValidationFailure ? result.message : null;
    };
  }

  ValidationFailure getFailure(
    MessageFactory? customFactory,
    ValidationCode code,
    Map<String, dynamic> context,
    String defaultMessage,
  ) {
    final message = customFactory?.call(label, context) ??
        ValidatorLocale.current?.messages[code]?.call(context) ??
        defaultMessage;
    return ValidationFailure(code: code, message: message, context: context);
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```
dart test test/validate_base_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/validator_base.dart test/validate_base_test.dart
git commit -m "feat: refactor BaseValidator to return ValidationResult"
```

---

## Task 5: Update `ValidateString`

**Files:**
- Modify: `lib/src/util/validate_string.dart`
- Replace: `test/validate_string_test.dart`

- [ ] **Step 1: Write the failing test**

Overwrite `test/validate_string_test.dart`:

```dart
import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('min()', () {
    test('passes when length >= min', () {
      expect(ValidateString().min(3).validate('abc'), isA<ValidationSuccess>());
    });

    test('fails when length < min', () {
      final result = ValidateString().setLabel('Name').min(3).validate('ab');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.stringMin);
      expect(result.context['min'], 3);
    });

    test('passes for null (null-skip)', () {
      expect(ValidateString().min(3).validate(null), isA<ValidationSuccess>());
    });

    test('uses messageFactory', () {
      final result = ValidateString().setLabel('이름').min(3,
          messageFactory: (label, p) => '$label 최소 ${p['min']}자').validate('ab')
          as ValidationFailure;
      expect(result.message, '이름 최소 3자');
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.stringMin: (p) => '${p['name']} 짧음',
      }));
      final result = ValidateString().setLabel('비번').min(8).validate('abc')
          as ValidationFailure;
      expect(result.message, '비번 짧음');
    });
  });

  group('email()', () {
    test('passes for valid email', () {
      expect(ValidateString().email().validate('a@b.com'), isA<ValidationSuccess>());
    });

    test('fails for invalid email', () {
      final result = ValidateString().email().validate('notanemail');
      expect(result, isA<ValidationFailure>());
      expect((result as ValidationFailure).code, ValidationCode.emailInvalid);
    });

    test('passes for null', () {
      expect(ValidateString().email().validate(null), isA<ValidationSuccess>());
    });

    test('passes for empty string', () {
      expect(ValidateString().email().validate(''), isA<ValidationSuccess>());
    });
  });

  group('required()', () {
    test('fails for null', () {
      final result = ValidateString().required().validate(null);
      expect((result as ValidationFailure).code, ValidationCode.required);
    });

    test('fails for empty string', () {
      expect(ValidateString().required().validate(''), isA<ValidationFailure>());
    });
  });

  group('notBlank()', () {
    test('fails for whitespace-only string', () {
      final result = ValidateString().notBlank().validate('   ');
      expect((result as ValidationFailure).code, ValidationCode.notBlank);
    });

    test('passes for null', () {
      expect(ValidateString().notBlank().validate(null), isA<ValidationSuccess>());
    });
  });

  group('max()', () {
    test('fails when length > max', () {
      final result = ValidateString().max(2).validate('abc');
      expect((result as ValidationFailure).code, ValidationCode.stringMax);
    });
  });

  group('matches()', () {
    test('fails when regex does not match', () {
      final result = ValidateString().matches(RegExp(r'^\d+$')).validate('abc');
      expect((result as ValidationFailure).code, ValidationCode.matches);
    });
  });

  group('password()', () {
    test('fails when too short', () {
      final result = ValidateString().password(minLength: 8).validate('short');
      expect((result as ValidationFailure).code, ValidationCode.passwordMin);
    });
  });

  group('alpha()', () {
    test('fails for non-alpha string', () {
      final result = ValidateString().alpha().validate('abc123');
      expect((result as ValidationFailure).code, ValidationCode.alpha);
    });
  });

  group('toValidator()', () {
    test('returns null on success', () {
      expect(ValidateString().email().toValidator()('a@b.com'), isNull);
    });

    test('returns message string on failure', () {
      final fn = ValidateString().setLabel('Email').email().toValidator();
      expect(fn('bad'), isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
dart test test/validate_string_test.dart
```

Expected: failures because `validate_string.dart` still calls `ValidatorLocale.current?.string[...]`.

- [ ] **Step 3: Rewrite `lib/src/util/validate_string.dart`**

```dart
import '../model/message_factory.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'validate_locale.dart';
import 'validator_base.dart';

class ValidateString extends BaseValidator<String, ValidateString> {
  ValidateString min(int min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.trim().length < min) {
        return getFailure(messageFactory, ValidationCode.stringMin,
            {'name': label, 'min': min}, '$label must be at least $min characters.');
      }
      return null;
    });
  }

  ValidateString max(int max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.trim().length > max) {
        return getFailure(messageFactory, ValidationCode.stringMax,
            {'name': label, 'max': max}, '$label must be at most $max characters.');
      }
      return null;
    });
  }

  ValidateString matches(RegExp regex, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && !regex.hasMatch(value.trim())) {
        return getFailure(messageFactory, ValidationCode.matches,
            {'name': label}, '$label does not match the required format.');
      }
      return null;
    });
  }

  ValidateString email({MessageFactory? messageFactory}) {
    const emailRegex =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@'
        r'((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|'
        r'(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(emailRegex).hasMatch(value.trim())) {
        return getFailure(messageFactory, ValidationCode.emailInvalid,
            {'name': label}, '$label is not a valid email address.');
      }
      return null;
    });
  }

  ValidateString password({int minLength = 4, MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (value.trim().length < minLength) {
        return getFailure(messageFactory, ValidationCode.passwordMin,
            {'name': label, 'minLength': minLength},
            '$label must be at least $minLength characters.');
      }
      return null;
    });
  }

  ValidateString emoji({MessageFactory? messageFactory}) {
    final emojiRegex = RegExp(r'\p{Emoji_Presentation}', unicode: true);
    return addPhaseValidator(1, (value) {
      if (value != null && value.isNotEmpty && emojiRegex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.emoji,
            {'name': label}, '$label cannot contain emoji.');
      }
      return null;
    });
  }

  ValidateString notBlank({MessageFactory? messageFactory}) {
    return addPhaseValidator(0, (value) {
      if (value != null && value.trim().isEmpty) {
        return getFailure(messageFactory, ValidationCode.notBlank,
            {'name': label}, '$label cannot be blank.');
      }
      return null;
    });
  }

  ValidateString alpha({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(r'^[a-zA-Z]+$').hasMatch(value.trim())) {
        return getFailure(messageFactory, ValidationCode.alpha,
            {'name': label}, '$label must contain only letters.');
      }
      return null;
    });
  }

  ValidateString alphanumeric({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(value.trim())) {
        return getFailure(messageFactory, ValidationCode.alphanumeric,
            {'name': label}, '$label must contain only letters and numbers.');
      }
      return null;
    });
  }

  ValidateString numeric({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (!RegExp(r'^[0-9]+$').hasMatch(value.trim())) {
        return getFailure(messageFactory, ValidationCode.numeric,
            {'name': label}, '$label must contain only digits.');
      }
      return null;
    });
  }

  ValidateString mobile({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^\d{2,3}-\d{3,4}-\d{4}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.mobileInvalid,
            {'name': label}, '$label is not a valid mobile number.');
      }
      return null;
    });
  }

  ValidateString phone({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^(0[2-9]{1}\d?)-\d{3,4}-\d{4}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.phoneInvalid,
            {'name': label}, '$label is not a valid phone number.');
      }
      return null;
    });
  }

  ValidateString bizno({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^\d{3}-\d{2}-\d{5}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.biznoInvalid,
            {'name': label}, '$label is not a valid business registration number.');
      }
      return null;
    });
  }

  ValidateString url({MessageFactory? messageFactory}) {
    final regex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.url,
            {'name': label}, '$label is not a valid URL.');
      }
      return null;
    });
  }

  ValidateString uuid({MessageFactory? messageFactory}) {
    final regex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        return getFailure(messageFactory, ValidationCode.uuid,
            {'name': label}, '$label is not a valid UUID.');
      }
      return null;
    });
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```
dart test test/validate_string_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/validate_string.dart test/validate_string_test.dart
git commit -m "feat: update ValidateString to use ValidationCode and return ValidationFailure"
```

---

## Task 6: Update `ValidateNumber`

Includes string-parsing `toValidator()` override for `TextFormField` compatibility.

**Files:**
- Modify: `lib/src/util/validate_number.dart`
- Replace: `test/validate_number_test.dart`

- [ ] **Step 1: Write the failing test**

Overwrite `test/validate_number_test.dart`:

```dart
import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('min()', () {
    test('passes when value >= min', () {
      expect(ValidateNumber().min(5).validate(10), isA<ValidationSuccess>());
    });

    test('fails when value < min', () {
      final result = ValidateNumber().min(18).validate(17);
      expect((result as ValidationFailure).code, ValidationCode.numberMin);
      expect(result.context['min'], 18);
    });

    test('passes for null', () {
      expect(ValidateNumber().min(5).validate(null), isA<ValidationSuccess>());
    });
  });

  group('max()', () {
    test('fails when value > max', () {
      final result = ValidateNumber().max(100).validate(200);
      expect((result as ValidationFailure).code, ValidationCode.numberMax);
    });
  });

  group('isInteger()', () {
    test('fails for decimal', () {
      final result = ValidateNumber().isInteger().validate(1.5);
      expect((result as ValidationFailure).code, ValidationCode.integer);
    });

    test('passes for whole number', () {
      expect(ValidateNumber().isInteger().validate(3), isA<ValidationSuccess>());
    });
  });

  group('isPositive()', () {
    test('fails for zero', () {
      expect(ValidateNumber().isPositive().validate(0), isA<ValidationFailure>());
    });

    test('passes for positive', () {
      expect(ValidateNumber().isPositive().validate(1), isA<ValidationSuccess>());
    });
  });

  group('between()', () {
    test('fails outside range', () {
      final result = ValidateNumber().between(1, 10).validate(0);
      expect((result as ValidationFailure).code, ValidationCode.between);
    });
  });

  group('toValidator() — string-parsing override', () {
    test('returns null for valid input', () {
      final fn = ValidateNumber().min(18).toValidator();
      expect(fn('20'), isNull);
    });

    test('returns parse error for non-numeric input', () {
      final fn = ValidateNumber().setLabel('나이').min(18).toValidator();
      expect(fn('abc'), contains('나이'));
    });

    test('returns validation error for out-of-range input', () {
      final fn = ValidateNumber().setLabel('나이').min(18).toValidator();
      expect(fn('17'), isNotNull);
    });

    test('passes null through to required check', () {
      final fn = ValidateNumber().required().toValidator();
      expect(fn(null), isNotNull);
    });
  });

  group('locale', () {
    test('uses locale message for numberMin', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.numberMin: (p) => '${p['name']} 최솟값 초과',
      }));
      final result = ValidateNumber().setLabel('나이').min(18).validate(10)
          as ValidationFailure;
      expect(result.message, '나이 최솟값 초과');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
dart test test/validate_number_test.dart
```

Expected: failures because `validate_number.dart` still uses old locale API, and `toValidator()` returns `String? Function(num?)` not `String? Function(String?)`.

- [ ] **Step 3: Rewrite `lib/src/util/validate_number.dart`**

```dart
import '../model/message_factory.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'validator_base.dart';

class ValidateNumber extends BaseValidator<num, ValidateNumber> {
  ValidateNumber min(num min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value < min) {
        return getFailure(messageFactory, ValidationCode.numberMin,
            {'name': label, 'min': min}, '$label must be at least $min.');
      }
      return null;
    });
  }

  ValidateNumber max(num max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value > max) {
        return getFailure(messageFactory, ValidationCode.numberMax,
            {'name': label, 'max': max}, '$label must be at most $max.');
      }
      return null;
    });
  }

  ValidateNumber isInteger({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && value % 1 != 0) {
        return getFailure(messageFactory, ValidationCode.integer,
            {'name': label}, '$label must be an integer.');
      }
      return null;
    });
  }

  ValidateNumber isPositive({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value <= 0) {
        return getFailure(messageFactory, ValidationCode.positive,
            {'name': label}, '$label must be positive.');
      }
      return null;
    });
  }

  ValidateNumber isNegative({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value >= 0) {
        return getFailure(messageFactory, ValidationCode.negative,
            {'name': label}, '$label must be negative.');
      }
      return null;
    });
  }

  ValidateNumber isNonNegative({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value < 0) {
        return getFailure(messageFactory, ValidationCode.nonNegative,
            {'name': label}, '$label must be zero or positive.');
      }
      return null;
    });
  }

  ValidateNumber isNonPositive({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value > 0) {
        return getFailure(messageFactory, ValidationCode.nonPositive,
            {'name': label}, '$label must be zero or negative.');
      }
      return null;
    });
  }

  ValidateNumber between(num min, num max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && (value < min || value > max)) {
        return getFailure(messageFactory, ValidationCode.between,
            {'name': label, 'min': min, 'max': max},
            '$label must be between $min and $max.');
      }
      return null;
    });
  }

  ValidateNumber isEven({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value % 2 != 0) {
        return getFailure(messageFactory, ValidationCode.even,
            {'name': label}, '$label must be an even number.');
      }
      return null;
    });
  }

  ValidateNumber isOdd({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value % 2 == 0) {
        return getFailure(messageFactory, ValidationCode.odd,
            {'name': label}, '$label must be an odd number.');
      }
      return null;
    });
  }

  ValidateNumber isMultipleOf(num factor, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value % factor != 0) {
        return getFailure(messageFactory, ValidationCode.multipleOf,
            {'name': label, 'factor': factor},
            '$label must be a multiple of $factor.');
      }
      return null;
    });
  }

  /// Parses a [String?] input to [num] then validates.
  /// Compatible with Flutter's TextFormField.validator.
  /// Returns a parse error if input is non-null, non-empty, and not a valid number.
  String? Function(String?) toValidator({String? parseErrorMessage}) {
    return (String? input) {
      if (input == null || input.isEmpty) {
        final result = validate(null);
        return result is ValidationFailure ? result.message : null;
      }
      final parsed = num.tryParse(input);
      if (parsed == null) {
        return parseErrorMessage ?? '$label is not a valid number.';
      }
      final result = validate(parsed);
      return result is ValidationFailure ? result.message : null;
    };
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```
dart test test/validate_number_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/validate_number.dart test/validate_number_test.dart
git commit -m "feat: update ValidateNumber to use ValidationCode, add string-parsing toValidator()"
```

---

## Task 7: Update `ValidateList`

`eachItem` signature changes from `String? Function(T)` to `ValidationFailure? Function(T)`.

**Files:**
- Modify: `lib/src/util/validate_list.dart`
- Replace: `test/validate_list_test.dart`

- [ ] **Step 1: Write the failing test**

Overwrite `test/validate_list_test.dart`:

```dart
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
```

- [ ] **Step 2: Run test to verify it fails**

```
dart test test/validate_list_test.dart
```

Expected: failures due to old locale API and `eachItem` type mismatch.

- [ ] **Step 3: Rewrite `lib/src/util/validate_list.dart`**

```dart
import '../model/message_factory.dart';
import '../model/validation_code.dart';
import '../model/validation_result.dart';
import 'validator_base.dart';

class ValidateList<T> extends BaseValidator<List<T>, ValidateList<T>> {
  ValidateList<T> isNotEmpty({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) {
        return getFailure(messageFactory, ValidationCode.listNotEmpty,
            {'name': label}, '$label cannot be empty.');
      }
      return null;
    });
  }

  ValidateList<T> isEmpty({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && value.isNotEmpty) {
        return getFailure(messageFactory, ValidationCode.listEmpty,
            {'name': label}, '$label must be empty.');
      }
      return null;
    });
  }

  ValidateList<T> minLength(int min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.length < min) {
        return getFailure(messageFactory, ValidationCode.listMin,
            {'name': label, 'min': min}, '$label must have at least $min items.');
      }
      return null;
    });
  }

  ValidateList<T> maxLength(int max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.length > max) {
        return getFailure(messageFactory, ValidationCode.listMax,
            {'name': label, 'max': max},
            '$label cannot have more than $max items.');
      }
      return null;
    });
  }

  ValidateList<T> lengthBetween(int min, int max,
      {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.length < min || value.length > max) {
        return getFailure(messageFactory, ValidationCode.listLengthBetween,
            {'name': label, 'min': min, 'max': max},
            '$label length must be between $min and $max.');
      }
      return null;
    });
  }

  ValidateList<T> hasLength(int length, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.length != length) {
        return getFailure(messageFactory, ValidationCode.listExactLength,
            {'name': label, 'length': length},
            '$label must have exactly $length items.');
      }
      return null;
    });
  }

  ValidateList<T> contains(T item, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null || !value.contains(item)) {
        return getFailure(messageFactory, ValidationCode.contains,
            {'name': label, 'item': item}, '$label must contain $item.');
      }
      return null;
    });
  }

  ValidateList<T> doesNotContain(T item, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.contains(item)) {
        return getFailure(messageFactory, ValidationCode.doesNotContain,
            {'name': label, 'item': item}, '$label must not contain $item.');
      }
      return null;
    });
  }

  ValidateList<T> all(bool Function(T) predicate,
      {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && !value.every(predicate)) {
        return getFailure(messageFactory, ValidationCode.all, {'name': label},
            'All items in $label must satisfy the condition.');
      }
      return null;
    });
  }

  ValidateList<T> any(bool Function(T) predicate,
      {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (!value.any(predicate)) {
        return getFailure(messageFactory, ValidationCode.any, {'name': label},
            'At least one item in $label must satisfy the condition.');
      }
      return null;
    });
  }

  ValidateList<T> none(bool Function(T) predicate,
      {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.any(predicate)) {
        return getFailure(messageFactory, ValidationCode.none, {'name': label},
            'No items in $label must satisfy the condition.');
      }
      return null;
    });
  }

  ValidateList<T> hasNoDuplicates({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.toSet().length != value.length) {
        return getFailure(messageFactory, ValidationCode.noDuplicates,
            {'name': label}, '$label must not contain duplicate items.');
      }
      return null;
    });
  }

  ValidateList<T> eachItem(
    ValidationFailure? Function(T) itemValidator, {
    MessageFactory? messageFactory,
  }) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      for (int i = 0; i < value.length; i++) {
        final failure = itemValidator(value[i]);
        if (failure != null) {
          final msg = messageFactory
                  ?.call(label, {'index': i, 'error': failure.message}) ??
              getFailure(null, ValidationCode.eachItem,
                      {'name': label, 'index': i, 'error': failure.message},
                      'Item at index $i in $label: ${failure.message}')
                  .message;
          return ValidationFailure(
            code: ValidationCode.eachItem,
            message: msg,
            context: {'name': label, 'index': i, 'innerFailure': failure},
          );
        }
      }
      return null;
    });
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```
dart test test/validate_list_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/validate_list.dart test/validate_list_test.dart
git commit -m "feat: update ValidateList to use ValidationCode; eachItem accepts ValidationFailure?"
```

---

## Task 8: Update `ValidateBool`

**Files:**
- Modify: `lib/src/util/validate_bool.dart`
- Replace: `test/validate_bool_test.dart`

- [ ] **Step 1: Write the failing test**

Overwrite `test/validate_bool_test.dart`:

```dart
import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('isTrue()', () {
    test('passes for true', () {
      expect(ValidateBool().isTrue().validate(true), isA<ValidationSuccess>());
    });

    test('fails for false', () {
      final result = ValidateBool().isTrue().validate(false);
      expect((result as ValidationFailure).code, ValidationCode.boolTrue);
    });

    test('passes for null', () {
      expect(ValidateBool().isTrue().validate(null), isA<ValidationSuccess>());
    });

    test('uses locale', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.boolTrue: (p) => '${p['name']} 참이어야 합니다.',
      }));
      final result = ValidateBool().setLabel('동의').isTrue().validate(false)
          as ValidationFailure;
      expect(result.message, '동의 참이어야 합니다.');
    });
  });

  group('isFalse()', () {
    test('passes for false', () {
      expect(ValidateBool().isFalse().validate(false), isA<ValidationSuccess>());
    });

    test('fails for true', () {
      final result = ValidateBool().isFalse().validate(true);
      expect((result as ValidationFailure).code, ValidationCode.boolFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
dart test test/validate_bool_test.dart
```

Expected: failures due to old locale API and `ValidationCode.boolTrue` / `.boolFalse` not yet used.

- [ ] **Step 3: Rewrite `lib/src/util/validate_bool.dart`**

```dart
import '../model/message_factory.dart';
import '../model/validation_code.dart';
import 'validator_base.dart';

class ValidateBool extends BaseValidator<bool, ValidateBool> {
  ValidateBool isTrue({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value != true) {
        return getFailure(messageFactory, ValidationCode.boolTrue,
            {'name': label}, '$label must be true.');
      }
      return null;
    });
  }

  ValidateBool isFalse({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value != false) {
        return getFailure(messageFactory, ValidationCode.boolFalse,
            {'name': label}, '$label must be false.');
      }
      return null;
    });
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```
dart test test/validate_bool_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/validate_bool.dart test/validate_bool_test.dart
git commit -m "feat: update ValidateBool to use ValidationCode.boolTrue / boolFalse"
```

---

## Task 9: Update `ValidateDateTime`

**Files:**
- Modify: `lib/src/util/validate_date_time.dart`
- Replace: `test/validate_date_time_test.dart`

- [ ] **Step 1: Write the failing test**

Overwrite `test/validate_date_time_test.dart`:

```dart
import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  final past = DateTime(2000);
  final future = DateTime(2099);
  final now = DateTime.now();

  group('isBefore()', () {
    test('passes when value is before target', () {
      expect(ValidateDateTime().isBefore(future).validate(now),
          isA<ValidationSuccess>());
    });

    test('fails when value is after target', () {
      final result = ValidateDateTime().isBefore(past).validate(now);
      expect((result as ValidationFailure).code, ValidationCode.dateBefore);
    });

    test('passes for null', () {
      expect(ValidateDateTime().isBefore(future).validate(null),
          isA<ValidationSuccess>());
    });
  });

  group('isAfter()', () {
    test('fails when value is before target', () {
      final result = ValidateDateTime().isAfter(future).validate(now);
      expect((result as ValidationFailure).code, ValidationCode.dateAfter);
    });
  });

  group('min()', () {
    test('fails when value is before min', () {
      final result = ValidateDateTime().min(future).validate(now);
      expect((result as ValidationFailure).code, ValidationCode.dateMin);
    });
  });

  group('max()', () {
    test('fails when value is after max', () {
      final result = ValidateDateTime().max(past).validate(now);
      expect((result as ValidationFailure).code, ValidationCode.dateMax);
    });
  });

  group('isInFuture()', () {
    test('fails for past date', () {
      final result = ValidateDateTime().isInFuture().validate(past);
      expect((result as ValidationFailure).code, ValidationCode.dateInFuture);
    });
  });

  group('isInPast()', () {
    test('fails for future date', () {
      final result = ValidateDateTime().isInPast().validate(future);
      expect((result as ValidationFailure).code, ValidationCode.dateInPast);
    });
  });

  group('between()', () {
    test('fails outside range', () {
      final result = ValidateDateTime()
          .between(DateTime(2020), DateTime(2021))
          .validate(DateTime(2022));
      expect((result as ValidationFailure).code, ValidationCode.dateBetween);
    });
  });

  group('locale', () {
    test('uses locale message for dateBefore', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.dateBefore: (p) => '${p['name']} 날짜 오류',
      }));
      final result = ValidateDateTime()
          .setLabel('날짜')
          .isBefore(past)
          .validate(now) as ValidationFailure;
      expect(result.message, '날짜 날짜 오류');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
dart test test/validate_date_time_test.dart
```

Expected: failures due to old locale API.

- [ ] **Step 3: Rewrite `lib/src/util/validate_date_time.dart`**

```dart
import '../model/message_factory.dart';
import '../model/validation_code.dart';
import 'validator_base.dart';

class ValidateDateTime extends BaseValidator<DateTime, ValidateDateTime> {
  ValidateDateTime isBefore(DateTime target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (!value.isBefore(target)) {
        return getFailure(messageFactory, ValidationCode.dateBefore,
            {'name': label, 'target': target}, '$label must be before $target.');
      }
      return null;
    });
  }

  ValidateDateTime isAfter(DateTime target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (!value.isAfter(target)) {
        return getFailure(messageFactory, ValidationCode.dateAfter,
            {'name': label, 'target': target}, '$label must be after $target.');
      }
      return null;
    });
  }

  ValidateDateTime min(DateTime min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isBefore(min)) {
        return getFailure(messageFactory, ValidationCode.dateMin,
            {'name': label, 'min': min}, '$label must be on or after $min.');
      }
      return null;
    });
  }

  ValidateDateTime max(DateTime max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isAfter(max)) {
        return getFailure(messageFactory, ValidationCode.dateMax,
            {'name': label, 'max': max}, '$label must be on or before $max.');
      }
      return null;
    });
  }

  ValidateDateTime between(DateTime min, DateTime max,
      {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isBefore(min) || value.isAfter(max)) {
        return getFailure(messageFactory, ValidationCode.dateBetween,
            {'name': label, 'min': min, 'max': max},
            '$label must be between $min and $max.');
      }
      return null;
    });
  }

  ValidateDateTime isInFuture({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (!value.isAfter(DateTime.now())) {
        return getFailure(messageFactory, ValidationCode.dateInFuture,
            {'name': label}, '$label must be in the future.');
      }
      return null;
    });
  }

  ValidateDateTime isInPast({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (!value.isBefore(DateTime.now())) {
        return getFailure(messageFactory, ValidationCode.dateInPast,
            {'name': label}, '$label must be in the past.');
      }
      return null;
    });
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

```
dart test test/validate_date_time_test.dart
```

Expected: All tests pass.

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/validate_date_time.dart test/validate_date_time_test.dart
git commit -m "feat: update ValidateDateTime to use ValidationCode"
```

---

## Task 10: Implement `DupSchema`

**Files:**
- Create: `lib/src/util/dup_schema.dart`
- Create: `test/dup_schema_test.dart`

- [ ] **Step 1: Write the failing test**

```dart
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
}
```

- [ ] **Step 2: Run test to verify it fails**

```
dart test test/dup_schema_test.dart
```

Expected: compilation error — `DupSchema` not defined.

- [ ] **Step 3: Create `lib/src/util/dup_schema.dart`**

```dart
import '../model/form_validation_result.dart';
import '../model/validation_result.dart';
import 'validator_base.dart';

class DupSchema {
  final Map<String, BaseValidator> _schema;
  Map<String, ValidationFailure>? Function(Map<String, dynamic>)?
      _crossValidator;

  DupSchema(
    Map<String, BaseValidator> schema, {
    Map<String, String> labels = const {},
  }) : _schema = Map.from(schema) {
    for (final entry in _schema.entries) {
      final label = labels[entry.key] ?? entry.key;
      entry.value.setLabel(label);
    }
  }

  bool get hasAsyncValidators =>
      _schema.values.any((v) => v.hasAsyncValidators);

  DupSchema crossValidate(
    Map<String, ValidationFailure>? Function(Map<String, dynamic>) fn,
  ) {
    _crossValidator = fn;
    return this;
  }

  Future<FormValidationResult> validate(Map<String, dynamic> data) async {
    final errors = <String, ValidationFailure>{};
    for (final field in _schema.keys) {
      final result = await _schema[field]!.validateAsync(data[field]);
      if (result is ValidationFailure) {
        errors[field] = result;
      }
    }
    if (errors.isNotEmpty) return FormValidationFailure(errors);
    if (_crossValidator != null) {
      final crossErrors = _crossValidator!(data);
      if (crossErrors != null && crossErrors.isNotEmpty) {
        return FormValidationFailure(crossErrors);
      }
    }
    return const FormValidationSuccess();
  }

  FormValidationResult validateSync(Map<String, dynamic> data) {
    assert(
      !hasAsyncValidators,
      'validateSync() called on a schema that has async validators. '
      'Use validate() instead.',
    );
    final errors = <String, ValidationFailure>{};
    for (final field in _schema.keys) {
      final result = _schema[field]!.validate(data[field]);
      if (result is ValidationFailure) {
        errors[field] = result;
      }
    }
    if (errors.isNotEmpty) return FormValidationFailure(errors);
    if (_crossValidator != null) {
      final crossErrors = _crossValidator!(data);
      if (crossErrors != null && crossErrors.isNotEmpty) {
        return FormValidationFailure(crossErrors);
      }
    }
    return const FormValidationSuccess();
  }

  Future<ValidationResult> validateField(String field, dynamic value) async {
    final validator = _schema[field];
    if (validator == null) return const ValidationSuccess();
    return validator.validateAsync(value);
  }
}
```

- [ ] **Step 4: Export from `lib/dup.dart` (add only the new line)**

```dart
export 'src/util/dup_schema.dart';
```

- [ ] **Step 5: Run test to verify it passes**

```
dart test test/dup_schema_test.dart
```

Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/src/util/dup_schema.dart lib/dup.dart test/dup_schema_test.dart
git commit -m "feat: implement DupSchema replacing BaseValidatorSchema and UiFormService"
```

---

## Task 11: Update `message_resolution_test.dart`, delete old files, clean barrel

**Files:**
- Update: `test/message_resolution_test.dart`
- Delete: `lib/src/model/base_validator_schema.dart`
- Delete: `lib/src/util/form_validate_exception.dart`
- Delete: `lib/src/util/ui_form_service.dart`
- Delete: `test/form_validate_exception_test.dart`
- Delete: `test/ui_form_service_test.dart`
- Modify: `lib/dup.dart`

- [ ] **Step 1: Update `test/message_resolution_test.dart`**

Overwrite with:

```dart
import 'package:dup/dup.dart';
import 'package:test/test.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('3-level message priority', () {
    test('1st — messageFactory wins over locale and default', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.required: (_) => '로케일 메시지',
      }));
      final result = ValidateString()
          .setLabel('Email')
          .required(messageFactory: (_, __) => '팩토리 메시지')
          .validate(null) as ValidationFailure;
      expect(result.message, '팩토리 메시지');
    });

    test('2nd — locale wins over default when no messageFactory', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.required: (p) => '${p['name']} 로케일',
      }));
      final result = ValidateString()
          .setLabel('Email')
          .required()
          .validate(null) as ValidationFailure;
      expect(result.message, 'Email 로케일');
    });

    test('3rd — default used when no messageFactory and no locale', () {
      final result = ValidateString()
          .setLabel('Email')
          .required()
          .validate(null) as ValidationFailure;
      expect(result.message, 'Email is required.');
    });

    test('locale covers multiple codes independently', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.required: (_) => 'req',
        ValidationCode.emailInvalid: (_) => 'email bad',
      }));

      final req = ValidateString().setLabel('E').required().validate(null)
          as ValidationFailure;
      final email = ValidateString().setLabel('E').email().validate('bad')
          as ValidationFailure;

      expect(req.message, 'req');
      expect(email.message, 'email bad');
    });

    test('unregistered code falls back to default', () {
      ValidatorLocale.setLocale(ValidatorLocale({
        ValidationCode.required: (_) => 'req only',
      }));
      final result = ValidateString()
          .setLabel('Email')
          .email()
          .validate('bad') as ValidationFailure;
      expect(result.message, 'Email is not a valid email address.');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it passes**

```
dart test test/message_resolution_test.dart
```

Expected: All tests pass.

- [ ] **Step 3: Delete old files**

```bash
rm lib/src/model/base_validator_schema.dart
rm lib/src/util/form_validate_exception.dart
rm lib/src/util/ui_form_service.dart
rm test/form_validate_exception_test.dart
rm test/ui_form_service_test.dart
```

- [ ] **Step 4: Rewrite `lib/dup.dart`**

```dart
library;

// Core result types
export 'src/model/validation_code.dart';
export 'src/model/validation_result.dart';
export 'src/model/form_validation_result.dart';

// Base validator
export 'src/util/validator_base.dart';

// Validators
export 'src/util/validate_string.dart';
export 'src/util/validate_number.dart';
export 'src/util/validate_list.dart';
export 'src/util/validate_bool.dart';
export 'src/util/validate_date_time.dart';

// Locale
export 'src/util/validate_locale.dart';

// Schema
export 'src/util/dup_schema.dart';

// Helpers (still needed for MessageFactory typedef)
export 'src/model/locale_message.dart';
export 'src/model/message_factory.dart';
```

- [ ] **Step 5: Run full test suite**

```
dart test
```

Expected: All tests pass. No compilation errors.

- [ ] **Step 6: Run analyzer**

```
dart analyze
```

Expected: No issues.

- [ ] **Step 7: Commit**

```bash
git add test/message_resolution_test.dart lib/dup.dart
git rm lib/src/model/base_validator_schema.dart \
       lib/src/util/form_validate_exception.dart \
       lib/src/util/ui_form_service.dart \
       test/form_validate_exception_test.dart \
       test/ui_form_service_test.dart
git commit -m "feat: complete v2.0.0 API redesign — remove old form API, clean exports"
```

---

## Self-Review

### Spec coverage check

| Spec requirement | Covered in task |
|---|---|
| `ValidationCode` enum with all built-in codes | Task 1 |
| `sealed ValidationResult` with `ValidationSuccess` / `ValidationFailure` | Task 1 |
| `ValidationFailure.customCode` optional field | Task 1 |
| `ValidationFailure.message` is snapshot at validation time | Task 1 (doc comment) + Task 4 (`getFailure` resolves immediately) |
| `sealed FormValidationResult` | Task 2 |
| `FormValidationFailure.call()`, `.hasError()`, `.fields`, `.firstField` | Task 2 |
| `ValidatorLocale` with `Map<ValidationCode, LocaleMessage>` | Task 3 |
| `ValidatorLocale.resetLocale()` | Task 3 |
| `BaseValidator` returns `ValidationResult` | Task 4 |
| `addValidator(ValidationFailure? Function)` | Task 4 |
| `addAsyncValidator(Future<ValidationFailure?> Function)` | Task 4 |
| `hasAsyncValidators` getter | Task 4 |
| `toValidator()` → `String? Function(T?)` | Task 4 |
| `toAsyncValidator()` → `Future<String?> Function(T?)` | Task 4 |
| 3-level message priority (messageFactory → locale → default) | Task 4 (`getFailure`) |
| All `ValidateString` methods use `ValidationCode` | Task 5 |
| All `ValidateNumber` methods use `ValidationCode` | Task 6 |
| `ValidateNumber.toValidator()` parses string input | Task 6 |
| All `ValidateList` methods use `ValidationCode` | Task 7 |
| `eachItem` accepts `ValidationFailure? Function(T)` | Task 7 |
| `ValidateBool` uses `ValidationCode.boolTrue` / `.boolFalse` | Task 8 |
| `ValidateDateTime` uses `ValidationCode.dateXxx` | Task 9 |
| `DupSchema` with `labels` parameter | Task 10 |
| `DupSchema.validate()` async | Task 10 |
| `DupSchema.validateSync()` asserts on async validators | Task 10 |
| `DupSchema.validateField()` per-field validation | Task 10 |
| `DupSchema.crossValidate()` skipped when field errors exist | Task 10 |
| `DupSchema.hasAsyncValidators` | Task 10 |
| Remove `useUiForm`, `FormValidationException`, `BaseValidatorSchema` | Task 11 |
| `toAsyncValidator()` not shown as TextFormField-compatible | Task 6 (comment in code) |
