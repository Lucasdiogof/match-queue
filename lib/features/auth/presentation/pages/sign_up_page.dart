import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/l10n/validation_l10n.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/core/validation/field_touch.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/auth/presentation/widgets/auth_form_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmationFocus = FocusNode();

  final FieldTouch _displayNameTouch = FieldTouch();
  final FieldTouch _emailTouch = FieldTouch();
  final FieldTouch _passwordTouch = FieldTouch();
  final FieldTouch _confirmationTouch = FieldTouch();
  bool _submitted = false;

  bool get _canSubmit =>
      AppValidators.displayName(_displayName.text) == null &&
      AppValidators.email(_email.text) == null &&
      AppValidators.password(_password.text) == null &&
      AppValidators.passwordConfirmation(_confirmation.text, _password.text) ==
          null;

  @override
  void dispose() {
    _displayName.dispose();
    _email.dispose();
    _password.dispose();
    _confirmation.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmationFocus.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    context.read<AuthCubit>().clearFailure();
    setState(() {});
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_canSubmit) {
      return;
    }
    FocusScope.of(context).unfocus();
    final succeeded = await context.read<AuthCubit>().signUp(
      email: _email.text,
      password: _password.text,
      displayName: _displayName.text,
    );
    if (succeeded && mounted) {
      TextInput.finishAutofillContext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final isSubmitting = state.isSubmitting;
        final failure = state.failure;

        return AuthFormScaffold(
          title: l10n.signUpTitle,
          subtitle: l10n.signUpSubtitle,
          onBack: () => context.go(AppRoutes.login.path),
          backTooltip: l10n.actionBack,
          children: <Widget>[
            if (failure != null) ...<Widget>[
              AppBanner(
                tone: AppBannerTone.danger,
                message: failure.localizedMessage(l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppTextField(
                    label: l10n.authDisplayName,
                    controller: _displayName,
                    enabled: !isSubmitting,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const <String>[AutofillHints.nickname],
                    prefixIcon: Icons.sports_esports_outlined,
                    maxLength: AppValidators.displayNameMaxLength,
                    errorText: _displayNameTouch.errorFor(
                      _displayName.text,
                      submitted: _submitted,
                      format: (value) =>
                          AppValidators.displayName(value)?.message(l10n),
                      requiredMessage: l10n.validationDisplayNameRequired,
                    ),
                    onChanged: (value) {
                      _displayNameTouch.touched = true;
                      _onChanged(value);
                    },
                    onSubmitted: (_) => _emailFocus.requestFocus(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppTextField(
                    label: l10n.authEmail,
                    hintText: l10n.authEmailHint,
                    controller: _email,
                    focusNode: _emailFocus,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.email],
                    prefixIcon: Icons.mail_outline_rounded,
                    errorText: _emailTouch.errorFor(
                      _email.text,
                      submitted: _submitted,
                      format: (value) =>
                          AppValidators.email(value)?.message(l10n),
                      requiredMessage: l10n.validationEmailRequired,
                    ),
                    onChanged: (value) {
                      _emailTouch.touched = true;
                      _onChanged(value);
                    },
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppPasswordField(
                    label: l10n.authPassword,
                    helperText: l10n.authPasswordHelper(
                      AppValidators.passwordMinLength,
                    ),
                    prefixIcon: Icons.lock_outline_rounded,
                    controller: _password,
                    focusNode: _passwordFocus,
                    enabled: !isSubmitting,
                    textInputAction: TextInputAction.next,
                    revealTooltip: l10n.authRevealPassword,
                    hideTooltip: l10n.authHidePassword,
                    autofillHints: const <String>[AutofillHints.newPassword],
                    errorText: _passwordTouch.errorFor(
                      _password.text,
                      submitted: _submitted,
                      format: (value) =>
                          AppValidators.password(value)?.message(l10n),
                      requiredMessage: l10n.validationPasswordRequired,
                    ),
                    onChanged: (value) {
                      _passwordTouch.touched = true;
                      _onChanged(value);
                    },
                    onSubmitted: (_) => _confirmationFocus.requestFocus(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppPasswordField(
                    label: l10n.authConfirmPassword,
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline_rounded,
                    controller: _confirmation,
                    focusNode: _confirmationFocus,
                    enabled: !isSubmitting,
                    textInputAction: TextInputAction.done,
                    revealTooltip: l10n.authRevealPassword,
                    hideTooltip: l10n.authHidePassword,
                    errorText: _confirmationTouch.errorFor(
                      _confirmation.text,
                      submitted: _submitted,
                      format: (value) => AppValidators.passwordConfirmation(
                        value,
                        _password.text,
                      )?.message(l10n),
                      requiredMessage:
                          l10n.validationPasswordConfirmationRequired,
                    ),
                    onChanged: (value) {
                      _confirmationTouch.touched = true;
                      _onChanged(value);
                    },
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: l10n.authSignUp,
                    isLoading: isSubmitting,
                    onPressed: _canSubmit && !isSubmitting ? _submit : null,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
