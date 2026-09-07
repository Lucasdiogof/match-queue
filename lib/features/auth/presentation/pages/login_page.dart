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
import 'package:fifa_queue/features/auth/presentation/widgets/forgot_password_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  final FieldTouch _emailTouch = FieldTouch();
  final FieldTouch _passwordTouch = FieldTouch();
  bool _submitted = false;

  bool get _canSubmit =>
      AppValidators.email(_email.text) == null &&
      AppValidators.password(_password.text) == null;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _passwordFocus.dispose();
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
    final succeeded = await context.read<AuthCubit>().signIn(
      email: _email.text,
      password: _password.text,
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
          title: l10n.loginTitle,
          subtitle: l10n.appTagline,
          footer: AuthFooterPrompt(
            question: l10n.loginNoAccount,
            actionLabel: l10n.authSignUp,
            onAction: () => context.go(AppRoutes.signUp.path),
          ),
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
                    label: l10n.authEmail,
                    hintText: l10n.authEmailHint,
                    controller: _email,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const <String>[AutofillHints.email],
                    prefixIcon: Icons.alternate_email,
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
                    controller: _password,
                    focusNode: _passwordFocus,
                    enabled: !isSubmitting,
                    textInputAction: TextInputAction.done,
                    revealTooltip: l10n.authRevealPassword,
                    hideTooltip: l10n.authHidePassword,
                    autofillHints: const <String>[AutofillHints.password],
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
                    onSubmitted: (_) => _submit(),
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: AppButton.ghost(
                      label: l10n.authForgotPassword,
                      size: AppButtonSize.small,
                      onPressed: isSubmitting
                          ? null
                          : () => showForgotPasswordSheet(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n.authSignIn,
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
