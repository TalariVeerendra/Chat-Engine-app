// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:chat_app/controllers/profile_photo_controller.dart';
// import 'package:chat_app/controllers/auth_controller.dart';

// class ProfilePhotoWidget extends StatelessWidget {
//   final controller = Get.put(ProfilePhotoController());
//   final authController = Get.find<AuthController>();

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       final user = authController.currentUser.value;

//       return Stack(
//         alignment: Alignment.center,
//         children: [
//           // PROFILE PHOTO
//           CircleAvatar(
//             radius: 60,
//             backgroundImage: user?.photoUrl != null
//                 ? NetworkImage(user!.photoUrl!)
//                 : AssetImage("assets/default_avatar.png") as ImageProvider,
//           ),

//           // LOADING INDICATOR
//           if (controller.isUploadingPhoto.value)
//             Positioned(
//               bottom: 0,
//               right: 0,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 color: Colors.white,
//               ),
//             ),

//           // CAMERA BUTTON
//           Positioned(
//             bottom: 0,
//             right: 0,
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.blue,
//                 borderRadius: BorderRadius.circular(30),
//                 border: Border.all(color: Colors.white, width: 2),
//               ),
//               child: IconButton(
//                 icon: Icon(Icons.camera_alt, color: Colors.white, size: 22),
//                 onPressed: () => controller.updateProfilePhoto(),
//               ),
//             ),
//           ),
//         ],
//       );
//     });
//   }
// }
