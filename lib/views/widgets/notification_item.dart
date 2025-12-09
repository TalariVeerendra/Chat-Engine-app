import 'package:chat_app/models/notification_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';

class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final UserModel? user;
  final String timeText;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const NotificationItem({
    super.key,
    required this.notification,
    this.user,
    required this.timeText,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: notification.isRead
          ? null
          : AppTheme.primaryColor.withOpacity(0.5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                ),
                          ),
                        ),
                        if (notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      _getNotificationBody(),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      timeText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.close,
                  color: AppTheme.textSecondaryColor,
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getNotificationBody() {
    String body = notification.body;

    if (user != null) {
      switch (notification.type) {
        case NotificationType.friendRequest:
          body = '${user!.displayName} sent a friend Request to you';
          break;
        case NotificationType.friendRequestAccepted:
          body = '${user!.displayName} accepted your friend Request';
          break;
        case NotificationType.friendRequestDeclined:
          body = '${user!.displayName} Declined your friend Request';
          break;
        case NotificationType.newMessage:
          body = '${user!.displayName} sent a message to you';
          break;
        case NotificationType.friendRemoved:
          body = 'no longer friend with ${user!.displayName} ';
          break;
      }
    }
    return body;
  }
}
