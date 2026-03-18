import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ionicons/ionicons.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vaarta_app/Config/Constants.dart';
import 'package:vaarta_app/Config/WebSocket.dart';
import 'package:vaarta_app/Data/AccessTokenGenerator.dart';
import 'package:vaarta_app/Login_Logup/LoginPage.dart';
import 'package:vaarta_app/Providers/MenuIndexProvider.dart';
import 'package:vaarta_app/Providers/ThemeProvider.dart';
import 'package:vaarta_app/Providers/UserProvider.dart';
import "package:http/http.dart" as http;
import 'package:vaarta_app/Screens/AccountDelete.dart';
import 'package:vaarta_app/Screens/UploadProfile.dart';
class Settingsscreen extends StatefulWidget{
  @override
  State<Settingsscreen> createState() {
    return SettingsscreenState();
  }
}
class SettingsscreenState extends State<Settingsscreen>{
  final storage = FlutterSecureStorage();
  TextEditingController nameController = TextEditingController();
  TextEditingController statusController = TextEditingController();
  FocusNode _focusName = FocusNode();
  FocusNode _focusStatus = FocusNode();
  bool enableName = false;
  bool enableStatus = false;
  bool darkMode = true;

  @override
  void initState() {
    Future.microtask((){
      final userProvider =
      Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user != null) {
        nameController.text = userProvider.user!.name;
        statusController.text = userProvider.user!.status;
      }
    });
  }

  final ImagePicker _picker = ImagePicker();
  File? profileImage;
  // Future<void> pickFromGallery() async {
  //   try {
  //     // Pick image from gallery
  //     final XFile? image =
  //     await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
  //
  //     if (image == null) return; // User cancelled
  //
  //     profileImage = File(image.path);
  //
  //     // Read access token
  //     String? token = await storage.read(key: 'access_token');
  //     if (token == null) return;
  //
  //     final url = Uri.parse("${ApiConstant.baseUrl}/user/profile-image");
  //
  //     // Function to upload image
  //     Future<http.Response> uploadImage(String token) async {
  //       var request = http.MultipartRequest('POST', url);
  //       request.headers['Authorization'] = 'Bearer $token';
  //       request.files.add(
  //         await http.MultipartFile.fromPath(
  //           'profile_image', // Field name expected by backend
  //           profileImage!.path,
  //           contentType: http.MediaType('image', 'jpeg'), // adjust if PNG
  //         ),
  //       );
  //       var streamed = await request.send();
  //       return await http.Response.fromStream(streamed);
  //     }
  //
  //     http.Response response = await uploadImage(token);
  //
  //     // Handle token expiration
  //     if (response.statusCode == 401) {
  //       final refreshed = await accessTokenGenerator(context);
  //       if (!refreshed) return;
  //       token = await storage.read(key: 'access_token');
  //       if (token == null) return;
  //
  //       response = await uploadImage(token);
  //     }
  //
  //     // Check upload success
  //     if (response.statusCode == 200) {
  //       final res = jsonDecode(response.body);
  //       Provider.of<UserProvider>(context,listen: false).getDataFromServer(context);
  //       print('Image uploaded successfully: $res');
  //     } else {
  //       print('Upload failed: ${response.statusCode} - ${response.body}');
  //     }
  //
  //     // Update UI
  //     setState(() {});
  //   } catch (e) {
  //     print('Error picking/uploading image: $e');
  //   }
  // }

  Future<void> pickFromGallery() async {
    try {
      final XFile? image =
      await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80,);

      if (image == null) return;

      // Navigate to crop/upload screen and wait for result
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UploadProfile(image: image),
        ),
      );

      // result will be the updated image path
      if (result != null) {
        setState(() {
          profileImage = File(result);
        });
      }

    } catch (e) {
      print('Error picking image: $e');
    }
  }

  Future<bool> requestCameraPermission() async {
    var status = await Permission.camera.status;

    if (status.isDenied || status.isRestricted) {
      status = await Permission.camera.request();
    }

    return status.isGranted;
  }

  Future<void> showCameraPermissionDeniedDialog(BuildContext context) async {
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Prevent dismiss by tapping outside
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          title: const Text(
            "Permission Required",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "We need access to your camera to take profile photos. "
                "Please allow camera permission from settings.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Open Settings
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                "Open Settings",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    // If user pressed "Open Settings", launch app settings
    if (shouldOpenSettings == true) {
      openAppSettings();
    }
  }


  Future<void> pickFromCamera() async {
    if (!await requestCameraPermission()) {
      await showCameraPermissionDeniedDialog(context);
      return;
    }
    try {
      final XFile? image =
      await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);

      if (image == null) return;

      // Navigate to UploadProfile for cropping and uploading
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UploadProfile(image: image),
        ),
      );

      // result will be the updated/cropped image path
      if (result != null) {
        setState(() {
          profileImage = File(result);
        });
      }
    } catch (e) {
      print('Error picking image from camera: $e');
    }
  }

  String formatIndianMobile(String mobile) {
    // Remove any spaces
    final cleaned = mobile.replaceAll(' ', '');

    // Expecting +91XXXXXXXXXX
    if (!cleaned.startsWith('+91') || cleaned.length != 13) {
      return mobile; // fallback if format is unexpected
    }

    final countryCode = cleaned.substring(0, 3); // +91
    final firstPart = cleaned.substring(3, 8);   // 89686
    final secondPart = cleaned.substring(8, 13); // 97564

    return '$countryCode $firstPart $secondPart';
  }

  Future<String> saveChanges(String type,String value) async {
    final userProvider = Provider.of<UserProvider>(context,listen: false).user;
    if(type == "name" || type == "status"){
      if(type == "name"){
        value = value.trim();
        if (value.trim().isEmpty) {
          nameController.text = userProvider!.name;
          return 'Name is required';
        }
        if(value.trim().length < 2){
          return "Name must have least two characters";
        }
        if(value == Provider.of<UserProvider>(context,listen: false).user?.name){
          nameController.text = userProvider!.name;
          return 'No changes detected';
        }
      }
      if(type == "status"){
        if(value.trim().isEmpty){
          statusController.text = userProvider!.status;
          return "Status is required";
        }
        if(value.trim().length < 2){
          return "Status should be least 2 characters long";
        }
        if(value == Provider.of<UserProvider>(context,listen: false).user?.status){
          statusController.text = userProvider!.status;
          return 'No changes detected';
        }
      }
      try{
        String? token = await storage.read(key: 'access_token');
        final uri = Uri.parse("${ApiConstant.baseUrl}/user/update-user");
        http.Response response = await http.put(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              "Content-Type":"application/json"
            },
            body: jsonEncode({type:value})
        );
        if(response.statusCode == 401){
          final refreshed = await accessTokenGenerator(context);
          if (!refreshed) return "Failed to generate token";
          token = await storage.read(key: "access_token");
          if(token==null)return "No token found";
          response = await http.put(
              uri,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
              body: jsonEncode({type:value})
          );
        }
        final data = jsonDecode(response.body);
        if(response.statusCode == 200){
          Provider.of<UserProvider>(context,listen: false).getDataFromServer(context);
        }
        if(response.statusCode != 200){
          nameController.text = userProvider!.name;
        }
        return data['message'];
      }catch(e){
        nameController.text = userProvider!.name;
        return "Failed to save changes";
      }
    }
    return "Invalid update type";
  }


  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text("Settings",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600,),),
            automaticallyImplyLeading: false,
          ),
          body: SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.all(20),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20,
                children: [
                  Text("Profile",style: TextStyle(fontSize: 18,color: Theme.of(context).colorScheme.onSurface,fontWeight: FontWeight.w500),),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: GestureDetector(
                        onTap: () => showDpOptions(context),
                        child: Stack(
                            clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundImage: profileImage != null
                                  ? FileImage(profileImage!) // show new image immediately
                                  : (userProvider.user?.profileImage != null &&
                                  userProvider.user!.profileImage!.isNotEmpty
                                  ? NetworkImage(userProvider.user!.profileImage!)
                                  : NetworkImage("https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSOH2aZnIHWjMQj2lQUOWIL2f4Hljgab0ecZQ&s")) as ImageProvider,
                            ),
                            Positioned(
                              bottom: -1,
                              right: -2,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ]
                        ),
                      ),
                    ),
                  ),
                  Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Name",style: TextStyle(fontSize: 18,color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()) // dark mode opacity
                          : Theme.of(context).colorScheme.onSurface,),),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: nameController,
                              focusNode: _focusName,
                              enabled: enableName,
                              onSubmitted: (value) async {
                                String? message = await saveChanges("name", value);

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      message,
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Theme.of(context).colorScheme.onSurface.withAlpha((0.9 * 255).round())
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                );

                                setState(() => enableName = false);
                                _focusName.unfocus(); // hide keyboard
                              },
                              onTapOutside:(event) async {
                                // _focusName.unfocus();       // hide keyboard
                                String? message = await saveChanges("name",nameController.text);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message,)),
                                  );
                                });
                                setState(() => enableName = false);
                              },
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.onSurface.withAlpha((0.9 * 255).round()) // dark mode slightly transparent
                                    : Theme.of(context).colorScheme.onSurface, // light mode full color
                              ),
                              decoration: InputDecoration(
                              ),
                            ),
                          ),
                          IconButton(onPressed: (){
                            setState(() {
                              enableName = true;
                            });
                            // Step 2: request focus after rebuild
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _focusName.requestFocus();
                            });
                            },icon: Icon(Icons.edit,size: 22,))
                        ],
                      )
                    ],
                  ),
                  Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Status",style: TextStyle(fontSize: 18,color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()) // dark mode opacity
                          : Theme.of(context).colorScheme.onSurface,),),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: statusController,
                              focusNode: _focusStatus,
                              enabled: enableStatus,
                              onSubmitted: (value) async {
                                String? message = await saveChanges("status", value);

                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      message,
                                      style: TextStyle(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Theme.of(context).colorScheme.onSurface.withAlpha((0.9 * 255).round())
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                );

                                setState(() => enableStatus = false);
                                _focusStatus.unfocus(); // hide keyboard
                              },
                              onTapOutside:(event) async {
                                String? message = await saveChanges("status",statusController.text);
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message,)),
                                  );
                                });
                                setState(() => enableStatus = false); // hide emoji picker
                              },
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.onSurface.withAlpha((0.9 * 255).round()) // dark mode slightly transparent
                                    : Theme.of(context).colorScheme.onSurface, // light mode full color
                              ),
                              decoration: InputDecoration(
                              ),
                            ),
                          ),
                          IconButton(onPressed: (){
                            setState(() {
                              enableStatus = true;
                            });
                            // Step 2: request focus after rebuild
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _focusStatus.requestFocus();
                            });
                          },icon: Icon(Icons.edit,size: 22,))
                        ],
                      )
                    ],
                  ),
                  Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Phone",style: TextStyle(fontSize: 18,color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()) // dark mode opacity
                          : Theme.of(context).colorScheme.onSurface,),),
                      Row(
                        spacing: 20,
                        children: [
                          Icon(Icons.phone,size: 24,),
                          Text(
                            userProvider.user?.mobile != null
                                ? formatIndianMobile(userProvider.user!.mobile)
                                : '',
                            style: const TextStyle(fontSize: 18,),
                          ),
                        ],
                      )
                    ],
                  ),
                  Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email",style: TextStyle(fontSize: 18,color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()) // dark mode opacity
                          : Theme.of(context).colorScheme.onSurface,),),
                      Row(
                        spacing: 20,
                        children: [
                          Icon(Icons.email,size: 24,),
                          Text(
                            (userProvider.user?.email?.isEmpty ?? true)
                                ? "Not added"
                                : userProvider.user!.email!,
                            style: TextStyle(fontSize: 18, color: Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()) // dark mode opacity
                                : Theme.of(context).colorScheme.onSurface,),
                          )],
                      )
                    ],
                  ),
                  Text("Theme",style: TextStyle(fontSize: 18,color: Theme.of(context).colorScheme.onSurface,fontWeight: FontWeight.w500),),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Dark mode",style: TextStyle(fontSize: 18,color: Theme.of(context).brightness == Brightness.dark
                          ? Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()) // dark mode opacity
                          : Theme.of(context).colorScheme.onSurface,),),
                      Switch(
                        activeThumbColor: Colors.white,
                        activeTrackColor: Colors.blue,
                        value: Provider.of<ThemeProvider>(context).isDarkMode, // get value from provider
                        onChanged: (value) {
                          Provider.of<ThemeProvider>(context, listen: false).toggleTheme(value); // update provider
                        },
                      )
                    ],
                  ),
                  Text("Change Details",style: TextStyle(fontSize: 18,color: Theme.of(context).colorScheme.onSurface,fontWeight: FontWeight.w500),),
                  Text("Change phone number",style: TextStyle(fontSize: 18,color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()) // dark mode opacity
                      : Theme.of(context).colorScheme.onSurface,),),
                  Text("Change email address",style: TextStyle(fontSize: 18,color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()) // dark mode opacity
                      : Theme.of(context).colorScheme.onSurface,),),
                  Text("Change password",style: TextStyle(fontSize: 18,color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()) // dark mode opacity
                      : Theme.of(context).colorScheme.onSurface,),),
                  Text("Session",style: TextStyle(fontSize: 18,color: Theme.of(context).colorScheme.onSurface,fontWeight: FontWeight.w500),),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                    child: ElevatedButton(
                      onPressed: () async {
                        confirmAndLogout();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).brightness == Brightness.dark
                            ? Colors.red.shade800.withAlpha(220)   // dark mode, semi-transparent red
                            : Colors.red.shade400,                 // light mode, solid red
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Log out",
                            style: TextStyle(
                              fontSize: 15,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.shade200       // lighter red on dark background
                                  : Colors.white,            // white text on red button in light mode
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Ionicons.log_out,
                            color: Theme.of(context).brightness == Brightness.dark
                                ? Colors.red.shade200
                                : Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                      child: ElevatedButton(
                        onPressed: () async {
                          confirmDeleteAccount();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.red.shade900.withAlpha(220)  // dark mode, semi-transparent deep red
                              : Colors.red.shade500,                // light mode, solid red
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Delete account",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.red.shade300 // lighter red for dark mode
                                    : Colors.white,      // white text on red for light mode
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Ionicons.person_remove,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.red.shade300
                                  : Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            ),
          ),
        )
    );
  }

  Future<void> confirmAndLogout() async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // or any radius you want
          ),
          title: Text("Logout",style: TextStyle(fontSize:18,color: Theme.of(context).colorScheme.onSurface),),
          content: Text("Are you sure you want to logout?",style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text("Cancel",style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text("Logout",style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return; // User cancelled
    final socketService = SocketService.instance;
    socketService.disconnect();
    await storage.deleteAll();
    context.read<MenuindexProvider>().setIndex(0);
    // await deleteDeviceTokenFromBackend();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Loginpage()));
  }

  Future<void> confirmDeleteAccount() async {
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // or any radius you want
          ),
          title: Text("Delete Account",style: TextStyle(fontSize:18,color: Theme.of(context).colorScheme.onSurface),),
          content: Text("Are you sure you want to delete your account?",style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Cancel
              child: Text("Cancel",style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text("Delete",style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return; // User cancelled
    Navigator.push(context, MaterialPageRoute(builder: (_)=>DeleteAccountScreen()));
  }

  Future<void> deleteDeviceTokenFromBackend() async {
    final storage = FlutterSecureStorage();
    String? accessToken = await storage.read(key: "access_token");

    if (accessToken == null) return;

    final url = Uri.parse("${ApiConstant.baseUrl}/user/delete-device-token");

    final body = {
      "platform": "android", // or "ios"
    };

    try {
      http.Response response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $accessToken"
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        print("Device token deleted successfully!");
      } else {
        print("Failed to delete device token: ${response.body}");
      }
    } catch (e) {
      print("Error deleting device token: $e");
    }
  }

  Future<void> confirmAndRemoveDP() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.black,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        title: const Text(
          "Remove Profile Picture",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to remove your profile picture?",
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel",
                style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text("Remove",
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final success = await removeProfilePicture();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? "Profile picture removed successfully"
              : "Failed to remove profile picture",
        ),
      ),
    );

    if (success) {
      context.read<UserProvider>().getDataFromServer(context);
    }
    setState(() {
      profileImage = null;
    });
  }

  Future<bool> removeProfilePicture() async {
    try {
      String? token = await storage.read(key: 'access_token');
      if (token == null) return false;

      final url =
      Uri.parse("${ApiConstant.baseUrl}/user/remove-profile-image");

      Future<http.Response> deleteWithToken(String token) {
        return http.delete(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
        );
      }

      http.Response response = await deleteWithToken(token);

      // Handle 401 (token expired)
      if (response.statusCode == 401) {
        final refreshed = await accessTokenGenerator(context);
        if (!refreshed) return false;

        token = await storage.read(key: 'access_token');
        if (token == null) return false;

        response = await deleteWithToken(token);
      }

      return response.statusCode == 200;

    } catch (e) {
      print("Delete error: $e");
      return false;
    }
  }


  void showDpOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor
          ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final userProvider = context.watch<UserProvider>();

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (userProvider.user?.profileImage != null)
                if(userProvider.user!.profileImage.isNotEmpty)
                ListTile(
                  leading: Icon(
                    Icons.person,
                    color: colorScheme.onSurface,
                  ),
                  title: Text(
                    "Remove Profile",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    confirmAndRemoveDP();
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.camera_alt,
                  color: colorScheme.onSurface,
                ),
                title: Text(
                  "Camera",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  pickFromCamera();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.photo,
                  color: colorScheme.onSurface,
                ),
                title: Text(
                  "Gallery",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  pickFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}


