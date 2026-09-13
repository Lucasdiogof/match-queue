import 'dart:async';

import 'package:fifa_queue/features/game/presentation/widgets/win_loss_counter.dart';
import 'package:flutter/material.dart';

/// Wrapper com estado local + debounce sobre [WinLossCounter].
///
/// Cada clique atualiza o numero na tela instantaneamente. Depois de 800 ms
/// sem clique, os deltas acumulados sao enviados de uma vez via [onFlush].
/// Se o usuario navegar pra fora antes do timer, o dispose faz fire-and-forget.
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

  /// Envia os deltas acumulados. Retorna `true` se o save funcionou.
  final Future<bool> Function(int winDelta, int lossDelta) onFlush;

  @override
  State<DebouncedWinLossCounter> createState() =>
      _DebouncedWinLossCounterState();
}

class _DebouncedWinLossCounterState extends State<DebouncedWinLossCounter> {
  late int _wins = widget.wins;
  late int _losses = widget.losses;
  int _unsavedWinDelta = 0;
  int _unsavedLossDelta = 0;
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
    final ok = await widget.onFlush(wd, ld);
    if (!mounted) return;
    if (!ok) {
      _unsavedWinDelta += wd;
      _unsavedLossDelta += ld;
      _timer?.cancel();
      _timer = Timer(const Duration(seconds: 2), _flush);
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
      widget.onFlush(_unsavedWinDelta, _unsavedLossDelta);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WinLossCounter(
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
  );
}
