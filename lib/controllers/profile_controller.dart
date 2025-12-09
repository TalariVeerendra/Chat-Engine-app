import 'package:chat_app/controllers/auth_controller.dart';
import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ProfileController extends GetxController {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController displayNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();

  final RxBool _isLoading = false.obs;
  final RxBool _isEditing = false.obs;
  final RxString _error = ''.obs;
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);

  bool get isLoading => _isLoading.value;
  bool get isEditing => _isEditing.value;
  String get error => _error.value;
  UserModel? get currentUser => _currentUser.value;

  @override
  void onInit() {
    super.onInit();
    _loadUserData();
  }

  void _loadUserData() {
    final currentUserId = _authController.user?.uid;

    if (currentUserId != null) {
      _currentUser.bindStream(_firestoreService.getUsersStream(currentUserId));

      ever(_currentUser, (UserModel? user) {
        if (user != null) {
          displayNameController.text = user.displayName;
          emailController.text = user.email;
        }
      });
    }
  }

  void toggleEditing() {
    _isEditing.value = !_isEditing.value;

    if (!_isEditing.value) {
      final user = _currentUser.value;
      if (user != null) {
        displayNameController.text = user.displayName;
        emailController.text = user.email;
      }
    }
  }

  Future<void> updateProfile() async {
    try {
      _isLoading.value = false;
      _error.value = "";

      final user = _currentUser.value;
      if (user == null) return;

      final updatedUser = user.copyWith(
        displayName: displayNameController.text,
      );
      await _firestoreService.updateUser(updatedUser);
      _isEditing.value = false;
      Get.snackbar('Success', "Successfully to Profile Update the user");
    } catch (e) {
      _error.value = e.toString();
      print(e.toString());
      Get.snackbar('Error', "Failed to Update the user");
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await _authController.signOut();
    } catch (e) {
      Get.snackbar('Error', "Failed to SignOut");
    }
  }

  Future<void> deleteAccount() async {
    try {
      final result = await Get.dialog<bool>(
        AlertDialog(
          title: Text("Delete Account"),
          content: Text(
            "Are you Sure to delete your Account? This action can't be done",
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              style: TextButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (result == true) {
        _isLoading.value = true;
        await _authController.deleteAccount();
      } else {}
    } catch (e) {
      Get.snackbar('Error', "Failed to Delete Account");
    } finally {
      _isLoading.value = false;
    }
  }

  String getJoinedData() {
    final user = _currentUser.value;
    if (user == null) return "";
    final date = user.createdAt;

    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Joined ${months[date.month - 1]} ${date.year}';
  }

  void clearError() {
    _error.value = '';
  }
}
