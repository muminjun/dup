import '../util/validator_base.dart';

class BaseValidatorSchema {
  final Map<String, BaseValidator> schema;

  const BaseValidatorSchema(this.schema);
}
