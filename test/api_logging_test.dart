import 'package:flutter_test/flutter_test.dart';
import 'package:stockalert/core/network/api_client.dart';

void main() {
  test('API log redaction removes credentials and health fields', () {
    expect(
      redactApiLogValue({
        'email': 'patient@example.com',
        'password': 'secret',
        'profile': {
          'knownAllergies': ['penicillin'],
          'accessToken': 'token',
        },
      }),
      {
        'email': 'patient@example.com',
        'password': '[REDACTED]',
        'profile': {
          'knownAllergies': '[REDACTED]',
          'accessToken': '[REDACTED]',
        },
      },
    );
  });
}
