import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:vaarta_app/Config/Constants.dart';
import 'package:vaarta_app/Config/LocalNotification.dart';
import 'package:vaarta_app/Data/TokenStorage.dart';
import 'package:vaarta_app/Login_Logup/LogupPage.dart';
import 'package:vaarta_app/PermissionHelper/ContactPermission.dart';
import 'package:vaarta_app/Providers/UserProvider.dart';
import 'package:vaarta_app/Screens/HomeScreen.dart';
import 'package:http/http.dart' as http;
import 'package:vaarta_app/Screens/handleRegistration.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<String?> getDeviceToken() async {
  try {
    String? token = await FirebaseMessaging.instance.getToken();
    print("FCM Device Token: $token");
    return token;
  } catch (e) {
    print("Error getting FCM token: $e");
    return null;
  }
}

Future<void> saveDeviceTokenToBackend(String token) async {
  final storage = FlutterSecureStorage();
  final url = Uri.parse("${ApiConstant.baseUrl}/user/device-token"); // your backend endpoint
  final accessToken = await storage.read(key: "access_token");

  if (accessToken == null) return;

  final body = {
    "deviceToken": token,
    "platform": "android" // or "ios" if needed
  };

  try {
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $accessToken"
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print("Device token saved successfully!");
    } else {
      print("Failed to save device token: ${response.body}");
    }
  } catch (e) {
    print("Error saving device token: $e");
  }
}


class Loginpage extends StatefulWidget{
  @override
  State<Loginpage> createState() => LoginPageState();
}

class LoginPageState extends State<Loginpage>{
  final _loginForm = GlobalKey<FormState>();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool hidePassword = true;
  bool isProcessing = false;
  String errorMessage = "";
  @override
  void dispose() {
    _passwordController.dispose();
    _mobileController.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: SafeArea(
          child: Container(
            color: Colors.black87,
            height: double.infinity,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 20,
                    children: [
                      Container(
                        child: Column(
                          spacing: 80,
                          children: [
                            CircleAvatar(
                              radius: 70,
                              backgroundColor: Colors.white,
                              child: const Text("VA",style: TextStyle(fontSize: 45,color: Colors.black),),
                            ),
                            Text("Login",style: TextStyle(fontWeight: FontWeight.w500,fontSize: 25,color: Colors.white)),
                          ],
                        ),
                      ),
                      Form(
                        key: _loginForm,
                          child: Column(
                            spacing: 40,
                            children: [
                              TextFormField(
                                controller: _mobileController,
                                keyboardType: TextInputType.number,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20
                                ),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.all(10),
                                  fillColor: Colors.black38,
                                  filled: true,
                                  labelText: "Mobile",
                                  prefixIcon: Icon(Icons.phone,color: Colors.white,),
                                  labelStyle: TextStyle(color: Colors.white),
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      width: 2,
                                      color: Colors.white24
                                    )
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white, width: 2),
                                  ),
                                  errorStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.red, width: 1),
                                  ),
                                ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                validator: (value) {
                                  if (value == null || value.length != 10) {
                                    return 'Enter a valid 10-digit mobile number';
                                  }
                                  return null;
                                },
                              ),
                              TextFormField(
                                controller: _passwordController,
                                keyboardType: TextInputType.text,
                                obscureText: hidePassword,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20
                                ),
                                decoration: InputDecoration(
                                  contentPadding: EdgeInsets.all(10),
                                  labelText: "Password",
                                  prefixIcon: Icon(Icons.lock,color: Colors.white,),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      hidePassword ?
                                        Icons.visibility_off : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: (){
                                      setState(() {
                                        hidePassword = !hidePassword;
                                      });
                                    },
                                  ),
                                  labelStyle: TextStyle(color: Colors.white),
                                  border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                          width: 2,
                                          color: Colors.white24
                                      )
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white, width: 2),
                                  ),
                                  errorStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(
                                      color: Colors.white,
                                      width: 1,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.red, width: 1),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (value.length < 6) {
                                    return 'Minimum 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(
                                child: Text(errorMessage,style: TextStyle(fontSize: 14,color: Colors.white),)
                              ),
                              Container(
                                width: double.infinity,
                                child: FilledButton(
                                    onPressed: !isProcessing ? () async {
                                      if(_loginForm.currentState!.validate()){
                                        setState(() {
                                          isProcessing = true;
                                          errorMessage = "";
                                        });
                                        try{
                                          final tokens = await _login(mobile:_mobileController.text, password:_passwordController.text);
                                          await TokenStorage.saveTokens(accessToken: tokens["accessToken"], refreshToken: tokens["refreshToken"]);
                                          final userProvider =
                                          Provider.of<UserProvider>(context, listen: false);

                                          await userProvider.getDataFromServer(context);
                                          final fcmToken = await getDeviceToken();
                                          if (fcmToken != null) {
                                            await saveDeviceTokenToBackend(fcmToken);
                                          }

                                          Navigator.pushReplacement(
                                              context, MaterialPageRoute(builder: (_) => Homescreen()));// Navigator.pushAndRemoveUntil(
                                        }catch(e){
                                          if(e is ApiException){
                                            setState(() {
                                              isProcessing = false;
                                              errorMessage = e.message;
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(e.message)),
                                                );
                                            });
                                            _loginForm.currentState!.validate();
                                          }
                                        }
                                      }
                                    }:null,
                                    style: FilledButton.styleFrom(
                                        backgroundColor: Colors.white,
                                      shape:RoundedRectangleBorder()
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      spacing: 10,
                                      children: [
                                        if(isProcessing)
                                        SizedBox(height: 30,width: 30,child: CircularProgressIndicator(color: Colors.black,)),
                                        Text("Login",style: TextStyle(fontSize: 18,color: Colors.black),),
                                      ],
                                    )
                                ),
                              ),
                              TextButton(onPressed: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context)=>Loguppage()));
                              }, child: Text("Create an account ?",style: TextStyle(color: Colors.white,fontSize: 18),))
                            ],
                          )
                      )
                    ],
                  ),
                ),
              ),
            ),
          )
      ),
    );
  }

  Future<Map<String,dynamic>> _login({required String mobile,required String password}) async {
    final url = Uri.parse("${ApiConstant.baseUrl}/user/login");
    final body = {
      "mobile": mobile,
      "password": password,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type":"application/json"},
        body: jsonEncode(body),
      );

      final res = jsonDecode(response.body);
      print(response);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (res["accessToken"] == null || res["refreshToken"] == null) {
          throw ApiException(message: "Missing tokens from server");
        }
        return {
          "accessToken": res["accessToken"],
          "refreshToken": res["refreshToken"],
        };
      }

      if (response.statusCode == 400 || response.statusCode == 409) {
        throw ApiException(
          message: res["message"] ?? "Validation error",
          fieldErrors: res["errors"],
        );
      }

      throw ApiException(message: res["message"] ?? "Something went wrong");

    } catch (e) {
      print(e);
      if (e is ApiException) rethrow;
      throw ApiException(message: "Unable to connect to server. Try again.");
    }
  }

}