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
    test('max passes when within limit', () {
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
      expect(ValidateString().setLabel('PW').password(minLength: 8).validate('short12'), isNotNull);
      expect(ValidateString().setLabel('PW').password(minLength: 8).validate('longpass1'), isNull);
    });
    test('accepts non-ASCII characters', () {
      expect(ValidateString().setLabel('PW').password().validate('비밀번호!'), isNull);
    });
    test('skips on null', () {
      expect(ValidateString().setLabel('PW').password().validate(null), isNull);
    });
    test('skips on empty string', () {
      expect(ValidateString().setLabel('PW').password().validate(''), isNull);
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
    test('skips on empty string', () {
      expect(ValidateString().setLabel('X').emoji().validate(''), isNull);
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
      final v = ValidateString().setLabel('Phone').mobile(
        customRegex: RegExp(r'^\+1\d{10}$'),
      );
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
      final v = ValidateString().setLabel('BRN').bizno(
        customRegex: RegExp(r'^\d{2}-\d{7}$'),
      );
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
    test('fails for ftp (only http/https)', () {
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

  group('ValidateString — phase ordering', () {
    test('required fires before email regardless of chain order', () {
      final v = ValidateString().setLabel('Email').email().required();
      expect(v.validate(null), equals('Email is required.'));
    });

    test('email (phase 1) fires before min (phase 2)', () {
      final v = ValidateString().setLabel('Email').min(100).email();
      expect(v.validate('not-an-email'), contains('not a valid email'));
    });
  });
}
