/// Exception thrown when form validation fails.
class FormValidationException implements Exception {
  final Map<String, String?> errors;
  final String fallbackMessage;

  FormValidationException(
    this.errors, {
    this.fallbackMessage = 'Invalid form.',
  });

  @override
  String toString() {
    return errors.values.firstWhere(
      (e) => e != null && e.isNotEmpty,
      orElse: () => fallbackMessage,
    )!;
  }
}
