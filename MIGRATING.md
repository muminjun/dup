# Migrating from dup v1 to v2

This guide covers every breaking change between `dup ^1.0.4` and `dup ^2.0.0`,
with before/after code for each. The validator rule methods themselves
(`min`, `max`, `email`, `required`, `equalTo`, etc.) are unchanged — only
the surrounding infrastructure changed.

---

## Summary of changes

| Area | v1 | v2 |
|---|---|---|
| Schema class | `BaseValidatorSchema` | `DupSchema` |
| Form validation entry point | `useUiForm.validate(schema, data)` | `schema.validate(data)` |
| Form validation result | throws `FormValidationException` | returns `FormValidationFailure` |
| Read an error | `useUiForm.getError(field, ex)` | `result(field)?.message` |
| Check for error | `useUiForm.hasError(field, ex)` | `result.hasError(field)` |
| Custom validator return type | `String?` | `ValidationFailure?` |
| Locale constructor | `ValidatorLocale(mixed:, number:, string:, array:)` | `ValidatorLocale(Map<ValidationCode, fn>)` |
| Locale keys | plain strings (`'phoneInvalid'`, `'moreThan'`, …) | `ValidationCode` enum values |

---

## 1. Schema class rename

```dart
// v1
final schema = BaseValidatorSchema({
  'email': ValidateString().email().required(),
});

// v2
final schema = DupSchema({
  'email': ValidateString().email().required(),
});
```

`DupSchema` also accepts an optional `labels` map to override field-name labels
in error messages, and a `crossValidate()` method for cross-field checks — see
[Cross-field validation](#cross-field-validation) below.

---

## 2. Form validation call site

v1 throws an exception. v2 returns a sealed result value — no try/catch needed.

```dart
// v1
try {
  await useUiForm.validate(schema, formData);
  // success
} on FormValidationException catch (ex) {
  final msg = useUiForm.getError('email', ex);
  final has = useUiForm.hasError('email', ex);
}

// v2
final result = await schema.validate(formData);
switch (result) {
  FormValidationSuccess() => submitForm(),
  FormValidationFailure(:final errors) => showErrors(errors),
}

// Or with is-checks:
if (result is FormValidationFailure) {
  result('email')?.message;   // String? — the error message
  result.hasError('email');   // bool
  result.fields;              // List<String> of all failing fields
}
```

`DupSchema` also exposes:
- `validateSync(data)` — synchronous path (asserts no async validators are present)
- `validateField(field, value)` — single-field validation for on-change feedback

---

## 3. `addValidator` return type

Every custom validator callback must now return `ValidationFailure?`
instead of `String?`.

```dart
// v1
ValidateString().addValidator((value) {
  if (value != null && !value.startsWith('APP-')) {
    return 'Code must start with APP-.';   // String?
  }
  return null;
});

// v2
ValidateString().addValidator((value) {
  if (value != null && !value.startsWith('APP-')) {
    return const ValidationFailure(
      code: ValidationCode.custom,
      message: 'Code must start with APP-.',
    );
  }
  return null;
});
```

For validators registered on a `BaseValidator` subclass, you can use the
inherited `getFailure(code, label)` helper if you need the label in the message:

```dart
ValidateString()
  .setLabel('Code')
  .addValidator((value) {
    if (value != null && !value.startsWith('APP-')) {
      return ValidationFailure(
        code: ValidationCode.custom,
        message: 'Code must start with APP-.',
      );
    }
    return null;
  });
```

---

## 4. Locale setup

The `ValidatorLocale` constructor is completely different. v1 used four
named parameters with plain-string keys; v2 uses a single `Map<ValidationCode, fn>`.

```dart
// v1
ValidatorLocale.setLocale(
  ValidatorLocale(
    mixed: {
      'required': (args) => '${args['name']}은(는) 필수 항목입니다.',
      'equal':    (args) => '${args['name']}이(가) 일치하지 않습니다.',
    },
    number: {
      'min':          (args) => '${args['name']}은(는) ${args['min']} 이상이어야 합니다.',
      'moreThan':     (args) => '${args['name']}은(는) ${args['min']} 초과여야 합니다.',
      'lessThan':     (args) => '${args['name']}은(는) ${args['max']} 미만이어야 합니다.',
      'phoneEmpty':   (args) => '전화번호를 입력해주세요.',
      'phoneInvalid': (args) => '올바른 전화번호 형식이 아닙니다.',
      'biznoEmpty':   (args) => '사업자번호를 입력해주세요.',
      'biznoInvalid': (args) => '올바른 사업자번호 형식이 아닙니다.',
    },
    string: {
      'min':          (args) => '${args['name']}은(는) ${args['min']}자 이상이어야 합니다.',
      'emailEmpty':   (args) => '이메일을 입력해주세요.',
      'emailInvalid': (args) => '올바른 이메일 형식이 아닙니다.',
    },
    array: {
      'min': (args) => '${args['name']}은(는) ${args['min']}개 이상 선택해야 합니다.',
    },
  ),
);

// v2
ValidatorLocale.setLocale(
  ValidatorLocale({
    ValidationCode.required:      (p) => '${p['name']}은(는) 필수 항목입니다.',
    ValidationCode.equal:         (p) => '${p['name']}이(가) 일치하지 않습니다.',
    ValidationCode.numberMin:     (p) => '${p['name']}은(는) ${p['min']} 이상이어야 합니다.',
    ValidationCode.numberMax:     (p) => '${p['name']}은(는) ${p['max']} 이하여야 합니다.',
    // moreThan / lessThan were removed — use min() / max() instead
    ValidationCode.phoneInvalid:  (p) => '올바른 전화번호 형식이 아닙니다.',
    ValidationCode.biznoInvalid:  (p) => '올바른 사업자번호 형식이 아닙니다.',
    ValidationCode.stringMin:     (p) => '${p['name']}은(는) ${p['min']}자 이상이어야 합니다.',
    ValidationCode.emailInvalid:  (p) => '올바른 이메일 형식이 아닙니다.',
    ValidationCode.listMin:       (p) => '${p['name']}은(는) ${p['min']}개 이상 선택해야 합니다.',
  }),
);
```

### v1 → v2 locale key mapping

| v1 key (mixed) | v2 `ValidationCode` |
|---|---|
| `'required'` | `required` |
| `'equal'` | `equal` |
| `'notEqual'` | `notEqual` |
| `'oneOf'` | `oneOf` |
| `'notOneOf'` | `notOneOf` |
| `'condition'` | `condition` |
| `'default'` | _(removed — v2 always has a built-in English default)_ |

| v1 key (number) | v2 `ValidationCode` |
|---|---|
| `'min'` | `numberMin` |
| `'max'` | `numberMax` |
| `'moreThan'` | _(removed — use `min()` with exclusive semantics if needed)_ |
| `'lessThan'` | _(removed — use `max()` with exclusive semantics if needed)_ |
| `'integer'` | `integer` |
| `'phoneEmpty'` | `required` _(empty phone now triggers the shared `required` code)_ |
| `'phoneInvalid'` | `phoneInvalid` |
| `'biznoEmpty'` | `required` |
| `'biznoInvalid'` | `biznoInvalid` |

| v1 key (string) | v2 `ValidationCode` |
|---|---|
| `'min'` | `stringMin` |
| `'max'` | `stringMax` |
| `'length'` | _(no direct equivalent; use `min` + `max` with same value)_ |
| `'matches'` | `matches` |
| `'emailEmpty'` | `required` |
| `'emailInvalid'` | `emailInvalid` |
| `'passwordEmpty'` | `required` |
| `'passwordMin'` | `passwordMin` |
| `'passwordAscii'` | `matches` _(ASCII check uses matches internally)_ |
| `'emoji'` | `emoji` |
| `'mobileEmpty'` | `required` |
| `'mobileInvalid'` | `mobileInvalid` |
| `'url'` | `url` |

| v1 key (array) | v2 `ValidationCode` |
|---|---|
| `'min'` | `listMin` |
| `'max'` | `listMax` |

---

## 5. Removed methods

| v1 method | Replacement |
|---|---|
| `ValidateNumber().moreThan(n)` | `ValidateNumber().min(n)` (note: `min` is `>=`, not `>`) |
| `ValidateNumber().lessThan(n)` | `ValidateNumber().max(n)` (note: `max` is `<=`, not `<`) |

If you relied on strict `>` / `<` semantics, use `satisfy()`:

```dart
ValidateNumber().satisfy((v) => v! > 0, message: 'Must be greater than 0.');
```

---

## 6. Cross-field validation

v1 had no built-in cross-field mechanism. v2 adds `DupSchema.crossValidate()`,
called only when all individual fields pass:

```dart
final schema = DupSchema({
  'password':        ValidateString().min(8).required(),
  'passwordConfirm': ValidateString().required(),
}).crossValidate((data) {
  if (data['password'] != data['passwordConfirm']) {
    return {
      'passwordConfirm': const ValidationFailure(
        code: ValidationCode.custom,
        message: '비밀번호가 일치하지 않습니다.',
      ),
    };
  }
  return null;
});
```

---

## 7. New in v2

- **`DupSchema.validateSync(data)`** — synchronous path, no `await` needed for pure-sync schemas
- **`DupSchema.validateField(field, value)`** — single-field validation for `TextFormField` onChange
- **`ValidationCode` enum** — type-safe, IDE-autocomplete locale keys; no more typo-prone strings
- **`ValidationFailure.code`** — read the failure reason programmatically
- **`FormValidationFailure` as a return value** — cleaner async flow, no try/catch
- **`ValidateNumber.toValidator({parseErrorMessage})`** — strips non-numeric characters (`"1,000"`, `"17세"`) before validating; directly usable as Flutter `TextFormField.validator`
- Many new `ValidateList` methods: `hasLength`, `all`, `any`, `none`, `hasNoDuplicates`, `eachItem`
- New `ValidateNumber` methods: `isPositive`, `isNegative`, `isNonNegative`, `isNonPositive`, `isEven`, `isOdd`, `isMultipleOf`, `between`
- New `ValidateBool` type (was absent in v1)
- New `ValidateDateTime` type (was absent in v1)
