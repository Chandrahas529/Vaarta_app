import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:vaarta_app/Login_Logup/LoginPage.dart';
import 'package:vaarta_app/Providers/UserProvider.dart';
import 'package:vaarta_app/Screens/HomeScreen.dart';


class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initApp();
    });
  }

  void _initApp() async {
    String? token = await storage.read(key: 'access_token');
    await Future.delayed(Duration(seconds: 2));

    if (token == null || token.isEmpty) {
      Navigator.pushReplacement(
         context, MaterialPageRoute(builder: (_) => Loginpage()));
      return;
    }
    final userProvider =
    Provider.of<UserProvider>(context, listen: false);

    await userProvider.getDataFromServer(context);
      Navigator.pushReplacement(
         context, MaterialPageRoute(builder: (_) => Homescreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 70,
                backgroundColor: Colors.white,
                child: const Text("VA",style: TextStyle(fontSize: 45,color: Colors.black),),
              ),
              SizedBox(height: 60,),
              Text("VAarta App",style: TextStyle(fontSize: 25,color: Colors.white),),
              SizedBox(height: 60),
              CircularProgressIndicator(color: Colors.white,),
            ],
          ),
        ),
      ),
    );
  }
}
