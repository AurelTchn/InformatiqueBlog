import 'package:flutter/material.dart';
class utilisateurs extends StatefulWidget {
  const utilisateurs({super.key});

  @override
  State<utilisateurs> createState() => _utilisateursState();
}

class _utilisateursState extends State<utilisateurs> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("utilisateurs"),backgroundColor: Colors.blue),
      body: Column(children: [
        Center(child: Text("utilisateurs"),)
      ],),
    );
  }
}
