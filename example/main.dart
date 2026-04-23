import 'package:dup/dup.dart';

void main() async {
  final schema = DupSchema({
    'email': ValidateString()
        .setLabel('Email')
        .required(messageFactory: (label, _) => 'Please enter your email.')
        .email(messageFactory: (label, _) => 'Invalid email format.'),
    'password': ValidateString()
        .setLabel('Password')
        .required(messageFactory: (label, _) => 'Please enter your password.')
        .password(
          messageFactory: (label, _) =>
              'Password must be at least 4 characters and contain only ASCII letters, numbers, or symbols.',
        ),
    'age': ValidateNumber()
        .setLabel('Age')
        .required(messageFactory: (label, _) => 'Please enter your age.')
        .min(
          18,
          messageFactory: (label, args) =>
              'You must be at least 18 years old to sign up.',
        ),
    'phone': ValidateString()
        .setLabel('Phone Number')
        .required(messageFactory: (label, _) => 'Please enter your phone number.')
        .mobile(messageFactory: (label, _) => 'Invalid phone number format.'),
  });

  final formData = {
    'email': 'test@example.com',
    'password': '1234',
    'age': 17,
    'phone': '010-1234-5678',
  };

  final result = await schema.validate(formData);

  switch (result) {
    case FormValidationSuccess():
      print('Form validated successfully!');
    case FormValidationFailure():
      print('Form validation failed:');
      for (final field in result.fields) {
        print('- $field: ${result(field)!.message}');
      }
  }
}
