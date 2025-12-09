import 'package:chat_app/controllers/friends_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/views/widgets/friend_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FriendsView extends GetView<FriendsController> {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Friends'),
        leading: SizedBox(),
        actions: [
          IconButton(
            onPressed: controller.openFriendRequests,
            icon: Icon(Icons.person_add_alt_1),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.borderColor.withOpacity(0.5),
                  width: 1,
                ),
              ),
            ),
            child: TextField(
              onChanged: controller.updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Search Friends',
                prefixIcon: Icon(Icons.search),
                suffixIcon: Obx(() {
                  return controller.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: controller.clearSearch,
                        )
                      : SizedBox.shrink();
                }),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: AppTheme.cardColor,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshFriends,
              child: Obx(() {
                if (controller.isLoading && controller.friends.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }
                if (controller.filteredFriends.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: EdgeInsets.all(16),

                  itemCount: controller.filteredFriends.length,
                  separatorBuilder: (context, index) {
                    return SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    final friend = controller.filteredFriends[index];
                    return FriendListItem(
                      friend: friend,
                      lastSeenText: controller.getLastSeenText(friend),
                      onTap: () => controller.startChat(friend),
                      onRemove: () => controller.removeFriend(friend),
                      onBlock: () => controller.blockFriend(friend),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
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
                Icons.people_outline,
                size: 50,
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(height: 24),
            Text(
              controller.searchQuery.isNotEmpty
                  ? 'No friends found'
                  : 'No friends yet',
              style: Theme.of(Get.context!).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              controller.searchQuery.isNotEmpty
                  ? 'Try a different search Name'
                  : 'Add Friends to Start Chating with them',
              style: Theme.of(Get.context!).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (controller.searchQuery.isEmpty) ...[
              SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: controller.openFriendRequests,
                icon: Icon(Icons.person_search),
                label: Text('View Friend Requests'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
