import 'package:chat_app/models/user_model.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuthController extends GetxController {
  final AuthService _authServices = AuthService();
  final Rx<User?> _user = Rx<User?>(null);
  final Rx<UserModel?> _userModel = Rx<UserModel?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _error = ''.obs;
  final RxBool _isintialized = false.obs;

  
  User? get user => _user.value;
  UserModel? get userModel => _userModel.value;
  bool get isLoading => _isLoading.value;
  String get error => _error.value;
  bool get isAuthenticated => _user.value != null;
  bool get isintialized => _isintialized.value;

  @override
  void onInit() {
    super.onInit();
    _user.bindStream(_authServices.authStateChanges);
    ever(_user, _handleAuthStateChange);
  }

  void _handleAuthStateChange(User? user) {
    if (user == null) {
      if (Get.currentRoute != AppRoutes.login) {
        Get.offAllNamed(AppRoutes.login);
      }
    } else {
      if (Get.currentRoute != AppRoutes.main) {
        Get.offAllNamed(AppRoutes.profile);
      }
    }
    if (!_isintialized.value) {
      _isintialized.value = true;
    }
  }

  void checkIntialAuthState() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      _user.value = currentUser;
      Get.offAllNamed(AppRoutes.main);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
    _isintialized.value = true;
  }

  Future<void> signInWithEmailandPassword(String email, String password) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      UserModel? userModel = await _authServices.signInWithEmailandPassword(
        email,
        password,
      );
      if (userModel != null) {
        _userModel.value = userModel;
        Get.offAllNamed(AppRoutes.main);
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to Login');
      print(e);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> registerWithEmailandPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      _isLoading.value = true;
      _error.value = '';

      UserModel? userModel = await _authServices.registerWithEmailandPassword(
        email,
        password,
        displayName,
      );
      if (userModel != null) {
        _userModel.value = userModel;
        Get.offAllNamed(AppRoutes.main);
      }
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to Create Account');
      print(e);
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading.value = true;
      await _authServices.signOut();
      _userModel.value = null;
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to SignOut');
    } finally {
      _isLoading.value = false;
    }
  }

  Future<void> deleteAccount() async {
    try {
      _isLoading.value = true;
      await _authServices.deleteAccount();
      _userModel.value = null;
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      _error.value = e.toString();
      Get.snackbar('Error', 'Failed to Delete Account');
    } finally {
      _isLoading.value = false;
    }
  }

  void clearError() {
    _error.value = '';
  }
}
