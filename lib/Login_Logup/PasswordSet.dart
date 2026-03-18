import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaarta_app/Config/Constants.dart';
import 'package:vaarta_app/Config/LocalNotification.dart';
import 'package:vaarta_app/Data/TokenStorage.dart';
import 'package:vaarta_app/Login_Logup/LoginPage.dart';
import 'package:vaarta_app/PermissionHelper/ContactPermission.dart';
import 'package:vaarta_app/Providers/UserProvider.dart';
import 'package:vaarta_app/Screens/HomeScreen.dart';
import 'package:http/http.dart' as http;
import 'package:vaarta_app/Screens/handleRegistration.dart';

class Passwordset extends StatefulWidget{
  final String name;
  final String mobile;
  const Passwordset({super.key, required this.name, required this.mobile});
  @override
  State<Passwordset> createState() => PasswordsetState();
}

class PasswordsetState extends State<Passwordset> implements Exception{
  final _passwordKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool showPassword = true;
  bool showConfirmPassword = true;
  bool isPrcoessing = false;
  String errorMessage = "";
  Map<String, String?> fieldErrors = {};
  @override
  void dispose() {
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: SafeArea(
          child: Container(
            height: double.infinity,
            width: double.infinity,
            color: Colors.black87,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 40,
                children: [
                  Text("Set Your Password",style: TextStyle(fontSize: 25,color: Colors.white)),
                  Form(
                    key: _passwordKey,
                      child: Column(
                        spacing: 40,
                        children: [
                          TextFormField(
                            controller: _password,
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: showPassword,
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
                                  showPassword ?
                                  Icons.visibility_off : Icons.visibility,
                                  color: Colors.white,
                                ),
                                onPressed: (){
                                  setState(() {
                                    showPassword = !showPassword;
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
                          )
                          ,TextFormField(
                            controller: _confirmPassword,
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: showConfirmPassword,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 20
                            ),
                            decoration: InputDecoration(
                              contentPadding: EdgeInsets.all(10),
                              labelText: "Confirm Password",
                              prefixIcon: Icon(Icons.lock,color: Colors.white,),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  showConfirmPassword ?
                                  Icons.visibility_off : Icons.visibility,
                                  color: Colors.white,
                                ),
                                onPressed: (){
                                  setState(() {
                                    showConfirmPassword = !showConfirmPassword;
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
                                return 'Confirm password is required';
                              }
                              if (value != _password.text) {
                                return 'Confirm password does not match';
                              }
                              return null;
                            },
                          ),
                          if(fieldErrors.isNotEmpty)SizedBox(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: fieldErrors.entries.map<Widget>((entry) {
                                return Text(
                                  '${entry.key}: ${entry.value}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          if(errorMessage!=null)
                            SizedBox(
                              child: Text(errorMessage,style: TextStyle(fontSize: 14,color: Colors.white),)
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                onPressed: () async {
                                  setState(() {
                                    fieldErrors.clear(); // clear previous errors
                                  });
                                  if (_passwordKey.currentState!.validate()) {
                                    setState(() {
                                      isPrcoessing =true;
                                      errorMessage = "";
                                    });
                                    try {
                                      final tokens = await submitUser(
                                        name: widget.name,
                                        password: _password.text,
                                        mobile: widget.mobile,
                                        deviceId: "flutter-device",
                                      );
                                      await TokenStorage.saveTokens(accessToken: tokens["accessToken"], refreshToken: tokens["refreshToken"]);                                        // Navigator.pushAndRemoveUntil(
                                      final userProvider =
                                      Provider.of<UserProvider>(context, listen: false);

                                      await userProvider.getDataFromServer(context);
                                      final fcmToken = await getDeviceToken();
                                      if (fcmToken != null) {
                                        await saveDeviceTokenToBackend(fcmToken);
                                      }

                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (context) => Homescreen()),
                                            (Route<dynamic> route) => false,
                                      );
                                    } catch (e) {
                                      if (e is ApiException) {
                                        setState(() {
                                          isPrcoessing = false;
                                          if (e.fieldErrors != null) {
                                            e.fieldErrors!.forEach((key, value) {
                                              fieldErrors[key] = value.toString();
                                            });
                                          } else {
                                            errorMessage = e.message;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text(e.message)),
                                            );
                                          }
                                        });
                                        _passwordKey.currentState!.validate();
                                      }
                                    }
                                  }
                                },
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    shape:RoundedRectangleBorder()
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  spacing: 10,
                                  children: [
                                    if(isPrcoessing)
                                      SizedBox(
                                        height: 30,
                                        width: 30,
                                        child: CircularProgressIndicator(color: Colors.black,),
                                      ),
                                    Text("Submit",style: TextStyle(fontSize: 18,color: Colors.black),),
                                  ],
                                )
                            ),
                          )
                        ],
                      )
                  ),
                ],
              ),
            ),
          )
      ),
    );
  }


  Future<Map<String, dynamic>> submitUser({required String name,required String password,required String mobile,String? deviceId}) async {
    final url = Uri.parse("${ApiConstant.baseUrl}/user/create");

    // Prepare request body
    final Map<String, dynamic> body = {
      "name": name,
      "password": password,
      "mobile": mobile,
      if (deviceId != null) "deviceId": deviceId
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      // Parse response
      final Map<String, dynamic> res = jsonDecode(response.body);

      // Handle success
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          "accessToken": res["accessToken"],
          "refreshToken": res["refreshToken"],
        };
      }

      // Handle validation errors (field-level)
      if (response.statusCode == 400 || response.statusCode == 409) {
        throw ApiException(
          message: res["message"] ?? "Validation error",
          fieldErrors: res["errors"],
        );
      }

      // Fallback for unknown server error
      throw ApiException(
        message: res["message"] ?? "Something went wrong",
      );
    } catch (e) {
      if (e is ApiException) {
        rethrow; // already handled
      } else {
        throw ApiException(message: "Unable to connect to server. Try again.");
      }
    }
  }

}


