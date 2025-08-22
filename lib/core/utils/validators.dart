class Validators {
  static String? required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  static String? email(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final r = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return r.hasMatch(v) ? null : 'Invalid email';
  }
}