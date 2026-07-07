class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email tidak boleh kosong';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Email tidak valid';
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password tidak boleh kosong';
    if (value.length < 6) return 'Password minimal 6 karakter';
    return null;
  }

  static String? validateRequired(String? value, String field) {
    if (value == null || value.isEmpty) return '$field tidak boleh kosong';
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Username tidak boleh kosong';
    if (value.length < 3) return 'Username minimal 3 karakter';
    return null;
  }
}