import 'package:chat_app/models/chat_model.dart';
import 'package:chat_app/models/friend_request_model.dart';
import 'package:chat_app/models/friendship_model.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/notification_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Failed to Create User: ${e.toString()}');
    }
  }

  Future<UserModel?> getUser(String userId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to Get User: ${e.toString()}');
    }
  }

  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      if (doc.exists) {
        await _firestore.collection('users').doc(userId).update({
          'isOnline': isOnline,
          'lastSeen': DateTime.now(),
        });
      }
    } catch (e) {
      throw Exception('Failed to Update User Online Status: ${e.toString()}');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      throw Exception('Failed to Delete User: ${e.toString()}');
    }
  }

  Stream<UserModel?> getUsersStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromMap(doc.data()!) : null);
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('failed to Update User');
    }
  }

  Stream<List<UserModel>> getAllUsersStream() {
    return _firestore
        .collection('users')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => UserModel.fromMap(doc.data()))
              .toList(),
        );
  }

  //Friend request Collection
  Future<void> sendFriendRequest(FriendRequestModel request) async {
    try {
      await _firestore
          .collection('friendRequests')
          .doc(request.id)
          .set(request.toMap());

      String notificationId =
          'friend_request_${request.senderId}_${request.receiverId}_${DateTime.now().millisecondsSinceEpoch}';

      await createNotification(
        NotificationModel(
          id: notificationId,
          userId: request.receiverId,
          title: "New Friend Request",
          body: "You have recieved a Friend Request",
          type: NotificationType.friendRequest,
          data: {'senderId': request.senderId, 'requestId': request.id},
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('failed to send Friend request : ${e.toString()}');
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      DocumentSnapshot requestDoc = await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .get();

      if (requestDoc.exists) {
        FriendRequestModel request = FriendRequestModel.fromMap(
          requestDoc.data() as Map<String, dynamic>,
        );
        await _firestore.collection('friendRequests').doc(requestId).delete();

        await deleteNotificationsByTypeAndUser(
          request.receiverId,
          NotificationType.friendRequest,
          request.senderId,
        );
      }
    } catch (e) {
      throw Exception('failed to Cancel Friend request : ${e.toString()}');
    }
  }

  Future<void> respondToFriendRequest(
    String requestId,
    FriendRequestStatus status,
  ) async {
    try {
      await _firestore.collection('friendRequests').doc(requestId).update({
        'status': status.name,
        'respondedAt': DateTime.now().millisecondsSinceEpoch,
      });

      DocumentSnapshot requestDoc = await _firestore
          .collection('friendRequests')
          .doc(requestId)
          .get();

      if (requestDoc.exists) {
        FriendRequestModel request = FriendRequestModel.fromMap(
          requestDoc.data() as Map<String, dynamic>,
        );

        if (status == FriendRequestStatus.accepted) {
          await createFriendShip(request.senderId, request.receiverId);

          await createNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: request.senderId,
              title: 'Friend Request Accepted',
              body: 'your Friend Requested have been Accepted',
              type: NotificationType.friendRequestAccepted,
              data: {'userId': request.receiverId},
              createdAt: DateTime.now(),
            ),
          );
          await _removeNotificationForCancelledRequest(
            request.receiverId,
            request.senderId,
          );
        } else if (status == FriendRequestStatus.declined) {
          await createNotification(
            NotificationModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              userId: request.senderId,
              title: 'Friend Request Declined',
              body: 'your Friend Requested have been Declined',
              type: NotificationType.friendRequestDeclined,
              data: {'userId': request.receiverId},
              createdAt: DateTime.now(),
            ),
          );
          await _removeNotificationForCancelledRequest(
            request.receiverId,
            request.senderId,
          );
        }
      }
    } catch (e) {
      throw Exception('failed to Respond Friend request : ${e.toString()}');
    }
  }

  Stream<List<FriendRequestModel>> getFriendRequestsStream(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Stream<List<FriendRequestModel>> getSentFriendRequestStream(String userId) {
    return _firestore
        .collection('friendRequests')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => FriendRequestModel.fromMap(doc.data()))
              .toList(),
        );
  }

  Future<FriendRequestModel?> getFriendRequest(
    String senderId,
    String receiverId,
  ) async {
    try {
      QuerySnapshot query = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .where('status', isEqualTo: 'pending')
          .get();

      if (query.docs.isNotEmpty) {
        return FriendRequestModel.fromMap(
          query.docs.first.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get friend Request: ${e.toString()}');
    }
  }

  // FriendShip Collections

  Future<void> createFriendShip(String user1Id, String user2Id) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendShipId = '${userIds[0]}_${userIds[1]}';

      FriendshipModel frinedShip = FriendshipModel(
        id: friendShipId,
        user1Id: userIds[0],
        user2Id: userIds[1],
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .set(frinedShip.toMap());
    } catch (e) {
      throw Exception('Failed to Create a FriendShip: ${e.toString()}');
    }
  }

  Future<void> removeFriendShip(String user1Id, String user2Id) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendShipId = '${userIds[0]}_${userIds[1]}';

      await _firestore.collection('friendships').doc(friendShipId).delete();

      await createNotification(
        NotificationModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: user2Id,
          title: 'Friend Removed',
          body: 'You are no longer Friends',
          type: NotificationType.friendRemoved,
          data: {'userId': user1Id},
          createdAt: DateTime.now(),
        ),
      );
    } catch (e) {
      throw Exception('Failed to Remove a FriendShip: ${e.toString()}');
    }
  }

  Future<void> blockUser(String blockerId, String blockedId) async {
    try {
      List<String> userIds = [blockerId, blockedId];
      userIds.sort();

      String friendShipId = '${userIds[0]}_${userIds[1]}';

      await _firestore.collection('friendships').doc(friendShipId).update({
        'isBlocked': true,
        'blockedBy': blockerId,
      });
    } catch (e) {
      throw Exception('Failed to blocked a user: ${e.toString()}');
    }
  }

  Future<void> unblockUser(String user1Id, String user2Id) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendShipId = '${userIds[0]}_${userIds[1]}';

      await _firestore.collection('friendships').doc(friendShipId).update({
        'isBlocked': false,
        'blockedBy': null,
      });
    } catch (e) {
      throw Exception('Failed to unblocked a user: ${e.toString()}');
    }
  }

  Stream<List<FriendshipModel>> getFriendsStream(String userId) {
    return _firestore
        .collection('friendships')
        .where('user1Id', isEqualTo: userId)
        .snapshots()
        .asyncMap((snapshot1) async {
          QuerySnapshot snapshot2 = await _firestore
              .collection('friendships')
              .where('user2Id', isEqualTo: userId)
              .get();

          List<FriendshipModel> friendships = [];

          for (var doc in snapshot1.docs) {
            friendships.add(
              FriendshipModel.fromMap(doc.data() as Map<String, dynamic>),
            );
          }
          for (var doc in snapshot2.docs) {
            friendships.add(
              FriendshipModel.fromMap(doc.data() as Map<String, dynamic>),
            );
          }
          return friendships.where((f) => !f.isBlocked).toList();
        });
  }

  Future<FriendshipModel?> getFriendships(
    String user1Id,
    String user2Id,
  ) async {
    try {
      List<String> userIds = [user1Id, user2Id];
      userIds.sort();

      String friendShipId = '${userIds[0]}_${userIds[1]}';

      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .get();

      if (doc.exists) {
        return FriendshipModel.fromMap(doc.data() as Map<String, dynamic>);
      }

      return null;
    } catch (e) {
      throw Exception('Failed to get FriensShip : ${e.toString()}');
    }
  }

  Future<bool> isUserBlocked(String userId, String otherUserId) async {
    try {
      List<String> userIds = [userId, otherUserId];
      userIds.sort();

      String friendShipId = '${userIds[0]}_${userIds[1]}';

      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .get();

      if (doc.exists) {
        FriendshipModel friendship = FriendshipModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );

        return friendship.isBlocked;
      }
      return false;
    } catch (e) {
      throw Exception('Failed to check if user is  blocked : ${e.toString()}');
    }
  }

  Future<bool> isUnfriended(String userId, String otherUserId) async {
    try {
      List<String> userIds = [userId, otherUserId];
      userIds.sort();

      String friendShipId = '${userIds[0]}_${userIds[1]}';

      DocumentSnapshot doc = await _firestore
          .collection('friendships')
          .doc(friendShipId)
          .get();

      return !doc.exists || (doc.exists && doc.data() == null);
    } catch (e) {
      throw Exception('Failed to check if user is  blocked : ${e.toString()}');
    }
  }

  // Chats Collections

  Future<String> createOrGetChat(String user1Id, String user2Id) async {
    try {
      List<String> participants = [user1Id, user2Id];
      participants.sort();

      String chatId = '${participants[0]}_${participants[1]}';

      DocumentReference chatRef = _firestore.collection('chats').doc(chatId);
      DocumentSnapshot chatDoc = await chatRef.get();
      if (chatDoc.exists) {
        ChatModel newChat = ChatModel(
          id: chatId,
          participants: participants,
          unreadCount: {user1Id: 0, user2Id: 0},
          deleteBy: {user1Id: false, user2Id: false},
          deletedAt: {user1Id: null, user2Id: null},
          lastSeenBy: {user1Id: DateTime.now(), user2Id: DateTime.now()},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await chatRef.set(newChat.toMap());
      } else {
        ChatModel existingChat = ChatModel.fromMap(
          chatDoc.data() as Map<String, dynamic>,
        );
        if (existingChat.isDeleteBy(user1Id)) {
          await restoreChatForUser(chatId, user1Id);
        }
        if (existingChat.isDeleteBy(user2Id)) {
          await restoreChatForUser(chatId, user2Id);
        }
      }
      return chatId;
    } catch (e) {
      throw Exception('Failed to Create Or Get Chat : ${e.toString()}');
    }
  }

  Stream<List<ChatModel>> getUserChatsStream(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => ChatModel.fromMap(doc.data()))
              .where((chat) => !chat.isDeleteBy(userId))
              .toList(),
        );
  }

  Future<void> updateChatLastMessage(
    String chatId,
    MessageModel message,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message.content,
        'lastMessageTime': message.timestamp.millisecondsSinceEpoch,
        'lastMessageSenderId': message.senderId,
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      throw Exception('Failed to Updated the Last message : ${e.toString()}');
    }
  }

  Future<void> updateUserLastSeen(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'lastSeenBy.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to Update User Last Seen : ${e.toString()}');
    }
  }

  Future<void> deleteChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deleteBy.$userId': true,
        'deletedAt.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to Delete chat for  User : ${e.toString()}');
    }
  }

  Future<void> restoreChatForUser(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'deleteBy.$userId': false,
        // 'deletedAt.$userId': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to Delete chat for  User : ${e.toString()}');
    }
  }

  Future<void> updateUnreadCount(
    String chatId,
    String userId,
    int count,
  ) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': count,
      });
    } catch (e) {
      throw Exception('Failed to update unread count : ${e.toString()}');
    }
  }

  Future<void> restoreUnreadCount(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      throw Exception('Failed to restore unread count : ${e.toString()}');
    }
  }
  //Message Collection

  Future<void> sendMessage(MessageModel message) async {
    try {
      await _firestore
          .collection('messages')
          .doc(message.id)
          .set(message.toMap());

      String chatId = await createOrGetChat(
        message.senderId,
        message.receiverId,
      );

      await updateChatLastMessage(chatId, message);

      await updateUserLastSeen(chatId, message.senderId);

      DocumentSnapshot chatDoc = await _firestore
          .collection('chats')
          .doc(chatId)
          .get();

      if (chatDoc.exists) {
        ChatModel chat = ChatModel.fromMap(
          chatDoc.data() as Map<String, dynamic>,
        );
        int currentUnread = chat.getUnreadCount(message.receiverId);

        await updateUnreadCount(chatId, message.receiverId, currentUnread + 1);
      }
    } catch (e) {
      throw Exception('Failed to Send a message to : ${e.toString()}');
    }
  }

  Stream<List<MessageModel>> getMessagesStream(String user1Id, String user2Id) {
    return _firestore
        .collection('messages')
        .where('senderId', whereIn: [user1Id, user2Id])
        .snapshots()
        .asyncMap((snapshot) async {
          List<String> participants = [user1Id, user2Id];
          participants.sort();
          String chatId = '${participants[0]}_${participants[1]}';

          DocumentSnapshot chatDoc = await _firestore
              .collection('chats')
              .doc(chatId)
              .get();

          ChatModel? chat;

          if (chatDoc.exists) {
            chat = ChatModel.fromMap(chatDoc.data() as Map<String, dynamic>);
          }

          List<MessageModel> messages = [];
          for (var doc in snapshot.docs) {
            MessageModel message = MessageModel.fromMap(doc.data());
            if ((message.senderId == user1Id &&
                    message.receiverId == user2Id) ||
                (message.senderId == user2Id &&
                    message.receiverId == user1Id)) {
              bool includeMessage = true;

              if (chat != null) {
                DateTime? currentUserDeletedAt = chat.getDeletedAt(user1Id);
                if (currentUserDeletedAt != null &&
                    message.timestamp.isBefore(currentUserDeletedAt)) {
                  includeMessage = false;
                }
              }
              if (includeMessage) {
                messages.add(message);
              }
            }
          }
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return messages;
        });
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception('Failed to mark  message as Read to : ${e.toString()}');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection('messages').doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete  message to : ${e.toString()}');
    }
  }

  Future<void> editMessage(String messageId, String newContent) async {
    try {
      await _firestore.collection('messages').doc(messageId).update({
        'content': newContent,
        'isEdited': true,
        'editedAt': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('failed to edit a message: ${e.toString()}');
    }
  }

  // Notification collection

  Future<void> createNotification(NotificationModel notification) async {
    try {
      await _firestore
          .collection('notifications')
          .doc(notification.id)
          .set(notification.toMap());
    } catch (e) {
      throw Exception('failed to create Notification: ${e.toString()}');
    }
  }

  Stream<List<NotificationModel>> getNotificationsStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((docs) => NotificationModel.fromMap(docs.data()))
              .toList(),
        );
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      throw Exception(
        'failed to Mark Notification as Read to : ${e.toString()}',
      );
    }
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      WriteBatch batch = _firestore.batch();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception(
        'failed to Mark All Notification as Read to : ${e.toString()}',
      );
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).delete();
    } catch (e) {
      throw Exception('failed to Delete Notification to : ${e.toString()}');
    }
  }

  Future<void> deleteNotificationsByTypeAndUser(
    String userId,
    NotificationType type,
    String relatedUserId,
  ) async {
    try {
      QuerySnapshot notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('type', isEqualTo: type.name)
          .get();

      WriteBatch batch = _firestore.batch();
      for (var doc in notifications.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        if (data['data'] != null &&
            (data['data']['senderId'] == relatedUserId ||
                data['data']['userId'] == relatedUserId)) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
    } catch (e) {
      // throw Exception('failed to Delete Notification to : ${e.toString()}');
      print("error deleting notifications: $e");
    }
  }

  Future<void> _removeNotificationForCancelledRequest(
    String receiverId,
    String senderId,
  ) async {
    try {
      await deleteNotificationsByTypeAndUser(
        receiverId,
        NotificationType.friendRequest,
        senderId,
      );
    } catch (e) {
      print("error removing notifications for cancelled request: $e");
    }
  }
}
