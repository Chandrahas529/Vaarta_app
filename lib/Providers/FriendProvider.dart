import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:vaarta_app/Config/Constants.dart';
import 'package:vaarta_app/Data/AccessTokenGenerator.dart';
import 'package:vaarta_app/Modals/FriendModal.dart';
import 'package:http/http.dart' as http;
class FriendProvider extends ChangeNotifier{
  final storage = FlutterSecureStorage();
  Friend? _friend ;
  bool isLoading = false;
  String? _error ;

  Friend? get friend => _friend;
  bool get loading => isLoading;
  String? get error => _error;

Future<void> getFriendDetailsFromServer(String id,BuildContext context) async {
    isLoading = true;
    notifyListeners();
    String? token = await storage.read(key: 'access_token');
    final url = Uri.parse("${ApiConstant.baseUrl}/user/friend-details");
    if(token != null){
      try{
        http.Response response = await http.post(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            "Content-Type":"application/json"
          },
          body: jsonEncode({"id":id})
        );
        if(response.statusCode == 401){
          final refreshed = await accessTokenGenerator(context);
          if (!refreshed) return ;
          token = await storage.read(key: "access_token");
          if(token==null)return;
          response = await http.post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({"id":id})
          );
        }
        if(response.statusCode == 200){
          final res = jsonDecode(response.body);
          _friend = Friend.fromJson(res);
          _error = null;
          notifyListeners();
        }
        else{
          _error = "Server error: ${response.statusCode}";
        }
      }
      catch(e){
        _error = e.toString();
      }finally{
        isLoading = false;
        notifyListeners();
      }
    }
  }
}