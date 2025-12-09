import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/notification_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  final RxList<ChatModel> _allChats = <ChatModel>[].obs;
  final RxList<ChatModel> _filteredChats = <ChatModel>[].obs;
  final RxList<NotificationModel> _notifications = <NotificationModel>[].obs;

  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxMap<String, UserModel> _users = <String, UserModel>{}.obs;
  final RxString _searchQuery = ''.obs;
  final RxBool _isSearching = false.obs;
  final RxString _activeFilter = 'All'.obs;

  List<ChatModel> get chats => _getFilteredChats();
  List<ChatModel> get allChats => _allChats;
  List<ChatModel> get filtredChats => _filteredChats;
  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  String get searchQuery => _searchQuery.value;
  bool get isSearching => _isSearching.value;
  String get activeFilter => _activeFilter.value;
  Map<String, UserModel> get users => _users;

  @override
  void onInit() {
    super.onInit();
    _loadChats();
    _loadUsers();
    _loadNotifications();
  }

  void _loadChats() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      _allChats.bindStream(_firestoreService.getUserChatsStream(currentUserId));

      ever(_allChats, (_) {
        if (_isSearching.value && _searchQuery.value.isNotEmpty) {
          _performSearch(_searchQuery.value);
        }
      });
      ever(_activeFilter, (_) {
        if (_searchQuery.value.isEmpty) {
          _performSearch(_searchQuery.value);
        }
      });
    }
  }

  void _loadUsers() {
    _users.bindStream(
      _firestoreService.getAllUsersStream().map((userList) {
        Map<String, UserModel> usersMap = {};

        for (var user in userList) {
          usersMap[user.id] = user;
        }
        return usersMap;
      }),
    );
  }

  void _loadNotifications() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      _notifications.bindStream(
        _firestoreService.getNotificationsStream(currentUserId),
      );
    }
  }

  UserModel? getOtherUser(ChatModel chat) {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      final otherUserId = chat.getOtherParticipant(currentUserId);

      return _users[otherUserId];
    }
    return null;
  }

  String formatLastMessageTime(DateTime? time) {
    if (time == null) return '';

    final now = DateTime.now();
    final differences = now.difference(time);

    if (differences.inMinutes < 1) {
      return 'Just now';
    } else if (differences.inHours < 1) {
      return '${differences.inMinutes} m ago';
    } else if (differences.inDays < 1) {
      return ' ${differences.inHours} h ago';
    } else if (differences.inDays < 7) {
      return ' ${differences.inDays} d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }

  List<ChatModel> _getFilteredChats() {
    List<ChatModel> baseList = _isSearching.value ? _filteredChats : _allChats;

    switch (_activeFilter.value) {
      case 'Unread':
        return _applyUnreadFilter(baseList);

      case 'Recent':
        return _applyRecentFilter(baseList);

      case 'Active':
        return _applyActiveFilter(baseList);
      case 'All':
      default:
        return baseList;
    }
  }

  List<ChatModel> _applyUnreadFilter(List<ChatModel> chats) {
    final currentUserId = _authController.user?.uid;

    if (currentUserId == null) return [];

    return chats
        .where((chat) => chat.getUnreadCount(currentUserId) > 0)
        .toList();
  }

  List<ChatModel> _applyRecentFilter(List<ChatModel> chats) {
    final now = DateTime.now();

    final threeDaysAgo = now.subtract(Duration(days: 3));

    return chats.where((chat) {
      if (chat.lastMessageTime == null) return false;
      return chat.lastMessageTime!.isAfter(threeDaysAgo);
    }).toList();
  }

  List<ChatModel> _applyActiveFilter(List<ChatModel> chats) {
    final now = DateTime.now();

    final onWeekAgo = now.subtract(Duration(days: 7));

    return chats.where((chat) {
      if (chat.lastMessageTime == null) return false;
      return chat.lastMessageTime!.isAfter(onWeekAgo);
    }).toList();
  }

  void setFilter(String filterType) {
    _activeFilter.value = filterType;

    if (filterType == 'All') {
      if (_searchQuery.value.isEmpty) {
        _isSearching.value = false;
        _filteredChats.clear();
      }
    }
  }

  void clearAllFilters() {
    _activeFilter.value = 'All';
    _clearSearch();
  }

  void onSearchChanged(String query) {
    _searchQuery.value = query;
    if (query.isEmpty) {
      _clearSearch();
    } else {
      _isSearching.value = true;
      _performSearch(query);
    }
  }

  void _performSearch(String query) {
    final lowercaseQuery = query.toLowerCase().trim();

    _filteredChats.value = _allChats.where((chat) {
      final otherUser = getOtherUser(chat);
      if (otherUser == null) return false;

      final displayNameMatch =
          otherUser.displayName.toLowerCase().contains(lowercaseQuery) ?? false;

      final emailMatch =
          otherUser.email.toLowerCase().contains(lowercaseQuery) ?? false;

      final lastMessageMatch =
          chat.lastMessage?.toLowerCase().contains(lowercaseQuery) ?? false;

      return displayNameMatch || emailMatch || lastMessageMatch;
    }).toList();
    _sortSearchResults(lowercaseQuery);
  }

  void _sortSearchResults(String query) {
    filtredChats.sort((a, b) {
      final userA = getOtherUser(a);
      final userB = getOtherUser(b);

      if (userA == null || userB == null) return 0;

      final exactMatchA =
          userA.displayName.toLowerCase().startsWith(query) ?? false;

      final exactMatchB =
          userB.displayName.toLowerCase().startsWith(query) ?? false;

      if (exactMatchA && !exactMatchB) return -1;
      if (!exactMatchA && exactMatchB) return 1;

      return (b.lastMessageTime ?? DateTime(0)).compareTo(
        a.lastMessageTime ?? DateTime(0),
      );
    });
  }

  void _clearSearch() {
    _isSearching.value = false;
    _filteredChats.clear();
  }

  void clearSearch() {
    _searchQuery.value = '';
    _clearSearch();
  }

  void searchUserByName(String name) {
    onSearchChanged(name);
  }

  void searchByLastMessage(String message) {
    onSearchChanged(message);
  }

  List<ChatModel> getUnreadChats() {
    return _applyUnreadFilter(_allChats);
  }

  List<ChatModel> getActiveChats() {
    return _applyActiveFilter(_allChats);
  }

  List<ChatModel> getRecentChats({int limit = 10}) {
    final recentChats = _applyRecentFilter(_allChats);

    final sortedChats = List<ChatModel>.from(recentChats);

    sortedChats.sort((a, b) {
      return (b.lastMessageTime ?? DateTime(0)).compareTo(
        a.lastMessageTime ?? DateTime(0),
      );
    });
    return sortedChats.take(limit).toList();
  }

  int getUnreadCount() {
    return getUnreadChats().length;
  }

  int getRecentCount() {
    return _applyRecentFilter(_allChats).length;
  }

  int getActiveCount() {
    return getActiveChats().length;
  }

  List<String> getSearchSuggestions() {
    final suggestions = <String>[];

    for (var chat in _allChats) {
      final otherUser = getOtherUser(chat);
      if (otherUser?.displayName != null) {
        suggestions.add(otherUser!.displayName);
      }
    }
    return suggestions.toSet().toList();
  }

  void openChat(ChatModel chat) {
    final otherUser = getOtherUser(chat);

    if (otherUser != null) {
      Get.toNamed(
        AppRoutes.chat,
        arguments: {'chatId': chat.id, 'otherUser': otherUser},
      );
    }
  }

  void openFriends() {
    Get.toNamed(AppRoutes.friends);
  }

  void openNotifications() {
    Get.toNamed(AppRoutes.notifications);
  }

  Future<void> refreshChats() async {
    _isLoading.value = true;
    try {
      await Future.delayed(Duration(seconds: 1));

      if (_isSearching.value && _searchQuery.value.isNotEmpty) {
        _performSearch(_searchQuery.value);
      }
    } catch (e) {
      _error.value = 'Failed to refresh chats';
      print(e.toString());
    } finally {
      _isLoading.value = false;
    }
  }

  int getTotalUnreadCount() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId == null) return 0;

    int total = 0;
    for (var chat in _allChats) {
      total += chat.getUnreadCount(currentUserId);
    }
    return total;
  }

  int getUnreadNotificationsCount() {
    return _notifications.where((notify) => !notify.isRead).length;
  }

  Future<void> deleteChat(ChatModel chat) async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null) return;

      final otherUser = getOtherUser(chat);

      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Delete Chat'),
          content: Text(
            'Are you sure want to delete the chat with ${otherUser?.displayName ?? 'this user'}',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );

      if (result == true) {
        await _firestoreService.deleteChatForUser(chat.id, currentUserId);
        Get.snackbar('Success', 'Chat delete successfully');
      }
    } catch (e) {
      print(e.toString());
      Get.snackbar('Error', 'Failed to  delete Chat');
    } finally {
      _isLoading.value = false;
    }
  }

  void clearError() {
    _error.value = '';
  }

  @override
  void onClose() {
    super.onClose();
  }
}
