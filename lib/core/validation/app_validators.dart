enum EmailValidationError { empty, invalid }

enum PasswordValidationError { empty, tooShort }

enum PasswordConfirmationError { empty, mismatch }

enum DisplayNameValidationError { empty, tooShort, tooLong }

enum TeamNameValidationError { empty, tooShort, tooLong }

enum TeamTagValidationError { tooShort, tooLong, invalidCharacters }

enum FcAccountNameValidationError { empty, tooShort, tooLong }

class AppValidators {
  const AppValidators._();

  static const int displayNameMinLength = 2;
  static const int displayNameMaxLength = 32;
  static const int passwordMinLength = 8;
  static const int teamNameMinLength = 2;
  static const int teamNameMaxLength = 40;
  static const int teamTagMinLength = 2;
  static const int teamTagMaxLength = 6;
  static const int fcAccountNameMinLength = 2;
  static const int fcAccountNameMaxLength = 40;

  static final RegExp _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');
  static final RegExp _whitespaceRun = RegExp(r'\s+');
  static final RegExp _teamTag = RegExp(r'^[A-Z0-9]+$');

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

  static String normalizeTeamName(String value) =>
      value.trim().replaceAll(_whitespaceRun, ' ');

  static String? normalizeTeamTag(String? value) {
    final normalized = (value ?? '').trim().toUpperCase().replaceAll(' ', '');
    return normalized.isEmpty ? null : normalized;
  }

  static TeamNameValidationError? teamName(String? value) {
    final normalized = normalizeTeamName(value ?? '');
    if (normalized.isEmpty) {
      return TeamNameValidationError.empty;
    }
    if (normalized.runes.length < teamNameMinLength) {
      return TeamNameValidationError.tooShort;
    }
    if (normalized.runes.length > teamNameMaxLength) {
      return TeamNameValidationError.tooLong;
    }
    return null;
  }

  static TeamTagValidationError? teamTag(String? value) {
    final normalized = normalizeTeamTag(value);
    if (normalized == null) {
      return null;
    }
    if (normalized.length < teamTagMinLength) {
      return TeamTagValidationError.tooShort;
    }
    if (normalized.length > teamTagMaxLength) {
      return TeamTagValidationError.tooLong;
    }
    if (!_teamTag.hasMatch(normalized)) {
      return TeamTagValidationError.invalidCharacters;
    }
    return null;
  }

  static String normalizeFcAccountName(String value) =>
      value.trim().replaceAll(_whitespaceRun, ' ');

  static FcAccountNameValidationError? fcAccountName(String? value) {
    final normalized = normalizeFcAccountName(value ?? '');
    if (normalized.isEmpty) {
      return FcAccountNameValidationError.empty;
    }
    if (normalized.runes.length < fcAccountNameMinLength) {
      return FcAccountNameValidationError.tooShort;
    }
    if (normalized.runes.length > fcAccountNameMaxLength) {
      return FcAccountNameValidationError.tooLong;
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
