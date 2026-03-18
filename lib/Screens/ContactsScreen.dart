import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:vaarta_app/Config/Constants.dart';
import 'package:vaarta_app/Data/AccessTokenGenerator.dart';
import 'package:vaarta_app/Data/TokenStorage.dart';
import 'package:vaarta_app/Login_Logup/LoginPage.dart';
import 'package:vaarta_app/PermissionHelper/ContactPermission.dart';
import 'package:vaarta_app/Providers/ChatOptionProvider.dart';
import 'package:vaarta_app/Providers/ContactsProvider.dart';
import 'package:vaarta_app/Providers/MenuIndexProvider.dart';
import 'package:vaarta_app/Providers/UserProvider.dart';
import 'package:vaarta_app/Screens/UserChatPage.dart';
import 'package:http/http.dart' as http;

class Contactsscreen extends StatefulWidget{
  @override
  State<Contactsscreen> createState() {
    return ContactsscreenState();
  }
}
class ContactsscreenState extends State<Contactsscreen>{
  final storage = FlutterSecureStorage();
  late Future<List<dynamic>> contactsFuture;
  bool _hasLoadedContacts = false;
  List<dynamic> allContacts = []; // full list from server
  List<dynamic> filteredContacts = []; // filtered by search
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();

    searchController.addListener(() {
      final query = searchController.text.toLowerCase();
      setState(() {
        filteredContacts = allContacts.where((contact) {
          final name = contact['name']?.toString().toLowerCase() ?? '';
          final phone = contact['normalizedPhone']?.toString().toLowerCase() ?? '';
          return name.contains(query) || phone.contains(query);
        }).toList();
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    int currentIndex = context.watch<MenuindexProvider>().getIndex();

    // Only fetch when the tab is visible AND not loaded yet
    if (!_hasLoadedContacts && currentIndex == 2) {
      _hasLoadedContacts = true;

      contactsFuture = getContactNumbers(context).then((contacts) {
        allContacts = contacts;
        filteredContacts = List.from(allContacts);
        return contacts;
      });
    }
  }



  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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


  // Future<List<dynamic>> getContactNumbers() async {
  //   final bool granted = await requestContactsPermission();
  //   if (!granted) {
  //     showPermissionDeniedDialog(context);
  //     return [];
  //   }
  //
  //   final Iterable<Contact> contacts =
  //   await FlutterContacts.getContacts(withProperties: true);
  //
  //   final List<Map<String, String>> payload = [];
  //   final Set<String> uniquePhones = {};
  //
  //   for (final contact in contacts) {
  //     final String name = contact.displayName ?? "";
  //
  //     for (final phone in contact.phones) {
  //       if (phone.number.isEmpty) continue;
  //
  //       final String normalized = normalizedPhone(phone.number);
  //       if (uniquePhones.contains(normalized)) continue;
  //
  //       uniquePhones.add(normalized);
  //
  //       payload.add({
  //         "name": name,
  //         "phone": phone.number,
  //         "normalizedPhone": normalized,
  //       });
  //     }
  //   }
  //   if (payload.isEmpty) return [];
  //
  //   final Uri url =
  //   Uri.parse("${ApiConstant.baseUrl}/user/friends-list");
  //
  //   try {
  //     final token = await storage.read(key: "access_token");
  //     http.Response response = await http.post(
  //       url,
  //       headers: {
  //         'Authorization': 'Bearer $token',
  //         "Content-Type": "application/json"},
  //       body: jsonEncode(payload),
  //     );
  //     if(response.statusCode == 401){
  //       final refreshToken = await storage.read(key: "refresh_token");
  //       final refreshResponse = await http.get(
  //         url,
  //         headers: {
  //           'Authorization': 'Bearer $refreshToken',
  //           "Content-Type": "application/json"},
  //       );
  //       if(refreshResponse.statusCode == 403){
  //         await storage.deleteAll();
  //         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=>Loginpage()));
  //         return [];
  //       }
  //       if(refreshResponse.statusCode == 401){
  //         final newAccesstoken = jsonDecode(refreshResponse.body);
  //         await TokenStorage.updateAccessToken(
  //           newAccesstoken["accessToken"],
  //         );
  //         final token = await storage.read(key: "access_token");
  //         response = await http.post(
  //           url,
  //           headers: {
  //             'Authorization': 'Bearer $token',
  //             "Content-Type": "application/json"},
  //           body: jsonEncode(payload),
  //         );
  //       }
  //
  //     }
  //     if (response.statusCode == 200) {
  //       final Map<String, dynamic> decoded =
  //       jsonDecode(response.body);
  //
  //       // ✅ THIS IS THE IMPORTANT LINE
  //       return List<dynamic>.from(decoded["data"] ?? []);
  //     } else {
  //       debugPrint(
  //         "Server error ${response.statusCode}: ${response.body}",
  //       );
  //       return [];
  //     }
  //   } catch (e) {
  //     debugPrint("Network error: $e");
  //     return [];
  //   }
  // }

  Future<List<dynamic>> getContactNumbers(BuildContext context) async {
    final bool granted = await requestContactsPermission();
    if (!granted) {
      showPermissionDeniedDialog(context);
      return [];
    }

    final contacts =
    await FlutterContacts.getContacts(withProperties: true);

    final List<Map<String, String>> payload = [];
    final Set<String> uniquePhones = {};

    for (final contact in contacts) {
      final name = contact.displayName ?? "";

      for (final phone in contact.phones) {
        if (phone.number.isEmpty) continue;

        final normalized = normalizedPhone(phone.number);
        if (uniquePhones.contains(normalized)) continue;

        uniquePhones.add(normalized);

        payload.add({
          "name": name,
          "phone": phone.number,
          "normalizedPhone": normalized,
        });
      }
    }
    if (payload.isEmpty) return [];
    final friendsUrl =
    Uri.parse("${ApiConstant.baseUrl}/user/friends-list");
    final refreshUrl =
    Uri.parse("${ApiConstant.baseUrl}/user/refresh-token");
    try {
      String? token = await storage.read(key: "access_token");
      if (token == null) return [];
      http.Response response = await http.post(
        friendsUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );
      // 🔁 Access token expired
      if (response.statusCode == 401) {
        final refreshed = await accessTokenGenerator(context);
        if (!refreshed) return [];
        token = await storage.read(key: "access_token");
        if(token==null)return [];
        response = await http.post(
          friendsUrl,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        );
      }

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return List<dynamic>.from(decoded["data"] ?? []);
      }

      debugPrint("Server error ${response.statusCode}");
      return [];
    } catch (e) {
      debugPrint("Network error: $e");
      return [];
    }
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

  Future<void> _refreshContacts() async {
    final future = getContactNumbers(context);
    setState(() {
      contactsFuture = future;
    });
    await future; // important so refresh spinner waits
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    return Scaffold(
      // backgroundColor: Color(0xff09090e),
      appBar: AppBar(
        title: Text("Contacts",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
        // backgroundColor: Color(0xff09090e),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsetsGeometry.symmetric(horizontal: 20,vertical: 0),
          // color: Color(0xff09090e),
          height: double.infinity,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Add new friends",
                style: TextStyle( fontSize: 18),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: searchController,
                onChanged: (_) => setState(() {}),
                onTapOutside: (event) => FocusScope.of(context).unfocus(),
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface, // adaptive text color
                ),
                decoration: InputDecoration(
                  fillColor: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface.withAlpha((0.12 * 255).round()) // dark mode background
                      : Theme.of(context).colorScheme.primary.withAlpha((0.08 * 255).round()), // light mode background
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  hintText: "Search here",
                  hintStyle: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey.shade300
                        : Colors.grey.shade700, // adaptive hint color
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.onSurface), // adaptive icon
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
                    onPressed: () {
                      searchController.clear();
                      setState(() {});
                    },
                  )
                      : null,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      width: 1,
                      color: Theme.of(context).colorScheme.onSurface, // adaptive border
                    ),
                    borderRadius: BorderRadius.circular(40),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // The scrollable list starts here
              Expanded(
                child: RefreshIndicator(
                  color: Colors.blue,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  onRefresh: _refreshContacts,
                  child: FutureBuilder<List<dynamic>>(
                    future: contactsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && snapshot.data == null) {
                        return SkeletonLoader();
                      }
                      if (snapshot.hasError){
                        print(snapshot.error);
                        return ListView(physics: const AlwaysScrollableScrollPhysics(),children: [SizedBox(height:  MediaQuery.of(context).size.height * 0.6,child: Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.white))))]);
                      }

                      final contacts = snapshot.data ?? [];
                      final searchText = searchController.text.toLowerCase();
                      final filteredContacts = contacts.where((c) {
                        final name = c['name']?.toLowerCase() ?? '';
                        final phone = c['normalizedPhone'] ?? '';
                        return name.contains(searchText) || phone.contains(searchText);
                      }).toList();

                      final availableContacts = filteredContacts.where((c) => c['availableInApp'] == true).toList();
                      final notAvailableContacts = filteredContacts.where((c) => c['availableInApp'] == false).toList();

                      if (contacts.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [SizedBox(
                            height: MediaQuery.of(context).size.height * 0.6,
                            child: Center(
                              child: Text(
                                "No contacts found",
                                style: const TextStyle( fontSize: 18),
                              ),
                            ),
                          ),]
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.only(top: 0),
                        children: [
                          // Available contacts
                          const Text(
                            "Available to chat",
                            style: TextStyle( fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          if (availableContacts.isEmpty)
                            const Text("No available contacts", style: TextStyle(color: Colors.white60, fontSize: 18)),
                          ...availableContacts.map((contact) => ListTile(
                            contentPadding:EdgeInsets.zero,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => Userchatpage(
                                    name: contact['name'].toString(),
                                    id: contact["id"],
                                  ),
                                ),
                              );
                            },
                            leading: GestureDetector(
                              onTap: () => showDpPopup(
                                context,
                                (contact['profileImage'] != null &&
                                    contact['profileImage'].toString().isNotEmpty)
                                    ? contact['profileImage']
                                    : "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSOH2aZnIHWjMQj2lQUOWIL2f4Hljgab0ecZQ&s",
                              ),
                              child:CircleAvatar(
                                backgroundImage: NetworkImage(
                                  (contact["profileImage"] != null &&
                                      contact["profileImage"].toString().trim().isNotEmpty)
                                      ? contact["profileImage"]
                                      : "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSOH2aZnIHWjMQj2lQUOWIL2f4Hljgab0ecZQ&s",
                                ),radius: 22,
                            ),),
                            title: Text(
                              contact["normalizedPhone"] == user?.mobile
                                  ? "${contact['name']} (You)"
                                  : contact['name'],
                              style: TextStyle(color:Theme.of(context).colorScheme.onSurface, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            subtitle: Text(
                              formatIndianMobile(contact['normalizedPhone']) ?? '',
                              style: TextStyle(color: Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()) // dark mode semi-transparent
                                  : Theme.of(context).colorScheme.onSurface, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          )),
                          const SizedBox(height: 20),
                          const Text("Not available", style: TextStyle( fontSize: 18)),
                          const SizedBox(height: 10),
                          if (notAvailableContacts.isEmpty)
                            const Text("No contacts found", style: TextStyle( fontSize: 18)),
                          ...notAvailableContacts.map((contact) => ListTile(
                            contentPadding:EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                  "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSOH2aZnIHWjMQj2lQUOWIL2f4Hljgab0ecZQ&s"),
                              radius: 22,
                            ),
                            title: Text(contact['name'] ?? '',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                            subtitle: Text(formatIndianMobile(contact['normalizedPhone']) ?? '',
                                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(context).colorScheme.onSurface.withAlpha((0.6 * 255).round()) // dark mode semi-transparent
                          : Theme.of(context).colorScheme.onSurface,  fontSize: 16),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1),
                            trailing: TextButton(
                              onPressed: () {},
                              child: const Text("Invite", style: TextStyle(fontSize: 16, color: Colors.greenAccent)),
                            ),
                          )),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          )
        ),
      )
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
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: 9,
        itemBuilder: (context,index){
          return ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 0),
            leading: CircleAvatar(
              radius: 22,
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
              padding: const EdgeInsets.only(top: 15),
              child: Container(
                height: 15,
                width: 80,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10)
                ),
              ),
            ),
          );
        });
  }
}