import 'package:fifa_queue/core/design_system/theme/theme_context_extensions.dart';
import 'package:fifa_queue/core/design_system/tokens/app_radii.dart';
import 'package:fifa_queue/core/design_system/tokens/app_sizing.dart';
import 'package:flutter/material.dart';

enum AppAvatarShape { circle, rounded }

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    required this.label,
    this.imageUrl,
    this.size = AppSizing.avatarMd,
    this.shape = AppAvatarShape.circle,
    this.borderColor,
    super.key,
  });

  final String label;
  final String? imageUrl;
  final double size;
  final AppAvatarShape shape;
  final Color? borderColor;

  String get _initials {
    final parts = label.trim().split(RegExp(r'\s+'))
      ..removeWhere((part) => part.isEmpty);
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return '${parts.first.characters.first}${parts.last.characters.first}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = shape == AppAvatarShape.circle
        ? BorderRadius.circular(size)
        : AppRadii.borderMd;

    final url = imageUrl;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceHighest,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? colors.borderSubtle),
      ),
      child: url == null || url.isEmpty
          ? Text(
              _initials,
              style: context.textStyles.labelMedium?.copyWith(
                color: colors.textSecondary,
                fontSize: size * 0.36,
              ),
            )
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Text(
                _initials,
                style: context.textStyles.labelMedium?.copyWith(
                  color: colors.textSecondary,
                  fontSize: size * 0.36,
                ),
              ),
            ),
    );
  }
}
