import 'package:flutter/material.dart';

class homePage extends StatefulWidget {
  const homePage({super.key});

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home Page"),backgroundColor: Colors.amber),
      body: Center(
        child: Column(children: [
          SizedBox(width: 100,height: 200,child:Image(image: AssetImage("assets/image/simo.png")),),
          Text("J'ai une image", style: TextStyle(fontSize: 30),)
        ],),
      ),
    );
  }
}
