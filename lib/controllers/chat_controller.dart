import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/message_model.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();

  final TextEditingController messageController = TextEditingController();
  final Uuid _uuid = Uuid();

  ScrollController? _scrollController;
  ScrollController get scrollController {
    _scrollController ??= ScrollController();
    return _scrollController!;
  }

  final RxList<MessageModel> _messages = <MessageModel>[].obs;
  final RxBool _isLoading = false.obs;
  final RxBool _isSending = false.obs;
  final RxString _error = ''.obs;
  final Rx<UserModel?> _otherUser = Rx<UserModel?>(null);
  final RxString _chatId = ''.obs;
  final RxBool _isTyping = false.obs;
  final RxBool _isChatActive = false.obs;

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading.value;
  bool get isSending => _isSending.value;
  String get error => _error.value;
  UserModel? get otherUser => _otherUser.value;
  String get chatId => _chatId.value;
  bool get isTyping => _isTyping.value;
  bool get isChatActive => _isChatActive.value;

  @override
  void onInit() {
    super.onInit();
    _initializeChat();
    messageController.addListener(_onMessageChanged);
  }

  @override
  void onReady() {
    super.onReady();
    _isChatActive.value = true;
  }

  @override
  void onClose() {
    _isChatActive.value = false;
    _markMessagesAsRead();
    super.onClose();
  }

  void _initializeChat() {
    final argements = Get.arguments;
    if (argements != null) {
      _chatId.value = argements['chatId'] ?? '';
      _otherUser.value = argements['otherUser'];
      _loadMessages();
      _markMessagesAsRead();
    }
  }

  void _loadMessages() {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;

    if (currentUserId != null && otherUserId != null) {
      _messages.bindStream(
        _firestoreService.getMessagesStream(currentUserId, otherUserId),
      );
      ever(_messages, (List<MessageModel> messageList) {
        if (_isChatActive.value) {
          _markUnReadMessagesAsRead(messageList);
        }
        _scrolltoBottom();
      });
    }
  }

  void _scrolltoBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController != null && _scrollController!.hasClients) {
        _scrollController!.animateTo(
          _scrollController!.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _markUnReadMessagesAsRead(List<MessageModel> messageList) async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId == null) return;

    try {
      final unreadMessages = messageList
          .where(
            (message) =>
                message.receiverId == currentUserId &&
                !message.isRead &&
                message.senderId != currentUserId,
          )
          .toList();

      for (var message in unreadMessages) {
        await _firestoreService.markMessageAsRead(message.id);
      }

      if (unreadMessages.isNotEmpty && _chatId.value.isNotEmpty) {
        await _firestoreService.restoreUnreadCount(
          _chatId.value,
          currentUserId,
        );
      }
      if (_chatId.value.isNotEmpty) {
        await _firestoreService.updateUserLastSeen(
          _chatId.value,
          currentUserId,
        );
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteChat() async {
    try {
      final currentUserId = _authController.user?.uid;
      if (currentUserId == null || _chatId.value.isNotEmpty) return;

      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text('Delete chat'),
          content: Text('Are you sure to delete this chat'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: Text('Delete'),
            ),
          ],
        ),
      );
      if (result == true) {
        _isLoading.value = true;
        await _firestoreService.deleteChatForUser(_chatId.value, currentUserId);

        Get.delete<ChatController>(tag: _chatId.value);
        Get.back();
        Get.snackbar('Success', 'Chat delete Successfully');
      }
    } catch (e) {
      _error.value = e.toString();
      print(e);
      Get.snackbar('Error', 'failed to  delete Chat');
    } finally {
      _isLoading.value = false;
    }
  }

  void _onMessageChanged() {
    _isTyping.value = messageController.text.isNotEmpty;
  }

  Future<void> sendMessage() async {
    final currentUserId = _authController.user?.uid;
    final otherUserId = _otherUser.value?.id;
    final content = messageController.text.trim();
    messageController.clear();

    if (currentUserId == null || otherUserId == null || content.isEmpty) {
      Get.snackbar("Error", 'You cannot send message to this user');
      return;
    }
    if (await _firestoreService.isUnfriended(currentUserId, otherUserId)) {
      Get.snackbar(
        "Error",
        'You cannot send message to this user as you are not friend',
      );
      return;
    }

    try {
      _isLoading.value = true;
      final message = MessageModel(
        id: _uuid.v4(),
        senderId: currentUserId,
        receiverId: otherUserId,
        content: content,
        type: MessageType.text,
        timestamp: DateTime.now(),
      );
      await _firestoreService.sendMessage(message);
      _isTyping.value = true;
      _scrolltoBottom();
      // Get.snackbar("Success", 'You can send message');
    } catch (e) {
      // Get.snackbar("Error", 'You cannot send message');
      print(e);
    } finally {
      _isSending.value = false;
    }
  }

  Future<void> _markMessagesAsRead() async {
    final currentUserId = _authController.user?.uid;
    if (currentUserId != null && _chatId.value.isNotEmpty) {
      try {
        await _firestoreService.restoreUnreadCount(
          _chatId.value,
          currentUserId,
        );
      } catch (e) {
        print(e);
      }
    }
  }

  void onChatResumed() {
    _isChatActive.value = true;
    _markMessagesAsRead();
  }

  void onChatPaused() {
    _isChatActive.value = false;
  }

  Future<void> deleteMessage(MessageModel message) async {
    try {
      await _firestoreService.deleteMessage(message.id);
      Get.snackbar("Success", 'message Delete');
    } catch (e) {
      Get.snackbar("Error", 'failed delete a message');
      print(e);
    }
  }

  Future<void> editMessage(MessageModel message, String newContent) async {
    try {
      await _firestoreService.editMessage(message.id, newContent);
      Get.snackbar("Success", 'message Edited');
    } catch (e) {
      Get.snackbar("Error", 'failed edit a message');
      print(e);
    }
  }

  bool isMyMessage(MessageModel message) {
    return message.senderId == _authController.user?.uid;
  }

  String formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final differences = now.difference(timestamp);

    if (differences.inMinutes < 1) {
      return 'Just now';
    } else if (differences.inHours < 1) {
      return '${differences.inMinutes} m ago';
    } else if (differences.inDays < 1) {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else if (differences.inDays < 7) {
      final days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
      return '${days[timestamp.weekday - 1]} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  void clearError() {
    _error.value = '';
  }
}
