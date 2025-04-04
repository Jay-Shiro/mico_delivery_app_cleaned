import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:micollins_delivery_app/components/m_orange_buttons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as path;

class ProfileEdit extends StatefulWidget {
  const ProfileEdit({super.key});

  @override
  State<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  // Replace nameEditController with separate controllers for first and last name
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneEditController = TextEditingController();
  final TextEditingController emailEditController = TextEditingController();

  String? firstName;
  String? lastName;
  String? userEmail;
  String? phone;
  String? userId;
  bool isLoading = false;
  bool isUploadingImage = false;
  double uploadProgress = 0.0;
  String? profileImageUrl;
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');

    if (userString != null) {
      final userData = json.decode(userString);
      setState(() {
        userEmail = userData['email'];
        firstName = userData['firstname'];
        lastName = userData['lastname'];
        phone = userData['phone'];
        userId = userData['_id']; // Store user ID
        profileImageUrl =
            userData['profile_picture_url']; // Get profile image if available
        // Update to use separate controllers
        firstNameController.text = firstName ?? '';
        lastNameController.text = lastName ?? '';
        emailEditController.text = userEmail ?? '';
        phoneEditController.text = phone ?? '';
      });

      // Debug print for user ID
      print('Debug - User ID in Profile Edit: $userId');
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();

    // Show image source selection dialog
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Select Image Source",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(0, 31, 62, 1),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildImageSourceOption(
                    icon: Icons.camera_alt,
                    label: "Camera",
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? photo =
                          await picker.pickImage(source: ImageSource.camera);
                      if (photo != null) {
                        setState(() {
                          selectedImage = File(photo.path);
                        });
                        _uploadProfilePicture(File(photo.path));
                      }
                    },
                  ),
                  _buildImageSourceOption(
                    icon: Icons.photo_library,
                    label: "Gallery",
                    onTap: () async {
                      Navigator.pop(context);
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setState(() {
                          selectedImage = File(image.path);
                        });
                        _uploadProfilePicture(File(image.path));
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 31, 62, 0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: const Color.fromRGBO(0, 31, 62, 1),
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color.fromRGBO(0, 31, 62, 1),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadProfilePicture(File imageFile) async {
    if (userId == null) {
      // Use a snackbar instead of dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("User ID not found. Cannot upload profile picture."),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isUploadingImage = true;
    });

    // Show a modern overlay loading indicator
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        child: Material(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      color: Color.fromRGBO(0, 31, 62, 1),
                      strokeWidth: 3,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Uploading profile picture...",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(0, 31, 62, 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);

    try {
      // Create a multipart request
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse(
            'https://deliveryapi-ten.vercel.app/users/$userId/profile-picture'),
      );

      // Add the image file
      var imageStream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();

      var multipartFile = http.MultipartFile(
        'profile_picture',
        imageStream,
        length,
        filename: path.basename(imageFile.path),
      );

      request.files.add(multipartFile);

      // Send the request
      var response = await request.send();

      // Get the response
      var responseData = await response.stream.bytesToString();
      var jsonResponse = json.decode(responseData);

      // Remove the overlay
      overlayEntry.remove();

      if (response.statusCode == 200) {
        // Update the stored user data with new profile picture URL
        final prefs = await SharedPreferences.getInstance();
        final userString = prefs.getString('user');

        if (userString != null) {
          final userData = json.decode(userString);
          userData['profile_picture_url'] = jsonResponse['profile_picture_url'];

          await prefs.setString('user', json.encode(userData));

          setState(() {
            profileImageUrl = jsonResponse['profile_picture_url'];
          });
        }

        // Show success snackbar instead of dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Profile picture updated successfully!",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Show error snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Failed to upload profile picture: ${response.statusCode}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      // Remove the overlay if it's still showing
      overlayEntry.remove();

      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "An error occurred: $e",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      setState(() {
        isUploadingImage = false;
      });
    }
  }

  Future<void> updateProfile() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("User ID not found. Cannot update profile."),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Get the values from text controllers
      String firstname = firstNameController.text.trim();
      String lastname = lastNameController.text.trim();
      String phone = phoneEditController.text.trim();

      // Check if any field has been changed
      bool hasChanges = false;
      if (firstname != firstName) hasChanges = true;
      if (lastname != lastName) hasChanges = true;
      if (phone != this.phone) hasChanges = true;

      if (!hasChanges) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.amber,
            content: Text("No changes to update."),
          ),
        );
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Create a multipart request to match the curl example
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('https://deliveryapi-ten.vercel.app/users/$userId/update'),
      );

      // Add form fields
      if (firstname.isNotEmpty) request.fields['firstname'] = firstname;
      if (lastname.isNotEmpty) request.fields['lastname'] = lastname;
      if (phone.isNotEmpty) request.fields['phone'] = phone;

      // Send the request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      print('Update response: ${response.statusCode}, ${response.body}');

      if (response.statusCode == 200) {
        // Update shared preferences
        final prefs = await SharedPreferences.getInstance();
        final userString = prefs.getString('user');

        if (userString != null) {
          final userData = json.decode(userString);

          // Update the user data in shared preferences
          if (firstname.isNotEmpty) userData['firstname'] = firstname;
          if (lastname.isNotEmpty) userData['lastname'] = lastname;
          if (phone.isNotEmpty) userData['phone'] = phone;

          await prefs.setString('user', json.encode(userData));

          // Update the state variables
          setState(() {
            firstName = firstname;
            lastName = lastname;
            this.phone = phone;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    "Profile updated successfully!",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );

        Navigator.pop(
            context, true); // Return true to indicate successful update
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    "Failed to update profile: ${response.statusCode} - ${response.body}",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      print('Update Profile Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  "An error occurred: $e",
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back, color: Color.fromRGBO(0, 31, 62, 1)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: Color.fromRGBO(0, 31, 62, 1),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // Profile picture section with camera icon
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color.fromRGBO(0, 31, 62, 0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: const Color.fromRGBO(0, 31, 62, 0.1),
                          radius: 60,
                          backgroundImage: profileImageUrl != null
                              ? NetworkImage(profileImageUrl!)
                              : null,
                          child: profileImageUrl == null
                              ? const Icon(
                                  Icons.person,
                                  size: 60,
                                  color: Color.fromRGBO(0, 31, 62, 0.5),
                                )
                              : null,
                        ),
                      ),
                      GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(0, 31, 62, 1),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Form fields
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'First Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(0, 31, 62, 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: firstNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your first name',
                          filled: true,
                          fillColor: const Color.fromRGBO(0, 31, 62, 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Last Name',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(0, 31, 62, 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: lastNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter your last name',
                          filled: true,
                          fillColor: const Color.fromRGBO(0, 31, 62, 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(0, 31, 62, 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: emailEditController,
                        enabled: false, // Email cannot be edited
                        decoration: InputDecoration(
                          hintText: 'Your email address',
                          filled: true,
                          fillColor: const Color.fromRGBO(0, 31, 62, 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Add phone field
                      const Text(
                        'Phone',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color.fromRGBO(0, 31, 62, 0.7),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: phoneEditController,
                        decoration: InputDecoration(
                          hintText: 'Enter your phone number',
                          filled: true,
                          fillColor: const Color.fromRGBO(0, 31, 62, 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 40),

                      // Replace MOrangeButton method call with the widget
                      ElevatedButton(
                        onPressed: isLoading ? null : updateProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(0, 31, 62, 1),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.0,
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
