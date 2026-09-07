enum EmailValidationError { empty, invalid }

enum PasswordValidationError { empty, tooShort }

enum PasswordConfirmationError { empty, mismatch }

enum DisplayNameValidationError { empty, tooShort, tooLong }

class AppValidators {
  const AppValidators._();

  static const int displayNameMinLength = 2;
  static const int displayNameMaxLength = 32;
  static const int passwordMinLength = 8;

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
  static final RegExp _whitespaceRun = RegExp(r'\s+');

  static String normalizeEmail(String value) => value.trim().toLowerCase();

  static String normalizeDisplayName(String value) =>
      value.trim().replaceAll(_whitespaceRun, ' ');

  static EmailValidationError? email(String? value) {
    final normalized = normalizeEmail(value ?? '');
    if (normalized.isEmpty) {
      return EmailValidationError.empty;
    }
    if (!_email.hasMatch(normalized)) {
      return EmailValidationError.invalid;
    }
    return null;
  }

  static PasswordValidationError? password(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return PasswordValidationError.empty;
    }
    if (password.length < passwordMinLength) {
      return PasswordValidationError.tooShort;
    }
    return null;
  }

  static PasswordConfirmationError? passwordConfirmation(
    String? value,
    String password,
  ) {
    final confirmation = value ?? '';
    if (confirmation.isEmpty) {
      return PasswordConfirmationError.empty;
    }
    if (confirmation != password) {
      return PasswordConfirmationError.mismatch;
    }
    return null;
  }

  static DisplayNameValidationError? displayName(String? value) {
    final normalized = normalizeDisplayName(value ?? '');
    if (normalized.isEmpty) {
      return DisplayNameValidationError.empty;
    }
    if (normalized.runes.length < displayNameMinLength) {
      return DisplayNameValidationError.tooShort;
    }
    if (normalized.runes.length > displayNameMaxLength) {
      return DisplayNameValidationError.tooLong;
    }
    return null;
  }
}
