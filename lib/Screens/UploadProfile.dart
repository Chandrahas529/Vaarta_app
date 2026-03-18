import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:vaarta_app/Config/Constants.dart';
import 'package:vaarta_app/Data/AccessTokenGenerator.dart';
import 'package:vaarta_app/Providers/UserProvider.dart';

class UploadProfile extends StatefulWidget {
  final XFile image;
  const UploadProfile({Key? key, required this.image}) : super(key: key);

  @override
  State<UploadProfile> createState() => _UploadProfileState();
}

class _UploadProfileState extends State<UploadProfile> {
  final storage = const FlutterSecureStorage();
  late File currentImage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    currentImage = File(widget.image.path); // Preview immediately
    Future.microtask(() => cropImage());
  }

  /// Pick and Crop image
  Future<void> cropImage() async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: currentImage.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Profile',           // Text in AppBar
          backgroundColor: Color(0xff09090e),
          toolbarColor: Color(0xff09090e),             // AppBar background color
          toolbarWidgetColor: Colors.white,       // Back button & text color
          statusBarColor: Colors.green.shade700,  // Status bar color
          activeControlsWidgetColor: Colors.blue, // Crop box/controls
          dimmedLayerColor: Color(0xff09090e),
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
      ],
    );

    if (croppedFile != null && mounted) {
      setState(() {
        currentImage = File(croppedFile.path);
      });
    }
  }

  /// Upload image to server
  Future<void> uploadImage() async {
    setState(() => isLoading = true);

    try {
      String? token = await storage.read(key: 'access_token');
      if (token == null) return;

      final url = Uri.parse("${ApiConstant.baseUrl}/user/profile-image");

      // Function to upload image
      Future<http.Response> uploadWithToken(String token) async {
        var request = http.MultipartRequest('POST', url);
        request.headers['Authorization'] = 'Bearer $token';
        request.files.add(
          await http.MultipartFile.fromPath(
            'profile_image',
            currentImage.path,
          ),
        );

        var streamed = await request.send();
        return await http.Response.fromStream(streamed);
      }

      // Initial upload attempt
      http.Response response = await uploadWithToken(token);

      // Handle token expiration (401)
      if (response.statusCode == 401) {
        final refreshed = await accessTokenGenerator(context); // Your token refresh function
        if (!refreshed) return;

        token = await storage.read(key: 'access_token');
        if (token == null) return;

        response = await uploadWithToken(token);
      }

      // Check upload success
      if (response.statusCode == 200) {
        final res = jsonDecode(response.body);
        Provider.of<UserProvider>(context, listen: false).getDataFromServer(context);
        Navigator.pop(context,currentImage.path); // Go back after successful upload
      } else {
        print('Upload failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print("Upload error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double avatarRadius = 80;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Profile Photo",
          style: TextStyle(fontSize: 18),
        ),
        elevation: 0,
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: avatarRadius,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: FileImage(currentImage),
                ),
                GestureDetector(
                  onTap: cropImage,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: isLoading ? null : uploadImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Save",
                    style: TextStyle(fontSize: 16,color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
