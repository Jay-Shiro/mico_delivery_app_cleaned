import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
          child: SizedBox(
        height: MediaQuery.sizeOf(context).height,
        width: MediaQuery.sizeOf(context).width,
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 18,
            ),
            child: customerChatPage(),
          ),
        ),
      )),
    );
  }

  Widget customerChatPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 74),
        chatTitle(),
      ],
    );
  }

  Widget chatTitle() {
    return Center(
      widthFactor: MediaQuery.sizeOf(context).width,
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios),
          ),
          const SizedBox(
            width: 110,
          ),
          Text(
            'MY SUPPORT',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(
            height: 12,
          ),
          Divider(
            thickness: 0.5,
            height: 2,
            color: Colors.black87,
          ),
          const SizedBox(
            height: 24,
          ),
        ],
      ),
    );
  }
}
