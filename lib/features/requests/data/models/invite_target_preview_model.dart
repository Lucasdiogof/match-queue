import 'package:fifa_queue/features/requests/domain/entities/invite_target_preview.dart';

class InviteTargetPreviewModel {
  const InviteTargetPreviewModel._();

  static InviteTargetPreview fromJson(Map<String, dynamic> json) {
    if (json['found'] != true) {
      return const InviteTargetPreview.notFound();
    }
    return InviteTargetPreview(
      found: true,
      userId: '${json['user_id']}',
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      fcAccountName: json['fc_account_name'] as String?,
    );
  }
}
