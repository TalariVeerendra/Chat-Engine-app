import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/controllers/home_controller.dart';
import 'package:chat_app/controllers/main_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/views/widgets/chat_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeView extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, authController),
      body: Column(
        children: [
          _buildSearchBar(),
          Obx(
            () => controller.isSearching && controller.searchQuery.isNotEmpty
                ? _buildSearchResults()
                : _buildQuickFilters(),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refreshChats,
              color: AppTheme.primaryColor,
              child: Obx(() {
                if (controller.chats.isEmpty) {
                  if (controller.isSearching &&
                      controller.searchQuery.isNotEmpty) {
                    return _buildNoSearchResults();
                  } else if (controller.activeFilter != 'All') {
                    return _buildNoFilterResults();
                  } else {
                    return _buildEmptyState();
                  }
                }
                return _buildChatList();
              }),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthController authController,
  ) {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.textPrimaryColor,
      elevation: 0,
      title: Obx(
        () => Text(
          controller.isSearching ? 'search Results' : "Messages",
          // style: TextStyle(fontSize: 24,fontWeight: FontWeight.w700),
        ),
      ),
      automaticallyImplyLeading: false,
      actions: [
        Obx(
          () => controller.isSearching
              ? IconButton(
                  onPressed: controller.clearSearch,
                  icon: Icon(Icons.clear_rounded),
                )
              : _buildNotificationButton(),
        ),
        SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNotificationButton() {
    return Obx(() {
      final unreadNotifications = controller.getUnreadNotificationsCount();
      return Container(
        margin: EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                onPressed: controller.openNotifications,
                icon: Icon(Icons.notifications_outlined),
                iconSize: 22,
                splashRadius: 20,
              ),
            ),
            if (unreadNotifications > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: BoxConstraints(minHeight: 16, maxWidth: 16),
                  child: Text(
                    unreadNotifications > 99
                        ? '99+'
                        : unreadNotifications.toString(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 8, 15, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          onChanged: controller.onSearchChanged,
          decoration: InputDecoration(
            hintText: 'search conversations... ',
            hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: Colors.grey[500],
              size: 20,
            ),
            suffixIcon: Obx(
              () => controller.searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: controller.clearSearch,
                      icon: Icon(
                        Icons.clear_rounded,
                        color: Colors.grey[500],
                        size: 18,
                      ),
                    )
                  : SizedBox.shrink(),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Obx(
              () => _buildFilterChip(
                'All',
                () => controller.setFilter('All'),
                controller.activeFilter == 'All',
              ),
            ),
            SizedBox(width: 8),
            Obx(
              () => _buildFilterChip(
                'Unread (${controller.getUnreadCount()})',
                () => controller.setFilter('Unread'),
                controller.activeFilter == 'Unread',
              ),
            ),
            SizedBox(width: 8),
            Obx(
              () => _buildFilterChip(
                'Recent (${controller.getRecentCount()})',
                () => controller.setFilter('Recent'),
                controller.activeFilter == 'Recent',
              ),
            ),
            SizedBox(width: 8),
            Obx(
              () => _buildFilterChip(
                'Active (${controller.getActiveCount()})',
                () => controller.setFilter('Active'),
                controller.activeFilter == 'Active',
              ),
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onTap, bool isSelected) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 8, 18, 8),
      child: Row(
        children: [
          Obx(
            () => Text(
              'Found ${controller.filtredChats.length} results${controller.filtredChats.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
          ),
          Spacer(),
          TextButton(
            onPressed: controller.clearSearch,
            child: Text(
              'Clear',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResults() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
              SizedBox(height: 16),
              Text(
                "NO conversation Found",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 8),
              Obx(
                () => Text(
                  'No results for "${controller.searchQuery}"',
                  style: TextStyle(color: AppTheme.textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoFilterResults() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getFilterIcon(controller.activeFilter),
                size: 64,
                color: Colors.grey[400],
              ),
              SizedBox(height: 16),
              Text(
                'No ${controller.activeFilter.toLowerCase()} conversations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _getFilterEmptyMessage(controller.activeFilter),
                style: TextStyle(color: AppTheme.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => controller.setFilter('All'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text("Show All Conversations"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Unread':
        return Icons.mark_email_unread_outlined;
      case 'Recent':
        return Icons.schedule_outlined;
      case 'Active':
        return Icons.trending_up_outlined;

      default:
        return Icons.filter_list_outlined;
    }
  }

  String _getFilterEmptyMessage(String filter) {
    switch (filter) {
      case 'Unread':
        return 'All conversation up to date';
      case 'Recent':
        return 'No conversation from last 3 days';
      case 'Active':
        return 'No conversation from the last week';

      default:
        return 'No conversation found';
    }
  }

  Widget _buildChatList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          if (controller.isSearching || controller.searchQuery.isEmpty)
            _buildChatHeader(),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(
                vertical: controller.isSearching ? 16 : 8,
                horizontal: 16,
              ),
              itemCount: controller.chats.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey[200], indent: 72),
              itemBuilder: (context, index) {
                final chat = controller.chats[index];
                final otherUser = controller.getOtherUser(chat);

                if (otherUser == null) {
                  return SizedBox.shrink();
                }
                return AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  child: ChatListItem(
                    chat: chat,
                    otherUser: otherUser,
                    lastMessageTime: controller.formatLastMessageTime(
                      chat.lastMessageTime,
                    ),
                    onTap: () => controller.openChat(chat),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Obx(() {
            String title = ' recent Chats';
            switch (controller.activeFilter) {
              case "Unread":
                title = 'Unread  messages';

                break;
              case "Recent":
                title = 'Recent  messages';

                break;
              case "Active":
                title = 'Active  messages';

                break;
            }
            return Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            );
          }),
          Row(
            children: [
              if (controller.activeFilter != 'All')
                TextButton(
                  onPressed: controller.clearAllFilters,
                  child: Text(
                    'Clear Filter',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          final mainController = Get.find<MainController>();
          mainController.changeTabIndex(1);
        },
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: Icon(Icons.chat_outlined),
        label: Text(
          'New Chats',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(Get.context!).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildEmptyStateIcon(),
                SizedBox(height: 24),
                _buildEmptyStateText(),
                SizedBox(height: 24),
                _buildEmptyStateAction(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyStateIcon() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.primaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(70),
      ),
      child: Icon(
        Icons.chat_bubble_outline_rounded,
        size: 64,
        color: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildEmptyStateText() {
    return Column(
      children: [
        Text(
          'No conversation yet',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Connect with friends and start conversations',
          style: TextStyle(
            fontSize: 15,
            color: AppTheme.textPrimaryColor,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEmptyStateAction() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              final mainController = Get.find<MainController>();
              mainController.changeTabIndex(2);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.person_search_outlined),
            label: Text(
              'Find People',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              final mainController = Get.find<MainController>();
              mainController.changeTabIndex(1);
            },
            style: ElevatedButton.styleFrom(
              foregroundColor: AppTheme.primaryColor,
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(Icons.people_outline_rounded),
            label: Text(
              'View Friends',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
