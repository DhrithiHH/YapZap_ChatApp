import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class UserProfilePage extends StatelessWidget {
  final String userId;
  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("User not found"));
          }

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          String? email = userData['email'];
          String? username = userData['username'];
          String? bio = userData['bio'];
          String? profilePic = userData['profilePic'];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture Section
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: profilePic != null && profilePic.isNotEmpty
                              ? NetworkImage(profilePic) as ImageProvider
                              : const AssetImage('assets/images/yapzap_logo.png'),
                        ),
                        if (profilePic == null || profilePic.isEmpty) ...[
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFFFB0FE), // Pink Button
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white),
                                onPressed: () {
                                  _showPhotoOptions(context);
                                },
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  // User Info Section
                  UserInfoField(label: "Name", value: userData['username'] ?? "Not Available"),
                  const Divider(height: 30, thickness: 1),
                  UserInfoField(label: "Username", value: username ?? "Not Available"),
                  const Divider(height: 30, thickness: 1),
                  UserInfoField(label: "About", value: bio ?? "Not Available"),
                  const Divider(height: 30, thickness: 1),
                  UserInfoField(label: "Email ID", value: email ?? "Not Available"),
                  const Divider(height: 30, thickness: 1),

                  // Settings Section
                  const SizedBox(height: 30),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Settings",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 15),
                  ListTile(
                    leading: const Icon(Icons.account_circle, color: Colors.black),
                    title: const Text("Account"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/account_settings');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.privacy_tip, color: Colors.black),
                    title: const Text("Privacy"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pushNamed(context, '/privacy_settings');
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showPhotoOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Take Photo"),
                onTap: () async {
                  XFile? image = await _pickImage(ImageSource.camera);
                  if (image != null) {
                    _uploadImage(image);
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text("Choose from Gallery"),
                onTap: () async {
                  XFile? image = await _pickImage(ImageSource.gallery);
                  if (image != null) {
                    _uploadImage(image);
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Remove Photo", style: TextStyle(color: Colors.red)),
                onTap: () {
                  _removeProfilePic();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<XFile?> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    return await picker.pickImage(source: source);
  }

  // Upload image to Firebase Storage and update Firestore
  Future<void> _uploadImage(XFile image) async {
    try {
      // Create a reference to Firebase Storage
      String fileName = 'profile_pics/${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
      await storageRef.putFile(File(image.path));

      // Get the download URL of the uploaded image
      String downloadUrl = await storageRef.getDownloadURL();

      // Update Firestore with the image URL
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'profilePic': downloadUrl,
      });
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  // Remove profile picture from Firebase Storage and Firestore
  Future<void> _removeProfilePic() async {
    try {
      // Get the current profile picture URL
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      String? currentPic = userDoc['profilePic'];

      if (currentPic != null && currentPic.isNotEmpty) {
        // Delete the image from Firebase Storage
        Reference storageRef = FirebaseStorage.instance.refFromURL(currentPic);
        await storageRef.delete();

        // Remove the profilePic field from Firestore
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'profilePic': FieldValue.delete(),
        });
      }
    } catch (e) {
      print("Error removing photo: $e");
    }
  }
}

// Reusable User Info Field Widget
class UserInfoField extends StatelessWidget {
  final String label;
  final String value;

  const UserInfoField({Key? key, required this.label, required this.value})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
