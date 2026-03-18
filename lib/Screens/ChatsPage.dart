import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:vaarta_app/Config/Constants.dart';
import 'package:vaarta_app/Config/LocalNotification.dart';
import 'package:vaarta_app/Config/WebSocket.dart';
import 'package:vaarta_app/Data/AccessTokenGenerator.dart';
import 'package:vaarta_app/Login_Logup/LoginPage.dart';
import 'package:vaarta_app/PermissionHelper/ContactPermission.dart';
import 'package:vaarta_app/Providers/ContactsProvider.dart';
import 'package:vaarta_app/Providers/UserProvider.dart';
import 'package:vaarta_app/Screens/Camera.dart';
import 'package:vaarta_app/Screens/UploadProfile.dart';
import 'package:vaarta_app/Screens/UserChatPage.dart';
import 'package:vaarta_app/Providers/ChatOptionProvider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:http/http.dart' as http;
import 'package:vaarta_app/main.dart';

class Chatspage extends StatefulWidget{
  @override
  State<Chatspage> createState() => _ChatspageState();
}

class _ChatspageState extends State<Chatspage> {
  final storage = FlutterSecureStorage();
  final ImagePicker _picker = ImagePicker();


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
    await deleteDeviceTokenFromBackend();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>Loginpage()));
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
    } catch (e) {
      print('Error picking image from camera: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text("VAarta",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
        // backgroundColor: Color(0xff09090e),
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: IconButton(onPressed:(){pickFromCamera();},icon: Icon(Icons.camera_alt_outlined,size: size*0.030,)),
          ),
          PopupMenuButton(
            // iconColor: Colors.white,
              iconSize: 26,
              // color: Colors.black,
              itemBuilder: (context) => [
                PopupMenuItem(
                  padding: EdgeInsets.all(0),
                  child: TextButton(
                      onPressed: () {
                        confirmAndLogout();
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.all(0)
                        // backgroundColor: Color(0xff09090e)
                      ),
                      child: Row(
                        spacing: 6,
                        children: [
                          IconButton(onPressed: (){}, icon:Icon(Icons.logout,size: 20),),
                          Text("Log out",style: TextStyle(fontSize: 16),)
                        ],
                      ),
                    ),
                )
              ]
          )
        ],
      ),
      body: ChatsList(),
    );
  }
}

class ChatsList extends StatefulWidget {
  @override
  State<ChatsList> createState() => _ChatsListState();
}

class _ChatsListState extends State<ChatsList> with RouteAware{
  final storage = FlutterSecureStorage();
  List<dynamic> messageByUsers = [];
  bool isLoading = false;
  List<Map<String,dynamic>> allContacts = [];
  List<Map<String, dynamic>> contactsFromPhone = [];
  late Future<List<dynamic>> getListOfMessage;
  late Future<List<Map<String,String>>> contacts;
  bool _contactsInitialized = false;

  Future<void> refreshChats() async {
    setState(() {
      if(messageByUsers.isEmpty){
        isLoading = true; // show loader
      }
    });

    try {
      final messages = await getChat();
      setState(() {
        messageByUsers = messages;
      });
    } catch (e) {
      print("Error refreshing chats: $e");
    } finally {
      setState(() {
        isLoading = false; // hide loader
      });
    }
  }

  @override
  void initState() {
    super.initState();
    isLoading = true;
    getPermission();
    SocketService.instance.onChatListUpdate = handleChatListUpdate;
  }

  void getPermission() async {
    final granted = await requestContactsPermission();
    if (!granted) {
      setState(() {
        isLoading = false;
      });
      return ;
    }
    await loadContactsOnStartup(granted: granted);

    Provider.of<ContactsProvider>(context, listen: false)
        .getContactNumbers(context, granted: granted);
  }

  void handleChatListUpdate(Map<String, dynamic> data) {
    final update = data["data"];
    if (!mounted) return;

    // 1️⃣ Normalize conversationId
    final senderId = update["lastMessage"]["senderId"].toString();
    final receiverId = update["lastMessage"]["receiverId"].toString();
    final sortedIds = [senderId, receiverId]..sort();
    final String socketConversationId = sortedIds.join('_');
    // 2️⃣ Display name from contacts
    final Map<String, String> phoneToName = {
      for (var contact in allContacts) contact['normalizedPhone']: contact['name']
    };
    final mobile = update["otherUser"]?["mobile"];
    update["displayName"] = phoneToName[mobile] ?? update["otherUser"]?["name"] ?? "";

    // 3️⃣ Ensure messages array exists
    update["messages"] ??= [update["lastMessage"]];

    setState(() {
      final index = messageByUsers.indexWhere((chat) {
        final ids = chat["conversationId"].toString().split('_')..sort();
        final normalizedExistingId = ids.join('_');
        return normalizedExistingId == socketConversationId;
      });


      if (index != -1) {
        // Existing chat → merge
        final existingChat = messageByUsers[index];
        existingChat["lastMessage"] = update["lastMessage"];
        existingChat["unreadCount"] = (existingChat["unreadCount"] ?? 0) + 1;
        existingChat["messages"] ??= [];

        final alreadyExists = existingChat["messages"].any(
              (m) => m["messageAt"] == update["lastMessage"]["messageAt"],
        );
        if (!alreadyExists) {
          existingChat["messages"].add(update["lastMessage"]);
        }

        // Move to top
        messageByUsers.removeAt(index);
        messageByUsers.insert(0, existingChat);
      } else {
        // New conversation → add
        update["unreadCount"] = 1;
        messageByUsers.insert(0, update);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final provider = context.watch<ContactsProvider>();

    if (provider.contacts.isNotEmpty && !_contactsInitialized) {
      allContacts = provider.contacts;  // store AFTER load
      _contactsInitialized = true;

      refreshChats(); // now safe to load chats
    }
  }


  Future<List<dynamic>> getChat() async {
    getPermission();
      String? token = await storage.read(key: "access_token");
      if (token == null) {
        print("Token not found");
        return [];
      }

      final url = Uri.parse("${ApiConstant.baseUrl}/message/chat-with-all");

      try {
        http.Response response = await http.get(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
        );

        if (response.statusCode == 401) {
          final refreshed = await accessTokenGenerator(context);
          if (!refreshed) return [];
          token = await storage.read(key: "access_token");
          if (token == null) return [];
          response = await http.get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          );
        }
        if (response.statusCode == 200) {
          final List<dynamic> res = jsonDecode(response.body);
          for (final element in res) {
            for (final contact in allContacts) {
              final name = contact['name'] ?? "";
              final normalized = contact['normalizedPhone'] ?? "";
              if (normalized == element['otherUser']['mobile']) {
                element['displayName'] = name;
                break; // stop after first match
              }
            }
          }
          return res;
        }
        else {
          print("Error: ${response.body}");
          return [];
        }
      } catch (e) {
        print("Exception in getChat: $e");
        return [];
      }
  }

  List<String> topList = [
      "All",
      "Unread 13",
      "Group 1",
      "Group 2",
      "Group 3",
      "Group 4",
  ];

  @override
  void dispose() {
    super.dispose();
    SocketService.instance.onChatListUpdate = null;
  }


  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,//Color(0xff09090e),
      child: Column(
        children: [
          SizedBox(height: 10,),
          Container(
            //color: Color(0xff09090e),
            padding: EdgeInsets.symmetric(horizontal: 10,vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                spacing: 5,
                children: topList.map((list)=>
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurface.withAlpha((0.12 * 255).round()) // dark mode
                            : Theme.of(context).colorScheme.primary.withAlpha((0.08 * 255).round()),
                    ),
                    child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0,vertical: 4),
                        child: Text(list.toString(),style: TextStyle(fontSize: 12,color: Theme.of(context).colorScheme.onSurface),),
                      ),
                  )
                ).toList()
              ),
            ),
          ),
          SizedBox(height: 10,),
          Expanded(
            child:RefreshIndicator(
              onRefresh: refreshChats,
                color: Colors.blue,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                child: isLoading
                    ? SkeletonLoader()
                    : messageByUsers.isEmpty
                    ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.7,
                          child: Center(
                            child: Text('No messages',style: TextStyle(color: Colors.white),),
                          ),
                        ),
                      ]
                    )
                    : Container(
                      child: ListView.builder(
                                        itemCount: messageByUsers.length,
                                        scrollDirection: Axis.vertical,
                                        itemBuilder: (context, index) {
                      final message = messageByUsers[index]['lastMessage'];
                      final otherUser = messageByUsers[index]['otherUser'];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Userchatpage(
                                key: ValueKey(otherUser['userId']),
                                name: messageByUsers[index]?['displayName'] ?? "",
                                id: otherUser['userId'],
                              ),
                            ),
                          ).then((_) => refreshChats());
                        },
                        child: ListTile(
                          leading: GestureDetector(
                            onTap: () => showDpPopup(
                              context,
                              (otherUser['profileImage'] != null &&
                                  otherUser['profileImage'].toString().isNotEmpty)
                                  ? otherUser['profileImage']
                                  : "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSOH2aZnIHWjMQj2lQUOWIL2f4Hljgab0ecZQ&s",
                            ),
                            child: CircleAvatar(
                              radius: 25,
                              backgroundImage: NetworkImage(
                                (otherUser['profileImage'] != null &&
                                    otherUser['profileImage'].toString().isNotEmpty)
                                    ? otherUser['profileImage']
                                    : "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSOH2aZnIHWjMQj2lQUOWIL2f4Hljgab0ecZQ&s",
                              ),
                            ),
                          ),
                          title: Text(
                            messageByUsers[index]?['displayName'] != null
                                ? (otherUser?['mobile'] == user?.mobile
                                ? "${messageByUsers[index]['displayName']} (You)"
                                : messageByUsers[index]['displayName'])
                                : formatIndianMobile(otherUser?['mobile'] ?? ""),
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: message['messageType'] == "text"
                              ? Text(
                            message['messageText'] ?? "",
                            style: TextStyle(fontSize: 15,color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round(),),),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                              : Text(
                            "Media file",
                            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round(),),),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            spacing: 10,
                            children: [
                              Text(
                                formatChatDate(message['messageAt']),
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13),
                              ),
                              if ((messageByUsers[index]['unreadCount'] ?? 0) > 0)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    (messageByUsers[index]['unreadCount'] ?? 0).toString(),
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 12),
                                  ),
                                )
                            ],
                          ),
                        ),
                      );
                                        },
                                      ),
                    )

          ))
        ],
      ),
    );
  }

  String formatChatDate(String isoDate) {
    final date = DateTime.parse(isoDate).toLocal();
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);

    final difference = today.difference(messageDay).inDays;

    if (difference == 0) {
      // Today → show time
      return DateFormat('h:mm a').format(date); // 9:47 AM
    } else if (difference == 1) {
      // Yesterday
      return "Yesterday";
    } else {
      // Older → date
      return DateFormat('d/M/yy').format(date); // 1/2/26
    }
  }

  String normalizedPhone(String phone) {
    // Remove everything except digits
    String digits = phone.replaceAll(RegExp(r'\D'), '');

    // If number already has country code (91)
    if (digits.startsWith('91') && digits.length == 12) {
      return '+$digits';
    }

    // If it's a 10-digit Indian number
    if (digits.length == 10) {
      return '+91$digits';
    }

    // Fallback (unknown format)
    return '+$digits';
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


  void showDpPopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 50, vertical: 150), // small box
        child: Stack(
          children: [
            Container(
              height: 250,
              width: 250,
              child: PhotoView(
                imageProvider: NetworkImage(imageUrl),
                backgroundDecoration: BoxDecoration(color: Colors.black),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> showPermissionDeniedDialog(BuildContext context) async {
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
            "We need access to your contacts to help you find friends. "
                "Please allow contacts permission from settings.",
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


}

class SkeletonLoader extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: 10,
        itemBuilder: (context,index){
      return ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.white24,
        ),
        title: Align(
          alignment: AlignmentGeometry.centerLeft,
          child: Container(
            height: 15,
            width: 200,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10)
            ),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            height: 15,
            width: 80,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10)
            ),
          ),
        ),
        trailing: Padding(
          padding: const EdgeInsets.only(bottom: 28.0),
          child: Container(
            height: 15,
            width: 40,
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(10)
            ),
          ),
        )
      );
    });
  }
}