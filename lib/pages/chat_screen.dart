import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ImagePicker _picker = ImagePicker();

  void _sendMessage({String? text, File? image}) {
    if (text == null && image == null) return;
    String timestamp =
        DateFormat('hh:mm a • MMM d, yyyy').format(DateTime.now());
    setState(() {
      _messages.add({
        'text': text,
        'image': image,
        'isUser': true,
        'timestamp': timestamp,
        'sender': 'You'
      });
      _messages.add({
        'text': 'Thank you for reaching out.',
        'image': null,
        'isUser': false,
        'timestamp': timestamp,
        'sender': 'Customer Care'
      });
    });
    _messageController.clear();
  }

  Future<void> _sendImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _sendMessage(image: File(pickedFile.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentDateTime =
        DateFormat('EEEE . hh:mm a').format(DateTime.now());

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                const SizedBox(height: 90),
                const Text(
                  "MY SUPPORT",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  currentDateTime,
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1),
          Expanded(
            child: ListView.builder(
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                return Column(
                  crossAxisAlignment: message['isUser']
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      child: Text(
                        message['sender'],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                    Align(
                      alignment: message['isUser']
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: message['isUser']
                              ? const Color.fromRGBO(0, 31, 62, 1)
                              : const Color.fromRGBO(126, 168, 82, 1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (message['text'] != null)
                              Text(
                                message['text'],
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            if (message['image'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child:
                                    Image.file(message['image'], height: 150),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 5),
                              child: Text(
                                message['timestamp'],
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    spreadRadius: 1,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image),
                    color: const Color.fromRGBO(0, 31, 62, 1),
                    onPressed: _sendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.send_rounded,
                      color: Color.fromRGBO(126, 168, 82, 1),
                    ),
                    onPressed: () =>
                        _sendMessage(text: _messageController.text.trim()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
