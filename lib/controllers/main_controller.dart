import 'package:chat_app/controllers/friends_controller.dart';
import 'package:chat_app/controllers/home_controller.dart';
import 'package:chat_app/controllers/profile_controller.dart';
import 'package:chat_app/controllers/users_list_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class MainController extends GetxController {
  final RxInt _currentIndex = 0.obs;
  final PageController pageController = PageController();

  int get currentIndex => _currentIndex.value;

  @override
  void onInit() {
    super.onInit();
    // Init all required controllers
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => FriendsController());
    Get.lazyPut(() => UsersListController());
    Get.lazyPut(() => ProfileController());
  }

  @override
  void onClose() {
    super.onClose();
    pageController.dispose();
  }

  void changeTabIndex(int index) {
    _currentIndex.value = index;
    pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  void onPageChanged(int index) {
    _currentIndex.value = index;
  }

  int getUnreadCount() {
    try {
      final homeController = Get.find<HomeController>();
      return homeController.getTotalUnreadCount();

    } catch (e) {
      return 0;
    }
  }

  int getNotificationCount() {
    try {
      final homeController = Get.find<HomeController>();
      return homeController.getUnreadNotificationsCount();

    } catch (e) {
      return 0;
    }
  }
}
