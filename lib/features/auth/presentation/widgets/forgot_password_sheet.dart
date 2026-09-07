import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/core/l10n/validation_l10n.dart';
import 'package:fifa_queue/core/validation/app_validators.dart';
import 'package:fifa_queue/core/validation/field_touch.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showForgotPasswordSheet(BuildContext context) {
  final cubit = context.read<AuthCubit>();
  cubit.clearFailure();
  return showAppBottomSheet<void>(
    context: context,
    builder: (sheetContext) => BlocProvider<AuthCubit>.value(
      value: cubit,
      child: const _ForgotPasswordSheetBody(),
    ),
  );
}

class _ForgotPasswordSheetBody extends StatefulWidget {
  const _ForgotPasswordSheetBody();

  @override
  State<_ForgotPasswordSheetBody> createState() =>
      _ForgotPasswordSheetBodyState();
}

class _ForgotPasswordSheetBodyState extends State<_ForgotPasswordSheetBody> {
  final TextEditingController _email = TextEditingController();
  final FieldTouch _emailTouch = FieldTouch();

  bool _submitted = false;
  bool _sent = false;
  String _sentEmail = '';
  bool _resending = false;
  bool _resendDone = false;

  bool get _canSubmit => AppValidators.email(_email.text) == null;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _emailTouch.touched = true;
    context.read<AuthCubit>().clearFailure();
    setState(() {});
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (AppValidators.email(_email.text) != null) {
      return;
    }
    FocusScope.of(context).unfocus();
    final email = AppValidators.normalizeEmail(_email.text);
    final succeeded = await context.read<AuthCubit>().sendPasswordReset(
      email,
    );
    if (!mounted) {
      return;
    }
    if (succeeded) {
      setState(() {
        _sent = true;
        _sentEmail = email;
      });
    }
  }

  Future<void> _resend() async {
    if (_resending) {
      return;
    }
    setState(() {
      _resending = true;
      _resendDone = false;
    });
    final succeeded = await context.read<AuthCubit>().sendPasswordReset(
      _sentEmail,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _resending = false;
      _resendDone = succeeded;
    });
  }

  @override
  Widget build(BuildContext context) => AppBottomSheet(
    child: AnimatedSize(
      duration: AppDurations.fast,
      alignment: Alignment.topCenter,
      child: _sent ? _buildConfirmation(context) : _buildForm(context),
    ),
  );

  Widget _buildForm(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<AuthCubit, AuthState>(
      key: const ValueKey<String>('form'),
      builder: (context, state) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SheetHeader(
            icon: Icons.lock_reset,
            title: l10n.forgotPasswordTitle,
            description: l10n.forgotPasswordMessage,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (state.failure != null) ...<Widget>[
            AppBanner(
              tone: AppBannerTone.danger,
              message: state.failure!.localizedMessage(l10n),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AppTextField(
            label: l10n.authEmail,
            hintText: l10n.authEmailHint,
            controller: _email,
            enabled: !state.isSubmitting,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const <String>[AutofillHints.email],
            prefixIcon: Icons.alternate_email,
            errorText: _emailTouch.errorFor(
              _email.text,
              submitted: _submitted,
              format: (value) => AppValidators.email(value)?.message(l10n),
              requiredMessage: l10n.validationEmailRequired,
            ),
            onChanged: _onChanged,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: l10n.forgotPasswordAction,
            isLoading: state.isSubmitting,
            onPressed: _canSubmit && !state.isSubmitting ? _submit : null,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmation(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      key: const ValueKey<String>('confirmation'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _SheetHeader(
          icon: Icons.mark_email_read_outlined,
          title: l10n.forgotPasswordSentTitle,
          description: l10n.forgotPasswordSentMessage,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          _sentEmail,
          textAlign: TextAlign.center,
          style: context.textStyles.bodyLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: l10n.actionClose,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ResendAction(
          resending: _resending,
          done: _resendDone,
          onResend: _resend,
        ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      children: <Widget>[
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.surfaceHighest,
            shape: BoxShape.circle,
            border: Border.all(color: colors.borderSubtle),
          ),
          child: Icon(icon, size: AppSizing.iconLg, color: colors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(title, textAlign: TextAlign.center, style: context.textStyles.headlineSmall),
        const SizedBox(height: AppSpacing.sm),
        Text(
          description,
          textAlign: TextAlign.center,
          style: context.textStyles.bodyMedium?.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ResendAction extends StatelessWidget {
  const _ResendAction({
    required this.resending,
    required this.done,
    required this.onResend,
  });

  final bool resending;
  final bool done;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    if (done) {
      return Text(
        l10n.forgotPasswordResendSuccess,
        textAlign: TextAlign.center,
        style: context.textStyles.bodySmall?.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    if (resending) {
      return Text(
        l10n.forgotPasswordResending,
        textAlign: TextAlign.center,
        style: context.textStyles.bodySmall?.copyWith(
          color: colors.textSecondary,
        ),
      );
    }
    return Center(
      child: GestureDetector(
        onTap: onResend,
        behavior: HitTestBehavior.opaque,
        child: Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: '${l10n.forgotPasswordNotReceived} ',
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              TextSpan(
                text: l10n.forgotPasswordResend,
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
