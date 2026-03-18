import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Statusscreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return StatusscreenState();
  }
}
class StatusscreenState extends State<Statusscreen>{
  @override
  Widget build(BuildContext context) {
    double size = MediaQuery.of(context).size.height;
    return SafeArea(
        child: Scaffold(
          appBar: AppBar(
            title: Text("Status",style: TextStyle(fontSize: 20,fontWeight: FontWeight.w600),),
            // backgroundColor: Color(0xff09090e),
            automaticallyImplyLeading: false,
          ),
          body: Container(
            // color: Color(0xff09090e),
            child: Center(
              child: Text("No status found",style: TextStyle(fontSize: 18),),
            ),
          ),
        )
    );
  }
}