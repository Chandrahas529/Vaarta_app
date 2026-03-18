import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';
import 'package:vaarta_app/ChatModel.dart';
import 'package:vaarta_app/Config/Constants.dart';
import 'package:vaarta_app/Config/WebSocket.dart';
import 'package:vaarta_app/Modals/MessageModal.dart';
import 'package:vaarta_app/Data/AccessTokenGenerator.dart';
import 'package:vaarta_app/MediaChat/AudioMessage.dart';
import 'package:vaarta_app/MediaChat/VideoBubbleMessage.dart';
import 'package:vaarta_app/Providers/ChatOptionProvider.dart';
import 'package:vaarta_app/Providers/FriendProvider.dart';
import 'package:vaarta_app/Providers/UserProvider.dart';
import 'package:vaarta_app/Screens/ImageViewPage.dart';
import 'package:vaarta_app/Screens/ProfileViewPage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:vaarta_app/Screens/SelectedMediaPreviewPage.dart';
import 'package:http/http.dart' as http;

class Userchatpage extends StatefulWidget{
  final String name;
  final String id;
  const Userchatpage({super.key, required this.name, required this.id});
  @override
  State<Userchatpage> createState() => UserchatpageState();
}

class UserchatpageState extends State<Userchatpage> {
  final storage = FlutterSecureStorage();
  final GlobalKey<ChatsState> chatsKey = GlobalKey();
  final GlobalKey<InputBoxState> inputBoxKey = GlobalKey<InputBoxState>();
  final AudioPlayer _player = AudioPlayer(); // initialize once
  late ValueNotifier<bool> selectModeNotifier;
  late ValueNotifier<int> selectionCountNotifier;
  final FocusNode _messageFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_){
      _initApp();
    });
    final provider = context.read<Chatoptionprovider>();

    // Initialize ValueNotifiers with provider's current state
    selectModeNotifier = ValueNotifier<bool>(provider.getSelectMode());
    selectionCountNotifier = ValueNotifier<int>(provider.getSelectionCount());

    // Listen to provider changes and update ValueNotifier
    provider.addListener(() {
      selectModeNotifier.value = provider.getSelectMode();
      selectionCountNotifier.value = provider.getSelectionCount();
    });
  }

  @override
  void dispose() {
    selectModeNotifier.dispose();
    selectionCountNotifier.dispose();
    super.dispose();
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

  // Future<void> deleteMessages() async {
  //   final selectedIds =
  //   Provider.of<Chatoptionprovider>(context, listen: false).getSelectedIds();
  //
  //   final messageIds = selectedIds
  //       .where((e) =>
  //   e['type'] == 'text' || e['type'] == 'image' || e['type'] == 'video')
  //       .map((e) => e['id'])
  //       .toList();
  //
  //   if (messageIds.isEmpty) return;
  //
  //   String? token = await storage.read(key: "access_token");
  //   if (token == null) {
  //     print("Token not found");
  //     return;
  //   }
  //
  //   final url = Uri.parse("${ApiConstant.baseUrl}/message/delete");
  //
  //   try {
  //     http.Response response = await http.delete(
  //       url,
  //       headers: {
  //         "Content-Type": "application/json",
  //         "Authorization": "Bearer $token"
  //       },
  //       body: jsonEncode({"deleteList": messageIds}),
  //     );
  //
  //     // Handle token refresh
  //     if (response.statusCode == 401) {
  //       final refreshed = await accessTokenGenerator(context);
  //       if (!refreshed) return;
  //
  //       token = await storage.read(key: "access_token");
  //       if (token == null) return;
  //
  //       response = await http.delete(
  //         url,
  //         headers: {
  //           'Authorization': 'Bearer $token',
  //           'Content-Type': 'application/json',
  //         },
  //         body: jsonEncode({"deleteList": messageIds}),
  //       );
  //     }
  //
  //     if (response.statusCode == 200) {
  //       chatsKey.currentState?.refreshChats();
  //
  //       // ✅ Play delete sound
  //       try {
  //         await _player.play(AssetSource('audios/delete.wav'));
  //         // Use the correct file name and extension you actually have
  //       } catch (e) {
  //         print("Error playing delete sound: $e");
  //       }
  //     } else {
  //       print("Error deleting messages: ${response.body}");
  //     }
  //   } catch (e) {
  //     print("Exception in deleteMessages: $e");
  //   }
  // }

  Future<void> deleteMessages() async {
    final socketService = SocketService.instance;
    _messageFocusNode.unfocus();
    final selectedIds =
    Provider.of<Chatoptionprovider>(context, listen: false)
        .getSelectedIds();
    final messageIds = selectedIds
        .where((e) =>
    e['type'] == 'text' ||
        e['type'] == 'image' ||
        e['type'] == 'video')
        .map((e) => e['id'])
        .toList();
    if (messageIds.isEmpty) return;

    final deletePayload = {
      "type": "DELETE_MESSAGE",
      "deleteList": messageIds,
    };

    // Try reconnecting if not connected (same as sendMessage)
    if (!socketService.isConnected) {
      socketService.connect(context); // don’t await
    }

    try {
      // Send immediately
      socketService.send(deletePayload);

      // Play delete sound
    } catch (e) {
      print("Error deleting message or playing sound: $e");
    }
    final provider = context.read<Chatoptionprovider>();
    provider.resetSelectionCount();
    provider.selectModeStatus();
  }


  Future<void> confirmAndDeleteMessages() async {
    final selectedIds = Provider.of<Chatoptionprovider>(context, listen: false).getSelectedIds();
    if (selectedIds.isEmpty) return;

    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // or any radius you want
          ),
          title: Text("Delete Messages",style: TextStyle(fontSize:18,color: Theme.of(context).colorScheme.onSurface),),
          content: Text("Are you sure you want to delete these messages?",style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                Provider.of<Chatoptionprovider>(context).resetChatOption();
              },
              child: Text("Cancel",style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true), // Confirm
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text("Delete",style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return; // User cancelled

    // Call your existing delete function
    await deleteMessages();
  }

  Future<void> deleteAllMessages(String friendId) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
          ),
          title: Text(
            "Delete All Messages",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18),
          ),
          content: Text(
            "Are you sure you want to delete all messages in this chat?",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel", style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text("Delete All", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    String? token = await storage.read(key: "access_token");
    if (token == null) return;

    final url = Uri.parse("${ApiConstant.baseUrl}/message/delete-all");

    try {
      http.Response response = await http.delete(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"friendId": friendId}),
      );

      // Handle token refresh
      if (response.statusCode == 401) {
        final refreshed = await accessTokenGenerator(context);
        if (!refreshed) return;

        token = await storage.read(key: "access_token");
        if (token == null) return;

        response = await http.delete(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({"friendId": friendId}),
        );
      }

      if (response.statusCode == 200) {
        // Refresh UI
        chatsKey.currentState?.refreshChats();

        // ✅ Play delete sound
        try {
          await _player.play(AssetSource('audios/delete.mp3'));
        } catch (e) {
          print("Error playing delete sound: $e");
        }

        print("All messages deleted!");
      } else {
        print("Error deleting all messages: ${response.body}");
      }
    } catch (e) {
      print("Exception in deleteAllMessages: $e");
    }
    final provider = context.read<Chatoptionprovider>();
    provider.resetSelectionCount();
    provider.selectModeStatus();
    _messageFocusNode.unfocus();
  }

  void refreshChat(){
    chatsKey.currentState?.refreshChats();
  }

  Future<void> _initApp() async {
    final userProvider =
    Provider.of<FriendProvider>(context, listen: false);

    await userProvider.getFriendDetailsFromServer(widget.id,context);
  }

  String formatLastSeen(dynamic lastSeenValue) {
    if (lastSeenValue == null) return "Last seen recently";

    DateTime lastSeen;

    if (lastSeenValue is DateTime) {
      lastSeen = lastSeenValue;
    } else {
      try {
        String value = lastSeenValue.toString().replaceFirst(' ', 'T');
        lastSeen = DateTime.parse(value);
      } catch (_) {
        return "Last seen recently";
      }
    }

    final now = DateTime.now();
    DateTime lastSeenLocal = lastSeen.toLocal(); // 👈 NOT final

    // Fix future timestamps
    if (lastSeenLocal.isAfter(now)) {
      lastSeenLocal = now;
    }

    final today = DateTime(now.year, now.month, now.day);
    final lastSeenDate = DateTime(
      lastSeenLocal.year,
      lastSeenLocal.month,
      lastSeenLocal.day,
    );

    final dayDiff = today.difference(lastSeenDate).inDays;

    if (dayDiff == 0) {
      return "Last seen today at ${DateFormat.jm().format(lastSeenLocal)}";
    }

    if (dayDiff == 1) {
      return "Last seen yesterday at ${DateFormat.jm().format(lastSeenLocal)}";
    }

    if (dayDiff < 7) {
      return "Last seen ${DateFormat('EEEE').format(lastSeenLocal)} at ${DateFormat.jm().format(lastSeenLocal)}";
    }

    return "Last seen ${DateFormat.yMd().format(lastSeenLocal)}";
  }


  @override
  Widget build(BuildContext context){
    double width = MediaQuery.of(context).size.width;
    final friend = Provider.of<FriendProvider>(context).friend;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return PopScope(
      canPop: !context.watch<Chatoptionprovider>().getSelectMode(),
      onPopInvokedWithResult: (didPop, result) {
        final provider = context.read<Chatoptionprovider>();
        if(provider.getSelectMode()==true){
          provider.resetSelectionCount();
          provider.selectModeStatus();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
                onTap: (){Navigator.push(context, MaterialPageRoute(builder: (context)=>Profileviewpage(sender: widget.name,src: (friend?.profileImage != null && friend!.profileImage!.isNotEmpty)? friend!.profileImage! : "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSOH2aZnIHWjMQj2lQUOWIL2f4Hljgab0ecZQ&s",)));},
              child: CircleAvatar(
                radius: 16,
                backgroundImage: NetworkImage(
                  (friend?.profileImage != null && friend!.profileImage!.isNotEmpty)
                      ? friend!.profileImage!
                      : "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSOH2aZnIHWjMQj2lQUOWIL2f4Hljgab0ecZQ&s",
                ),),
            ),
          ),
          title: ValueListenableBuilder<bool>(
            valueListenable: selectModeNotifier,
            builder: (context, isSelectMode, _) {
              return !isSelectMode
                  ? InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Profileviewpage(
                        sender: widget.name,
                        src: (friend?.profileImage != null && friend!.profileImage!.isNotEmpty)
                            ? friend!.profileImage!
                            : "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSOH2aZnIHWjMQj2lQUOWIL2f4Hljgab0ecZQ&s",
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (widget.name?.isNotEmpty ?? false) ? widget.name! : formatIndianMobile(friend?.mobile ?? ''),
                      style: TextStyle(fontSize: 18,color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      friend == null
                          ? ""
                          : friend.isOnline
                          ? "Online"
                          : friend.lastSeen != null
                          ? "${formatLastSeen(friend.lastSeen!)}"
                          : "Offline",
                      style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )
                  : ValueListenableBuilder<int>(
                valueListenable: selectionCountNotifier,
                builder: (context, count, _) {
                  return Text(
                    "$count message selected",
                    style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  );
                },
              );
            },
          ),
          automaticallyImplyLeading: false,
          // backgroundColor: Color(0xff09090e),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: selectModeNotifier,
              builder: (context, isSelectMode, _) {
                final provider = context.read<Chatoptionprovider>();
                if (isSelectMode) {
                  return Row(
                    children: [
                    ValueListenableBuilder<int>(
                        valueListenable: selectionCountNotifier,
                        builder: (context, count, _) {
                          if(count==1){
                            return IconButton(onPressed: (){
                              provider.setSelectedMessage();
                              provider.selectForwardMode(true);
                              provider.resetSelectionCount();
                              provider.selectModeStatus();
                            }, icon: Icon(Ionicons.return_up_back_outline,fontWeight: FontWeight.w900,));
                          }else{
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                      IconButton(
                        onPressed: () async {
                          await confirmAndDeleteMessages();
                          // provider.resetSelectionCount();
                          // provider.selectModeStatus();
                        },
                        icon: const Icon(Icons.delete, size: 24),
                      ),
                      IconButton(
                        onPressed: () {
                          provider.resetSelectionCount();
                          provider.selectModeStatus();
                        },
                        icon: const Icon(Icons.close, size: 24),
                      ),
                    ],
                  );
                } else {
                  return PopupMenuButton<String>(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade900 : Colors.white,
                    borderRadius: BorderRadius.circular(40),
                    icon: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(Icons.more_vert, size: 24),
                    ),
                    onSelected: (value) {
                      switch (value) {
                        case "about":
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Profileviewpage(
                                sender: widget.name,
                                src: friend?.profileImage ?? "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSOH2aZnIHWjMQj2lQUOWIL2f4Hljgab0ecZQ&s",
                              ),
                            ),
                          );
                          break;
                        case "select":
                          provider.selectModeStatus();
                          break;
                        case "deleteAll":
                          deleteAllMessages(friend!.id);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: "about",
                        child: Row(
                          spacing: 10,
                          children: [
                            Icon(Icons.info_outline, size: width * 0.06),
                            const Text("About", style: TextStyle(fontSize: 16,)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "select",
                        child: Row(
                          spacing: 10,
                          children: [
                            Icon(Icons.check_box, size: width * 0.06),
                            const Text("Select messages", style: TextStyle(fontSize: 16,)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: "deleteAll",
                        child: Row(
                          spacing: 10,
                          children: [
                            Icon(Icons.delete, size: width * 0.06),
                            const Text("Delete all messages", style: TextStyle(fontSize: 16,)),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(isDark ? "assets/images/chat-bg.jpg" : "assets/images/light_chat_bg.jpg",fit: BoxFit.cover,),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        bottom: 0,
                        right: 0,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Container(
                            child: Chats(
                              key: chatsKey,
                              userId: widget.id,
                              name:widget.name
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                          bottom: 0,
                          right: 0,
                          left: 0,
                          child: InputBox(
                            onSend: refreshChat,
                            focusNode:_messageFocusNode
                          ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Chats extends StatefulWidget{
  final String userId;
  final String name;
  const Chats({Key? key, required this.userId, required this.name}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return ChatsState();
  }
}

class ChatsState extends State<Chats>{
  List<bool> selectMessage = [];
  List<Message> messages = [];
  late ValueNotifier<bool> selectModeNotifier;
  late ValueNotifier<int> selectionCountNotifier;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? initialMessageId;
  late ScrollController _scrollController;
  final storage = FlutterSecureStorage();
  final AudioPlayer _player = AudioPlayer(); // initialize once
  @override
  void initState() {
    super.initState();
    messages = [];
    _scrollController = ScrollController();
    getChat(widget.userId);
    SocketService.instance.onMessageReceived = handleIncomingMessage;
    SocketService.instance.onMessagesSeen = handleMessagesSeenByFriend;
    SocketService.instance.onMessagesDeleted = handleMessageDelete;
    markMessagesAsSeen();
    final provider = context.read<Chatoptionprovider>();

    // Initialize ValueNotifiers with provider's current state
    selectModeNotifier = ValueNotifier<bool>(provider.getSelectMode());
    selectionCountNotifier = ValueNotifier<int>(provider.getSelectionCount());

    // Listen to provider changes and update ValueNotifier
    provider.addListener(() {
      selectModeNotifier.value = provider.getSelectMode();
      selectionCountNotifier.value = provider.getSelectionCount();
    });
    final friend = Provider.of<FriendProvider>(context, listen: false).friend;
    _scrollController.addListener(() {
      if (!_scrollController.hasClients) return;

      // When reversed, top is maxScrollExtent
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!isLoadingMore && hasMore) {
          final friend =
              Provider.of<FriendProvider>(context, listen: false).friend;

          if (friend?.id != null) {
            getChat(friend!.id);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    SocketService.instance.onMessageReceived = null;
    SocketService.instance.onMessagesSeen = null;
    selectModeNotifier.dispose();
    _scrollController.dispose();
    selectionCountNotifier.dispose();
    super.dispose();
  }

  void refreshChats() {
    final friend = Provider.of<FriendProvider>(context, listen: false).friend;
    if (friend?.id != null) {
      setState(() {
          isLoading = true;
        getChat(friend!.id);
      });
    }
  }

  void markMessagesAsSeen() {
    final friend = context.read<FriendProvider>().friend;
    final me = context.read<UserProvider>().user;
    if (friend == null || me == null) return;

    SocketService.instance.send({
      "type": "MESSAGE_SEEN",
      "data": {
        "senderId": friend.id,   // who sent the messages
        "receiverId": me.id,     // who saw them
      }
    });
  }

  /// Call this whenever the server confirms messages are seen by the friend
  void handleMessagesSeenByFriend(Map<String, dynamic> data) {
    final me = context.read<UserProvider>().user;
    if (me == null) return;
    if (!mounted) return;
    setState(() {
      for (var msg in messages) {
        if (msg.senderId == me.id && msg.seenStatus == false) {
          msg.seenStatus = true;
        }
      }
    });
  }

  void handleMessageDelete(Map<String, dynamic> data) async {
    if (!mounted) return;

    final List<dynamic>? deletedIds = data["deleteList"];

    if (deletedIds == null || deletedIds.isEmpty) return;

    setState(() {
      for (int i = messages.length - 1; i >= 0; i--) {
        if (deletedIds.contains(messages[i].id)) {
          messages.removeAt(i);
          if (i < selectMessage.length) {
            selectMessage.removeAt(i);
          }
        }
      }
    });

    // Optional: clear selection mode
    final chatProvider =
    Provider.of<Chatoptionprovider>(context, listen: false);
    chatProvider.removeAllSelectedIds();

    // Optional: play delete sound
    try {
      await _player.play(AssetSource('audios/delete.wav'));
    } catch (e) {
      debugPrint("Delete sound error: $e");
    }
  }

  void handleIncomingMessage(Map<String, dynamic> data) async {
    final friend = context.read<FriendProvider>().friend;
    final me = context.read<UserProvider>().user; // Current logged-in user
    if (friend == null || me == null) return;
    try {
      final type = data["type"];
      final payload = data["data"];
      if (payload == null) return;
      if (type == "NEW_MESSAGE") {
        final senderId = payload['senderId'];
        final receiverId = payload['receiverId'];

        // Ignore messages not related to this chat
        if (!((senderId == friend.id && receiverId == me.id) ||
            (senderId == me.id && receiverId == friend.id))) return;

        final Message newMessage = Message.fromJson(payload);

        // Prevent duplicates
        final alreadyExists = messages.any((m) => m.id == newMessage.id);
        if (alreadyExists) return;

        if (!mounted) return;
        setState(() {
          // Insert at the top because ListView is reverse:true
          messages.insert(0, newMessage);
          selectMessage.insert(0, false);
        });

        // Mark as seen if friend sent this message
        if (senderId == friend.id) {
          markMessagesAsSeen();
        }

        // Play sound
        try {
          await _player.play(AssetSource('audios/receiver.wav'));
        } catch (e) {
          print("Error playing receive sound: $e");
        }

        // ------------------------------
        // 2️⃣ Handle MESSAGES_SEEN (friend saw my messages)
        // -----------------------------
      }
    } catch (e) {
      debugPrint("Error handling incoming message: $e");
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final chatProvider = context.read<Chatoptionprovider>();
    final friend = context.read<FriendProvider>().friend;
    if (!chatProvider.getSelectMode()) {
      selectMessage = List<bool>.filled(messages.length, false,growable: true);
      chatProvider.removeAllSelectedIds();
    }
    // if (friend?.id != null && _loadedFriendId != friend!.id) {
    //   _loadedFriendId = friend.id; getChat(friend.id);
    // }
    markMessagesAsSeen();
  }


  Future<void> getChat(String friendId) async {
    if (friendId.isEmpty) {
      debugPrint("Friend ID not found");
      return;
    }

    String? token = await storage.read(key: "access_token");
    if (token == null) {
      debugPrint("Token not found");
      return;
    }

    final url = Uri.parse(
        "${ApiConstant.baseUrl}/message/one-to-one-chat?initialMessageId=$initialMessageId");

    if (isLoadingMore || !hasMore) return; // 🔥 ADD THIS

    isLoadingMore = true;

    try {
      http.Response response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"friendId": friendId}),
      );

      // Refresh token if unauthorized
      if (response.statusCode == 401) {
        final refreshed = await accessTokenGenerator(context);
        if (!refreshed) return;

        token = await storage.read(key: "access_token");
        if (token == null) return;

        response = await http.post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({"friendId": friendId}),
        );
      }

      if (response.statusCode == 200) {
        final List<dynamic> res = jsonDecode(response.body);
        if (!mounted) return;

        final List<Message> fetchedMessages =
        res.map((e) => Message.fromJson(e)).toList();

        setState(() {
          if (initialMessageId == null) {
            // 🔹 First load (old code style)
            messages = fetchedMessages;
            selectMessage =
            List<bool>.filled(messages.length, false, growable: true);

            if (messages.isNotEmpty) {
              initialMessageId = messages.last.id; // cursor for pagination
            }
          } else {
            // 🔹 Load more (pagination)
            messages.addAll(fetchedMessages);
            selectMessage.addAll(
                List<bool>.filled(fetchedMessages.length, false));

            if (messages.isNotEmpty) {
              initialMessageId = messages.last.id; // update cursor
            }

            if (fetchedMessages.isEmpty) {
              hasMore = false; // stop further loading
            }
          }

          isLoading = false;
          isLoadingMore = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          isLoading = false;
          isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      debugPrint("Exception in getChat: $e");
    }
  }
  Map<int, double> _dragOffsets = {};

  @override
  Widget build(BuildContext context) {
    final messageCountRead = context.read<Chatoptionprovider>();
    final selectedIds = messageCountRead;
    final friend = Provider.of<FriendProvider>(context).friend;
    if (friend?.id == null) {
      return Center(child: Text("No message found"));
    }

    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return Center(child: Text("No messages yet"));
    }

    // Make sure selectMessage list is initialized

    return ValueListenableBuilder<bool>(
        valueListenable: selectModeNotifier,
        builder: (context, isSelectMode, _) {
          if (selectMessage.length != messages.length) {
            selectMessage = List<bool>.filled(messages.length, false, growable: true);
          }
          if (!isSelectMode) {
            for (int i = 0; i < selectMessage.length; i++) {
              selectMessage[i] = false;
            }
          }
      return ListView.builder(
        padding: EdgeInsets.only(bottom: 45),
        itemCount: messages.length + (isLoadingMore ? 1 : 0),
        reverse: true,
        controller: _scrollController,
        itemBuilder: (cont,index){
          if (isLoadingMore && index == messages.length) {
            return const Padding(
              padding: EdgeInsets.all(10),
              child: Center(
                child: SizedBox(
                  height: 25,
                  width: 25,
                  child: CircularProgressIndicator(strokeWidth: 2,color: Colors.blue,),
                ),
              ),
            );
          }
          final currentMessage = messages[index];
          final currentDate = parseUtc(currentMessage.messageAt.toString());
          bool showDateHeader = false;
          if (index == messages.length - 1) {
            // last item (top-most because reverse:true)
            showDateHeader = true;
          } else {
            final nextMessage = messages[index + 1];
            final nextDate = parseUtc(nextMessage.messageAt.toString());

            if (!isSameDay(currentDate, nextDate)) {
              showDateHeader = true;
            }
          }
          final colorScheme = Theme.of(context).colorScheme;
          final isSelectModeOn = Provider.of<Chatoptionprovider>(context,listen: false).getSelectMode();
          return Column(
                  children: [
                    if (showDateHeader)
                      dateHeader(getDayLabel(currentDate)),
                    Container(
                      color: (isSelectMode && selectMessage[index])
                          ? colorScheme.primary.withOpacity(0.15)
                          : Colors.transparent,
                      child: InkWell(
                        onLongPress: () {
                          if (isSelectMode == false) {
                            selectMessage[index] = !selectMessage[index];
                            messageCountRead.incrementSelectionCount();
                            messageCountRead.selectModeStatus();
                            String? content ;
                            if(currentMessage.messageType == "text"){
                              content = currentMessage!.messageText;
                            }
                            if(currentMessage.messageType == "image" || currentMessage.messageType == "video"){
                              content = currentMessage!.messageUrl!.networkUrl;
                            }
                            selectedIds.addSelectedIds(
                                currentMessage.id, currentMessage.messageType,content!);
                            setState(() {});
                          }
                        },
                        onTap: () {
                          if (isSelectMode) {
                            if (!selectMessage[index]) {
                              messageCountRead.incrementSelectionCount();
                              String? content ;
                              if(currentMessage.messageType == "text"){
                                content = currentMessage!.messageText;
                              }
                              if(currentMessage.messageType == "image" || currentMessage.messageType == "video"){
                                content = currentMessage!.messageUrl!.networkUrl;
                              }
                              selectedIds.addSelectedIds(
                                  currentMessage.id, currentMessage.messageType,content!);
                            } else {
                              messageCountRead.decrementSelectionCount();
                              selectedIds.removeSelectedIds(currentMessage.id);
                            }
                            selectMessage[index] = !selectMessage[index];
                            setState(() {});
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: 4),
                          width: double.infinity,
                          child: Stack(
                            children: [
                              if(isSelectMode)
                                Positioned(left: -200,
                                    child: Checkbox(value: selectMessage[index],
                                        onChanged: (value) {})),
                              if (messages[index].messageType == "text") Align(
                                alignment: (messages[index].itsMe == true)
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      maxWidth: MediaQuery
                                          .of(context)
                                          .size
                                          .width * .76,
                                      minWidth: 104
                                  ),
                                  child: GestureDetector(
                                    onHorizontalDragUpdate: (details) {
                                      setState(() {
                                        _dragOffsets[index] = (_dragOffsets[index] ?? 0) + details.delta.dx * 0.5;

                                        // clamp
                                        if (_dragOffsets[index]! > 30) _dragOffsets[index] = 30;
                                        if (_dragOffsets[index]! < -30) _dragOffsets[index] = -30;
                                      });
                                    },
                                    onHorizontalDragEnd: (details) {
                                      // Animate back to original position
                                      setState(() {
                                        _dragOffsets[index] = 0;
                                      });

                                      // Optional: detect swipe direction
                                      if (details.primaryVelocity != null) {
                                        final provider = context.read<Chatoptionprovider>();
                                        String? content ;
                                        if(currentMessage.messageType == "text"){
                                          content = currentMessage!.messageText;
                                        }
                                        if(currentMessage.messageType == "image" || currentMessage.messageType == "video"){
                                          content = currentMessage!.messageUrl!.networkUrl;
                                        }
                                        provider.setSwipeSelectedMessage(
                                            currentMessage.id, currentMessage.messageType,content!);
                                        provider.selectForwardMode(true);
                                      }
                                    },
                                    child: Transform.translate(
                                      offset:Offset(_dragOffsets[index] ?? 0, 0),
                                      child: Container(
                                        padding: EdgeInsets.only(top: 5,
                                            bottom: 2,
                                            left: 12,
                                            right: 12),
                                        decoration: BoxDecoration(
                                          color: (messages[index].itsMe == true)
                                              ? Color(0xff353658)
                                              : Color(0xff212121),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [

                                            /// 🔹 Main Content (Forward + Message)
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [

                                                /// 🔁 Forward Preview
                                                if (messages[index].isForward == true) ...[
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                                    // margin: const EdgeInsets.only(bottom: 6),
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      color: Colors.black.withOpacity(0.2),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text(
                                                          "Reply",
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.white70,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(height: 4),

                                                        if (messages[index].forwardType == "text")
                                                          Text(
                                                            messages[index].forwardContent ?? "",
                                                            maxLines: 2,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: const TextStyle(
                                                                fontSize: 13,
                                                                color: Colors.white
                                                            ),
                                                          )
                                                        else if (messages[index].forwardType == "image") ...[
                                                          if (messages[index].forwardContent != null &&
                                                              messages[index].forwardContent!.isNotEmpty)
                                                            Row(
                                                              children: [
                                                                ClipRRect(
                                                                  borderRadius: BorderRadius.circular(0),
                                                                  child: Image.network(
                                                                    messages[index].forwardContent!,
                                                                    height: 60,
                                                                    width: 60,
                                                                    fit: BoxFit.cover,
                                                                  ),
                                                                ),
                                                                SizedBox(width: 10),
                                                                Icon(Icons.image,
                                                                    size: 16, color: Colors.white70),
                                                                SizedBox(width: 4),
                                                                Text("Photo",
                                                                    style: TextStyle(color: Colors.white70)),
                                                              ],
                                                            ),
                                                        ]
                                                        else if (messages[index].forwardType == "video")
                                                            const Row(
                                                              children: [
                                                                Icon(Icons.videocam,
                                                                    size: 16, color: Colors.white70),
                                                                SizedBox(width: 4),
                                                                Text("Video",
                                                                    style: TextStyle(color: Colors.white70)),
                                                              ],
                                                            ),
                                                      ],
                                                    ),
                                                  ),
                                                ],

                                                /// 💬 Actual Message
                                                Text(
                                                  messages[index].messageText ?? "",
                                                  softWrap: true,
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    color: Colors.white,
                                                  ),
                                                ),

                                                const SizedBox(height: 12), // space for time
                                              ],
                                            ),

                                            /// 🕒 Time (Positioned)
                                            Positioned(
                                              right: 0,
                                              bottom: 0,
                                              child: messages[index].itsMe == true
                                                  ? Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    getTimeInAmPm(
                                                        messages[index].messageAt.toString()),
                                                    style: const TextStyle(
                                                        color: Colors.white, fontSize: 12),
                                                  ),
                                                  const SizedBox(width: 5),
                                                  Icon(
                                                    Icons.remove_red_eye_outlined,
                                                    size: 18,
                                                    color: messages[index].seenStatus
                                                        ? Colors.blue
                                                        : Colors.blueGrey,
                                                  ),
                                                ],
                                              )
                                                  : Text(
                                                getTimeInAmPm(
                                                    messages[index].messageAt.toString()),
                                                style: const TextStyle(
                                                    color: Colors.white, fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),                                  ),
                                    ),
                                  ),
                                ),
                              ) else Align(
                                alignment: (messages[index].itsMe == true)
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: GestureDetector(
                                  onHorizontalDragUpdate: (details) {
                                    setState(() {
                                      _dragOffsets[index] = (_dragOffsets[index] ?? 0) + details.delta.dx * 0.5;

                                      // clamp
                                      if (_dragOffsets[index]! > 30) _dragOffsets[index] = 30;
                                      if (_dragOffsets[index]! < -30) _dragOffsets[index] = -30;
                                    });
                                  },
                                  onHorizontalDragEnd: (details) {
                                    // Animate back to original position
                                    setState(() {
                                      _dragOffsets[index] = 0;
                                    });

                                    // Optional: detect swipe direction
                                    if (details.primaryVelocity != null) {
                                      final provider = context.read<Chatoptionprovider>();
                                      String? content ;
                                      if(currentMessage.messageType == "text"){
                                        content = currentMessage!.messageText;
                                      }
                                      if(currentMessage.messageType == "image" || currentMessage.messageType == "video"){
                                        content = currentMessage!.messageUrl!.networkUrl;
                                      }
                                      provider.setSwipeSelectedMessage(
                                          currentMessage.id, currentMessage.messageType,content!);
                                      provider.selectForwardMode(true);
                                    }
                                  },
                                  child: Transform.translate(
                                    offset: Offset(_dragOffsets[index] ?? 0, 0),
                                    child: Container(
                                      width: 280,
                                      height: 250,
                                      padding: EdgeInsets.only(
                                          top: 6, bottom: 6, left: 6, right: 6),
                                      decoration: BoxDecoration(
                                        color: (messages[index].itsMe == true)
                                            ? Color(0xff353658)
                                            : Color(0xff212121),
                                        borderRadius: messages[index]
                                            .messageType == "audio" ? BorderRadius
                                            .circular(15) : BorderRadius.circular(
                                            0),
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          if (messages[index].messageType =="image") ...[
                                            !isSelectModeOn ? InkWell(
                                              onTap: () {
                                                final imageUrl = messages[index]
                                                    .messageUrl?.networkUrl;
                                                if (imageUrl != null && imageUrl.isNotEmpty) {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          Imageviewpage(
                                                            sender: messages[index].itsMe == true
                                                                ? "You"
                                                                : (widget.name?.isNotEmpty ?? false)
                                                                ? widget.name!
                                                                : formatIndianMobile(friend?.mobile ?? ""),
                                                            time: getTimeInAmPm(
                                                              messages[index].messageAt.toString(),
                                                            ),
                                                            src: imageUrl,
                                                          ),
                                                    ),
                                                  );
                                                }
                                              },
                                              child: SizedBox(
                                                height: double.infinity,
                                                width: double.infinity,
                                                child: Image.network(
                                                  messages[index].messageUrl
                                                      ?.networkUrl ?? '',
                                                  loadingBuilder: (context, child,
                                                      loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return SizedBox(
                                                      height: 250,
                                                      child: Center(
                                                          child: CircularProgressIndicator()),
                                                    );
                                                  },
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      Container(
                                                        height: 250,
                                                        color: Colors.black12,
                                                        child: Icon(
                                                            Icons.broken_image,
                                                            color: Colors.white54),
                                                      ),
                                                ),
                                              ),
                                            ):SizedBox(
                                              height: double.infinity,
                                              width: double.infinity,
                                              child: Image.network(
                                                messages[index].messageUrl
                                                    ?.networkUrl ?? '',
                                                loadingBuilder: (context, child,
                                                    loadingProgress) {
                                                  if (loadingProgress == null)
                                                    return child;
                                                  return SizedBox(
                                                    height: 250,
                                                    child: Center(
                                                        child: CircularProgressIndicator()),
                                                  );
                                                },
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
                                                    Container(
                                                      height: 250,
                                                      color: Colors.black12,
                                                      child: Icon(
                                                          Icons.broken_image,
                                                          color: Colors.white54),
                                                    ),
                                              ),
                                            ),
                                            Positioned(
                                              right: 6,
                                              bottom: 2,
                                              child: messages[index].itsMe == true
                                                  ? Row(
                                                spacing: 5,
                                                children: [
                                                  Text(
                                                    getTimeInAmPm(
                                                        messages[index].messageAt
                                                            .toString()),
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12),
                                                  ),
                                                  Icon(
                                                    Icons.remove_red_eye_outlined,
                                                    color: messages[index]
                                                        .seenStatus
                                                        ? Colors.blue
                                                        : Colors.blueGrey,
                                                    size: 18,)
                                                ],
                                              )
                                                  : Text(
                                                getTimeInAmPm(
                                                    messages[index].messageAt
                                                        .toString()),
                                                style: TextStyle(
                                                    color: Colors.white),
                                              ),
                                            ),
                                          ],
                                          if(messages[index].messageType ==
                                              "video")...[
                                            VideoMessageBubble(
                                                url: messages[index].messageUrl
                                                    ?.networkUrl ?? ''),
                                            Positioned(
                                                right: 6,
                                                bottom: 2,
                                                child: messages[index].itsMe ==
                                                    true ? Row(
                                                  spacing: 5,
                                                  children: [
                                                    Text(getTimeInAmPm(
                                                        messages[index].messageAt
                                                            .toString()),
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12),),
                                                    Icon(Icons
                                                        .remove_red_eye_outlined,
                                                      color: messages[index]
                                                          .seenStatus ? Colors
                                                          .blue : Colors.blueGrey,
                                                      size: 18,)
                                                  ],) : Text(getTimeInAmPm(
                                                    messages[index].messageAt
                                                        .toString()),
                                                  style: TextStyle(
                                                      color: Colors.white,fontSize: 12),)),
                                          ],
                                          if(messages[index].messageType ==
                                              MessageType.audio)...[
                                            AudioMessage(
                                                url: messages[index].messageUrl
                                                    ?.networkUrl ?? ''),
                                            Positioned(
                                                right: 4,
                                                bottom: -12,
                                                child: messages[index].itsMe ==
                                                    true ? Row(
                                                  spacing: 5,
                                                  children: [
                                                    Text(getTimeInAmPm(
                                                        messages[index].messageAt
                                                            .toString()),
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 12),),
                                                    Icon(Icons
                                                        .remove_red_eye_outlined,
                                                      color: Colors.blue,
                                                      size: 18,)
                                                  ],) : Text(getTimeInAmPm(
                                                    messages[index].messageAt
                                                        .toString()),
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12),)),
                                          ]
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              });
        });
  }

  String getTimeInAmPm(String isoDate) {
    DateTime dt = DateTime.parse(isoDate);
    // Format as hour:minute AM/PM
    return DateFormat.jm().format(dt.toLocal());
  }

  DateTime parseUtc(String date) {
    return DateTime.parse(date).toLocal();
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String getDayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDay = DateTime(date.year, date.month, date.day);

    if (messageDay == today) {
      return "Today";
    } else if (messageDay == today.subtract(const Duration(days: 1))) {
      return "Yesterday";
    } else {
      return DateFormat('dd MMM yy').format(date); // 12 Jan 26
    }
  }

  Widget dateHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            text,
            style: const TextStyle(color: Colors.black, fontSize: 12),
          ),
        ),
      ),
    );
  }

}


class InputBox extends StatefulWidget{
  final VoidCallback onSend;
  final FocusNode focusNode;
  const InputBox({Key? key, required this.onSend,required this.focusNode,}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
   return InputBoxState();
  }
}

class InputBoxState extends State<InputBox>{
  final storage = FlutterSecureStorage();
  final TextEditingController _controller = TextEditingController();
  ValueNotifier<bool> isForward = ValueNotifier(false);
  ValueNotifier<Map<String, String>?> selectedMessage = ValueNotifier(null);
  bool _isEmojiVisible = false;

  void _toggleEmojiKeyboard() {
    if (_isEmojiVisible) {
      widget.focusNode.requestFocus(); // show keyboard
    } else {
      widget.focusNode.unfocus(); // hide keyboard
    }
    setState(() {
      _isEmojiVisible = !_isEmojiVisible;
    });
  }

  Future<void> pickFIle() async{
    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true,type: FileType.media);
    if(result != null){
      Navigator.push(context, MaterialPageRoute(builder: (context)=> Selectedmediapreviewpage(selectedFiles: result)));
    }
  }

  final AudioPlayer _player = AudioPlayer(); // initialize once

  Future<void> sendMessage() async {
    final friend = Provider.of<FriendProvider>(context, listen: false).friend;
    final socketService = SocketService.instance;
    final isForward = context.read<Chatoptionprovider>().getSelectForwardMode();
    final provider = context.read<Chatoptionprovider>();
    final selectedMessage = provider.getSelectedMessage();
    if (_controller.text.trim().isEmpty || friend?.id == null) return;

    final message = {
      "type": "CREATE_MESSAGE",
      "receiverId": friend!.id,
      "messageType": "text",
      "messageText": _controller.text.trim(),
      "isForward": isForward,
      "forwardedId":selectedMessage?['id'],
      "forwardType":selectedMessage?['type'],
      "forwardContent":selectedMessage?['content']
    };

    if(isForward){
      provider.removeSelectedMessage();
      provider.selectForwardMode(false);
    }
    // Try to connect if not connected, but don't block message sending
    if (!socketService.isConnected) {
      socketService.connect(context); // trigger reconnect but don't await
    }

    try {
      // Send message immediately; let SocketService handle retry if needed
      socketService.send(message);

      setState(() {
        _controller.text = '';
      });

      await _player.play(AssetSource('audios/send.mp3'));
    } catch (e) {
      print("Error sending message or playing sound: $e");
    }
  }

  @override
  void dispose() {
    isForward.dispose();
    selectedMessage.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    widget.focusNode.addListener(() {
      if (widget.focusNode.hasFocus) {
        setState(() {
          _isEmojiVisible = false; // hide emoji when keyboard opens
        });
      }
    });
    final provider = context.read<Chatoptionprovider>();
    isForward = ValueNotifier(provider.getSelectForwardMode());
    selectedMessage = ValueNotifier(provider.getSelectedMessage());
    provider.addListener((){
      isForward.value = provider.getSelectForwardMode();
      selectedMessage.value = provider.getSelectedMessage();
    });
    _controller.addListener(() {
      setState(() {});
    });
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<Chatoptionprovider>();
    // final selectedMessage = context.watch<Chatoptionprovider>().getSelectedMessage();
    return Container(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
        child: Form(
          child: Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: isForward,
                builder: (context, value, child) {
                  if (!value) return SizedBox(); // hide if false
                  return Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -20,
                          top: -20,
                          child: IconButton(
                            onPressed: () {
                              final provider = context.read<Chatoptionprovider>();
                              provider.removeSelectedMessage();
                              provider.selectForwardMode(false);
                            },
                            icon: Icon(Icons.clear, size: 18),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                            child: ValueListenableBuilder<Map<String, String>?>(
                              valueListenable: selectedMessage,
                              builder: (context, msg, child) {
                                if (msg == null) return const SizedBox();

                                switch (msg['type']) {
                                  case "text":
                                    return Text(
                                      msg['content'] ?? '',
                                      maxLines: 3,
                                    );
                                  case "image":
                                    return Image.network(
                                      msg['content'] ?? '',
                                      height: 60,
                                      fit: BoxFit.cover,
                                    );
                                  case "video":
                                    return Row(
                                      children: [
                                        const Icon(Icons.videocam),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            "Video",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    );
                                  default:
                                    return const SizedBox();
                                }
                              },
                            )
                        ),
                      ],
                    ),
                  );
                },
              ),
              TextFormField(
                controller: _controller,
                focusNode: widget.focusNode,
                minLines: 1,
                maxLines: 4,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface, // adaptive text
                  fontSize: 17,
                ),
                cursorColor: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: pickFIle,
                          icon: Icon(
                            Ionicons.attach,
                            size: 25,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          onPressed: _toggleEmojiKeyboard,
                          icon: Icon(
                            Ionicons.happy,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  suffixIcon: IconButton(
                    onPressed: _controller.text.isNotEmpty ? sendMessage : null,
                    icon: Icon(
                      Ionicons.send,
                      color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                    ),
                    disabledColor: isDark ? Colors.white54 : Colors.black38,
                  ),
                  fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                  filled: true,
                  hintText: "Message",
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black45,
                    fontSize: 16,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: isForward.value
                        ? BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    )
                        : BorderRadius.circular(40),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              Offstage(
                offstage: !_isEmojiVisible,
                child: SizedBox(
                  height: 250,
                  child: EmojiPicker(
                    onEmojiSelected: (category, emoji) {
                      _controller.text += emoji.emoji;
                    },
                    config: Config(
                      emojiViewConfig: EmojiViewConfig(
                        columns: 9,
                        emojiSizeMax: 32,
                      ),
                      height: 250,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}