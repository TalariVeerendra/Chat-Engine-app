import 'package:chat_app/controllers/chat_controller.dart';
import 'package:chat_app/controllers/friend_requests_controller.dart';
import 'package:chat_app/controllers/friends_controller.dart';
import 'package:chat_app/controllers/home_controller.dart';
import 'package:chat_app/controllers/main_controller.dart';
import 'package:chat_app/controllers/notification_controller.dart';
import 'package:chat_app/controllers/profile_controller.dart';
import 'package:chat_app/controllers/users_list_controller.dart';
import 'package:chat_app/routes/app_routes.dart';
import 'package:chat_app/views/auth/forgot_password_view.dart';
import 'package:chat_app/views/auth/login_view.dart';
import 'package:chat_app/views/chat_view.dart';
import 'package:chat_app/views/find_people_view.dart';
import 'package:chat_app/views/friend_requests_view.dart';
import 'package:chat_app/views/friends_view.dart';
import 'package:chat_app/views/home_view.dart';
import 'package:chat_app/views/notification_view.dart';
import 'package:chat_app/views/profile/change_password_view.dart';
import 'package:chat_app/views/profile/profile_view.dart';
import 'package:chat_app/views/main_view.dart';
import 'package:chat_app/views/auth/register_view.dart';
import 'package:chat_app/views/splash_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/route_manager.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => SplashView()),
    GetPage(name: AppRoutes.login, page: () => LoginView()),
    GetPage(name: AppRoutes.register, page: () => RegisterView()),
    GetPage(name: AppRoutes.forgotPassword, page: () => ForgotPasswordView()),
    GetPage(name: AppRoutes.changePassword, page: () => ChangePasswordView()),
    GetPage(
      name: AppRoutes.home,
      page: () => HomeView(),
      binding: BindingsBuilder(() {
        Get.put(HomeController());
      }),
    ),
    GetPage(
      name: AppRoutes.main,
      page: () => MainView(),
      binding: BindingsBuilder(() {
        Get.put(MainController());
      }),
    ),
    GetPage(
      name: AppRoutes.profile,
      page: () => ProfileView(),
      binding: BindingsBuilder(() {
        Get.put(ProfileController());
      }),
    ),
    GetPage(
      name: AppRoutes.chat,
      page: () => ChatView(),
      binding: BindingsBuilder(() {
        Get.put(ChatController());
      }),
    ),
    GetPage(
      name: AppRoutes.userList,
      page: () => FindPeopleView(),
      binding: BindingsBuilder(() {
        Get.put(UsersListController());
      }),
    ),
    GetPage(
      name: AppRoutes.friends,
      page: () => FriendsView(),
      binding: BindingsBuilder(() {
        Get.put(FriendsController());
      }),
    ),
    GetPage(
      name: AppRoutes.friendRequest,
      page: () => FriendRequestsView(),
      binding: BindingsBuilder(() {
        Get.put(FriendRequestsController());
      }),
    ),
    GetPage(
      name: AppRoutes.notifications,
      page: () => NotificationView(),
      binding: BindingsBuilder(() {
        Get.put(NotificationController());
      }),
    ),
  ];
}
