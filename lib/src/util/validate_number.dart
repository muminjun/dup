import 'package:dup/src/util/validate_locale.dart';
import 'package:dup/src/util/validator_base.dart';
import '../model/message_factory.dart';

class ValidateNumber extends BaseValidator<num, ValidateNumber> {
  ValidateNumber min(num min, {MessageFactory? messageFactory}) {
    return addPhaseValidator(2, (value) {
      if (value != null && value < min) {
        if (messageFactory != null) return messageFactory(label, {'min': min});
        final global = ValidatorLocale.current?.number['min']
            ?.call({'name': label, 'min': min});
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
        final global = ValidatorLocale.current?.number['max']
            ?.call({'name': label, 'max': max});
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
        final global = ValidatorLocale.current?.number['integer']
            ?.call({'name': label});
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
        final global = ValidatorLocale.current?.number['positive']
            ?.call({'name': label});
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
        final global = ValidatorLocale.current?.number['negative']
            ?.call({'name': label});
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
        final global = ValidatorLocale.current?.number['nonNegative']
            ?.call({'name': label});
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
        final global = ValidatorLocale.current?.number['nonPositive']
            ?.call({'name': label});
        if (global != null) return global;
        return '$label must be zero or negative.';
      }
      return null;
    });
  }
}
