import 'package:fifa_queue/core/config/app_config_scope.dart';
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
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final FocusNode _passwordFocus = FocusNode();

  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(_onInputChanged);
    _password.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _email
      ..removeListener(_onInputChanged)
      ..dispose();
    _password
      ..removeListener(_onInputChanged)
      ..dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _onInputChanged() {
    context.read<AuthCubit>().clearFailure();
    final hasInput = _email.text.isNotEmpty && _password.text.isNotEmpty;
    if (hasInput != _hasInput) {
      setState(() => _hasInput = hasInput);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
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
    final config = AppConfigScope.of(context);

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
            if (!config.hasSupabase) ...<Widget>[
              AppBanner(
                tone: AppBannerTone.warning,
                title: l10n.loginLocalModeBadge,
                message: l10n.loginLocalModeMessage,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
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
              child: AutofillGroup(
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
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                      validator: (value) =>
                          AppValidators.email(value)?.message(l10n),
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
                      onSubmitted: (_) => _submit(),
                      validator: (value) =>
                          AppValidators.password(value)?.message(l10n),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: AppButton.ghost(
                        label: l10n.authForgotPassword,
                        size: AppButtonSize.small,
                        onPressed: isSubmitting
                            ? null
                            : () => context.go(AppRoutes.forgotPassword.path),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppButton(
                      label: l10n.authSignIn,
                      isLoading: isSubmitting,
                      onPressed: _hasInput && !isSubmitting ? _submit : null,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
