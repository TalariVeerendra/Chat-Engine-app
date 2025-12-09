import 'package:chat_app/controllers/auth_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class ChangePasswordController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxBool _obscureCurrentPassword = true.obs;
  final RxBool _obscureNewPassword = true.obs;
  final RxBool _obscureConfirmPassword = true.obs;

  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get obscureCurrentPassword => _obscureCurrentPassword.value;
  bool get obscureNewPassword => _obscureNewPassword.value;
  bool get obscureConfirmPassword => _obscureConfirmPassword.value;

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleCurrentPasswordVisibility() {
    _obscureCurrentPassword.value = !_obscureCurrentPassword.value;
  }

  void toggleNewPasswordVisibility() {
    _obscureNewPassword.value = !_obscureNewPassword.value;
  }

  void toggleConfirmPasswordVisibility() {
    _obscureConfirmPassword.value = !_obscureConfirmPassword.value;
  }

  Future<void> chagePassword() async {
    if (!formKey.currentState!.validate()) return;

    try {
      _isLoading.value = true;
      _error.value = '';

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        throw Exception("No User Logged In");
      }

      await user.updatePassword(newPasswordController.text);

      Get.snackbar(
        'Success',
        'Password Updated Successfully',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: Duration(seconds: 3),
      );

      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      await _authController.signOut();
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'Wrong-password':
          errorMessage = 'Current password is incorrect';
          break;
        case 'weak-password':
          errorMessage = 'New password is weak password';
          break;
        case 'required-recent-login':
          errorMessage =
              'please signout and signin before changing the password';
          break;
        default:
          errorMessage = 'Failed to Change password';
      }

      _error.value = errorMessage;
      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: Duration(seconds: 4),
      );
    } catch (e) {
      _error.value = "Failed to change Password";
      print(e.toString());
      Get.snackbar(
        'Error',
        _error.value,
        backgroundColor: Colors.red.withOpacity(0.1),
        colorText: Colors.red,
        duration: Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  String? validateCurrentPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please Enter your Current Password';
    }
    return null;
  }

  String? validateNewPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please Enter your New Password';
    }
    if (value!.length < 6) {
      return 'Password must contain 6 Characters';
    }
    if (value == currentPasswordController.text) {
      return "It is previous Password Should conatin different from the current Passsword";
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value?.isEmpty ?? true) {
      return 'Please confirm your New Password';
    }
    if (value != newPasswordController.text) {
      return "Password shouldn't be matched";
    }
    return null;
  }

  void clearError() {
    _error.value = '';
  }
}
