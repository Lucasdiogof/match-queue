import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';

extension EmailValidationErrorL10n on EmailValidationError {
  String message(AppLocalizations l10n) => switch (this) {
    EmailValidationError.empty => l10n.validationEmailRequired,
    EmailValidationError.invalid => l10n.validationEmailInvalid,
  };
}

extension PasswordValidationErrorL10n on PasswordValidationError {
  String message(AppLocalizations l10n) => switch (this) {
    PasswordValidationError.empty => l10n.validationPasswordRequired,
    PasswordValidationError.tooShort => l10n.validationPasswordTooShort(
      AppValidators.passwordMinLength,
    ),
  };
}

extension PasswordConfirmationErrorL10n on PasswordConfirmationError {
  String message(AppLocalizations l10n) => switch (this) {
    PasswordConfirmationError.empty =>
      l10n.validationPasswordConfirmationRequired,
    PasswordConfirmationError.mismatch =>
      l10n.validationPasswordConfirmationMismatch,
  };
}

extension DisplayNameValidationErrorL10n on DisplayNameValidationError {
  String message(AppLocalizations l10n) => switch (this) {
    DisplayNameValidationError.empty => l10n.validationDisplayNameRequired,
    DisplayNameValidationError.tooShort => l10n.validationDisplayNameTooShort(
      AppValidators.displayNameMinLength,
    ),
    DisplayNameValidationError.tooLong => l10n.validationDisplayNameTooLong(
      AppValidators.displayNameMaxLength,
    ),
  };
}
