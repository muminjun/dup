import 'package:dup/dup.dart';

void main() async {
  // DupSchema assigns each validator's label from the map key (or the
  // optional `labels` map). No need to call setLabel() on the validators.
  final schema = DupSchema(
    {
      'email': ValidateString()
          .required(messageFactory: (label, _) => 'Please enter your email.')
          .email(messageFactory: (label, _) => 'Invalid email format.'),
      'password': ValidateString()
          .required(messageFactory: (label, _) => 'Please enter your password.')
          .password(
            messageFactory: (label, _) =>
                'Password must be at least 4 characters and contain only ASCII letters, numbers, or symbols.',
          ),
      'age': ValidateNumber()
          .required(messageFactory: (label, _) => 'Please enter your age.')
          .min(
            18,
            messageFactory: (label, args) =>
                'You must be at least 18 years old to sign up.',
          ),
      'phone': ValidateString()
          .required(
            messageFactory: (label, _) => 'Please enter your phone number.',
          )
          .koMobile(
              messageFactory: (label, _) => 'Invalid phone number format.'),
    },
    labels: {
      'email': 'Email',
      'password': 'Password',
      'age': 'Age',
      'phone': 'Phone Number',
    },
  );

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
