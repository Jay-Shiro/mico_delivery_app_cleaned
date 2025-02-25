import 'package:flutter/material.dart';
import 'package:micollins_delivery_app/components/m_buttons.dart';
import 'package:micollins_delivery_app/components/m_orange_buttons.dart';
import 'package:micollins_delivery_app/pages/chat_screen.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.9,
          width: MediaQuery.sizeOf(context).width,
          child: Scaffold(
            backgroundColor: Colors.white,
            body: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: supportpageUi(context)),
          ),
        ),
      ),
    );
  }

  Widget supportpageUi(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 74),
        supportTitle(),
        const SizedBox(height: 11),
        supportImage(),
        const SizedBox(height: 14),
        supportWelcomeText(),
        const SizedBox(height: 33),
        chatButton(context),
        const SizedBox(height: 20),
        FAQButton(),
      ],
    );
  }

  Widget supportTitle() {
    return Center(
      child: Text(
        'MY SUPPORT',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget supportImage() {
    return Container(
      child: Image.asset('assets/images/supportpage.png'),
    );
  }

  Widget supportWelcomeText() {
    return SizedBox(
      width: 312,
      child: Text(
        'Chat with our Customer service representative who is available 24/7 to attend to any complaints or questions',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget chatButton(BuildContext context) {
    return MButtons(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatScreen(),
            ),
          );
        },
        btnText: 'Start Chat');
  }

  Widget FAQButton() {
    return MOrangeButtons(onTap: () {}, btnText: 'View FAQ');
  }
}
