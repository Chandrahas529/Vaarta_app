import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:provider/provider.dart';
import 'package:vaarta_app/Config/LocalNotification.dart';
import 'package:vaarta_app/Config/WebSocket.dart';
import 'package:vaarta_app/Login_Logup/LoginPage.dart';
import 'package:vaarta_app/PermissionHelper/ContactPermission.dart';
import 'package:vaarta_app/Providers/ChatOptionProvider.dart';
import 'package:vaarta_app/Providers/ContactsProvider.dart';
import 'package:vaarta_app/Providers/FriendProvider.dart';
import 'package:vaarta_app/Providers/MenuIndexProvider.dart';
import 'package:vaarta_app/Providers/ThemeProvider.dart';
import 'package:vaarta_app/Providers/UserProvider.dart';
import 'package:vaarta_app/Screens/SplashScreen.dart';
import 'package:vaarta_app/Utils/theme.dart';
import 'package:vaarta_app/firebase_options.dart';
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print(message);
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initLocalNotifications(); // Ensure local notifications plugin is initialized
  await showLocalNotification(message); // This will display the notification
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await initLocalNotifications();
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
      bool granted = await requestContactsPermission(); // NEW
      if (granted) {
        await updateContactsCache();
      }
    }
    await showLocalNotification(message);
  });
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light
  ));

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_)=>MenuindexProvider()),
      ChangeNotifierProvider(create: (_)=>UserProvider()),
      ChangeNotifierProvider(create: (_)=>FriendProvider()),
      ChangeNotifierProvider(create: (_)=>ContactsProvider()),
      ChangeNotifierProvider(create: (_)=>Chatoptionprovider()),
      ChangeNotifierProvider(create: (_)=>ThemeProvider())
    ],
    child: MyApp(),
  ));
}

class MyApp extends StatefulWidget{
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("APP STATE: $state");

    final userProvider = context.read<UserProvider>();
    final socketService = SocketService.instance;

    // ✅ Only if authenticated
    if (!userProvider.isLoggedIn) return;

    if (state == AppLifecycleState.paused) {
      socketService.disconnect();
      print("🔌 Socket disconnected (background)");
    }

    if (state == AppLifecycleState.resumed) {
      socketService.connect(context);
      print("🔌 Socket reconnected (foreground)");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          navigatorObservers: [routeObserver],
          theme: TAppTheme.lightTheme,
          darkTheme: TAppTheme.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light, // use provider
          home: SplashScreen(),
        );
      },
    );
  }
}
