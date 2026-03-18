import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vaarta_app/Config/Constants.dart';
import 'package:vaarta_app/Data/TokenStorage.dart';
import 'package:vaarta_app/Login_Logup/LoginPage.dart';
import 'package:http/http.dart' as http;

Future<bool> accessTokenGenerator(BuildContext context) async {
  final refreshUrl =
  Uri.parse("${ApiConstant.baseUrl}/user/refresh-token");
  final storage = FlutterSecureStorage();
  final refreshToken =
        await storage.read(key: "refresh_token");

    if (refreshToken == null) {
      await storage.deleteAll();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Loginpage()),
      );
      return false;
    }

    final refreshResponse = await http.get(
      refreshUrl,
      headers: {
        'Authorization': 'Bearer $refreshToken',
        'Content-Type': 'application/json',
      },
    );

    // ❌ Refresh token invalid
    if (refreshResponse.statusCode != 200) {
      await storage.deleteAll();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => Loginpage()),
      );
      return false;
    }

    final refreshData = jsonDecode(refreshResponse.body);
    final newAccessToken = refreshData["accessToken"];

    if (newAccessToken == null) return false;

    await TokenStorage.updateAccessToken(newAccessToken);
    return true;
}
