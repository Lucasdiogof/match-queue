import 'package:fifa_queue/core/navigation/app_routes.dart';
import 'package:fifa_queue/features/notifications/presentation/cubit/notification_unread_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Item 39/40: acesso a Central via icone no topo, sem sexta aba na
/// navegacao inferior. O badge so mostra numero -- sem app icon badge nativo
/// (item 76, fora de escopo desta etapa).
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<NotificationUnreadCubit, int>(
        builder: (context, unreadCount) => IconButton(
          onPressed: () => context.push(AppRoutes.notifications.path),
          icon: Badge(
            isLabelVisible: unreadCount > 0,
            label: Text(unreadCount > 99 ? '99+' : '$unreadCount'),
            child: const Icon(Icons.notifications_outlined),
          ),
        ),
      );
}
