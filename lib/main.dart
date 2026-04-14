import 'package:flutter/material.dart';

void main() {
  runApp(VentingApp());
}

class VentingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Venting App',
      home: VentingHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class VentingHome extends StatefulWidget {
  @override
  _VentingHomeState createState() => _VentingHomeState();
}

class _VentingHomeState extends State<VentingHome> {
  TextEditingController textController = TextEditingController();
  String responseText = "Your response will appear here";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Voice Venting App"),
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: textController,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: "Type your feelings...",
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: Text("Record"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: Text("Stop"),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              child: Text("Send"),
            ),
            SizedBox(height: 30),
            Container(
              padding: EdgeInsets.all(15),
              width: double.infinity,
              height: 150,
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(responseText),
            )
          ],
        ),
      ),
    );
  }
}