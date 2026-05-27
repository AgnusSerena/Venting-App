import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(VentingApp());
}

class VentingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Emotion AI Assistant",
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  final TextEditingController controller = TextEditingController();

  final ScrollController scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];

  late stt.SpeechToText speech;

  bool isListening = false;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
  }

  // ---------------- ADD MESSAGE ---------------- //

  void addMessage(String text, bool isUser) {

    setState(() {

      messages.add({
        "text": text,
        "isUser": isUser,
      });

    });

    Future.delayed(Duration(milliseconds: 100), () {

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

    });
  }

  // ---------------- SEND MESSAGE ---------------- //

  Future<void> sendMessage() async {

    if (controller.text.trim().isEmpty) return;

    String userText = controller.text.trim();

    addMessage(userText, true);

    controller.clear();

    setState(() {
      isLoading = true;
    });

    try {

      final response = await http.post(

        Uri.parse("http://127.0.0.1:5000/chat"),

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode({
          "message": userText,
        }),
      );

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        String reply = data["reply"];

        addMessage(reply, false);

      } else {

        addMessage(
          "Sorry, something went wrong.",
          false,
        );

      }

    } catch (e) {

      addMessage(
        "Cannot connect to AI server.",
        false,
      );

      print(e);

    }

    setState(() {
      isLoading = false;
    });
  }

  // ---------------- START LISTENING ---------------- //

  Future<void> startListening() async {

    bool available = await speech.initialize();

    if (available) {

      setState(() {
        isListening = true;
      });

      speech.listen(

        onResult: (result) {

          setState(() {

            controller.text = result.recognizedWords;

          });

        },
      );
    }
  }

  // ---------------- STOP LISTENING ---------------- //

  Future<void> stopListening() async {

    await speech.stop();

    setState(() {
      isListening = false;
    });

    if (controller.text.trim().isNotEmpty) {

      sendMessage();

    }
  }

  // ---------------- CHAT BUBBLE ---------------- //

  Widget buildMessage(Map<String, dynamic> msg) {

    bool isUser = msg["isUser"];

    return Align(

      alignment:
          isUser
              ? Alignment.centerRight
              : Alignment.centerLeft,

      child: Container(

        margin: EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 5,
        ),

        padding: EdgeInsets.all(14),

        constraints: BoxConstraints(maxWidth: 320),

        decoration: BoxDecoration(

          color: isUser
              ? Colors.blue
              : Colors.white,

          borderRadius: BorderRadius.circular(18),

          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
            ),
          ],
        ),

        child: Text(

          msg["text"],

          style: TextStyle(
            color:
                isUser
                    ? Colors.white
                    : Colors.black87,
            fontSize: 16,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  // ---------------- UI ---------------- //

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Color(0xFFF4F1F8),

      appBar: AppBar(

        elevation: 0,

        backgroundColor: Colors.white,

        centerTitle: true,

        title: Text(
          "Emotion AI Assistant",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: Column(

        children: [

          Expanded(

            child: ListView.builder(

              controller: scrollController,

              padding: EdgeInsets.only(top: 10),

              itemCount: messages.length,

              itemBuilder: (context, index) {

                return buildMessage(messages[index]);

              },
            ),
          ),

          if (isLoading)

            Padding(

              padding: EdgeInsets.only(bottom: 8),

              child: Text(
                "Typing...",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

          // INPUT AREA

          Container(

            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 10,
            ),

            color: Colors.white,

            child: Row(

              children: [

                Expanded(

                  child: TextField(

                    controller: controller,

                    minLines: 1,
                    maxLines: 5,

                    decoration: InputDecoration(

                      hintText:
                          isListening
                              ? "Listening..."
                              : "Share your thoughts...",

                      filled: true,

                      fillColor: Color(0xFFF4F1F8),

                      border: OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(30),

                        borderSide: BorderSide.none,
                      ),

                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 8),

                // SEND BUTTON

                CircleAvatar(

                  backgroundColor: Colors.blue,

                  child: IconButton(

                    icon: Icon(
                      Icons.send,
                      color: Colors.white,
                    ),

                    onPressed: sendMessage,
                  ),
                ),

                SizedBox(width: 8),

                // MIC BUTTON

                CircleAvatar(

                  backgroundColor:
                      isListening
                          ? Colors.green
                          : Colors.red,

                  child: IconButton(

                    icon: Icon(

                      isListening
                          ? Icons.mic
                          : Icons.mic_none,

                      color: Colors.white,
                    ),

                    onPressed: () {

                      if (isListening) {

                        stopListening();

                      } else {

                        startListening();

                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}