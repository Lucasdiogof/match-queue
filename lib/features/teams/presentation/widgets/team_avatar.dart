import 'package:fifa_queue/core/design_system/design_system.dart';
import 'package:fifa_queue/features/teams/domain/entities/team.dart';
import 'package:flutter/material.dart';

class TeamAvatar extends StatelessWidget {
  const TeamAvatar({
    required this.team,
    this.size = AppSizing.avatarLg,
    super.key,
  });

  final Team team;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final background = _parseColor(team.primaryColor) ?? colors.surfaceHighest;
    final hasCustomColor = _parseColor(team.primaryColor) != null;
    final foreground = hasCustomColor
        ? _readableForeground(background)
        : colors.textPrimary;
    final logoUrl = team.logoUrl;
    final radius = BorderRadius.circular(size * 0.28);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          border: Border.all(color: colors.borderSubtle),
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: logoUrl != null
              ? Image.network(
                  logoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _Initials(team: team, size: size, color: foreground),
                )
              : _Initials(team: team, size: size, color: foreground),
        ),
      ),
    );
  }

  static Color? _parseColor(String? hex) {
    if (hex == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(hex)) {
      return null;
    }
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }

  static Color _readableForeground(Color background) {
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF0A0A0A) : const Color(0xFFFFFFFF);
  }
}

class _Initials extends StatelessWidget {
  const _Initials({
    required this.team,
    required this.size,
    required this.color,
  });

  final Team team;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      team.initials,
      style: context.textStyles.titleMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: size * 0.34,
        height: 1,
      ),
    ),
  );
}
