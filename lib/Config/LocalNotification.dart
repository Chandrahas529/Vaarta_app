import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vaarta_app/PermissionHelper/ContactPermission.dart';
import 'package:http/http.dart' as http;

import 'package:vaarta_app/Screens/UserChatPage.dart';
import 'package:vaarta_app/main.dart';

/// 🔔 Notification plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

final storage = FlutterSecureStorage();
/// 📇 Contact cache
final Map<String, String> contactNameByPhone = {};

String normalizedPhone(String input) {
  String digits = input.replaceAll(RegExp(r'\D'), '');

  if (digits.isEmpty) return '';

  if (digits.startsWith('91') && digits.length == 12) return '+$digits';

  if (digits.length == 10) return '+91$digits';

  if (input.trim().startsWith('+')) return '+$digits';

  // fallback
  return digits.length >= 10 ? '+91${digits.substring(digits.length - 10)}' : '+$digits';
}

Future<void> saveContactsList(List<Map<String, dynamic>> contacts) async {
  await storage.write(key: 'contactsList', value: jsonEncode(contacts));
}

/// Load contacts from storage
Future<List<Map<String, dynamic>>> loadContactsList() async {
  final data = await storage.read(key: 'contactsList');
  if (data == null) return [];
  final list = jsonDecode(data);
  if (list is List) {
    return list.map<Map<String, dynamic>>((e) {
      if (e is Map<String, dynamic>) return e;
      return {};
    }).toList();
  }
  return [];
}

Future<void> initLocalNotifications() async {
  final AndroidInitializationSettings androidInit =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initSettings =
  InitializationSettings(android: androidInit);


  await flutterLocalNotificationsPlugin.initialize(
    settings: initSettings,
    onDidReceiveNotificationResponse: (details) {
      final payload = details.payload;
      if (payload != null && payload.isNotEmpty) {
        // Assuming payload is JSON with senderName and senderId
        final data = jsonDecode(payload);
        final senderName = data['senderName'] ?? "Unknown";
        final senderId = data['senderId'];

        if (senderId != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => Userchatpage(
                name: senderName,
                id: senderId,
                key: ValueKey(senderId),
              ),
            ),
          );
        }
      }
    },
  );


  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel_test',
    'High Importance Notifications',
    description: 'Chat notifications',
    importance: Importance.max,
    playSound: true,
  );


  final androidPlugin =
  flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>();

  await androidPlugin?.createNotificationChannel(channel);
}

///////////////////////////////////////////////////////////////////////////////
/// UPDATE CONTACT CACHE (FOREGROUND ONLY)
///////////////////////////////////////////////////////////////////////////////
Future<void> updateContactsCache() async {
  final contacts = await FlutterContacts.getContacts(withProperties: true);
  final List<Map<String, dynamic>> contactsList = [];

  for (final contact in contacts) {
    final name = contact.displayName ?? "";
    for (final phone in contact.phones) {
      final normalized = normalizedPhone(phone.number);
      if (normalized.isNotEmpty) {
        contactNameByPhone[normalized] = name;
        contactsList.add({
          "name": name,
          "phone": phone.number,
          "normalizedPhone": normalized,
        });
      }
    }
  }

  await saveContactsList(contactsList); // save to secure storage
  debugPrint("Updated contacts cache: ${contactNameByPhone.length} contacts");
}

String formatIndianMobile(String mobile) {
  // Remove spaces, dashes, brackets
  String cleaned = mobile.replaceAll(RegExp(r'[^\d+]'), '');

  // Ensure it starts with +91
  if (cleaned.startsWith('0')) {
    cleaned = '+91' + cleaned.substring(1); // remove leading 0
  } else if (cleaned.startsWith('91')) {
    cleaned = '+$cleaned';
  } else if (!cleaned.startsWith('+91')) {
    cleaned = '+91$cleaned';
  }

  // After normalization, must have 13 chars (+91XXXXXXXXXX)
  if (cleaned.length != 13) return mobile; // fallback

  final countryCode = cleaned.substring(0, 3);   // +91
  final firstPart = cleaned.substring(3, 8);     // first 5 digits
  final secondPart = cleaned.substring(8, 13);   // last 5 digits

  return '$countryCode $firstPart $secondPart';
}


///////////////////////////////////////////////////////////////////////////////
/// RESOLVE SENDER NAME
///////////////////////////////////////////////////////////////////////////////
/// Resolve sender name (background/killed)
Future<String> resolveSenderName(String senderPhone, {bool isForeground = false}) async {
  final normalized = normalizedPhone(senderPhone);

  // 1️⃣ Only use memory cache if in foreground
  if (isForeground && contactNameByPhone.containsKey(normalized)) {
    return contactNameByPhone[normalized]!;
  }

  // 2️⃣ Fallback to storage
  final savedContacts = await loadContactsList();
  for (final contact in savedContacts) {
    if (contact['normalizedPhone'] == normalized) {
      return contact['name'] ?? senderPhone;
    }
  }

  // 3️⃣ Fallback to formatted number
  return formatIndianMobile(senderPhone);
}
///////////////////////////////////////////////////////////////////////////////
/// SHOW LOCAL NOTIFICATION (FOREGROUND + BACKGROUND)
Future<void> showLocalNotification(RemoteMessage message) async {
  final senderPhone = message.data['senderPhone'];
  final messageText = message.data['messageText'] ?? '';
  final messageType = message.data["messageType"] ?? "";
  final profileUrl = message.data['senderProfile'] == "" ?
      "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSOH2aZnIHWjMQj2lQUOWIL2f4Hljgab0ecZQ&s": message.data['senderProfile'];

  print(senderPhone);
  final isForeground = WidgetsBinding.instance.lifecycleState != null &&
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;


  // Always update cache if foreground
  if (isForeground) {
    await updateContactsCache();
  }

  // Resolve sender name, only using memory cache if foreground
  final title = await resolveSenderName(senderPhone, isForeground: isForeground);

  AndroidBitmap<Object>? largeIcon;

  // Load sender profile picture as circle
  if (profileUrl.isNotEmpty) {
    try {
      final response = await http.get(Uri.parse(profileUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        largeIcon = ByteArrayAndroidBitmap(bytes); // now circular
      }

    } catch (e) {
      debugPrint("Failed to load profile image: $e");
    }
  }

  final androidDetails = AndroidNotificationDetails(
    'high_importance_channel_test',
    'High Importance Notifications',
    channelDescription: 'Chat notifications',
    importance: Importance.max,
    playSound: true,
    sound: RawResourceAndroidNotificationSound('notification'),
    enableVibration: true,
    groupKey: 'chat_$senderPhone', // ✅ here you know the sender
    setAsGroupSummary: false, // individual message
    priority: Priority.high,
    icon: 'ic_notification',
    largeIcon: largeIcon,
  );

  final notificationDetails = NotificationDetails(android: androidDetails);
  final textShow = messageType == "text" ? messageText : "Sent you a $messageType";
  await flutterLocalNotificationsPlugin.show(
    id: message.hashCode,
    title: title,
    body: textShow,
    notificationDetails: notificationDetails,
    payload:jsonEncode({
      "senderName": title,
      "senderId": message.data['senderId'],
    }),
  );
}


/// Call this **once at app startup**, after login or when app resumes
Future<void> loadContactsOnStartup({bool granted = false}) async {
  final hasPermission = granted || await requestContactsPermission();
  if (!hasPermission) return;

  final contacts = await FlutterContacts.getContacts(withProperties: true);
  contactNameByPhone.clear();
  final List<Map<String, dynamic>> contactsList = [];

  for (final contact in contacts) {
    final name = contact.displayName ?? "";
    for (final phone in contact.phones) {
      final normalized = normalizedPhone(phone.number);
      if (normalized.isNotEmpty) {
        contactNameByPhone[normalized] = name;
        contactsList.add({
          "name": name,
          "phone": phone.number,
          "normalizedPhone": normalized,
        });
      }
    }
  }

  await saveContactsList(contactsList);
  debugPrint("Contacts loaded at startup: ${contactNameByPhone.length}");
}