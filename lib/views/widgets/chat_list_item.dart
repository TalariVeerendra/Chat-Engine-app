import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/controllers/home_controller.dart';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatListItem extends StatelessWidget {
  final ChatModel chat;
  final UserModel otherUser;
  final String lastMessageTime;
  final VoidCallback onTap;
  const ChatListItem({
    super.key,
    required this.chat,
    required this.otherUser,
    required this.lastMessageTime,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final HomeController homeController = Get.find<HomeController>();
    final currentUserId = authController.user?.uid ?? '';
    final unReadCount = chat.getUnreadCount(currentUserId);
    return Card(
      child: InkWell(
        onTap: onTap,
        onLongPress: () => _showChatOptions(context, homeController),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryColor,
                    child: otherUser.photoURL.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              otherUser.photoURL,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Text(
                                  otherUser.displayName.isNotEmpty
                                      ? otherUser.displayName[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                );
                              },
                            ),
                          )
                        : Text(
                            otherUser.displayName.isNotEmpty
                                ? otherUser.displayName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  if (otherUser.isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          border: BoxBorder.all(color: Colors.white, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            otherUser.displayName,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  fontWeight: unReadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (lastMessageTime.isNotEmpty)
                          Text(
                            lastMessageTime,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: unReadCount > 0
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondaryColor,

                                  fontWeight: unReadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              if (chat.lastMessageSenderId ==
                                  currentUserId) ...[
                                Icon(
                                  _getSeenStatusIcon(),
                                  size: 14,
                                  color: _getSeenStatusColor(),
                                ),
                                SizedBox(width: 4),
                              ],
                              Expanded(
                                child: Text(
                                  chat.lastMessage ?? 'No message Yet',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: unReadCount > 0
                                            ? AppTheme.primaryColor
                                            : AppTheme.textSecondaryColor,

                                        fontWeight: unReadCount > 0
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (unReadCount > 0) ...[
                          SizedBox(width: 8),
                          Container(
                            margin: EdgeInsets.only(left: 8),
                            padding: EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unReadCount > 99 ? '99+' : unReadCount.toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (chat.lastMessageSenderId == currentUserId) ...[
                      Text(
                        _getSeenStatusText(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getSeenStatusColor(),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSeenStatusIcon() {
    final AuthController authController = Get.find<AuthController>();
    final currentUserId = authController.user?.uid ?? '';
    final otherUserId = chat.getOtherParticipant(currentUserId);

    if (chat.isMessageSeen(currentUserId, otherUserId)) {
      return Icons.done_all;
    } else {
      return Icons.done;
    }
  }

  Color _getSeenStatusColor() {
    final AuthController authController = Get.find<AuthController>();
    final currentUserId = authController.user?.uid ?? '';
    final otherUserId = chat.getOtherParticipant(currentUserId);

    if (chat.isMessageSeen(currentUserId, otherUserId)) {
      return AppTheme.primaryColor;
    } else {
      return AppTheme.textSecondaryColor;
    }
  }

  String _getSeenStatusText() {
    final AuthController authController = Get.find<AuthController>();
    final currentUserId = authController.user?.uid ?? '';
    final otherUserId = chat.getOtherParticipant(currentUserId);

    if (chat.isMessageSeen(currentUserId, otherUserId)) {
      return 'Seen';
    } else {
      return 'Delivered';
    }
  }

  void _showChatOptions(BuildContext context, HomeController homeController) {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.delete_outline, color: AppTheme.errorColor),
              title: Text('Delete Chat'),
              subtitle: Text('this chat delete that chat for you only'),
              onTap: () {
                Get.back();
                homeController.deleteChat(chat);
              },
            ),
            ListTile(
              leading: Icon(Icons.person_outline, color: AppTheme.primaryColor),
              title: Text('View Profile'),
              onTap: () {
                Get.back();
                //Navigate to user Profile
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
