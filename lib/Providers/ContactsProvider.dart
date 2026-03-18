import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vaarta_app/Config/Constants.dart';
import 'package:vaarta_app/Data/AccessTokenGenerator.dart';
import 'package:vaarta_app/PermissionHelper/ContactPermission.dart';
import 'package:http/http.dart' as http;

class ContactsProvider extends ChangeNotifier {
  final storage = const FlutterSecureStorage();

  // Store contacts dynamically
  List<Map<String, dynamic>> contacts = [];
  bool isLoading = false;

  // Normalize Indian phone numbers
  String normalizeIndianPhone(String input) {
    String digits = input.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) return '';

    if (digits.startsWith('91') && digits.length == 12) return '+$digits';

    if (digits.length == 10) return '+91$digits';

    if (input.trim().startsWith('+')) return '+$digits';

    // fallback
    return digits.length >= 10 ? '+91${digits.substring(digits.length - 10)}' : '+$digits';
  }

  // Fetch device contacts and sync with backend
  Future<void> getContactNumbers(BuildContext context,{required bool granted}) async {
    bool hasPermission = granted;

    // Only request if NOT already granted
    if (!hasPermission) {
      hasPermission = await requestContactsPermission();
    }

    if (!hasPermission) {
      await showPermissionDeniedDialog(context);
      return;
    }

    try {
      isLoading = true;
      notifyListeners();

      final deviceContacts = await FlutterContacts.getContacts(withProperties: true);
      final List<Map<String, String>> payload = [];
      final Set<String> uniquePhones = {};

      for (final contact in deviceContacts) {
        final name = contact.displayName ?? "";

        for (final phone in contact.phones) {
          if (phone.number.isEmpty) continue;

          final normalized = normalizeIndianPhone(phone.number);
          if (uniquePhones.contains(normalized)) continue;

          uniquePhones.add(normalized);

          payload.add({
            "name": name,
            "phone": phone.number,
            "normalizedPhone": normalized,
          });
        }
      }

      if (payload.isEmpty) {
        contacts = [];
        return;
      }

      final friendsUrl = Uri.parse("${ApiConstant.baseUrl}/user/friends-list");
      String? token = await storage.read(key: "access_token");
      if (token == null) return;

      http.Response response = await http.post(
        friendsUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      // Refresh token if token expired
      if (response.statusCode == 401) {
        final refreshed = await accessTokenGenerator(context);
        if (!refreshed) return;

        token = await storage.read(key: "access_token");
        if (token == null) return;

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
        try {
          final decoded = jsonDecode(response.body);

          if (decoded is! Map<String, dynamic>) {
            throw Exception("Expected a JSON object, got ${decoded.runtimeType}");
          }

          final dataList = decoded['data'];
          if (dataList is! List) {
            throw Exception("Expected 'data' to be a List, got ${dataList.runtimeType}");
          }

          // Store dynamically
          contacts = dataList.map<Map<String, dynamic>>((e) {
            if (e is Map<String, dynamic>) return e;
            return {};
          }).toList();

        } catch (e) {
          debugPrint("Error decoding JSON: $e");
          contacts = [];
        }
      } else {
        debugPrint("Server error: ${response.statusCode} body: ${response.body}");
        contacts = [];
      }
    } catch (e) {
      debugPrint("Network error: $e");
      contacts = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Show permission denied dialog
  Future<void> showPermissionDeniedDialog(BuildContext context) async {
    final shouldOpenSettings = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text("Permission Required", style: TextStyle(color: Colors.white)),
          content: const Text(
            "We need access to your contacts to help you find friends.\n\nPlease allow contacts permission from settings.",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("Open Settings", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (shouldOpenSettings == true) {
      openAppSettings();
    }
  }
}
