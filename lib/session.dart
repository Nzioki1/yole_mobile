/// Minimal in-memory session guard. Replace with secure storage as needed.
class Session {
  Session._();
  static final Session instance = Session._();

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  void setLoggedIn(bool v) {
    _loggedIn = v;
  }
}
