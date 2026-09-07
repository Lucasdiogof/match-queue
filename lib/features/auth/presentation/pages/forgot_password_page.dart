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

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _email = TextEditingController();

  bool _hasInput = false;
  bool _requestSent = false;

  @override
  void initState() {
    super.initState();
    _email.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _email
      ..removeListener(_onInputChanged)
      ..dispose();
    super.dispose();
  }

  void _onInputChanged() {
    context.read<AuthCubit>().clearFailure();
    final hasInput = _email.text.isNotEmpty;
    if (hasInput != _hasInput || _requestSent) {
      setState(() {
        _hasInput = hasInput;
        _requestSent = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    FocusScope.of(context).unfocus();
    final succeeded = await context.read<AuthCubit>().sendPasswordReset(
      _email.text,
    );
    if (succeeded && mounted) {
      setState(() => _requestSent = true);
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
          title: l10n.forgotPasswordTitle,
          subtitle: l10n.forgotPasswordMessage,
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
            if (_requestSent) ...<Widget>[
              AppBanner(
                tone: AppBannerTone.success,
                title: l10n.forgotPasswordSentTitle,
                message: l10n.forgotPasswordSentMessage,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppTextField(
                    label: l10n.authEmail,
                    hintText: l10n.authEmailHint,
                    controller: _email,
                    enabled: !isSubmitting,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const <String>[AutofillHints.email],
                    prefixIcon: Icons.alternate_email,
                    onSubmitted: (_) => _submit(),
                    validator: (value) =>
                        AppValidators.email(value)?.message(l10n),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppButton(
                    label: l10n.forgotPasswordAction,
                    isLoading: isSubmitting,
                    onPressed: _hasInput && !isSubmitting ? _submit : null,
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
