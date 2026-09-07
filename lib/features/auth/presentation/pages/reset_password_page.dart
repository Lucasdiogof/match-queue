import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/l10n/validation_l10n.dart';
import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:fifa_queue/features/auth/presentation/widgets/auth_form_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();
  final FocusNode _confirmationFocus = FocusNode();

  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _password.addListener(_onInputChanged);
    _confirmation.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _password
      ..removeListener(_onInputChanged)
      ..dispose();
    _confirmation
      ..removeListener(_onInputChanged)
      ..dispose();
    _confirmationFocus.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    context.read<AuthCubit>().clearFailure();
    final hasInput = _password.text.isNotEmpty && _confirmation.text.isNotEmpty;
    if (hasInput != _hasInput) {
      setState(() => _hasInput = hasInput);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final messenger = ScaffoldMessenger.of(context);
    final successMessage = context.l10n.resetPasswordSuccess;
    final succeeded = await context.read<AuthCubit>().updatePassword(
      _password.text,
    );
    if (!succeeded || !mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    context.go(AppRoutes.home.path);
  }

  void _skip() {
    context.read<AuthCubit>().dismissPasswordRecovery();
    context.go(AppRoutes.home.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (!state.isAuthenticated) {
          return AuthFormScaffold(
            title: l10n.resetPasswordInvalidTitle,
            subtitle: l10n.resetPasswordInvalidMessage,
            children: <Widget>[
              AppButton(
                label: l10n.forgotPasswordAction,
                onPressed: () => context.go(AppRoutes.forgotPassword.path),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton.ghost(
                label: l10n.forgotPasswordBackToLogin,
                expanded: true,
                onPressed: () => context.go(AppRoutes.login.path),
              ),
            ],
          );
        }

        final isSubmitting = state.isSubmitting;
        final failure = state.failure;

        return AuthFormScaffold(
          title: l10n.resetPasswordTitle,
          subtitle: l10n.resetPasswordMessage,
          children: <Widget>[
            if (failure != null) ...<Widget>[
              AppBanner(
                tone: AppBannerTone.danger,
                message: failure.localizedMessage(l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppPasswordField(
                    label: l10n.resetPasswordNewPassword,
                    helperText: l10n.authPasswordHelper(
                      AppValidators.passwordMinLength,
                    ),
                    controller: _password,
                    enabled: !isSubmitting,
                    textInputAction: TextInputAction.next,
                    revealTooltip: l10n.authRevealPassword,
                    hideTooltip: l10n.authHidePassword,
                    autofillHints: const <String>[AutofillHints.newPassword],
                    onSubmitted: (_) => _confirmationFocus.requestFocus(),
                    validator: (value) =>
                        AppValidators.password(value)?.message(l10n),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppPasswordField(
                    label: l10n.authConfirmPassword,
                    controller: _confirmation,
                    focusNode: _confirmationFocus,
                    enabled: !isSubmitting,
                    textInputAction: TextInputAction.done,
                    revealTooltip: l10n.authRevealPassword,
                    hideTooltip: l10n.authHidePassword,
                    onSubmitted: (_) => _submit(),
                    validator: (value) => AppValidators.passwordConfirmation(
                      value,
                      _password.text,
                    )?.message(l10n),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: l10n.resetPasswordAction,
                    isLoading: isSubmitting,
                    onPressed: _hasInput && !isSubmitting ? _submit : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton.ghost(
                    label: l10n.actionNotNow,
                    expanded: true,
                    onPressed: isSubmitting ? null : _skip,
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
