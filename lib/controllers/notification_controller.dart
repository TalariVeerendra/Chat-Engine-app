import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/notification_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class NotificationController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;

  List<NotificationModel> get notifications => _notifications;
  Map<String, UserModel> get users => _users;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;

  @override
  void onInit() {
    super.onInit();
    _loadNotifications();
    _loadUsers();
  }

  void _loadNotifications() {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null) {
      _notifications.bindStream(
        _firestoreService.getNotificationsStream(currentUserId),
      );
    }
  }

  void _loadUsers() {
    _users.bindStream(
      _firestoreService.getAllUsersStream().map((userList) {
        Map<String, UserModel> userMap = {};
        for (var user in userList) {
          userMap[user.id] = user;
        }
        return userMap;
      }),
    );
  }

  UserModel? getUser(String userId) {
    return _users[userId];
  }

  Future<void> markAsRead(NotificationModel notification) async {
    try {
      if (notification.isRead) {
        await _firestoreService.markNotificationAsRead(notification.id);
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar("Error", 'Failed to read notification');
      print(e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        await _firestoreService.markAllNotificationsAsRead(currentUserId);
        Get.snackbar("Success", 'successfully Mark as All notification');
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar("Error", 'Failed to read notifications All');
      print(e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteNotification(NotificationModel notification) async {
    try {
      await _firestoreService.deleteNotification(notification.id);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar("Error", 'Failed to delete notifications');
      print(e.toString());
    }
  }

  void handleNotificationType(NotificationModel notification) {
    markAsRead(notification);

    switch (notification.type) {
      case NotificationType.friendRequest:
        Get.toNamed(AppRoutes.friendRequest);
        break;

      case NotificationType.friendRequestAccepted:
      case NotificationType.friendRequestDeclined:
        Get.toNamed(AppRoutes.friends);
        break;

      case NotificationType.newMessage:
        final userId = notification.data['userId'];
        if (userId != null) {
          final user = getUser(userId);
          if (user != null) {
            Get.toNamed(AppRoutes.chat, arguments: {'otherUser': user});
          }
        }
        break;
      case NotificationType.friendRemoved:
        break;
    }
  }

  String getNotificationTimeText(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return ' ${difference.inMinutes} m ago';
    } else if (difference.inDays < 1) {
      return ' ${difference.inHours} h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} d ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  IconData getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return Icons.person_add;
      case NotificationType.friendRequestAccepted:
        return Icons.check_circle;
      case NotificationType.friendRequestDeclined:
        return Icons.cancel;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.friendRemoved:
        return Icons.person_remove;
    }
  }

  Color getNotificationIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.friendRequest:
        return AppTheme.primaryColor;
      case NotificationType.friendRequestAccepted:
        return AppTheme.successColor;
      case NotificationType.friendRequestDeclined:
        return AppTheme.errorColor;
      case NotificationType.newMessage:
        return AppTheme.secondaryColor;
      case NotificationType.friendRemoved:
        return AppTheme.errorColor;
    }
  }

  int getUnreadCount() {
    return _notifications.where((notification) => !notification.isRead).length;
  }

  void clearError() {
    _error.value = '';
  }
}
