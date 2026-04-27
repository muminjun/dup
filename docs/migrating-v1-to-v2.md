# Migrating from dup v1 to v2

dup 2.0.0 is a focused redesign of the infrastructure around validators.
The **validator rule methods** (`min`, `max`, `email`, `required`, `equalTo`, etc.)
are unchanged — only the schema, result, and locale APIs changed.

---

## Quick reference

| Area | v1 | v2 |
|---|---|---|
| Schema class | `BaseValidatorSchema` | `DupSchema` |
| Run validation | `useUiForm.validate(schema, data)` | `schema.validate(data)` |
| On success | _(no exception)_ | `FormValidationSuccess` |
| On failure | throws `FormValidationException` | returns `FormValidationFailure` |
| Read error | `useUiForm.getError(field, ex)` | `result(field)?.message` |
| Has error? | `useUiForm.hasError(field, ex)` | `result.hasError(field)` |
| Custom validator | returns `String?` | returns `ValidationFailure?` |
| Locale setup | `ValidatorLocale(mixed:, number:, string:, array:)` | `ValidatorLocale(Map<ValidationCode, fn>)` |

---

## Step 1 — Rename `BaseValidatorSchema` to `DupSchema`

```dart
// Before
final schema = BaseValidatorSchema({
  'email': ValidateString().email().required(),
  'age':   ValidateNumber().min(18).required(),
});

// After
final schema = DupSchema({
  'email': ValidateString().email().required(),
  'age':   ValidateNumber().min(18).required(),
});
```

`DupSchema` also supports optional field label overrides and cross-field validation:

```dart
DupSchema(
  {'passwordConfirm': ValidateString().required()},
  labels: {'passwordConfirm': '비밀번호 확인'},
)
```

---

## Step 2 — Replace `useUiForm.validate()` with `schema.validate()`

v1 threw an exception on failure. v2 returns a sealed result value.

```dart
// Before
try {
  await useUiForm.validate(schema, formData);
  submitForm();
} on FormValidationException catch (ex) {
  final msg = useUiForm.getError('email', ex);
  final has = useUiForm.hasError('email', ex);
}

// After
final result = await schema.validate(formData);

switch (result) {
  FormValidationSuccess() => submitForm(),
  FormValidationFailure(:final errors) => showErrors(errors),
}

// Or with is-checks:
if (result is FormValidationFailure) {
  result('email')?.message;   // String? — error message
  result.hasError('email');   // bool
  result.fields;              // List<String> — all failing fields
  result.firstField;          // String? — first failing field
}
```

New in v2:

```dart
// Sync path — no await needed (asserts no async validators are present)
final result = schema.validateSync(formData);

// Single-field validation for TextFormField onChange
final fieldResult = await schema.validateField('email', value);
```

---

## Step 3 — Update `addValidator` callbacks

Every custom validator callback must return `ValidationFailure?` instead of `String?`.

```dart
// Before
ValidateString().addValidator((value) {
  if (value != null && !value.startsWith('APP-')) {
    return 'Code must start with APP-.';
  }
  return null;
});

// After
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

---

## Step 4 — Rewrite `ValidatorLocale.setLocale()`

The constructor changed from four named parameters with string keys to a single
`Map<ValidationCode, fn>`.

```dart
// Before
ValidatorLocale.setLocale(
  ValidatorLocale(
    mixed: {
      'required':     (p) => '${p['name']}은(는) 필수 항목입니다.',
      'equal':        (p) => '${p['name']}이(가) 일치하지 않습니다.',
    },
    number: {
      'min':          (p) => '${p['name']}은(는) ${p['min']} 이상이어야 합니다.',
      'phoneInvalid': (p) => '올바른 전화번호 형식이 아닙니다.',
      'biznoInvalid': (p) => '올바른 사업자번호 형식이 아닙니다.',
    },
    string: {
      'min':          (p) => '${p['name']}은(는) ${p['min']}자 이상이어야 합니다.',
      'emailInvalid': (p) => '올바른 이메일 형식이 아닙니다.',
    },
    array: {
      'min':          (p) => '${p['name']}은(는) ${p['min']}개 이상 선택해야 합니다.',
    },
  ),
);

// After
ValidatorLocale.setLocale(
  ValidatorLocale({
    ValidationCode.required:      (p) => '${p['name']}은(는) 필수 항목입니다.',
    ValidationCode.equal:         (p) => '${p['name']}이(가) 일치하지 않습니다.',
    ValidationCode.numberMin:     (p) => '${p['name']}은(는) ${p['min']} 이상이어야 합니다.',
    ValidationCode.phoneInvalid:  (p) => '올바른 전화번호 형식이 아닙니다.',
    ValidationCode.biznoInvalid:  (p) => '올바른 사업자번호 형식이 아닙니다.',
    ValidationCode.stringMin:     (p) => '${p['name']}은(는) ${p['min']}자 이상이어야 합니다.',
    ValidationCode.emailInvalid:  (p) => '올바른 이메일 형식이 아닙니다.',
    ValidationCode.listMin:       (p) => '${p['name']}은(는) ${p['min']}개 이상 선택해야 합니다.',
  }),
);
```

### Full locale key mapping

**Shared (was `mixed:` in v1)**

| v1 string key | v2 `ValidationCode` |
|---|---|
| `'required'` | `required` |
| `'equal'` | `equal` |
| `'notEqual'` | `notEqual` |
| `'oneOf'` | `oneOf` |
| `'notOneOf'` | `notOneOf` |
| `'condition'` | `condition` |
| `'default'` | _(removed — built-in English defaults always present)_ |

**Number (was `number:` in v1)**

| v1 string key | v2 `ValidationCode` |
|---|---|
| `'min'` | `numberMin` |
| `'max'` | `numberMax` |
| `'moreThan'` | _(removed — see [Removed methods](#removed-methods))_ |
| `'lessThan'` | _(removed — see [Removed methods](#removed-methods))_ |
| `'integer'` | `integer` |
| `'phoneEmpty'` | `required` _(unified with the shared required code)_ |
| `'phoneInvalid'` | `phoneInvalid` |
| `'biznoEmpty'` | `required` |
| `'biznoInvalid'` | `biznoInvalid` |

**String (was `string:` in v1)**

| v1 string key | v2 `ValidationCode` |
|---|---|
| `'min'` | `stringMin` |
| `'max'` | `stringMax` |
| `'matches'` | `matches` |
| `'emailEmpty'` | `required` |
| `'emailInvalid'` | `emailInvalid` |
| `'passwordEmpty'` | `required` |
| `'passwordMin'` | `passwordMin` |
| `'passwordAscii'` | `matches` |
| `'emoji'` | `emoji` |
| `'mobileEmpty'` | `required` |
| `'mobileInvalid'` | `mobileInvalid` |
| `'url'` | `url` |

**Array/List (was `array:` in v1)**

| v1 string key | v2 `ValidationCode` |
|---|---|
| `'min'` | `listMin` |
| `'max'` | `listMax` |

---

## Removed methods

| v1 method | v2 replacement | Note |
|---|---|---|
| `ValidateNumber().moreThan(n)` | `ValidateNumber().min(n)` | `min` is `>=`, not `>` |
| `ValidateNumber().lessThan(n)` | `ValidateNumber().max(n)` | `max` is `<=`, not `<` |

If you need strict `>` or `<` semantics, use `satisfy()`:

```dart
ValidateNumber().satisfy((v) => v! > 0, message: '0 초과 값을 입력해주세요.');
```

---

## New in v2

### Cross-field validation

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

### `ValidateNumber.toValidator()` — string parsing

Parses strings like `"1,000"` and `"17세"` before validating.
Directly compatible with Flutter `TextFormField.validator`:

```dart
TextFormField(
  validator: ValidateNumber()
      .setLabel('나이')
      .min(14)
      .max(120)
      .isInteger()
      .toValidator(parseErrorMessage: '숫자를 입력해주세요.'),
)
```

### New validator types

- **`ValidateBool`** — `isTrue()`, `isFalse()`
- **`ValidateDateTime`** — `isBefore()`, `isAfter()`, `min()`, `max()`, `between()`, `isInFuture()`, `isInPast()`

### New `ValidationCode` values (read errors programmatically)

```dart
final result = ValidateString().email().validate(input);
if (result is ValidationFailure) {
  switch (result.code) {
    ValidationCode.required      => // ...
    ValidationCode.emailInvalid  => // ...
    _                            => // ...
  }
}
```

---

## Checklist

- [ ] Replace all `BaseValidatorSchema` → `DupSchema`
- [ ] Remove `useUiForm` imports; replace `useUiForm.validate()` → `schema.validate()`
- [ ] Remove `FormValidationException` try/catch; switch on `FormValidationResult`
- [ ] Update all `addValidator` callbacks to return `ValidationFailure?`
- [ ] Rewrite `ValidatorLocale.setLocale()` with `ValidationCode` enum keys
- [ ] Replace `moreThan()` / `lessThan()` with `min()` / `max()` or `satisfy()`
- [ ] Remove `'phoneEmpty'` / `'emailEmpty'` / `'biznoEmpty'` locale keys (now unified under `required`)
