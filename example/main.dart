import 'package:dup/dup.dart';

void main() async {
  // 1. Define the validation schema
  final BaseValidatorSchema schema = BaseValidatorSchema({
    'email': ValidateString()
        .setLabel('Email')
        .required(messageFactory: (label, _) => 'Please enter your email.')
        .email(messageFactory: (label, _) => 'Invalid email format.'),
    'password': ValidateString()
        .setLabel('Password')
        .required(messageFactory: (label, _) => 'Please enter your password.')
        .password(
          messageFactory:
              (label, _) =>
                  'Password must be at least 4 characters and contain only ASCII letters, numbers, or symbols.',
        ),
    'age': ValidateNumber()
        .setLabel('Age')
        .required(messageFactory: (label, _) => 'Please enter your age.')
        .min(
          18,
          messageFactory:
              (label, args) => 'You must be at least 18 years old to sign up.',
        ),
    'phone': ValidateString()
        .setLabel('Phone Number')
        .required(
          messageFactory: (label, _) => 'Please enter your phone number.',
        )
        .mobile(messageFactory: (label, _) => 'Invalid phone number format.'),
  });

  // 2. Example user input
  final formData = {
    'email': 'test@example.com',
    'password': '1234',
    'age': 17, // Intentionally set to 17 to trigger an error
    'phone': '010-1234-5678',
  };

  // 3. Run validation
  try {
    await useUiForm.validate(schema, formData);
    print('Form validated successfully!');
  } on FormValidationException catch (e) {
    print('Form validation failed:');
    e.errors.forEach((field, error) {
      if (error != null) {
        print('- $field: $error');
      }
    });
  }
}
