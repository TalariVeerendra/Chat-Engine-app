import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/friend_request_model.dart';
import 'package:chat_app/models/friendship_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

enum UserRelationshipStatus {
  none,
  friendRequestSent,
  friendRequestReceived,
  friends,
  blocked,
}

class UsersListController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final Uuid _uuid = Uuid();

  final RxList<UserModel> _users = <UserModel>[].obs;
  final RxList<UserModel> _filteredUsers = <UserModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _searchQuery = ''.obs;
  final RxString _error = ''.obs;

  final RxMap<String, UserRelationshipStatus> _userRelationships =
      <String, UserRelationshipStatus>{}.obs;

  final RxList<FriendRequestModel> _sendRequests = <FriendRequestModel>[].obs;
  final RxList<FriendRequestModel> _receivedRequests =
      <FriendRequestModel>[].obs;

  final RxList<FriendshipModel> _friendships = <FriendshipModel>[].obs;

  List<UserModel> get users => _users;
  List<UserModel> get filteredUsers => _filteredUsers;
  bool get isloading => _isLoading.value;
  String get searchQuery => _searchQuery.value;
  String get error => _error.value;
  Map<String, UserRelationshipStatus> get userRelationships =>
      _userRelationships;

  @override
  void onInit() {
    super.onInit();
    _loadUsers();
    _loadRelationships();

    debounce(
      _sendRequests,
      (_) => _filterUsers(),
      time: Duration(milliseconds: 300),
    );
  }

  void _loadUsers() async {
    _users.bindStream(_firestoreService.getAllUsersStream());

    //Filter out current user and update the filtered list
    ever(_users, (List<UserModel> userList) {
      final currentUserId = _authController.user?.uid;
      final otherUsers = userList
          .where((user) => user.id != currentUserId)
          .toList();

      if (_searchQuery.isEmpty) {
        _filteredUsers.value = otherUsers;
      } else {
        _filterUsers();
      }
    });
  }

  void _loadRelationships() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      //Load Sender Friends Request
      _sendRequests.bindStream(
        _firestoreService.getSentFriendRequestStream(currentUserId),
      );

      //Load Reciever Friends Request
      _receivedRequests.bindStream(
        _firestoreService.getFriendRequestsStream(currentUserId),
      );

      //Load Friends or Friendship
      _friendships.bindStream(
        _firestoreService.getFriendsStream(currentUserId),
      );

      //Update Realationship status whenever any of the Lists changes
      ever(_sendRequests, (_) => _updateAllRelationshipsStatus());
      ever(_receivedRequests, (_) => _updateAllRelationshipsStatus());
      ever(_friendships, (_) => _updateAllRelationshipsStatus());

      ever(_users, (_) => _updateAllRelationshipsStatus());
    }
  }

  void _updateAllRelationshipsStatus() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId == null) return;

    for (var user in _users) {
      if (user.id != currentUserId) {
        final status = _calculateUserRelationshipStatus(user.id);
        _userRelationships[user.id] = status;
      }
    }
  }

  UserRelationshipStatus _calculateUserRelationshipStatus(String userId) {
    final currentUserId = _authController.user?.uid;

    if (currentUserId == null) return UserRelationshipStatus.none;

    // Check if they are Friends or not
    final friendship = _friendships.firstWhereOrNull(
      (f) =>
          (f.user1Id == currentUserId && f.user2Id == userId) ||
          (f.user1Id == userId && f.user2Id == currentUserId),
    );
    if (friendship != null) {
      if (friendship.isBlocked) {
        return UserRelationshipStatus.blocked;
      } else {
        return UserRelationshipStatus.friends;
      }
    }

    // Check if there is a pending friend request from the user
    final sentRequest = _sendRequests.firstWhereOrNull(
      (r) => r.receiverId == userId && r.status == FriendRequestStatus.pending,
    );

    if (sentRequest != null) {
      return UserRelationshipStatus.friendRequestSent;
    }

    // Check if there is a pending friend request from the user
    final receivedRequest = _receivedRequests.firstWhereOrNull(
      (r) => r.senderId == userId && r.status == FriendRequestStatus.pending,
    );

    if (receivedRequest != null) {
      return UserRelationshipStatus.friendRequestReceived;
    }
    return UserRelationshipStatus.none;
  }

  void _filterUsers() {
    final currentUserId = _authController.user?.uid;
    final query = _searchQuery.value.toLowerCase();

    if (query.isEmpty) {
      _filteredUsers.value = _users
          .where((user) => user.id != currentUserId)
          .toList();
    } else {
      _filteredUsers.value = _users.where((user) {
        return user.id != currentUserId &&
            (user.displayName.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query));
      }).toList();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery.value = query;
  }

  void clearSearch() {
    _searchQuery.value = '';
  }

  Future<void> sendFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = FriendRequestModel(
          id: _uuid.v4(),
          senderId: currentUserId,
          receiverId: user.id,
          createdAt: DateTime.now(),
        );

        _userRelationships[user.id] = UserRelationshipStatus.friendRequestSent;

        await _firestoreService.sendFriendRequest(request);
        Get.snackbar('Success', 'Friend Request sent to ${user.displayName}');
      }
    } catch (e) {
      _userRelationships[user.id] = UserRelationshipStatus.none;
      _error.value = e.toString();
      print("Error sending Friend request : $e");
      Get.snackbar('Error', 'Failed to send a Friend Request ');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> cancelFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _sendRequests.firstWhereOrNull(
          (r) =>
              r.receiverId == user.id &&
              r.status == FriendRequestStatus.pending,
        );

        if (request != null) {
          _userRelationships[user.id] = UserRelationshipStatus.none;

          await _firestoreService.cancelFriendRequest(request.id);
          Get.snackbar('Success', 'Friend Request cancelled');
        }
      }
    } catch (e) {
      _userRelationships[user.id] = UserRelationshipStatus.friendRequestSent;
      _error.value = e.toString();
      print("Error Cancelling Friend request: $e");
      Get.snackbar('Error', 'Failed to Cancel a Friend Request ');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> acceptFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _receivedRequests.firstWhereOrNull(
          (r) =>
              r.senderId == user.id && r.status == FriendRequestStatus.pending,
        );
        if (request != null) {
          _userRelationships[user.id] = UserRelationshipStatus.friends;

          await _firestoreService.respondToFriendRequest(
            request.id,
            FriendRequestStatus.accepted,
          );
          Get.snackbar('Success', 'Friend Request Accepting Successfully');
        }
      }
    } catch (e) {
      _userRelationships[user.id] =
          UserRelationshipStatus.friendRequestReceived;
      _error.value = e.toString();
      print("Error Accepting Friend request: $e");
      Get.snackbar('Error', 'Failed to Accept a Friend Request ');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> declineFriendRequest(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final request = _receivedRequests.firstWhereOrNull(
          (r) =>
              r.senderId == user.id && r.status == FriendRequestStatus.pending,
        );
        if (request != null) {
          _userRelationships[user.id] = UserRelationshipStatus.none;

          await _firestoreService.respondToFriendRequest(
            request.id,
            FriendRequestStatus.declined,
          );
          Get.snackbar('Success', 'Friend Request Decline ');
        }
      }
    } catch (e) {
      _userRelationships[user.id] =
          UserRelationshipStatus.friendRequestReceived;
      _error.value = e.toString();
      print("Error Accepting Friend request: $e");
      Get.snackbar('Error', 'Failed to send a Decline Request ');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> startChat(UserModel user) async {
    try {
      _isLoading.value = true;
      final currentUserId = _authController.user?.uid;

      if (currentUserId != null) {
        final relationship =
            _userRelationships[user.id] ?? UserRelationshipStatus.none;
        if (relationship != UserRelationshipStatus.friends) {
          Get.snackbar(
            'Info',
            'You can chat with friends. Please send a friend Request fisrt',
          );
          return;
        }

        final chatId = await _firestoreService.createOrGetChat(
          currentUserId,
          user.id,
        );

        Get.toNamed(
          AppRoutes.chat,
          arguments: {'chatId': chatId, 'otherUser': user},
        );
      }
    } catch (e) {
      _error.value = e.toString();
      print('Error starting chat: $e');
      Get.snackbar('Error', 'Failed to start chat');
    } finally {
      _isLoading.value = false;
    }
  }

  UserRelationshipStatus getUserRelationshipStatus(String userId) {
    return _userRelationships[userId] ?? UserRelationshipStatus.none;
  }

  String getRelationshipButtonText(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none:
        return 'Add Friend';
      case UserRelationshipStatus.friendRequestSent:
        return 'Request Sent';
      case UserRelationshipStatus.friendRequestReceived:
        return 'Accept';
      case UserRelationshipStatus.friends:
        return 'Message';
      case UserRelationshipStatus.blocked:
        return 'Blocked';
    }
  }

  IconData getRelationshipButtonIcon(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none:
        return Icons.person_add;

      case UserRelationshipStatus.friendRequestSent:
        return Icons.access_time;

      case UserRelationshipStatus.friendRequestReceived:
        return Icons.check;

      case UserRelationshipStatus.friends:
        return Icons.chat_bubble_outline;

      case UserRelationshipStatus.blocked:
        return Icons.block;
    }
  }

  Color getRelationshipButtonColor(UserRelationshipStatus status) {
    switch (status) {
      case UserRelationshipStatus.none:
        return Colors.blue;

      case UserRelationshipStatus.friendRequestSent:
        return Colors.orange;

      case UserRelationshipStatus.friendRequestReceived:
        return Colors.green;

      case UserRelationshipStatus.friends:
        return Colors.lightBlue;

      case UserRelationshipStatus.blocked:
        return Colors.redAccent;
    }
  }

  void handleRelationshipAction(UserModel user) {
    final status = getUserRelationshipStatus(user.id);

    switch (status) {
      case UserRelationshipStatus.none:
        sendFriendRequest(user);
        break;

      case UserRelationshipStatus.friendRequestSent:
        cancelFriendRequest(user);
        break;

      case UserRelationshipStatus.friendRequestReceived:
        acceptFriendRequest(user);
        break;

      case UserRelationshipStatus.friends:
        startChat(user);
        break;

      case UserRelationshipStatus.blocked:
        Get.snackbar('info', 'You have blocked this User');
        break;
    }
  }

  String getLastSeenText(UserModel user) {
    if (user.isOnline) {
      return "Online";
    } else {
      final now = DateTime.now();
      final differences = now.difference(user.lastSeen);

      if (differences.inMinutes < 1) {
        return 'Just now';
      } else if (differences.inHours < 1) {
        return 'Last Seen ${differences.inMinutes} m ago';
      } else if (differences.inDays < 1) {
        return 'Last Seen ${differences.inHours} h ago';
      } else if (differences.inDays < 7) {
        return 'Last Seen ${differences.inDays} d ago';
      } else {
        return 'Last Seen on ${user.lastSeen.day}/${user.lastSeen.month}/${user.lastSeen.year}';
      }
    }
  }

  void _clearError() {
    _error.value = '';
  }
}
