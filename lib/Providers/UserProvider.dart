import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:vaarta_app/Config/Constants.dart';
import 'package:vaarta_app/Data/AccessTokenGenerator.dart';
import 'package:vaarta_app/Modals/UserModal.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
class UserProvider extends ChangeNotifier{
  final storage = FlutterSecureStorage();
  User? _user;
  bool isLoading = false;
  String? _error;
  User? get user => _user;
  bool get loading => isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user != null;

  Future<void> getDataFromServer(BuildContext context) async {
    isLoading = true;
    notifyListeners();
    String? token = await storage.read(key: 'access_token');
    final url = Uri.parse("${ApiConstant.baseUrl}/user/profile");

    if(token != null){
      try{
        http.Response response = await http.post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              "Content-Type":"application/json"
            },
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
          );
        }
        if(response.statusCode == 200){
          final res = jsonDecode(response.body);
          _user = User.fromJson(res);
          _error = null;
        }else{
          _error = "Server error: ${response.statusCode}";
        }
      }catch(e){
        _error = e.toString();
      }finally{
        isLoading = false;
        notifyListeners();
      }
    }
  }
}