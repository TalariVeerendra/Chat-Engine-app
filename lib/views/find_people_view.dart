import 'package:chat_app/controllers/users_list_controller.dart';
import 'package:chat_app/theme/app_theme.dart';
import 'package:chat_app/views/widgets/user_list_item.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FindPeopleView extends GetView<UsersListController> {
  const FindPeopleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Find People"), leading: SizedBox()),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: Obx(() {
              if (controller.filteredUsers.isEmpty) {
                return _buildEmptyState();
              }
              return ListView.separated(
                padding: EdgeInsets.all(16),
                separatorBuilder: (context, index) => SizedBox(height: 8),
                itemCount: controller.filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = controller.filteredUsers[index];
                  return UserListItem(
                    user: user,
                    onTap: () => controller.handleRelationshipAction(user),
                    controller: controller,
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(Get.context!).scaffoldBackgroundColor,
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
          hintText: 'Search People',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Obx(() {
            return controller.searchQuery.isNotEmpty
                ? IconButton(
                    onPressed: () {
                      controller.clearSearch();
                    },
                    icon: Icon(Icons.clear),
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
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: AppTheme.cardColor,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
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
                  ? 'No results found'
                  : 'No peolpe Found',
              style: Theme.of(Get.context!).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              controller.searchQuery.isNotEmpty
                  ? 'Try a different search Name'
                  : 'All user shown here',
              style: Theme.of(
                Get.context!,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.primaryColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
