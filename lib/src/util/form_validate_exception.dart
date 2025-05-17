/// Exception thrown when form validation fails.
class FormValidationException implements Exception {
  final Map<String, String?> errors;

  FormValidationException(this.errors);

  @override
  String toString() {
    return errors.values.firstWhere(
          (e) => e != null,
      orElse: () => 'A validation error has occurred.',
    )!;
  }
}
