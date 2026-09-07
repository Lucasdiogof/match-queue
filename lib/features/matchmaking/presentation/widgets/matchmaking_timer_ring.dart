import 'dart:async';
import 'dart:math' as math;

import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Redesenha a cada segundo so pra atualizar o texto/anel na tela -- quem
/// decide quando o tempo realmente acabou e sempre o servidor (lazy
/// expiration + cron), nunca este widget. O restante e calculado a cada
/// tick contra estimatedServerNow(), que ja embute a correcao de clock
/// drift calculada pelo MatchmakingCubit a cada snapshot novo.
class MatchmakingTimerRing extends StatefulWidget {
  const MatchmakingTimerRing({
    required this.startedAt,
    required this.expiresAt,
    required this.estimatedServerNow,
    this.size = 168,
    super.key,
  });

  final DateTime startedAt;
  final DateTime expiresAt;
  final DateTime Function() estimatedServerNow;
  final double size;

  @override
  State<MatchmakingTimerRing> createState() => _MatchmakingTimerRingState();
}

class _MatchmakingTimerRingState extends State<MatchmakingTimerRing> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = widget.expiresAt.difference(widget.startedAt);
    final rawRemaining = widget.expiresAt.difference(
      widget.estimatedServerNow(),
    );
    final remaining = rawRemaining.isNegative ? Duration.zero : rawRemaining;
    final fraction = total.inMilliseconds <= 0
        ? 0.0
        : (remaining.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
    final seconds = remaining.inSeconds;
    final ringColor = seconds <= 10
        ? colors.danger
        : seconds <= 30
        ? colors.warning
        : colors.textPrimary;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RingPainter(
              fraction: fraction,
              color: ringColor,
              trackColor: colors.borderSubtle,
            ),
          ),
          Text(_format(seconds), style: AppTypography.timerDisplay(ringColor)),
        ],
      ),
    );
  }

  String _format(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
  });

  final double fraction;
  final Color color;
  final Color trackColor;

  static const double _strokeWidth = 8;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - _strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (fraction <= 0) {
      return;
    }
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * fraction,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}
