import 'package:chat_app/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ForgotPasswordController extends GetxController {
  final AuthService _authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxBool _emailSent = false.obs;

  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get emailSent => _emailSent.value;

  @override
  void onClose() {
    emailController.dispose();
    super.onClose();
  }

  Future<void> sentPasswordResetEmail() async {
    if (!formKey.currentState!.validate()) return;

    try {
      _isLoading.value = true;

      await _authService.sendPasswordResentEmail(emailController.text.trim());

      _emailSent.value = true;
      Get.snackbar(
        'Success',
        'Password rest link sent to ${emailController.text}',
        backgroundColor: Colors.green.withOpacity(0.1),
        colorText: Colors.green,
        duration: Duration(seconds: 4),
      );
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar(
        'Error',
        e.toString(),
        backgroundColor: Colors.redAccent.withOpacity(0.1),
        colorText: Colors.redAccent,
        duration: Duration(seconds: 4),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  void goBackToLogin() {
    Get.back();
  }

  void resentEmail() {
    _emailSent.value = false;
    sentPasswordResetEmail();
  }

  String? validateEmail(String? value) {
    if (value?.isEmpty ?? true) {
      return "Please Enter Your Email";
    }
    if (!GetUtils.isEmail(value!)) {
      return "Please Enter Valid Email";
    }
    return null;
  }

  void _clearError() {
    _error.value = '';
  }
}
