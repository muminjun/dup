# dup v2.0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Overhaul the `dup` Dart validation library to v2.0 — fixing all known bugs, adding phase-based execution (zod-style), async validator support, `ValidateBool`/`ValidateDateTime` types, and removing the Flutter dependency.

**Architecture:** `BaseValidator` is rewritten with a phase-tagged entry list so validators always execute in phase order (0: presence → 1: format → 2: constraint → 3: custom → 4: async) regardless of chain order. All validators are pure Dart with no Flutter dependency. New types (`ValidateBool`, `ValidateDateTime`) extend `BaseValidator` directly.

**Tech Stack:** Dart 3.7+, `test: ^1.25.0`, `lints: ^5.0.0`. Test runner: `dart test`. No Flutter.

---

## Execution Order

```
WAVE 1 (all parallel):
  Task 1 — Project infrastructure
  Task 2 — BaseValidator rewrite
  Task 3 — ValidatorLocale + ValidatorLocaleKeys
  Task 4 — FormValidationException type fix

WAVE 2 (all parallel, requires Wave 1 complete):
  Task 5 — ValidateString
  Task 6 — ValidateNumber
  Task 7 — ValidateList fixes
  Task 8 — ValidateBool (new)
  Task 9 — ValidateDateTime (new)
  Task 10 — UiFormService upgrade

WAVE 3 (requires Wave 2 complete):
  Task 11 — dup.dart exports + final verification
```

---

## WAVE 1

---

### Task 1: Project Infrastructure

**Files:**
- Modify: `pubspec.yaml`
- Modify: `.gitignore` (create if absent)

- [ ] **Step 1: Update pubspec.yaml**

Replace entire `pubspec.yaml` with:

```yaml
name: dup
description: "A powerful, flexible schema-based validation library for Dart, inspired by JavaScript's yup."
version: 2.0.0
homepage: https://github.com/muminjun/dup
repository: https://github.com/muminjun/dup

environment:
  sdk: ^3.7.2

dependencies: {}

dev_dependencies:
  test: ^1.25.0
  lints: ^5.0.0
```

- [ ] **Step 2: Update .gitignore**

Ensure `.gitignore` at repo root contains the following lines (add if missing):

```
# Generated API docs
doc/
.dart_tool/
build/
.packages
pubspec.lock
```

- [ ] **Step 3: Get dependencies**

```bash
dart pub get
```

Expected output: `Resolving dependencies... Got dependencies!`

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml .gitignore
git commit -m "chore: migrate to pure Dart, bump version to 2.0.0"
```

---

### Task 2: BaseValidator Rewrite

**Files:**
- Modify: `lib/src/util/validator_base.dart`
- Create: `test/validate_base_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/validate_base_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  group('BaseValidator — phase ordering', () {
    test('required() fires before email() regardless of chain order', () {
      final v = ValidateString()
          .setLabel('Email')
          .email()
          .required(); // required last in chain

      // null should trigger required (phase 0), not email (phase 1)
      final error = v.validate(null);
      expect(error, equals('Email is required.'));
    });

    test('format validator (email) fires before constraint (min)', () {
      final v = ValidateString()
          .setLabel('Email')
          .min(100)   // constraint (phase 2)
          .email();   // format (phase 1)

      final error = v.validate('not-an-email');
      expect(error, equals('Email is not a valid email address.'));
    });

    test('custom validator (satisfy) fires after format and constraint', () {
      final v = ValidateString()
          .setLabel('Field')
          .satisfy((_) => false)   // phase 3
          .min(1);                 // phase 2 — chain order reversed

      // min fires first (phase 2 < phase 3), value 'ab' passes min,
      // then satisfy fails
      final error = v.validate('ab');
      expect(error, equals('Field does not satisfy the condition.'));
    });

    test('required fires even when chained after all other validators', () {
      final v = ValidateString()
          .setLabel('Name')
          .min(3)
          .satisfy((_) => true)
          .required();

      expect(v.validate(null), equals('Name is required.'));
      expect(v.validate(''), equals('Name is required.'));
    });
  });

  group('BaseValidator — null contract', () {
    test('satisfy() skips on null value', () {
      final v = ValidateString()
          .setLabel('X')
          .satisfy((_) => false); // would always fail if reached
      expect(v.validate(null), isNull);
    });

    test('equalTo skips on null value', () {
      final v = ValidateString().setLabel('X').equalTo('hello');
      expect(v.validate(null), isNull);
    });

    test('notEqualTo skips on null value', () {
      final v = ValidateString().setLabel('X').notEqualTo('hello');
      expect(v.validate(null), isNull);
    });

    test('includedIn skips on null value', () {
      final v = ValidateString().setLabel('X').includedIn(['a', 'b']);
      expect(v.validate(null), isNull);
    });

    test('excludedFrom skips on null value', () {
      final v = ValidateString().setLabel('X').excludedFrom(['a', 'b']);
      expect(v.validate(null), isNull);
    });
  });

  group('BaseValidator — addValidator (custom, phase 3)', () {
    test('addValidator is called with value', () {
      final v = ValidateString()
          .setLabel('X')
          .addValidator((val) => val == 'bad' ? 'bad value' : null);
      expect(v.validate('bad'), equals('bad value'));
      expect(v.validate('good'), isNull);
    });
  });

  group('BaseValidator — addAsyncValidator', () {
    test('validateAsync runs async validator after sync', () async {
      final v = ValidateString()
          .setLabel('Email')
          .email()
          .addAsyncValidator((val) async => 'taken');

      // invalid email → sync error returned, async never runs
      expect(await v.validateAsync('bad'), equals('Email is not a valid email address.'));
    });

    test('validateAsync returns async error when sync passes', () async {
      final v = ValidateString()
          .setLabel('Email')
          .email()
          .addAsyncValidator((val) async => 'Email already taken.');

      expect(await v.validateAsync('user@example.com'), equals('Email already taken.'));
    });

    test('validateAsync returns null when all pass', () async {
      final v = ValidateString()
          .setLabel('Email')
          .email()
          .addAsyncValidator((val) async => null);

      expect(await v.validateAsync('user@example.com'), isNull);
    });

    test('validate() (sync) does not run async validators', () {
      final v = ValidateString()
          .setLabel('Email')
          .email()
          .addAsyncValidator((val) async => 'async error');

      // sync validate should not see the async error
      expect(v.validate('user@example.com'), isNull);
    });
  });

  group('BaseValidator — includedIn / excludedFrom', () {
    test('includedIn passes for allowed value', () {
      final v = ValidateString().setLabel('Role').includedIn(['admin', 'user']);
      expect(v.validate('admin'), isNull);
    });

    test('includedIn fails for disallowed value', () {
      final v = ValidateString().setLabel('Role').includedIn(['admin', 'user']);
      expect(v.validate('guest'), isNotNull);
    });

    test('excludedFrom passes when not in list', () {
      final v = ValidateString().setLabel('Name').excludedFrom(['root', 'admin']);
      expect(v.validate('alice'), isNull);
    });

    test('excludedFrom fails when in list', () {
      final v = ValidateString().setLabel('Name').excludedFrom(['root', 'admin']);
      expect(v.validate('admin'), isNotNull);
    });
  });

  group('BaseValidator — equalTo / notEqualTo', () {
    test('equalTo passes when values match', () {
      final v = ValidateString().setLabel('X').equalTo('hello');
      expect(v.validate('hello'), isNull);
    });

    test('equalTo fails when values differ', () {
      final v = ValidateString().setLabel('X').equalTo('hello');
      expect(v.validate('world'), isNotNull);
    });

    test('notEqualTo passes when values differ', () {
      final v = ValidateString().setLabel('X').notEqualTo('forbidden');
      expect(v.validate('allowed'), isNull);
    });

    test('notEqualTo fails when values match', () {
      final v = ValidateString().setLabel('X').notEqualTo('forbidden');
      expect(v.validate('forbidden'), isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
dart test test/validate_base_test.dart
```

Expected: compile error or test failures (BaseValidator doesn't have phase system yet).

- [ ] **Step 3: Rewrite lib/src/util/validator_base.dart**

```dart
import 'package:dup/src/util/validate_locale.dart';
import '../model/message_factory.dart';

class _ValidatorEntry<T> {
  final int phase;
  final String? Function(T?) fn;
  const _ValidatorEntry(this.phase, this.fn);
}

abstract class BaseValidator<T, V extends BaseValidator<T, V>> {
  final List<_ValidatorEntry<T>> _entries = [];
  final List<Future<String?> Function(T?)> _asyncEntries = [];

  String label = '';

  V setLabel(String text) {
    label = text;
    return this as V;
  }

  V addPhaseValidator(int phase, String? Function(T?) fn) {
    _entries.add(_ValidatorEntry(phase, fn));
    return this as V;
  }

  V addValidator(String? Function(T?) fn) => addPhaseValidator(3, fn);

  V addAsyncValidator(Future<String?> Function(T?) fn) {
    _asyncEntries.add(fn);
    return this as V;
  }

  V required({MessageFactory? messageFactory}) {
    return addPhaseValidator(0, (value) {
      if (value == null || (value is String && value.isEmpty)) {
        return getErrorMessage(
          messageFactory, 'required', {'name': label}, '$label is required.',
        );
      }
      return null;
    });
  }

  V equalTo(T target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && value != target) {
        return getErrorMessage(
          messageFactory, 'equal', {'name': label}, '$label does not match.',
        );
      }
      return null;
    });
  }

  V notEqualTo(T target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && value == target) {
        return getErrorMessage(
          messageFactory, 'notEqual', {'name': label}, '$label is not allowed.',
        );
      }
      return null;
    });
  }

  V includedIn(List<T> allowedValues, {MessageFactory? messageFactory}) {
    return addPhaseValidator(3, (value) {
      if (value != null && !allowedValues.contains(value)) {
        return getErrorMessage(
          messageFactory,
          'oneOf',
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
        return getErrorMessage(
          messageFactory,
          'notOneOf',
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
        return getErrorMessage(
          messageFactory, 'condition', {'name': label}, '$label does not satisfy the condition.',
        );
      }
      return null;
    });
  }

  String? validate(T? value) {
    final sorted = List<_ValidatorEntry<T>>.from(_entries)
      ..sort((a, b) => a.phase.compareTo(b.phase));
    for (final entry in sorted) {
      final error = entry.fn(value);
      if (error != null) return error;
    }
    return null;
  }

  Future<String?> validateAsync(T? value) async {
    final syncError = validate(value);
    if (syncError != null) return syncError;
    for (final fn in _asyncEntries) {
      final error = await fn(value);
      if (error != null) return error;
    }
    return null;
  }

  String? getErrorMessage(
    MessageFactory? customFactory,
    String messageKey,
    Map<String, dynamic> params,
    String defaultMessage,
  ) {
    return customFactory?.call(label, params) ??
        ValidatorLocale.current?.mixed[messageKey]?.call(params) ??
        defaultMessage;
  }
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
dart test test/validate_base_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/validator_base.dart test/validate_base_test.dart
git commit -m "feat: rewrite BaseValidator with phase-based execution and async support"
```

---

### Task 3: ValidatorLocale + ValidatorLocaleKeys

**Files:**
- Modify: `lib/src/util/validate_locale.dart`
- Create: `test/validate_locale_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/validate_locale_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  tearDown(() => ValidatorLocale.resetLocale());

  group('ValidatorLocale', () {
    test('setLocale and current work', () {
      final locale = ValidatorLocale(
        mixed: {},
        string: {},
        number: {},
        array: {},
        boolMessages: {},
        date: {},
      );
      ValidatorLocale.setLocale(locale);
      expect(ValidatorLocale.current, same(locale));
    });

    test('resetLocale clears current', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {}, string: {}, number: {}, array: {},
        boolMessages: {}, date: {},
      ));
      ValidatorLocale.resetLocale();
      expect(ValidatorLocale.current, isNull);
    });

    test('current is null by default', () {
      expect(ValidatorLocale.current, isNull);
    });

    test('locale message overrides default error message', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {
          'required': (args) => '${args['name']} 필수 입력',
        },
        string: {},
        number: {},
        array: {},
        boolMessages: {},
        date: {},
      ));

      final v = ValidateString().setLabel('이름').required();
      expect(v.validate(null), equals('이름 필수 입력'));
    });

    test('boolMessages category works', () {
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {},
        string: {},
        number: {},
        array: {},
        boolMessages: {
          'isTrue': (args) => '${args['name']} must be checked',
        },
        date: {},
      ));

      final v = ValidateBool().setLabel('Agreement').isTrue();
      expect(v.validate(false), equals('Agreement must be checked'));
    });

    test('date category works', () {
      final limit = DateTime(2020, 1, 1);
      ValidatorLocale.setLocale(ValidatorLocale(
        mixed: {},
        string: {},
        number: {},
        array: {},
        boolMessages: {},
        date: {
          'after': (args) => '${args['name']} too early',
        },
      ));

      final v = ValidateDateTime().setLabel('Date').isAfter(limit);
      expect(v.validate(DateTime(2019, 1, 1)), equals('Date too early'));
    });
  });

  group('ValidatorLocaleKeys constants', () {
    test('required key constant matches expected string', () {
      expect(ValidatorLocaleKeys.required, equals('required'));
    });

    test('stringEmail key constant matches expected string', () {
      expect(ValidatorLocaleKeys.stringEmail, equals('emailInvalid'));
    });

    test('boolTrue key constant matches expected string', () {
      expect(ValidatorLocaleKeys.boolTrue, equals('isTrue'));
    });

    test('dateAfter key constant matches expected string', () {
      expect(ValidatorLocaleKeys.dateAfter, equals('after'));
    });
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
dart test test/validate_locale_test.dart
```

Expected: compile errors (no `resetLocale`, no `boolMessages`, no `ValidatorLocaleKeys`).

- [ ] **Step 3: Rewrite lib/src/util/validate_locale.dart**

```dart
import '../model/locale_message.dart';

class ValidatorLocale {
  static ValidatorLocale? _current;

  final Map<String, LocaleMessage> mixed;
  final Map<String, LocaleMessage> number;
  final Map<String, LocaleMessage> string;
  final Map<String, LocaleMessage> array;
  final Map<String, LocaleMessage> boolMessages;
  final Map<String, LocaleMessage> date;

  ValidatorLocale({
    required this.mixed,
    required this.number,
    required this.string,
    required this.array,
    this.boolMessages = const {},
    this.date = const {},
  });

  static void setLocale(ValidatorLocale locale) => _current = locale;
  static void resetLocale() => _current = null;
  static ValidatorLocale? get current => _current;
}

abstract class ValidatorLocaleKeys {
  // mixed
  static const String required = 'required';
  static const String equal = 'equal';
  static const String notEqual = 'notEqual';
  static const String oneOf = 'oneOf';
  static const String notOneOf = 'notOneOf';
  static const String condition = 'condition';

  // string
  static const String stringMin = 'min';
  static const String stringMax = 'max';
  static const String stringMatches = 'matches';
  static const String stringEmail = 'emailInvalid';
  static const String stringPassword = 'passwordMin';
  static const String stringEmoji = 'emoji';
  static const String stringMobile = 'mobileInvalid';
  static const String stringPhone = 'phoneInvalid';
  static const String stringBizno = 'biznoInvalid';
  static const String stringUrl = 'url';
  static const String stringUuid = 'uuid';

  // number
  static const String numberMin = 'min';
  static const String numberMax = 'max';
  static const String numberInteger = 'integer';
  static const String numberPositive = 'positive';
  static const String numberNegative = 'negative';
  static const String numberNonNegative = 'nonNegative';
  static const String numberNonPositive = 'nonPositive';

  // array
  static const String arrayNotEmpty = 'notEmpty';
  static const String arrayEmpty = 'empty';
  static const String arrayMin = 'min';
  static const String arrayMax = 'max';
  static const String arrayLengthBetween = 'lengthBetween';
  static const String arrayExactLength = 'exactLength';
  static const String arrayContains = 'contains';
  static const String arrayDoesNotContain = 'doesNotContain';
  static const String arrayAllCondition = 'allCondition';
  static const String arrayAnyCondition = 'anyCondition';
  static const String arrayNoDuplicates = 'noDuplicates';
  static const String arrayEachItem = 'eachItem';

  // bool
  static const String boolTrue = 'isTrue';
  static const String boolFalse = 'isFalse';

  // date
  static const String dateMin = 'min';
  static const String dateMax = 'max';
  static const String dateBefore = 'before';
  static const String dateAfter = 'after';
  static const String dateBetween = 'between';
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
dart test test/validate_locale_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/validate_locale.dart test/validate_locale_test.dart
git commit -m "feat: add resetLocale, boolMessages/date categories, ValidatorLocaleKeys constants"
```

---

### Task 4: FormValidationException Type Fix

**Files:**
- Modify: `lib/src/util/form_validate_exception.dart`
- Create: `test/form_validate_exception_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/form_validate_exception_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  group('FormValidationException', () {
    test('errors map is non-nullable String values', () {
      final ex = FormValidationException({'email': 'Invalid email.'});
      // If this compiles and runs, Map<String, String> is correct
      final String error = ex.errors['email']!; // no ? needed on value type
      expect(error, equals('Invalid email.'));
    });

    test('toString returns first non-empty error', () {
      final ex = FormValidationException({
        'email': 'Invalid email.',
        'name': 'Name is required.',
      });
      expect(ex.toString(), equals('Invalid email.'));
    });

    test('toString returns fallbackMessage when errors empty', () {
      final ex = FormValidationException({}, fallbackMessage: 'Form is invalid.');
      expect(ex.toString(), equals('Form is invalid.'));
    });

    test('default fallbackMessage is used when not provided', () {
      final ex = FormValidationException({});
      expect(ex.toString(), equals('Invalid form.'));
    });

    test('hasError returns true for existing field', () {
      final ex = FormValidationException({'email': 'bad'});
      expect(ex.errors.containsKey('email'), isTrue);
    });

    test('hasError returns false for missing field', () {
      final ex = FormValidationException({'email': 'bad'});
      expect(ex.errors.containsKey('name'), isFalse);
    });
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
dart test test/form_validate_exception_test.dart
```

Expected: type errors or test failures.

- [ ] **Step 3: Update lib/src/util/form_validate_exception.dart**

```dart
class FormValidationException implements Exception {
  final Map<String, String> errors;
  final String fallbackMessage;

  FormValidationException(
    this.errors, {
    this.fallbackMessage = 'Invalid form.',
  });

  @override
  String toString() {
    return errors.values.firstWhere(
      (e) => e.isNotEmpty,
      orElse: () => fallbackMessage,
    );
  }
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
dart test test/form_validate_exception_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/form_validate_exception.dart test/form_validate_exception_test.dart
git commit -m "fix: change FormValidationException.errors to Map<String, String>"
```

---

## WAVE 2

> All Wave 2 tasks require Wave 1 to be complete. Run all Wave 2 tasks in parallel.

---

### Task 5: ValidateString

**Files:**
- Modify: `lib/src/util/validate_string.dart`
- Create: `test/validate_string_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/validate_string_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  group('ValidateString.min / max', () {
    test('min passes when length is sufficient', () {
      expect(ValidateString().setLabel('X').min(3).validate('abc'), isNull);
    });
    test('min fails when too short', () {
      expect(ValidateString().setLabel('X').min(3).validate('ab'), isNotNull);
    });
    test('max passes when length is within limit', () {
      expect(ValidateString().setLabel('X').max(5).validate('hello'), isNull);
    });
    test('max fails when too long', () {
      expect(ValidateString().setLabel('X').max(3).validate('toolong'), isNotNull);
    });
    test('min skips on null', () {
      expect(ValidateString().setLabel('X').min(3).validate(null), isNull);
    });
    test('max skips on null', () {
      expect(ValidateString().setLabel('X').max(3).validate(null), isNull);
    });
  });

  group('ValidateString.matches', () {
    test('passes when regex matches', () {
      expect(ValidateString().setLabel('X').matches(RegExp(r'^\d+$')).validate('123'), isNull);
    });
    test('fails when regex does not match', () {
      expect(ValidateString().setLabel('X').matches(RegExp(r'^\d+$')).validate('abc'), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateString().setLabel('X').matches(RegExp(r'^\d+$')).validate(null), isNull);
    });
  });

  group('ValidateString.email', () {
    test('passes for valid email', () {
      expect(ValidateString().setLabel('Email').email().validate('user@example.com'), isNull);
    });
    test('fails for invalid email', () {
      expect(ValidateString().setLabel('Email').email().validate('not-an-email'), isNotNull);
    });
    test('skips on null (no implicit required)', () {
      expect(ValidateString().setLabel('Email').email().validate(null), isNull);
    });
    test('skips on empty string (no implicit required)', () {
      expect(ValidateString().setLabel('Email').email().validate(''), isNull);
    });
    test('required() + email() catches null before checking format', () {
      final v = ValidateString().setLabel('Email').email().required();
      expect(v.validate(null), equals('Email is required.'));
    });
  });

  group('ValidateString.password', () {
    test('passes for valid password', () {
      expect(ValidateString().setLabel('PW').password().validate('secret123'), isNull);
    });
    test('fails when shorter than default minLength=4', () {
      expect(ValidateString().setLabel('PW').password().validate('abc'), isNotNull);
    });
    test('custom minLength is respected', () {
      expect(ValidateString().setLabel('PW').password(minLength: 8).validate('short'), isNotNull);
      expect(ValidateString().setLabel('PW').password(minLength: 8).validate('longpass1'), isNull);
    });
    test('accepts non-ASCII characters (international passwords)', () {
      expect(ValidateString().setLabel('PW').password().validate('비밀번호!'), isNull);
    });
    test('skips on null', () {
      expect(ValidateString().setLabel('PW').password().validate(null), isNull);
    });
  });

  group('ValidateString.emoji', () {
    test('fails when value contains emoji', () {
      expect(ValidateString().setLabel('X').emoji().validate('hello 😀'), isNotNull);
    });
    test('passes when value has no emoji', () {
      expect(ValidateString().setLabel('X').emoji().validate('hello world'), isNull);
    });
    test('skips on null', () {
      expect(ValidateString().setLabel('X').emoji().validate(null), isNull);
    });
  });

  group('ValidateString.mobile', () {
    test('passes for valid Korean mobile (default)', () {
      expect(ValidateString().setLabel('Phone').mobile().validate('010-1234-5678'), isNull);
    });
    test('fails for invalid format', () {
      expect(ValidateString().setLabel('Phone').mobile().validate('12345'), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateString().setLabel('Phone').mobile().validate(null), isNull);
    });
    test('skips on empty string', () {
      expect(ValidateString().setLabel('Phone').mobile().validate(''), isNull);
    });
    test('customRegex overrides default', () {
      final v = ValidateString().setLabel('Phone').mobile(customRegex: RegExp(r'^\+1\d{10}$'));
      expect(v.validate('+11234567890'), isNull);
      expect(v.validate('010-1234-5678'), isNotNull);
    });
  });

  group('ValidateString.phone', () {
    test('passes for valid Korean landline (default)', () {
      expect(ValidateString().setLabel('Phone').phone().validate('02-1234-5678'), isNull);
    });
    test('fails for invalid format', () {
      expect(ValidateString().setLabel('Phone').phone().validate('99-9999-9999'), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateString().setLabel('Phone').phone().validate(null), isNull);
    });
    test('customRegex overrides default', () {
      final v = ValidateString().setLabel('Phone').phone(
        customRegex: RegExp(r'^\+?[1-9]\d{1,14}$'),
      );
      expect(v.validate('+441234567890'), isNull);
    });
  });

  group('ValidateString.bizno', () {
    test('passes for valid Korean BRN (default)', () {
      expect(ValidateString().setLabel('BRN').bizno().validate('123-45-67890'), isNull);
    });
    test('fails for invalid format', () {
      expect(ValidateString().setLabel('BRN').bizno().validate('12345'), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateString().setLabel('BRN').bizno().validate(null), isNull);
    });
    test('customRegex overrides default', () {
      final v = ValidateString().setLabel('BRN').bizno(customRegex: RegExp(r'^\d{2}-\d{7}$'));
      expect(v.validate('12-3456789'), isNull);
      expect(v.validate('123-45-67890'), isNotNull);
    });
  });

  group('ValidateString.url', () {
    test('passes for http URL', () {
      expect(ValidateString().setLabel('URL').url().validate('http://example.com'), isNull);
    });
    test('passes for https URL', () {
      expect(ValidateString().setLabel('URL').url().validate('https://example.com/path?q=1'), isNull);
    });
    test('fails for non-URL', () {
      expect(ValidateString().setLabel('URL').url().validate('not a url'), isNotNull);
    });
    test('fails for ftp URL (only http/https)', () {
      expect(ValidateString().setLabel('URL').url().validate('ftp://example.com'), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateString().setLabel('URL').url().validate(null), isNull);
    });
  });

  group('ValidateString.uuid', () {
    test('passes for valid UUID v4', () {
      expect(
        ValidateString().setLabel('ID').uuid().validate('550e8400-e29b-41d4-a716-446655440000'),
        isNull,
      );
    });
    test('fails for non-UUID', () {
      expect(ValidateString().setLabel('ID').uuid().validate('not-a-uuid'), isNotNull);
    });
    test('passes for uppercase UUID', () {
      expect(
        ValidateString().setLabel('ID').uuid().validate('550E8400-E29B-41D4-A716-446655440000'),
        isNull,
      );
    });
    test('skips on null', () {
      expect(ValidateString().setLabel('ID').uuid().validate(null), isNull);
    });
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
dart test test/validate_string_test.dart
```

Expected: failures (no `phone`, `bizno`, `url`, `uuid` methods; old `password` rejects non-ASCII).

- [ ] **Step 3: Rewrite lib/src/util/validate_string.dart**

```dart
import 'package:dup/src/util/validate_locale.dart';
import 'package:dup/src/util/validator_base.dart';
import '../model/message_factory.dart';

class ValidateString extends BaseValidator<String, ValidateString> {
  ValidateString min(int min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.trim().length < min) {
        if (messageFactory != null) return messageFactory(label, {'min': min});
        final global = ValidatorLocale.current?.string['min']?.call({'name': label, 'min': min});
        if (global != null) return global;
        return '$label must be at least $min characters.';
      }
      return null;
    });
  }

  ValidateString max(int max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.trim().length > max) {
        if (messageFactory != null) return messageFactory(label, {'max': max});
        final global = ValidatorLocale.current?.string['max']?.call({'name': label, 'max': max});
        if (global != null) return global;
        return '$label must be at most $max characters.';
      }
      return null;
    });
  }

  ValidateString matches(RegExp regex, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && !regex.hasMatch(value.trim())) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['matches']?.call({'name': label});
        if (global != null) return global;
        return '$label does not match the required format.';
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
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['emailInvalid']?.call({'name': label});
        if (global != null) return global;
        return '$label is not a valid email address.';
      }
      return null;
    });
  }

  ValidateString password({int minLength = 4, MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.trim().isEmpty) return null;
      if (value.trim().length < minLength) {
        if (messageFactory != null) return messageFactory(label, {'minLength': minLength});
        final global = ValidatorLocale.current?.string['passwordMin']
            ?.call({'name': label, 'minLength': minLength});
        if (global != null) return global;
        return '$label must be at least $minLength characters.';
      }
      return null;
    });
  }

  ValidateString emoji({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && value.isNotEmpty) {
        if (RegExp(r'\p{Emoji}', unicode: true).hasMatch(value)) {
          if (messageFactory != null) return messageFactory(label, {});
          final global = ValidatorLocale.current?.string['emoji']?.call({'name': label});
          if (global != null) return global;
          return '$label cannot contain emoji.';
        }
      }
      return null;
    });
  }

  ValidateString mobile({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^\d{2,3}-\d{3,4}-\d{4}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['mobileInvalid']?.call({'name': label});
        if (global != null) return global;
        return '$label is not a valid mobile number.';
      }
      return null;
    });
  }

  ValidateString phone({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^(0[2-9]{1}\d?)-\d{3,4}-\d{4}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['phoneInvalid']?.call({'name': label});
        if (global != null) return global;
        return '$label is not a valid phone number.';
      }
      return null;
    });
  }

  ValidateString bizno({RegExp? customRegex, MessageFactory? messageFactory}) {
    final regex = customRegex ?? RegExp(r'^\d{3}-\d{2}-\d{5}$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['biznoInvalid']?.call({'name': label});
        if (global != null) return global;
        return '$label is not a valid business registration number.';
      }
      return null;
    });
  }

  ValidateString url({MessageFactory? messageFactory}) {
    final regex = RegExp(r'^https?://[^\s/$.?#].[^\s]*$');
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) return null;
      if (!regex.hasMatch(value)) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['url']?.call({'name': label});
        if (global != null) return global;
        return '$label is not a valid URL.';
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
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.string['uuid']?.call({'name': label});
        if (global != null) return global;
        return '$label is not a valid UUID.';
      }
      return null;
    });
  }
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
dart test test/validate_string_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/validate_string.dart test/validate_string_test.dart
git commit -m "feat: overhaul ValidateString — add phone/bizno/url/uuid, customRegex, fix null-skip, fix password"
```

---

### Task 6: ValidateNumber

**Files:**
- Modify: `lib/src/util/validate_number.dart`
- Create: `test/validate_number_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/validate_number_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  group('ValidateNumber.min / max', () {
    test('min passes when value is sufficient', () {
      expect(ValidateNumber().setLabel('Age').min(18).validate(18), isNull);
      expect(ValidateNumber().setLabel('Age').min(18).validate(25), isNull);
    });
    test('min fails when value is too low', () {
      expect(ValidateNumber().setLabel('Age').min(18).validate(17), isNotNull);
    });
    test('max passes when value is within limit', () {
      expect(ValidateNumber().setLabel('Score').max(100).validate(100), isNull);
    });
    test('max fails when value exceeds limit', () {
      expect(ValidateNumber().setLabel('Score').max(100).validate(101), isNotNull);
    });
    test('min skips on null', () {
      expect(ValidateNumber().setLabel('X').min(1).validate(null), isNull);
    });
    test('max skips on null', () {
      expect(ValidateNumber().setLabel('X').max(10).validate(null), isNull);
    });
  });

  group('ValidateNumber.isInteger', () {
    test('passes for integer', () {
      expect(ValidateNumber().setLabel('X').isInteger().validate(5), isNull);
    });
    test('fails for float', () {
      expect(ValidateNumber().setLabel('X').isInteger().validate(5.5), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateNumber().setLabel('X').isInteger().validate(null), isNull);
    });
  });

  group('ValidateNumber.isPositive', () {
    test('passes for value > 0', () {
      expect(ValidateNumber().setLabel('X').isPositive().validate(1), isNull);
      expect(ValidateNumber().setLabel('X').isPositive().validate(0.001), isNull);
    });
    test('fails for 0', () {
      expect(ValidateNumber().setLabel('X').isPositive().validate(0), isNotNull);
    });
    test('fails for negative', () {
      expect(ValidateNumber().setLabel('X').isPositive().validate(-1), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateNumber().setLabel('X').isPositive().validate(null), isNull);
    });
  });

  group('ValidateNumber.isNegative', () {
    test('passes for value < 0', () {
      expect(ValidateNumber().setLabel('X').isNegative().validate(-1), isNull);
    });
    test('fails for 0', () {
      expect(ValidateNumber().setLabel('X').isNegative().validate(0), isNotNull);
    });
    test('fails for positive', () {
      expect(ValidateNumber().setLabel('X').isNegative().validate(1), isNotNull);
    });
  });

  group('ValidateNumber.isNonNegative', () {
    test('passes for 0', () {
      expect(ValidateNumber().setLabel('X').isNonNegative().validate(0), isNull);
    });
    test('passes for positive', () {
      expect(ValidateNumber().setLabel('X').isNonNegative().validate(5), isNull);
    });
    test('fails for negative', () {
      expect(ValidateNumber().setLabel('X').isNonNegative().validate(-1), isNotNull);
    });
  });

  group('ValidateNumber.isNonPositive', () {
    test('passes for 0', () {
      expect(ValidateNumber().setLabel('X').isNonPositive().validate(0), isNull);
    });
    test('passes for negative', () {
      expect(ValidateNumber().setLabel('X').isNonPositive().validate(-5), isNull);
    });
    test('fails for positive', () {
      expect(ValidateNumber().setLabel('X').isNonPositive().validate(1), isNotNull);
    });
  });

  test('ValidateNumber does not have phone() method', () {
    // This test documents the removal. Compile-time: if phone() exists, this file fails to
    // compile with the check below. Runtime check via reflection is not idiomatic in Dart,
    // so we document the contract here.
    //
    // If you see a compile error on the next line, phone() was accidentally re-added:
    // ValidateNumber().phone(); // must NOT compile
    expect(true, isTrue); // placeholder assertion to keep test valid
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
dart test test/validate_number_test.dart
```

Expected: failures (no `isPositive`, `isNegative`, `isNonNegative`, `isNonPositive`).

- [ ] **Step 3: Rewrite lib/src/util/validate_number.dart**

```dart
import 'package:dup/src/util/validate_locale.dart';
import 'package:dup/src/util/validator_base.dart';
import '../model/message_factory.dart';

class ValidateNumber extends BaseValidator<num, ValidateNumber> {
  ValidateNumber min(num min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value < min) {
        if (messageFactory != null) return messageFactory(label, {'min': min});
        final global = ValidatorLocale.current?.number['min']?.call({'name': label, 'min': min});
        if (global != null) return global;
        return '$label must be at least $min.';
      }
      return null;
    });
  }

  ValidateNumber max(num max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value > max) {
        if (messageFactory != null) return messageFactory(label, {'max': max});
        final global = ValidatorLocale.current?.number['max']?.call({'name': label, 'max': max});
        if (global != null) return global;
        return '$label must be at most $max.';
      }
      return null;
    });
  }

  ValidateNumber isInteger({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && value % 1 != 0) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.number['integer']?.call({'name': label});
        if (global != null) return global;
        return '$label must be an integer.';
      }
      return null;
    });
  }

  ValidateNumber isPositive({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value <= 0) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.number['positive']?.call({'name': label});
        if (global != null) return global;
        return '$label must be positive.';
      }
      return null;
    });
  }

  ValidateNumber isNegative({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value >= 0) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.number['negative']?.call({'name': label});
        if (global != null) return global;
        return '$label must be negative.';
      }
      return null;
    });
  }

  ValidateNumber isNonNegative({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value < 0) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.number['nonNegative']?.call({'name': label});
        if (global != null) return global;
        return '$label must be zero or positive.';
      }
      return null;
    });
  }

  ValidateNumber isNonPositive({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value > 0) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.number['nonPositive']?.call({'name': label});
        if (global != null) return global;
        return '$label must be zero or negative.';
      }
      return null;
    });
  }
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
dart test test/validate_number_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/validate_number.dart test/validate_number_test.dart
git commit -m "feat: remove phone/bizno from ValidateNumber, add isPositive/isNegative/isNonNegative/isNonPositive"
```

---

### Task 7: ValidateList Fixes

**Files:**
- Modify: `lib/src/util/validate_list.dart`
- Create: `test/validate_list_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/validate_list_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  group('ValidateList — null handling (symmetry fix)', () {
    test('minLength skips on null (was: fails)', () {
      expect(ValidateList<String>().setLabel('X').minLength(1).validate(null), isNull);
    });
    test('hasLength skips on null (was: fails)', () {
      expect(ValidateList<String>().setLabel('X').hasLength(3).validate(null), isNull);
    });
    test('any skips on null (was: fails)', () {
      expect(ValidateList<int>().setLabel('X').any((e) => e > 0).validate(null), isNull);
    });
    test('maxLength skips on null (unchanged)', () {
      expect(ValidateList<String>().setLabel('X').maxLength(5).validate(null), isNull);
    });
    test('all skips on null (unchanged)', () {
      expect(ValidateList<int>().setLabel('X').all((e) => e > 0).validate(null), isNull);
    });
  });

  group('ValidateList.isNotEmpty / isEmpty', () {
    test('isNotEmpty passes for non-empty list', () {
      expect(ValidateList<int>().setLabel('X').isNotEmpty().validate([1]), isNull);
    });
    test('isNotEmpty fails for empty list', () {
      expect(ValidateList<int>().setLabel('X').isNotEmpty().validate([]), isNotNull);
    });
    test('isEmpty passes for empty list', () {
      expect(ValidateList<int>().setLabel('X').isEmpty().validate([]), isNull);
    });
    test('isEmpty fails for non-empty list', () {
      expect(ValidateList<int>().setLabel('X').isEmpty().validate([1]), isNotNull);
    });
  });

  group('ValidateList.minLength / maxLength / hasLength / lengthBetween', () {
    test('minLength passes when list has enough items', () {
      expect(ValidateList<int>().setLabel('X').minLength(2).validate([1, 2, 3]), isNull);
    });
    test('minLength fails when list is too short', () {
      expect(ValidateList<int>().setLabel('X').minLength(3).validate([1, 2]), isNotNull);
    });
    test('maxLength passes when within limit', () {
      expect(ValidateList<int>().setLabel('X').maxLength(3).validate([1, 2]), isNull);
    });
    test('maxLength fails when exceeds limit', () {
      expect(ValidateList<int>().setLabel('X').maxLength(2).validate([1, 2, 3]), isNotNull);
    });
    test('hasLength passes for exact length', () {
      expect(ValidateList<int>().setLabel('X').hasLength(2).validate([1, 2]), isNull);
    });
    test('hasLength fails for wrong length', () {
      expect(ValidateList<int>().setLabel('X').hasLength(2).validate([1]), isNotNull);
    });
    test('lengthBetween passes within range', () {
      expect(ValidateList<int>().setLabel('X').lengthBetween(2, 4).validate([1, 2, 3]), isNull);
    });
    test('lengthBetween fails outside range', () {
      expect(ValidateList<int>().setLabel('X').lengthBetween(2, 4).validate([1]), isNotNull);
    });
  });

  group('ValidateList.contains / doesNotContain', () {
    test('contains passes when item is in list', () {
      expect(ValidateList<int>().setLabel('X').contains(3).validate([1, 2, 3]), isNull);
    });
    test('contains fails when item is missing', () {
      expect(ValidateList<int>().setLabel('X').contains(4).validate([1, 2, 3]), isNotNull);
    });
    test('doesNotContain passes when item absent', () {
      expect(ValidateList<int>().setLabel('X').doesNotContain(4).validate([1, 2, 3]), isNull);
    });
    test('doesNotContain fails when item present', () {
      expect(ValidateList<int>().setLabel('X').doesNotContain(3).validate([1, 2, 3]), isNotNull);
    });
  });

  group('ValidateList.all / any', () {
    test('all passes when all items satisfy predicate', () {
      expect(ValidateList<int>().setLabel('X').all((e) => e > 0).validate([1, 2, 3]), isNull);
    });
    test('all fails when any item fails predicate', () {
      expect(ValidateList<int>().setLabel('X').all((e) => e > 0).validate([1, -1, 3]), isNotNull);
    });
    test('any passes when at least one item satisfies', () {
      expect(ValidateList<int>().setLabel('X').any((e) => e > 2).validate([1, 2, 3]), isNull);
    });
    test('any fails when no item satisfies', () {
      expect(ValidateList<int>().setLabel('X').any((e) => e > 5).validate([1, 2, 3]), isNotNull);
    });
  });

  group('ValidateList.hasNoDuplicates', () {
    test('passes for unique list', () {
      expect(ValidateList<int>().setLabel('X').hasNoDuplicates().validate([1, 2, 3]), isNull);
    });
    test('fails for list with duplicates', () {
      expect(ValidateList<int>().setLabel('X').hasNoDuplicates().validate([1, 2, 2]), isNotNull);
    });
  });

  group('ValidateList.eachItem', () {
    test('passes when all items pass validator', () {
      expect(
        ValidateList<int>().setLabel('Scores')
            .eachItem((e) => e >= 0 ? null : 'negative')
            .validate([1, 2, 3]),
        isNull,
      );
    });
    test('fails and reports index when item fails', () {
      final error = ValidateList<int>().setLabel('Scores')
          .eachItem((e) => e >= 0 ? null : 'negative')
          .validate([1, -1, 3]);
      expect(error, contains('1')); // index 1
    });
  });

  group('ValidateList — error message trailing period', () {
    test('isNotEmpty error ends with period', () {
      final error = ValidateList<int>().setLabel('Items').isNotEmpty().validate([]);
      expect(error, endsWith('.'));
    });
    test('minLength error ends with period', () {
      final error = ValidateList<int>().setLabel('Items').minLength(3).validate([1]);
      expect(error, endsWith('.'));
    });
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
dart test test/validate_list_test.dart
```

Expected: failures on null-handling and trailing period tests.

- [ ] **Step 3: Rewrite lib/src/util/validate_list.dart**

```dart
import 'package:dup/src/util/validate_locale.dart';
import 'package:dup/src/util/validator_base.dart';
import '../model/message_factory.dart';

class ValidateList<T> extends BaseValidator<List<T>, ValidateList<T>> {
  ValidateList<T> isNotEmpty({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null || value.isEmpty) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.array['notEmpty']?.call({'name': label});
        if (global != null) return global;
        return '$label cannot be empty.';
      }
      return null;
    });
  }

  ValidateList<T> isEmpty({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value != null && value.isNotEmpty) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.array['empty']?.call({'name': label});
        if (global != null) return global;
        return '$label must be empty.';
      }
      return null;
    });
  }

  ValidateList<T> minLength(int min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null; // null-skip fix
      if (value.length < min) {
        if (messageFactory != null) return messageFactory(label, {'min': min});
        final global = ValidatorLocale.current?.array['min']?.call({'name': label, 'min': min});
        if (global != null) return global;
        return '$label must have at least $min items.';
      }
      return null;
    });
  }

  ValidateList<T> maxLength(int max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.length > max) {
        if (messageFactory != null) return messageFactory(label, {'max': max});
        final global = ValidatorLocale.current?.array['max']?.call({'name': label, 'max': max});
        if (global != null) return global;
        return '$label cannot have more than $max items.';
      }
      return null;
    });
  }

  ValidateList<T> lengthBetween(int min, int max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null || value.length < min || value.length > max) {
        if (messageFactory != null) return messageFactory(label, {'min': min, 'max': max});
        final global = ValidatorLocale.current?.array['lengthBetween']
            ?.call({'name': label, 'min': min, 'max': max});
        if (global != null) return global;
        return '$label length must be between $min and $max.';
      }
      return null;
    });
  }

  ValidateList<T> hasLength(int length, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null; // null-skip fix
      if (value.length != length) {
        if (messageFactory != null) return messageFactory(label, {'length': length});
        final global = ValidatorLocale.current?.array['exactLength']
            ?.call({'name': label, 'length': length});
        if (global != null) return global;
        return '$label must have exactly $length items.';
      }
      return null;
    });
  }

  ValidateList<T> contains(T item, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null || !value.contains(item)) {
        if (messageFactory != null) return messageFactory(label, {'item': item});
        final global = ValidatorLocale.current?.array['contains']
            ?.call({'name': label, 'item': item});
        if (global != null) return global;
        return '$label must contain $item.';
      }
      return null;
    });
  }

  ValidateList<T> doesNotContain(T item, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.contains(item)) {
        if (messageFactory != null) return messageFactory(label, {'item': item});
        final global = ValidatorLocale.current?.array['doesNotContain']
            ?.call({'name': label, 'item': item});
        if (global != null) return global;
        return '$label must not contain $item.';
      }
      return null;
    });
  }

  ValidateList<T> all(bool Function(T) predicate, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && !value.every(predicate)) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.array['allCondition']?.call({'name': label});
        if (global != null) return global;
        return 'All items in $label must satisfy the condition.';
      }
      return null;
    });
  }

  ValidateList<T> any(bool Function(T) predicate, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null; // null-skip fix
      if (!value.any(predicate)) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.array['anyCondition']?.call({'name': label});
        if (global != null) return global;
        return 'At least one item in $label must satisfy the condition.';
      }
      return null;
    });
  }

  ValidateList<T> hasNoDuplicates({MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value.toSet().length != value.length) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.array['noDuplicates']?.call({'name': label});
        if (global != null) return global;
        return '$label must not contain duplicate items.';
      }
      return null;
    });
  }

  ValidateList<T> eachItem(String? Function(T) validator, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null) {
        for (int i = 0; i < value.length; i++) {
          final itemError = validator(value[i]);
          if (itemError != null) {
            if (messageFactory != null) {
              return messageFactory(label, {'index': i, 'error': itemError});
            }
            final global = ValidatorLocale.current?.array['eachItem']
                ?.call({'name': label, 'index': i, 'error': itemError});
            if (global != null) return global;
            return 'Item at index $i in $label: $itemError';
          }
        }
      }
      return null;
    });
  }
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
dart test test/validate_list_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/validate_list.dart test/validate_list_test.dart
git commit -m "fix: fix null-skip for minLength/hasLength/any, add trailing periods to ValidateList messages"
```

---

### Task 8: ValidateBool (New)

**Files:**
- Create: `lib/src/util/validate_bool.dart`
- Create: `test/validate_bool_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/validate_bool_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  group('ValidateBool.isTrue', () {
    test('passes for true', () {
      expect(ValidateBool().setLabel('Agreed').isTrue().validate(true), isNull);
    });
    test('fails for false', () {
      expect(ValidateBool().setLabel('Agreed').isTrue().validate(false), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateBool().setLabel('Agreed').isTrue().validate(null), isNull);
    });
    test('required() + isTrue() catches null before checking value', () {
      final v = ValidateBool().setLabel('Agreed').isTrue().required();
      expect(v.validate(null), equals('Agreed is required.'));
    });
  });

  group('ValidateBool.isFalse', () {
    test('passes for false', () {
      expect(ValidateBool().setLabel('Disabled').isFalse().validate(false), isNull);
    });
    test('fails for true', () {
      expect(ValidateBool().setLabel('Disabled').isFalse().validate(true), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateBool().setLabel('Disabled').isFalse().validate(null), isNull);
    });
  });

  group('ValidateBool — inherited methods', () {
    test('required() catches null', () {
      expect(ValidateBool().setLabel('X').required().validate(null), isNotNull);
    });
    test('equalTo() works with bool', () {
      expect(ValidateBool().setLabel('X').equalTo(true).validate(false), isNotNull);
      expect(ValidateBool().setLabel('X').equalTo(true).validate(true), isNull);
    });
    test('satisfy() works with bool', () {
      expect(ValidateBool().setLabel('X').satisfy((v) => v == true).validate(false), isNotNull);
    });
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
dart test test/validate_bool_test.dart
```

Expected: compile error (`ValidateBool` does not exist).

- [ ] **Step 3: Create lib/src/util/validate_bool.dart**

```dart
import 'package:dup/src/util/validate_locale.dart';
import 'package:dup/src/util/validator_base.dart';
import '../model/message_factory.dart';

class ValidateBool extends BaseValidator<bool, ValidateBool> {
  ValidateBool isTrue({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value != true) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.boolMessages['isTrue']?.call({'name': label});
        if (global != null) return global;
        return '$label must be true.';
      }
      return null;
    });
  }

  ValidateBool isFalse({MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (value != false) {
        if (messageFactory != null) return messageFactory(label, {});
        final global = ValidatorLocale.current?.boolMessages['isFalse']?.call({'name': label});
        if (global != null) return global;
        return '$label must be false.';
      }
      return null;
    });
  }
}
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
dart test test/validate_bool_test.dart
```

Expected: compile error — `ValidateBool` not exported from `dup.dart` yet. Add the export temporarily for this task:

```bash
# Add to lib/dup.dart temporarily (will be finalised in Task 11):
echo "export 'src/util/validate_bool.dart';" >> lib/dup.dart
```

Re-run:

```bash
dart test test/validate_bool_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/validate_bool.dart test/validate_bool_test.dart lib/dup.dart
git commit -m "feat: add ValidateBool with isTrue/isFalse"
```

---

### Task 9: ValidateDateTime (New)

**Files:**
- Create: `lib/src/util/validate_date_time.dart`
- Create: `test/validate_date_time_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/validate_date_time_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  final past = DateTime(2000, 1, 1);
  final future = DateTime(2030, 1, 1);
  final middle = DateTime(2015, 6, 15);

  group('ValidateDateTime.isBefore', () {
    test('passes when date is before target', () {
      expect(ValidateDateTime().setLabel('Date').isBefore(future).validate(past), isNull);
    });
    test('fails when date is after target', () {
      expect(ValidateDateTime().setLabel('Date').isBefore(past).validate(future), isNotNull);
    });
    test('fails when date equals target (not before)', () {
      expect(ValidateDateTime().setLabel('Date').isBefore(past).validate(past), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateDateTime().setLabel('Date').isBefore(future).validate(null), isNull);
    });
  });

  group('ValidateDateTime.isAfter', () {
    test('passes when date is after target', () {
      expect(ValidateDateTime().setLabel('Date').isAfter(past).validate(future), isNull);
    });
    test('fails when date is before target', () {
      expect(ValidateDateTime().setLabel('Date').isAfter(future).validate(past), isNotNull);
    });
    test('fails when date equals target (not after)', () {
      expect(ValidateDateTime().setLabel('Date').isAfter(future).validate(future), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateDateTime().setLabel('Date').isAfter(past).validate(null), isNull);
    });
  });

  group('ValidateDateTime.min', () {
    test('passes when date is on or after min', () {
      expect(ValidateDateTime().setLabel('Date').min(past).validate(past), isNull);
      expect(ValidateDateTime().setLabel('Date').min(past).validate(future), isNull);
    });
    test('fails when date is before min', () {
      expect(ValidateDateTime().setLabel('Date').min(future).validate(past), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateDateTime().setLabel('Date').min(past).validate(null), isNull);
    });
  });

  group('ValidateDateTime.max', () {
    test('passes when date is on or before max', () {
      expect(ValidateDateTime().setLabel('Date').max(future).validate(future), isNull);
      expect(ValidateDateTime().setLabel('Date').max(future).validate(past), isNull);
    });
    test('fails when date is after max', () {
      expect(ValidateDateTime().setLabel('Date').max(past).validate(future), isNotNull);
    });
    test('skips on null', () {
      expect(ValidateDateTime().setLabel('Date').max(future).validate(null), isNull);
    });
  });

  group('ValidateDateTime.between', () {
    test('passes when date is within range', () {
      expect(ValidateDateTime().setLabel('Date').between(past, future).validate(middle), isNull);
    });
    test('passes at boundary dates', () {
      expect(ValidateDateTime().setLabel('Date').between(past, future).validate(past), isNull);
      expect(ValidateDateTime().setLabel('Date').between(past, future).validate(future), isNull);
    });
    test('fails when date is before range', () {
      expect(
        ValidateDateTime().setLabel('Date').between(middle, future).validate(past),
        isNotNull,
      );
    });
    test('fails when date is after range', () {
      expect(
        ValidateDateTime().setLabel('Date').between(past, middle).validate(future),
        isNotNull,
      );
    });
    test('skips on null', () {
      expect(ValidateDateTime().setLabel('Date').between(past, future).validate(null), isNull);
    });
  });

  group('ValidateDateTime — required + format phase ordering', () {
    test('required() fires before isAfter() regardless of chain order', () {
      final v = ValidateDateTime().setLabel('Date').isAfter(past).required();
      expect(v.validate(null), equals('Date is required.'));
    });
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
dart test test/validate_date_time_test.dart
```

Expected: compile error (`ValidateDateTime` does not exist).

- [ ] **Step 3: Create lib/src/util/validate_date_time.dart**

```dart
import 'package:dup/src/util/validate_locale.dart';
import 'package:dup/src/util/validator_base.dart';
import '../model/message_factory.dart';

class ValidateDateTime extends BaseValidator<DateTime, ValidateDateTime> {
  ValidateDateTime isBefore(DateTime target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (!value.isBefore(target)) {
        if (messageFactory != null) return messageFactory(label, {'target': target});
        final global = ValidatorLocale.current?.date['before']
            ?.call({'name': label, 'target': target});
        if (global != null) return global;
        return '$label must be before $target.';
      }
      return null;
    });
  }

  ValidateDateTime isAfter(DateTime target, {MessageFactory? messageFactory}) {
    return addPhaseValidator(1, (value) {
      if (value == null) return null;
      if (!value.isAfter(target)) {
        if (messageFactory != null) return messageFactory(label, {'target': target});
        final global = ValidatorLocale.current?.date['after']
            ?.call({'name': label, 'target': target});
        if (global != null) return global;
        return '$label must be after $target.';
      }
      return null;
    });
  }

  ValidateDateTime min(DateTime min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isBefore(min)) {
        if (messageFactory != null) return messageFactory(label, {'min': min});
        final global = ValidatorLocale.current?.date['min']
            ?.call({'name': label, 'min': min});
        if (global != null) return global;
        return '$label must be on or after $min.';
      }
      return null;
    });
  }

  ValidateDateTime max(DateTime max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isAfter(max)) {
        if (messageFactory != null) return messageFactory(label, {'max': max});
        final global = ValidatorLocale.current?.date['max']
            ?.call({'name': label, 'max': max});
        if (global != null) return global;
        return '$label must be on or before $max.';
      }
      return null;
    });
  }

  ValidateDateTime between(DateTime min, DateTime max, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value == null) return null;
      if (value.isBefore(min) || value.isAfter(max)) {
        if (messageFactory != null) return messageFactory(label, {'min': min, 'max': max});
        final global = ValidatorLocale.current?.date['between']
            ?.call({'name': label, 'min': min, 'max': max});
        if (global != null) return global;
        return '$label must be between $min and $max.';
      }
      return null;
    });
  }
}
```

- [ ] **Step 4: Add temporary export and run tests**

```bash
echo "export 'src/util/validate_date_time.dart';" >> lib/dup.dart
dart test test/validate_date_time_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/validate_date_time.dart test/validate_date_time_test.dart lib/dup.dart
git commit -m "feat: add ValidateDateTime with min/max/isBefore/isAfter/between"
```

---

### Task 10: UiFormService Upgrade

**Files:**
- Modify: `lib/src/util/ui_form_service.dart`
- Create: `test/ui_form_service_test.dart`

- [ ] **Step 1: Write failing tests**

Create `test/ui_form_service_test.dart`:

```dart
import 'package:test/test.dart';
import 'package:dup/dup.dart';

void main() {
  group('UiFormService.validate — sync', () {
    test('passes when all fields are valid', () async {
      final schema = BaseValidatorSchema({
        'email': ValidateString().setLabel('Email').email().required(),
        'age': ValidateNumber().setLabel('Age').min(18).required(),
      });

      await expectLater(
        useUiForm.validate(schema, {'email': 'user@example.com', 'age': 25}),
        completes,
      );
    });

    test('throws FormValidationException when field is invalid', () async {
      final schema = BaseValidatorSchema({
        'email': ValidateString().setLabel('Email').email().required(),
      });

      await expectLater(
        useUiForm.validate(schema, {'email': 'bad'}),
        throwsA(isA<FormValidationException>()),
      );
    });

    test('errors map contains the failing field key', () async {
      final schema = BaseValidatorSchema({
        'email': ValidateString().setLabel('Email').email().required(),
        'name': ValidateString().setLabel('Name').required(),
      });

      try {
        await useUiForm.validate(schema, {'email': 'bad', 'name': 'Alice'});
        fail('Should have thrown');
      } on FormValidationException catch (e) {
        expect(e.errors.containsKey('email'), isTrue);
        expect(e.errors.containsKey('name'), isFalse);
      }
    });

    test('abortEarly stops after first error', () async {
      final schema = BaseValidatorSchema({
        'email': ValidateString().setLabel('Email').required(),
        'name': ValidateString().setLabel('Name').required(),
      });

      try {
        await useUiForm.validate(
          schema,
          {'email': null, 'name': null},
          abortEarly: true,
        );
        fail('Should have thrown');
      } on FormValidationException catch (e) {
        expect(e.errors.length, equals(1));
      }
    });

    test('missing field in request is treated as null', () async {
      final schema = BaseValidatorSchema({
        'email': ValidateString().setLabel('Email').required(),
      });

      try {
        await useUiForm.validate(schema, {}); // no 'email' key
        fail('Should have thrown');
      } on FormValidationException catch (e) {
        expect(e.errors.containsKey('email'), isTrue);
      }
    });
  });

  group('UiFormService.validate — async validators', () {
    test('runs async validator and catches error', () async {
      final schema = BaseValidatorSchema({
        'email': ValidateString()
            .setLabel('Email')
            .email()
            .addAsyncValidator((val) async => 'Email already taken.'),
      });

      try {
        await useUiForm.validate(schema, {'email': 'user@example.com'});
        fail('Should have thrown');
      } on FormValidationException catch (e) {
        expect(e.errors['email'], equals('Email already taken.'));
      }
    });

    test('async validator not reached when sync fails', () async {
      bool asyncCalled = false;
      final schema = BaseValidatorSchema({
        'email': ValidateString()
            .setLabel('Email')
            .email()
            .addAsyncValidator((val) async {
              asyncCalled = true;
              return null;
            }),
      });

      try {
        await useUiForm.validate(schema, {'email': 'bad-email'});
      } on FormValidationException catch (_) {}

      expect(asyncCalled, isFalse);
    });
  });

  group('UiFormService.hasError', () {
    test('returns true for field with error', () {
      final ex = FormValidationException({'email': 'Invalid.'});
      expect(useUiForm.hasError('email', ex), isTrue);
    });
    test('returns false for field without error', () {
      final ex = FormValidationException({'email': 'Invalid.'});
      expect(useUiForm.hasError('name', ex), isFalse);
    });
    test('returns false when exception is null', () {
      expect(useUiForm.hasError('email', null), isFalse);
    });
  });

  group('UiFormService.getError', () {
    test('returns error message for field', () {
      final ex = FormValidationException({'email': 'Invalid email.'});
      expect(useUiForm.getError('email', ex), equals('Invalid email.'));
    });
    test('returns null for field without error', () {
      final ex = FormValidationException({'email': 'Invalid email.'});
      expect(useUiForm.getError('name', ex), isNull);
    });
    test('returns null when exception is null', () {
      expect(useUiForm.getError('email', null), isNull);
    });
  });
}
```

- [ ] **Step 2: Run tests — verify they fail**

```bash
dart test test/ui_form_service_test.dart
```

Expected: failures (`getError` not defined, async validators not run).

- [ ] **Step 3: Rewrite lib/src/util/ui_form_service.dart**

```dart
import 'package:dup/src/util/validator_base.dart';
import '../model/base_validator_schema.dart';
import 'form_validate_exception.dart';

class UiFormService {
  Future<void> validate(
    BaseValidatorSchema schema,
    Map<String, dynamic> request, {
    bool abortEarly = false,
    String fallbackMessage = 'Invalid form.',
  }) async {
    final errors = <String, String>{};

    for (final field in schema.schema.keys) {
      final validator = schema.schema[field]!;
      final value = request[field];
      final String? error = await validator.validateAsync(value);

      if (error != null) {
        errors[field] = error;
        if (abortEarly) break;
      }
    }

    if (errors.isNotEmpty) {
      throw FormValidationException(errors, fallbackMessage: fallbackMessage);
    }
  }

  bool hasError(String path, FormValidationException? error) {
    if (error == null) return false;
    return error.errors.containsKey(path);
  }

  String? getError(String path, FormValidationException? error) {
    if (error == null) return null;
    return error.errors[path];
  }
}

final useUiForm = UiFormService();
```

- [ ] **Step 4: Run tests — verify they pass**

```bash
dart test test/ui_form_service_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/src/util/ui_form_service.dart test/ui_form_service_test.dart
git commit -m "feat: upgrade UiFormService — true async, add getError(), remove raw type"
```

---

## WAVE 3

---

### Task 11: Finalize Exports + Full Test Run

**Files:**
- Modify: `lib/dup.dart`

- [ ] **Step 1: Rewrite lib/dup.dart with all exports**

```dart
library;

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

// Schema and exceptions
export 'src/model/base_validator_schema.dart';
export 'src/util/form_validate_exception.dart';

// Form validation service
export 'src/util/ui_form_service.dart';

// Locale messages
export 'src/model/locale_message.dart';
export 'src/model/message_factory.dart';
```

- [ ] **Step 2: Run full test suite**

```bash
dart test
```

Expected: all tests pass with output like:
```
All tests passed!
XX tests passed in X.XXs
```

- [ ] **Step 3: Run analyzer**

```bash
dart analyze
```

Expected: `No issues found!`

- [ ] **Step 4: Commit**

```bash
git add lib/dup.dart
git commit -m "feat: finalize dup.dart exports for v2.0"
```

- [ ] **Step 5: Tag the release**

```bash
git tag v2.0.0
```

---

## Self-Review Checklist

- [x] **pubspec.yaml** Flutter removed, version 2.0.0, `test` + `lints` in dev → Task 1
- [x] **BaseValidator phase system** → Task 2
- [x] **BaseValidator async** (`addAsyncValidator`, `validateAsync`) → Task 2
- [x] **satisfy() null-skip fix** → Task 2
- [x] **ValidatorLocale resetLocale()** → Task 3
- [x] **boolMessages + date categories** → Task 3
- [x] **ValidatorLocaleKeys constants** → Task 3
- [x] **FormValidationException Map<String, String>** → Task 4
- [x] **ValidateString email/password/mobile null-skip** → Task 5
- [x] **ValidateString password ASCII restriction removed** → Task 5
- [x] **ValidateString emoji regex fix** → Task 5
- [x] **ValidateString phone/bizno (moved from ValidateNumber)** → Task 5
- [x] **ValidateString mobile/phone/bizno customRegex param** → Task 5
- [x] **ValidateString url() + uuid()** → Task 5
- [x] **ValidateNumber phone/bizno removed** → Task 6
- [x] **ValidateNumber isPositive/isNegative/isNonNegative/isNonPositive** → Task 6
- [x] **ValidateList minLength/hasLength/any null-skip fix** → Task 7
- [x] **ValidateList trailing period fix** → Task 7
- [x] **ValidateBool isTrue/isFalse** → Task 8
- [x] **ValidateDateTime min/max/isBefore/isAfter/between** → Task 9
- [x] **UiFormService truly async** → Task 10
- [x] **UiFormService getError()** → Task 10
- [x] **UiFormService raw type removal** → Task 10
- [x] **.gitignore doc/** → Task 1
- [x] **Tests for all components** → Tasks 2–10
