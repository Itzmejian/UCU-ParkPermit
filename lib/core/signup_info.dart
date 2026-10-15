const String kRoleStudent = 'Student';
const String kRoleEmployee = 'Employee';

/// Details collected at registration and carried to the next screens.
class SignupInfo {
  const SignupInfo({required this.email, required this.role});

  final String email;
  final String role;
}