import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:vaarta_app/Login_Logup/LoginPage.dart';

import '../Config/Constants.dart';
import '../Data/AccessTokenGenerator.dart';
import '../Providers/MenuIndexProvider.dart';
import '../Config/WebSocket.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({Key? key}) : super(key: key);

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final TextEditingController passwordController = TextEditingController();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> deleteAccount() async {
    final password = passwordController.text.trim();

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password is required")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      String? token = await storage.read(key: 'access_token');
      if (token == null) return;

      final url =
      Uri.parse("${ApiConstant.baseUrl}/user/delete-account");

      Future<http.Response> deleteWithToken(String token) {
        return http.delete(
          url,
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
          },
          body: jsonEncode({
            "password": password,
          }),
        );
      }

      http.Response response = await deleteWithToken(token);

      // Handle 401
      if (response.statusCode == 401) {
        final refreshed = await accessTokenGenerator(context);
        if (!refreshed) return;

        token = await storage.read(key: 'access_token');
        if (token == null) return;

        response = await deleteWithToken(token);
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {

        SocketService.instance.disconnect();

        await storage.deleteAll();

        context.read<MenuindexProvider>().setIndex(0);

        if (!mounted) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => Loginpage()),
              (route) => false,
        );
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Failed to delete account")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Something went wrong")),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff09090e),
      appBar: AppBar(
        backgroundColor: const Color(0xff09090e),
        title: const Text(
          "Delete Account",
          style: TextStyle(color: Colors.white,fontSize: 18),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your password to permanently delete your account.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Password",
                hintStyle: const TextStyle(color: Colors.white54),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : deleteAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text(
                  "Delete Account",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
}
