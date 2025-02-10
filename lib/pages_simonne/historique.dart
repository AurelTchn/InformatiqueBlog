import 'package:flutter/material.dart';


class historique extends StatefulWidget {
  const historique({super.key});

  @override
  State<historique> createState() => _historiqueState();
}

class _historiqueState extends State<historique> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("historique"),backgroundColor: Colors.amber),
      body: Column(children: [
        Text("essai"),
        ElevatedButton(onPressed: (){}, child: Text("Cliquez ici"))
      ],
      ),
    );
  }
}
