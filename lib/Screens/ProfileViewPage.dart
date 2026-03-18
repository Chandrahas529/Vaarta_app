import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vaarta_app/Providers/FriendProvider.dart';

class Profileviewpage extends StatelessWidget{
  final dynamic src;
  final dynamic sender;
  const Profileviewpage({super.key, required this.src, required this.sender});
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

  String formatLastSeen(dynamic lastSeenValue) {
    if (lastSeenValue == null) return "Last seen unknown";

    // Convert to string if needed
    String lastSeenStr = lastSeenValue.toString();

    // Remove curly braces if they exist
    lastSeenStr = lastSeenStr.replaceAll(RegExp(r'[{}]'), '');

    // Parse to DateTime
    DateTime lastSeen;
    try {
      lastSeen = DateTime.parse(lastSeenStr).toLocal();
    } catch (e) {
      return "Last seen unknown";
    }

    DateTime now = DateTime.now();
    Duration diff = now.difference(lastSeen);

    if (diff.inDays == 0) {
      // Today: show only time
      return DateFormat.jm().format(lastSeen); // 08:14 AM
    } else if (diff.inDays == 1) {
      // Yesterday
      return "Yesterday, ${DateFormat.jm().format(lastSeen)}";
    } else if (diff.inDays < 7) {
      // Within last week
      return "${DateFormat.EEEE().format(lastSeen)}, ${DateFormat.jm().format(lastSeen)}"; // Tuesday, 08:14 AM
    } else {
      // Older: show date
      return DateFormat.yMd().format(lastSeen); // 2/4/2026
    }
  }

  @override
  Widget build(BuildContext context) {
    final friend = Provider.of<FriendProvider>(context).friend;
    return Scaffold(
      appBar: AppBar(
        title: Text("About",style: TextStyle(fontSize: 20,),),
        automaticallyImplyLeading: false,
        actionsPadding: EdgeInsetsGeometry.only(right: 10),
        actions: [
          IconButton(onPressed: (){Navigator.pop(context);}, icon: Icon(Icons.close,size: 26,))
        ],
      ),
      body: SafeArea(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 40,
              children: [
                Container(
                  width: double.infinity,
                  child: Column(
                    spacing: 20,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: CircleAvatar(
                          radius: 100,
                          backgroundImage: NetworkImage(src),
                        ),
                      ),
                      Text(sender,style: TextStyle(fontSize: 20),),
                      Text(formatIndianMobile(friend!.mobile) ?? '',style: TextStyle(fontSize: 20,),),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text("Status",style: TextStyle(fontSize: 18),),
                    Text(friend?.status ?? "Hey there i am using vaarta app",style: TextStyle(fontSize: 18),)
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 6,
                  children: [
                    Text("Last seen",style: TextStyle(fontSize: 18),),
                    Text(friend == null
                        ? ""
                        : friend.isOnline
                        ? "Online"
                        : friend.lastSeen != null
                        ? "Last seen ${formatLastSeen(friend.lastSeen!)}"
                        : "Offline",style: TextStyle(fontSize: 18),)
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    Icon(Icons.delete,color: Colors.red,size: 24,),
                    Text("Delete chat",style: TextStyle(color: Colors.red,fontSize: 18),),
                  ],
                )
              ],
            ),
          )
      ),
    );
  }
}
