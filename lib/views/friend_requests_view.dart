import 'package:chat_app/controllers/friend_requests_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/views/widgets/friend_request_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FriendRequestsView extends GetView<FriendRequestsController> {
  const FriendRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friend Request'),
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardColor),
            ),
            // Tab Selector
            child: Obx(
              () => Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.changeTab(0),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 10,
                          // horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: controller.selectedTabIndex == 0
                              ? AppTheme.primaryColor
                              : Colors.transparent,

                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox,
                              color: controller.selectedTabIndex == 0
                                  ? Colors.white
                                  : AppTheme.textSecondaryColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Recieved (${controller.recievedRequests.length})',
                              style: TextStyle(
                                color: controller.selectedTabIndex == 0
                                    ? Colors.white
                                    : AppTheme.textSecondaryColor,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 2),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => controller.changeTab(1),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          vertical: 12,
                          // horizontal: 20,
                        ),
                        decoration: BoxDecoration(
                          color: controller.selectedTabIndex == 1
                              ? AppTheme.primaryColor
                              : Colors.transparent,

                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.send,
                              color: controller.selectedTabIndex == 1
                                  ? Colors.white
                                  : AppTheme.textSecondaryColor,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Sent (${controller.sentRequests.length})',
                              style: TextStyle(
                                color: controller.selectedTabIndex == 1
                                    ? Colors.white
                                    : AppTheme.textSecondaryColor,

                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: Obx(() {
              return IndexedStack(
                index: controller.selectedTabIndex,
                children: [
                  _buildRecievedRequestsTab(),
                  _buildSendRequestsTab(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildRecievedRequestsTab() {
    return Obx(() {
      if (controller.recievedRequests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.inbox_outlined,
          title: 'No Friend Request',
          message: 'when someone sends you friend request , It will appear',
        );
      }
      return ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: controller.recievedRequests.length,
        separatorBuilder: (context, index) => SizedBox(height: 8),

        itemBuilder: (context, index) {
          final request = controller.recievedRequests[index];
          final sender = controller.getUser(request.senderId);
          if (sender == null) {
            return SizedBox.shrink();
          }
          return FriendRequestItem(
            request: request,
            user: sender,
            timeText: controller.getRequestTimeText(request.createdAt),
            isReceived: true,
            onAccept: () => controller.acceptRequest(request),
            onDecline: () => controller.declineFriendRequest(request),
          );
        },
      );
    });
  }

  Widget _buildSendRequestsTab() {
    return Obx(() {
      if (controller.sentRequests.isEmpty) {
        return _buildEmptyState(
          icon: Icons.send_outlined,
          title: 'No send Request',
          message: 'Friend Request You send Appear here',
        );
      }
      return ListView.separated(
        padding: EdgeInsets.all(16),
        itemCount: controller.sentRequests.length,
        separatorBuilder: (context, index) => SizedBox(height: 8),

        itemBuilder: (context, index) {
          final request = controller.sentRequests[index];
          final receiver = controller.getUser(request.receiverId);
          if (receiver == null) {
            return SizedBox.shrink();
          }
          return FriendRequestItem(
            request: request,
            user: receiver,
            timeText: controller.getRequestTimeText(request.createdAt),
            isReceived: false,
            statusText: controller.getStatusText(request.status),
            statusColor: controller.getStatusColor(request.status),
          );
        },
      );
    });
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(icon, size: 40, color: AppTheme.primaryColor),
            ),
            SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(
                Get.context!,
              ).textTheme.headlineSmall?.copyWith(color: AppTheme.primaryColor),
            ),
            SizedBox(height: 8),
            Text(
              message,
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
