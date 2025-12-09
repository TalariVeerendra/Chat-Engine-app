import 'package:chat_app/controllers/notification_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/views/widgets/notification_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NotificationView extends GetView<NotificationController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back),
        ),
        actions: [
          Obx(() {
            final unreadCount = controller.getUnreadCount();
            return unreadCount > 0
                ? TextButton(
                    onPressed: controller.markAllAsRead,
                    child: Text('Mark all read'),
                  )
                : SizedBox.shrink();
          }),
        ],
      ),
      body: Obx(() {
        if (controller.notifications.isEmpty) {
          return _buildEmptyState();
        }
        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemCount: controller.notifications.length,
          separatorBuilder: (context, index) => SizedBox(height: 8),
          itemBuilder: (context, index) {
            final notification = controller.notifications[index];
            final user = notification.data['senderId'] != null
                ? controller.getUser(notification.data['senderId'])
                : notification.data['userId'] != null
                ? controller.getUser(notification.data['userId'])
                : null;

            return NotificationItem(
              notification: notification,
              user: user,
              timeText: controller.getNotificationTimeText(
                notification.createdAt,
              ),
              icon: controller.getNotificationIcon(notification.type),
              iconColor: controller.getNotificationIconColor(notification.type),
              onTap: () => controller.handleNotificationType(notification),
              onDelete: () => controller.deleteNotification(notification),
            );
          },
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.notifications_outlined,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'No Notification',
              style: Theme.of(Get.context!).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'When you Recieve friend request,messages and Other Updates',
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
