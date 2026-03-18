import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:provider/provider.dart';
import 'package:vaarta_app/Config/LocalNotification.dart';
import 'package:vaarta_app/Config/WebSocket.dart';
import 'package:vaarta_app/PermissionHelper/ContactPermission.dart';
import 'package:vaarta_app/Providers/ContactsProvider.dart';
import 'package:vaarta_app/Providers/MenuIndexProvider.dart';
import 'package:vaarta_app/Screens/ChatsPage.dart';
import 'package:vaarta_app/Screens/ContactsScreen.dart';
import 'package:vaarta_app/Screens/SettingsScreen.dart';
import 'package:vaarta_app/Screens/StatusScreen.dart';

class Homescreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return HomescreenState();
  }
}

class HomescreenState extends State<Homescreen>{
  @override
  void initState() {
    super.initState();
    _initSocket();
  }
  void _initSocket()async{
    final socketService = SocketService.instance;
    socketService.connect(context);
  }
  List <Widget> pages = [
    Chatspage(),
    Statusscreen(),
    Contactsscreen(),
    Settingsscreen()
  ];

  @override
  Widget build(BuildContext context){
    int index = context.watch<MenuindexProvider>().getIndex();

    return PopScope(
      canPop: context.watch<MenuindexProvider>().getHistoryTab().length < 2 ? true : false,
      onPopInvokedWithResult: (didPop, result) {
        final provider = context.read<MenuindexProvider>();
        if(provider.getHistoryTab().length > 1){
          provider.removeHistoryTab();
          provider.setIndex(provider.getHistoryTab().last);
        }
      },

      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 0,
        ),
        body: SafeArea(
          child: IndexedStack(
            index: index,
            children: pages,
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
            // backgroundColor: Color(0xff09090e),
            // type: BottomNavigationBarType.fixed,
            // iconSize: 30, // slightly smaller icons
            // selectedFontSize: 12, // reduce label font size
            // unselectedFontSize: 12,
            // selectedItemColor: Colors.white,
            // unselectedItemColor: Colors.white,
            currentIndex: index,
            onTap: (value) {
              context.read<MenuindexProvider>().setIndex(value);
              if (context.read<MenuindexProvider>().getHistoryTab().last != value) {
                context.read<MenuindexProvider>().setHistoryTab(value);
              }
            },
            items: [
              BottomNavigationBarItem(
                icon: Icon(index == 0 ? Ionicons.chatbox_ellipses : Ionicons.chatbox_ellipses_outline),
                label: "Chats",
              ),
              BottomNavigationBarItem(
                icon: Icon(index == 1 ? Ionicons.at_circle : Ionicons.at_circle_outline),
                label: "Status",
              ),
              BottomNavigationBarItem(
                icon: Icon(index == 2 ? Ionicons.people : Ionicons.people_outline),
                label: "Contacts",
              ),
              BottomNavigationBarItem(
                icon: Icon(index == 3 ? Ionicons.settings : Ionicons.settings_outline),
                label: "Settings",
              ),
            ],
          ),

        ),
    );
  }
}