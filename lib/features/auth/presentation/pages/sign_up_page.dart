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

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _displayName = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _confirmation = TextEditingController();
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();
  final FocusNode _confirmationFocus = FocusNode();

  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    for (final controller in _controllers) {
      controller.addListener(_onInputChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller
        ..removeListener(_onInputChanged)
        ..dispose();
    }
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmationFocus.dispose();
    super.dispose();
  }

  List<TextEditingController> get _controllers => <TextEditingController>[
    _displayName,
    _email,
    _password,
    _confirmation,
  ];

  void _onInputChanged() {
    context.read<AuthCubit>().clearFailure();
    final hasInput = _controllers.every(
      (controller) => controller.text.isNotEmpty,
    );
    if (hasInput != _hasInput) {
      setState(() => _hasInput = hasInput);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
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
          footer: AuthFooterPrompt(
            question: l10n.signUpHaveAccount,
            actionLabel: l10n.authSignIn,
            onAction: () => context.go(AppRoutes.login.path),
          ),
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
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AppTextField(
                      label: l10n.authDisplayName,
                      hintText: l10n.authDisplayNameHint,
                      controller: _displayName,
                      enabled: !isSubmitting,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const <String>[AutofillHints.nickname],
                      prefixIcon: Icons.sports_esports_outlined,
                      maxLength: AppValidators.displayNameMaxLength,
                      onSubmitted: (_) => _emailFocus.requestFocus(),
                      validator: (value) =>
                          AppValidators.displayName(value)?.message(l10n),
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
                      prefixIcon: Icons.alternate_email,
                      onSubmitted: (_) => _passwordFocus.requestFocus(),
                      validator: (value) =>
                          AppValidators.email(value)?.message(l10n),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    AppPasswordField(
                      label: l10n.authPassword,
                      helperText: l10n.authPasswordHelper(
                        AppValidators.passwordMinLength,
                      ),
                      controller: _password,
                      focusNode: _passwordFocus,
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
                      label: l10n.authSignUp,
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
