import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class Imageviewpage extends StatelessWidget{
  final String sender;
  final String src;
  final String time;
  const Imageviewpage({super.key,required this.sender, required this.src, required this.time});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(sender,style: TextStyle(fontSize: 16,color: Colors.white),),
            Text("Sent at ${time}",style: TextStyle(fontSize: 16,color: Colors.white),),
          ],
        ),
        backgroundColor: Color(0xff09090e),
        iconTheme: IconThemeData(
          color: Colors.white
        ),
      ),
      body: SafeArea(
        child: Container(
          color: Color(0xff09090e),
          child: Center(
              child: PhotoView(
                  imageProvider: NetworkImage(src)
              )
          ),
        ),
      ),
    );
  }
}