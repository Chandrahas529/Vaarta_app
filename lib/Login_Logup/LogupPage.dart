import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vaarta_app/Login_Logup/PasswordSet.dart';

class Loguppage extends StatefulWidget {
  const Loguppage({super.key});

  @override
  State<Loguppage> createState() => LogupPageState();
}

class LogupPageState extends State<Loguppage> {
  final _registerPage = GlobalKey<FormState>();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _mobileController = TextEditingController();
  bool showNext = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          height: double.infinity,
          color: Colors.black87,
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 20,
                  children: [
                    Container(
                      child: const Text(
                        "Register",
                        style: TextStyle(fontSize: 30, color: Colors.white),
                      ),
                    ),
                    Form(
                      key: _registerPage,
                      child: Column(
                        spacing: 40,
                        children: [
                          const SizedBox(height: 40),
                          TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.text,
                            style: TextStyle(color: Colors.white, fontSize: 20),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(10),
                              fillColor: Colors.black38,
                              filled: true,
                              labelText: "Name",
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                              labelStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: Colors.white24,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
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
                              if (value == null || value.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            controller: _mobileController,
                            keyboardType: TextInputType.phone,
                            onChanged: (value) {
                              setState(() {
                                showNext = value.length == 10;
                              });
                            },
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
                            style: TextStyle(color: Colors.white, fontSize: 20),
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.all(10),
                              fillColor: Colors.black38,
                              filled: true,
                              labelText: "Mobile",
                              hint: Text(
                                "Enter 10 digit mobile number",
                                style: TextStyle(color: Colors.white),
                              ),
                              prefix: Text(
                                "+91 ",
                                style: TextStyle(color: Colors.white),
                              ),
                              prefixIcon: Icon(Icons.phone, color: Colors.white),
                              labelStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2,
                                  color: Colors.white24,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
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
                          ),
                          Container(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: !showNext
                                  ? null
                                  : () {
                                      if (_registerPage.currentState!
                                          .validate()) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => Passwordset(
                                              name: _nameController.text.trim(),
                                              mobile: _mobileController.text,
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              style: FilledButton.styleFrom(
                                disabledBackgroundColor: Colors.white60,
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(),
                              ),
                              child: const Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 100),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context, "Ok");
                      },
                      child: const Text(
                        "Already have an account ?",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
