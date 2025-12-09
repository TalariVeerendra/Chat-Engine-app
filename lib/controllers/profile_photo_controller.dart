// import 'dart:io';
// import 'package:get/get.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// import 'package:chat_app/controllers/auth_controller.dart';

// class ProfilePhotoController extends GetxController {
//   final ImagePicker _picker = ImagePicker();
//   final AuthController _authController = Get.find<AuthController>();

//   var isUploadingPhoto = false.obs;

//   Future<void> updateProfilePhoto() async {
//     try {
//       // Pick image
//       final XFile? picked = await _picker.pickImage(
//         source: ImageSource.gallery,
//       );
//       if (picked == null) return;

//       isUploadingPhoto.value = true;

//       final userId = _authController.user!.uid;
//       final file = File(picked.path);

//       // Upload to Firebase Storage
//       final storageRef = FirebaseStorage.instance
//           .ref()
//           .child('profile_photos')
//           .child('$userId.jpg');

//       await storageRef.putFile(file);

//       // Get photo URL
//       final photoUrl = await storageRef.getDownloadURL();
//       final currentUserId = _authController.user?.uid;

//       // Update Firestore
//       await FirebaseFirestore.instance.collection('users').doc(userId).update({
//         'photoUrl': photoUrl,
//       });

//       // Update UI instantly
//       _authController.currentUserId.update((user) {
//         user?.photoUrl = photoUrl;
//       });

//       Get.snackbar("Success", "Profile photo updated");
//     } catch (e) {
//       Get.snackbar("Error", e.toString());
//     } finally {
//       isUploadingPhoto.value = false;
//     }
//   }
// }
