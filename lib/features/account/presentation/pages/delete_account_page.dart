import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fifa_queue/features/auth/presentation/cubit/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Fluxo de exclusão de conta -- irreversível de propósito, então exige que
/// a pessoa leia as consequências E digite a palavra de confirmação, em vez
/// de um único diálogo "tem certeza?". Nunca sai da tela sozinho em caso de
/// erro (ver item 15 da Etapa Fase A): só o sucesso muda o estado de auth.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key});

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  final TextEditingController _confirmController = TextEditingController();
  bool _matches = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _confirmController.removeListener(_onChanged);
    _confirmController.dispose();
    super.dispose();
  }

  void _onChanged() {
    final l10n = context.l10n;
    final matches =
        _confirmController.text.trim().toUpperCase() ==
        l10n.deleteAccountConfirmWord.toUpperCase();
    if (matches != _matches) {
      setState(() => _matches = matches);
    }
  }

  Future<void> _delete(BuildContext context) async {
    context.read<AuthCubit>().clearFailure();
    await context.read<AuthCubit>().deleteAccount();
    // Sucesso: AuthState vira unauthenticated e o redirect do GoRouter tira
    // a pessoa daqui sozinho, igual acontece no signOut. Falha: o estado
    // permanece autenticado e o BlocBuilder abaixo mostra o erro -- nunca
    // navegamos manualmente daqui.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.deleteAccountTitle),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: <Widget>[
            Icon(
              Icons.warning_amber_rounded,
              size: AppSizing.iconXl,
              color: colors.danger,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.deleteAccountWarningTitle,
              style: context.textStyles.titleLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.deleteAccountWarningMessage,
              style: context.textStyles.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ConsequenceRow(
                    text: l10n.deleteAccountConsequenceFcAccounts,
                  ),
                  _ConsequenceRow(text: l10n.deleteAccountConsequenceSquads),
                  _ConsequenceRow(text: l10n.deleteAccountConsequenceHistory),
                  _ConsequenceRow(text: l10n.deleteAccountConsequenceStats),
                  _ConsequenceRow(
                    text: l10n.deleteAccountConsequencePreferences,
                  ),
                  _ConsequenceRow(
                    text: l10n.deleteAccountConsequencePublicProfile,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (state.failure != null) ...<Widget>[
              AppBanner(
                tone: AppBannerTone.danger,
                message: state.failure!.localizedMessage(l10n),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Text(
              l10n.deleteAccountTypeToConfirm(l10n.deleteAccountConfirmWord),
              style: context.textStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppTextField(
              label: l10n.deleteAccountConfirmWord,
              controller: _confirmController,
              enabled: !state.isSubmitting,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              hintText: l10n.deleteAccountConfirmWord,
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton.danger(
              label: l10n.deleteAccountAction,
              icon: Icons.delete_forever_outlined,
              isLoading: state.isSubmitting,
              onPressed: (_matches && !state.isSubmitting)
                  ? () => _delete(context)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsequenceRow extends StatelessWidget {
  const _ConsequenceRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(
          Icons.remove_circle_outline,
          size: AppSizing.iconSm,
          color: context.colors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text, style: context.textStyles.bodyMedium)),
      ],
    ),
  );
}
