import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(VentingApp());
}

class VentingApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<Map<String, String>> messages = [];
  TextEditingController controller = TextEditingController();
  ScrollController scrollController = ScrollController();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _isProcessingVoice = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
  }

  /// Add message
  void addMessage(String text, bool isUser) {
    setState(() {
      messages.add({
        "text": text,
        "sender": isUser ? "user" : "bot",
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

  /// Send typed message
  void sendMessage() {
    if (controller.text.trim().isEmpty) return;

    String userText = controller.text.trim();

    addMessage(userText, true);
    controller.clear();

    Future.delayed(Duration(milliseconds: 500), () {
      addMessage("I'm here for you 💙", false);
    });
  }

  /// 🎤 Start Listening
  void startListening() async {
    controller.clear(); // clear old text

    bool available = await _speech.initialize(
      onStatus: (status) => print("Status: $status"),
      onError: (error) => print("Error: $error"),
    );

    if (available) {
      setState(() {
        _isListening = true;
        _isProcessingVoice = true;
      });

      _speech.listen(
        onResult: (result) {
          if (_isProcessingVoice) {
            setState(() {
              controller.text = result.recognizedWords;
            });
          }
        },
      );
    }
  }

  /// 🛑 Stop Listening (FIXED)
  void stopListening() async {
    _isProcessingVoice = false;

    await _speech.stop(); // ensure complete stop

    setState(() => _isListening = false);

    String spokenText = controller.text.trim();

    if (spokenText.isNotEmpty) {
      addMessage(spokenText, true);

      /// 🔥 CLEAR PROPERLY
      controller.text = "";
      controller.clear();

      await Future.delayed(Duration(milliseconds: 200));

      setState(() {});

      Future.delayed(Duration(milliseconds: 500), () {
        addMessage("I'm here for you 💙", false);
      });
    }
  }

  /// Chat bubble
  Widget buildMessage(Map<String, String> msg) {
    bool isUser = msg["sender"] == "user";

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: 250),
            decoration: BoxDecoration(
              color: isUser ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              msg["text"]!,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Venting Assistant 🤖"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          /// Chat Area
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessage(messages[index]);
              },
            ),
          ),

          /// Input Area
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.white,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 5,
                    textInputAction: TextInputAction.send,
                    decoration: InputDecoration(
                      hintText: _isListening
                          ? "Listening..."
                          : "Type your thoughts...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                    ),
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),

                SizedBox(width: 8),

                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: sendMessage,
                ),

                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.green : Colors.red,
                  ),
                  onPressed: () {
                    if (_isListening) {
                      stopListening();
                    } else {
                      startListening();
                    }
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}