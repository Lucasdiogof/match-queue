import 'dart:async';

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/game/presentation/widgets/win_loss_counter.dart';
import 'package:flutter/material.dart';

/// Wrapper com estado local + debounce sobre [WinLossCounter].
///
/// Cada clique atualiza o numero na tela instantaneamente. Depois de 800 ms
/// sem clique, os deltas acumulados sao enviados de uma vez via [onFlush]. Se
/// o usuario navegar pra fora antes do timer, o dispose faz fire-and-forget.
///
/// [onFlush] retorna `null` no sucesso, ou a mensagem de erro ja traduzida
/// (nunca um [Object]/[AppFailure] cru) quando falhar -- ela e exibida aqui
/// mesmo, embaixo do contador, e NUNCA no cubit compartilhado
/// (`FcAccountsCubit.actionFailure`). Antes disso, uma falha de incremento
/// (ex.: limite de 15 partidas do Champions) ficava no estado compartilhado
/// tempo suficiente para vazar pra outro bottomsheet aberto logo em seguida
/// (ex.: Renomear conta), que tambem observa esse mesmo campo. Por isso quem
/// chama [onFlush] deve ler a falha e limpar o cubit ANTES de retornar --
/// nunca depois.
///
/// A mensagem tambem precisa ser resolvida sem `BuildContext` (nada de
/// `context.l10n`/`context.read` dentro do closure): o `dispose()` chama
/// [onFlush] fora de qualquer build, quando o contexto do chamador pode ja
/// estar sendo desativado. Quem constroi o closure deve capturar `l10n` e o
/// cubit como valores simples ANTES, nunca reler `context` dentro dele.
class DebouncedWinLossCounter extends StatefulWidget {
  const DebouncedWinLossCounter({
    required this.wins,
    required this.losses,
    required this.winsLabel,
    required this.lossesLabel,
    required this.addWinTooltip,
    required this.addLossTooltip,
    required this.removeWinTooltip,
    required this.removeLossTooltip,
    required this.onFlush,
    super.key,
  });

  final int wins;
  final int losses;
  final String winsLabel;
  final String lossesLabel;
  final String addWinTooltip;
  final String addLossTooltip;
  final String removeWinTooltip;
  final String removeLossTooltip;

  /// Envia os deltas acumulados. `null` = sucesso; string = mensagem de erro
  /// ja traduzida, exibida abaixo do contador.
  final Future<String?> Function(int winDelta, int lossDelta) onFlush;

  @override
  State<DebouncedWinLossCounter> createState() =>
      _DebouncedWinLossCounterState();
}

class _DebouncedWinLossCounterState extends State<DebouncedWinLossCounter> {
  late int _wins = widget.wins;
  late int _losses = widget.losses;
  int _unsavedWinDelta = 0;
  int _unsavedLossDelta = 0;
  String? _errorMessage;
  Timer? _timer;

  @override
  void didUpdateWidget(DebouncedWinLossCounter old) {
    super.didUpdateWidget(old);
    if (old.wins != widget.wins || old.losses != widget.losses) {
      setState(() {
        _wins = widget.wins + _unsavedWinDelta;
        _losses = widget.losses + _unsavedLossDelta;
      });
    }
  }

  void _increment({int winDelta = 0, int lossDelta = 0}) {
    final newWins = _wins + winDelta;
    final newLosses = _losses + lossDelta;
    if (newWins < 0 || newLosses < 0) return;
    setState(() {
      _wins = newWins;
      _losses = newLosses;
      _unsavedWinDelta += winDelta;
      _unsavedLossDelta += lossDelta;
      _errorMessage = null;
    });
    _timer?.cancel();
    _timer = Timer(const Duration(milliseconds: 800), _flush);
  }

  Future<void> _flush() async {
    final wd = _unsavedWinDelta;
    final ld = _unsavedLossDelta;
    if (wd == 0 && ld == 0) return;
    _unsavedWinDelta = 0;
    _unsavedLossDelta = 0;
    final error = await widget.onFlush(wd, ld);
    if (!mounted) return;
    if (error != null) {
      // Delta revertido: o servidor recusou, entao o numero otimista na tela
      // volta ao que era antes deste incremento -- nunca fica um valor que o
      // backend nunca aceitou.
      setState(() {
        _wins -= wd;
        _losses -= ld;
        _errorMessage = error;
      });
      return;
    }
    if (_unsavedWinDelta != 0 || _unsavedLossDelta != 0) {
      _timer?.cancel();
      _timer = Timer(const Duration(milliseconds: 300), _flush);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (_unsavedWinDelta != 0 || _unsavedLossDelta != 0) {
      // Fire-and-forget de proposito: o widget ja era, nao ha onde mostrar
      // um erro. onFlush nunca toca BuildContext, entao chamar daqui e
      // seguro mesmo com a arvore em desativacao.
      unawaited(widget.onFlush(_unsavedWinDelta, _unsavedLossDelta));
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      WinLossCounter(
        wins: _wins,
        losses: _losses,
        winsLabel: widget.winsLabel,
        lossesLabel: widget.lossesLabel,
        addWinTooltip: widget.addWinTooltip,
        addLossTooltip: widget.addLossTooltip,
        removeWinTooltip: widget.removeWinTooltip,
        removeLossTooltip: widget.removeLossTooltip,
        onAddWin: () => _increment(winDelta: 1),
        onAddLoss: () => _increment(lossDelta: 1),
        onRemoveWin: () => _increment(winDelta: -1),
        onRemoveLoss: () => _increment(lossDelta: -1),
      ),
      if (_errorMessage != null) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        AppBanner(tone: AppBannerTone.danger, message: _errorMessage!),
      ],
    ],
  );
}
