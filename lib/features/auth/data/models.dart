class User {
  final String id;
  final String email;
  const User({required this.id, required this.email});
}

class AuthToken {
  final String value;
  const AuthToken(this.value);
}