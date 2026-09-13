import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/core/di/injector.dart';
import 'package:fifa_queue/core/errors/app_failure.dart';
import 'package:fifa_queue/core/l10n/app_failure_l10n.dart';
import 'package:fifa_queue/core/l10n/l10n_extensions.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account.dart';
import 'package:fifa_queue/features/fc_accounts/domain/entities/fc_account_stats.dart';
import 'package:fifa_queue/features/fc_accounts/domain/repositories/fc_account_repository.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_cubit.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/cubit/fc_accounts_state.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_l10n.dart';
import 'package:fifa_queue/features/fc_accounts/presentation/widgets/rivals_division_picker_sheet.dart';
import 'package:fifa_queue/features/game/presentation/widgets/debounced_win_loss_counter.dart';
import 'package:fifa_queue/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Detalhe de Division Rivals de uma conta -- all-time nesta etapa (sem
/// season/semana modelada ainda, simplificacao consciente). Artilharia/
/// assistencia saiu -- o produto nao rastreia mais gol/assistencia por
/// partida, so o placar que o usuario preenche.
class RivalsDetailPage extends StatefulWidget {
  const RivalsDetailPage({required this.account, super.key});

  final FcAccount account;

  @override
  State<RivalsDetailPage> createState() => _RivalsDetailPageState();
}

class _RivalsDetailPageState extends State<RivalsDetailPage> {
  late Future<RivalsAccountStats> _future;

  /// Capturados uma vez, nunca via `context.read`/`context.l10n` dentro do
  /// closure de onFlush -- ele pode ser chamado pelo dispose() do contador
  /// debounced, quando o context deste State pode ja estar desativado (ver
  /// doc de DebouncedWinLossCounter).
  late final FcAccountsCubit _cubit;
  late final AppLocalizations _l10n;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<FcAccountsCubit>();
    _l10n = context.l10n;
    _load();
  }

  void _load() {
    _future = getIt<FcAccountRepository>().fetchRivalsAccountStats(
      widget.account.id,
    );
  }

  Future<String?> _flushIncrement(int winDelta, int lossDelta) async {
    final ok = await _cubit.incrementRivalsRecord(
      accountId: widget.account.id,
      winDelta: winDelta,
      lossDelta: lossDelta,
    );
    if (ok) return null;
    final failure = _cubit.state.actionFailure;
    _cubit.clearActionFailure();
    return failure?.localizedMessage(_l10n) ?? _l10n.errorUnexpected;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      appBar: AppAppBar(title: l10n.rivalsDetailTitle),
      body: FutureBuilder<RivalsAccountStats>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const AppLoading();
          }
          final error = snapshot.error;
          if (error != null) {
            return AppErrorState(
              title: l10n.errorUnexpected,
              message: error is AppFailure
                  ? error.localizedMessage(l10n)
                  : l10n.errorUnexpected,
              retryLabel: l10n.actionRetry,
              onRetry: () => setState(_load),
            );
          }
          final stats = snapshot.data;
          if (stats == null) {
            return const SizedBox.shrink();
          }
          return _Body(
            accountId: widget.account.id,
            stats: stats,
            onFlush: _flushIncrement,
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.accountId,
    required this.stats,
    required this.onFlush,
  });

  final String accountId;
  final RivalsAccountStats stats;
  final Future<String?> Function(int winDelta, int lossDelta) onFlush;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      children: <Widget>[
        _DivisionSection(accountId: accountId),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          variant: AppCardVariant.elevated,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              DebouncedWinLossCounter(
                wins: stats.manual.wins,
                losses: stats.manual.losses,
                winsLabel: l10n.statsWinsLabel,
                lossesLabel: l10n.statsLossesLabel,
                addWinTooltip: l10n.recordAddWinTooltip,
                addLossTooltip: l10n.recordAddLossTooltip,
                removeWinTooltip: l10n.recordRemoveWinTooltip,
                removeLossTooltip: l10n.recordRemoveLossTooltip,
                onFlush: onFlush,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.rivalsAllTimeNote,
                style: context.textStyles.bodySmall?.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A divisao e o dado principal de Rivals, entao vive aqui e nao so na tela
/// da Conta: o card da Home diz "divisao nao informada" e traz o usuario pra
/// ca -- chegar sem poder informar era um beco sem saida. Reusa o mesmo
/// picker da Conta FC, nunca uma segunda forma de escrever o campo.
class _DivisionSection extends StatelessWidget {
  const _DivisionSection({required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<FcAccountsCubit, FcAccountsState>(
        builder: (context, state) {
          final l10n = context.l10n;
          FcAccount? account;
          for (final candidate in state.accounts) {
            if (candidate.id == accountId) {
              account = candidate;
            }
          }
          final division = account?.rivalsDivision;

          return AppCard(
            variant: AppCardVariant.elevated,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l10n.fcAccountDivisionTitle.toUpperCase(),
                  style: context.textStyles.labelSmall,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        division?.label(l10n) ?? l10n.fcAccountDivisionNone,
                        style: context.textStyles.titleMedium?.copyWith(
                          color: division == null
                              ? context.colors.textSecondary
                              : context.colors.textPrimary,
                        ),
                      ),
                    ),
                    if (account != null)
                      AppButton.ghost(
                        label: division == null
                            ? l10n.rivalsSetDivisionAction
                            : l10n.actionEdit,
                        onPressed: () => showRivalsDivisionPickerSheet(
                          context: context,
                          accountId: accountId,
                          selected: division,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      );
}
