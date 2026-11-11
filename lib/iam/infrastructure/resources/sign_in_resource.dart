/// Request body of `POST /authentication/sign-in/local`.
class SignInResource {
  const SignInResource({required this.username, required this.password, required this.channel});

  /// Username or the profile email (the backend accepts both).
  final String username;
  final String password;
  final String channel;

  Map<String, dynamic> toJson() => {'username': username, 'password': password, 'channel': channel};
}
