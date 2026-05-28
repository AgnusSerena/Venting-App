import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;

void main() {
  runApp(const VentingApp());
}

class VentingApp extends StatelessWidget {
  const VentingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Companion',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F4F6),
      ),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() =>
      _ChatScreenState();
}

class _ChatScreenState
    extends State<ChatScreen> {

  final TextEditingController controller =
      TextEditingController();

  final ScrollController scrollController =
      ScrollController();

  late stt.SpeechToText speech;

  bool isListening = false;

  bool isLoading = false;

  final List<Map<String, dynamic>>
      messages = [

    {
      "text":
          "Hi, how are you feeling today?",
      "isUser": false,
    }

  ];

  @override
  void initState() {

    super.initState();

    speech = stt.SpeechToText();
  }

  void speak(String text) {

    final synthesis =
        html.window.speechSynthesis;

    if (synthesis == null) return;

    synthesis.cancel();

    final utterance =
        html.SpeechSynthesisUtterance(
            text);

    utterance.lang = 'en-US';

    utterance.rate = 0.9;

    utterance.pitch = 1.0;

    synthesis.speak(utterance);
  }

  void addMessage(
      String text,
      bool isUser) {

    setState(() {

      messages.add({

        "text": text,
        "isUser": isUser,

      });

    });

    Future.delayed(
      const Duration(milliseconds: 100),
      () {

        scrollController.animateTo(

          scrollController
              .position.maxScrollExtent,

          duration:
              const Duration(
                  milliseconds: 300),

          curve: Curves.easeOut,
        );
      },
    );
  }

  Future<void> sendMessage() async {

    if (controller.text
        .trim()
        .isEmpty) return;

    String userText =
        controller.text.trim();

    addMessage(userText, true);

    controller.clear();

    setState(() {

      isLoading = true;

    });

    try {

      final response =
          await http.post(

        Uri.parse(
          'http://127.0.0.1:5000/chat',
        ),

        headers: {

          'Content-Type':
              'application/json',

        },

        body: jsonEncode({

          'message': userText,

        }),
      );

      if (response.statusCode ==
          200) {

        final data =
            jsonDecode(response.body);

        String aiReply =
            data['reply'];

        addMessage(
          aiReply,
          false,
        );

        speak(aiReply);

      } else {

        addMessage(
          "Something went wrong.",
          false,
        );
      }

    } catch (e) {

      addMessage(
        "Cannot connect to server.",
        false,
      );
    }

    setState(() {

      isLoading = false;

    });
  }

  Future<void> startListening() async {

    if (isListening) return;

    controller.clear();

    bool available =
        await speech.initialize();

    if (!available) return;

    setState(() {

      isListening = true;

    });

    speech.listen(

      partialResults: true,

      listenMode:
          stt.ListenMode.dictation,

      onResult: (result) {

        if (!mounted) return;

        controller.value =
            TextEditingValue(

          text:
              result.recognizedWords,

          selection:
              TextSelection
                  .collapsed(

            offset:
                result
                    .recognizedWords
                    .length,
          ),
        );
      },
    );
  }

  Future<void> stopListening() async {

    if (!isListening) return;

    await speech.stop();

    setState(() {

      isListening = false;

    });

    FocusScope.of(context)
        .unfocus();
  }

  Widget buildWaveBar(
      double height) {

    return AnimatedContainer(

      duration:
          const Duration(
              milliseconds: 300),

      margin:
          const EdgeInsets.symmetric(
        horizontal: 2,
      ),

      width: 4,

      height: height,

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(10),
      ),
    );
  }

  Widget buildMessage(
      Map<String, dynamic> msg) {

    bool isUser = msg['isUser'];

    return Align(

      alignment: isUser
          ? Alignment.centerRight
          : Alignment.centerLeft,

      child: Container(

        margin:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),

        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),

        constraints:
            const BoxConstraints(
          maxWidth: 320,
        ),

        decoration: BoxDecoration(

          gradient: isUser
              ? const LinearGradient(

                  colors: [

                    Color(0xFF6F4BFF),
                    Color(0xFF8A63FF),

                  ],
                )
              : null,

          color: isUser
              ? null
              : Colors.white,

          borderRadius:
              BorderRadius.circular(
                  26),

          boxShadow: [

            BoxShadow(

              color: Colors.black
                  .withOpacity(0.08),

              blurRadius: 10,

              offset:
                  const Offset(0, 4),
            ),
          ],
        ),

        child: Text(

          msg['text'],

          style: TextStyle(

            color: isUser
                ? Colors.white
                : Colors.black87,

            fontSize: 18,

            height: 1.5,

            fontWeight:
                FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor:
          const Color(0xFFF4F4F6),

      body: SafeArea(

        child: Column(

          children: [

            Container(

              width: double.infinity,

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),

              decoration:
                  const BoxDecoration(

                gradient:
                    LinearGradient(

                  colors: [

                    Color(0xFF6F4BFF),
                    Color(0xFF8A63FF),

                  ],

                  begin:
                      Alignment.topLeft,

                  end: Alignment
                      .bottomRight,
                ),

                borderRadius:
                    BorderRadius.only(

                  bottomLeft:
                      Radius.circular(
                          30),

                  bottomRight:
                      Radius.circular(
                          30),
                ),
              ),

              child: Column(

                children: [

                  Row(

                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,

                    children: [

                      CircleAvatar(

                        backgroundColor:
                            Colors.white
                                .withOpacity(
                                    0.2),

                        child:
                            const Icon(

                          Icons
                              .arrow_back_ios_new,

                          color:
                              Colors.white,
                        ),
                      ),

                      const Text(

                        "AI Companion",

                        style: TextStyle(

                          color:
                              Colors.white,

                          fontSize: 24,

                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      CircleAvatar(

                        backgroundColor:
                            Colors.white
                                .withOpacity(
                                    0.2),

                        child:
                            const Icon(

                          Icons.call,

                          color:
                              Colors.white,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                      height: 24),

                  Container(

                    width: 120,
                    height: 120,

                    decoration:
                        BoxDecoration(

                      shape:
                          BoxShape.circle,

                      color: Colors
                          .white
                          .withOpacity(
                              0.1),
                    ),

                    child: const Icon(

                      Icons
                          .smart_toy_rounded,

                      color:
                          Colors.white,

                      size: 70,
                    ),
                  ),

                  const SizedBox(
                      height: 18),

                  const Text(

                    "Your emotional wellness companion",

                    style: TextStyle(

                      color:
                          Colors.white70,

                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(

              child: ListView.builder(

                controller:
                    scrollController,

                padding:
                    const EdgeInsets.only(
                  top: 20,
                ),

                itemCount:
                    messages.length,

                itemBuilder:
                    (context, index) {

                  return buildMessage(
                    messages[index],
                  );
                },
              ),
            ),

            if (isLoading)

              const Padding(

                padding:
                    EdgeInsets.only(
                  bottom: 10,
                ),

                child: Text(

                  "Typing...",

                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),

            Container(

              margin:
                  const EdgeInsets.all(
                16,
              ),

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),

              decoration:
                  BoxDecoration(

                color: Colors.white,

                borderRadius:
                    BorderRadius.circular(
                        30),

                boxShadow: [

                  BoxShadow(

                    color: Colors.black
                        .withOpacity(0.06),

                    blurRadius: 10,

                    offset:
                        const Offset(0, 3),
                  ),
                ],
              ),

              child: Row(

                children: [

                  Expanded(

                    child: TextField(

                      controller:
                          controller,

                      minLines: 1,

                      maxLines: 5,

                      enabled:
                          !isLoading,

                      textInputAction:
                          TextInputAction
                              .send,

                      onSubmitted: (_) {

                        if (!isListening) {

                          sendMessage();
                        }
                      },

                      style:
                          const TextStyle(

                        fontSize: 17,
                      ),

                      decoration:
                          InputDecoration(

                        hintText:
                            isListening
                                ? "Listening..."
                                : "Share your thoughts...",

                        hintStyle:
                            const TextStyle(

                          color:
                              Colors.grey,
                        ),

                        border:
                            InputBorder.none,

                        contentPadding:
                            const EdgeInsets
                                .symmetric(

                          horizontal: 14,

                          vertical: 12,
                        ),
                      ),
                    ),
                  ),

                  GestureDetector(

                    onTap:
                        isListening
                            ? null
                            : sendMessage,

                    child: Container(

                      width: 56,
                      height: 56,

                      decoration:
                          BoxDecoration(

                        gradient:
                            LinearGradient(

                          colors:
                              isListening
                                  ? [

                                      Colors.grey,
                                      Colors.grey,
                                    ]
                                  : [

                                      const Color(
                                          0xFF6F4BFF),

                                      const Color(
                                          0xFF8A63FF),
                                    ],
                        ),

                        borderRadius:
                            BorderRadius
                                .circular(
                                    20),
                      ),

                      child:
                          const Icon(

                        Icons.send_rounded,

                        color:
                            Colors.white,

                        size: 30,
                      ),
                    ),
                  ),

                  const SizedBox(
                      width: 10),

                  GestureDetector(

                    onTap: () async {

                      if (isListening) {

                        await stopListening();

                      } else {

                        await startListening();
                      }
                    },

                    child: Container(

                      width: 56,
                      height: 56,

                      decoration:
                          BoxDecoration(

                        color: isListening
                            ? Colors.red
                            : Colors.green,

                        borderRadius:
                            BorderRadius
                                .circular(
                                    20),
                      ),

                      child: isListening

                          ? Row(

                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .center,

                              children: [

                                buildWaveBar(
                                    14),

                                buildWaveBar(
                                    22),

                                buildWaveBar(
                                    18),

                                buildWaveBar(
                                    26),

                                buildWaveBar(
                                    16),
                              ],
                            )

                          : const Icon(

                              Icons.mic,

                              color:
                                  Colors.white,

                              size: 30,
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}