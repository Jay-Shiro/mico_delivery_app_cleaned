import 'package:flutter/material.dart';
import 'package:micollins_delivery_app/pages/FAQ_screen.dart';
import 'package:micollins_delivery_app/pages/webview_screen.dart'; // Add this import
import 'package:shared_preferences/shared_preferences.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  String? userEmail;
  String? userName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userEmail = prefs.getString('email') ?? '';
      userName = prefs.getString('name') ?? 'User';
      isLoading = false;
    });
  }

  // Updated function to open chat in WebView
  void _openTawkChat() {
    print("Opening Tawk.to chat in WebView");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WebViewScreen(
          url: 'https://tawk.to/chat/67d5de5f842dae190d221409/1imdmp9qo',
          title: 'Live Chat Support',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'SUPPORT',
          style: TextStyle(
            color: Color.fromRGBO(0, 31, 62, 1),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Color.fromRGBO(0, 31, 62, 1),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(0, 31, 62, 1),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    // Support illustration
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(0, 31, 62, 0.05),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.support_agent,
                          size: 120,
                          color: const Color.fromRGBO(0, 31, 62, 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Welcome text
                    const Text(
                      'How can we help you today?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(0, 31, 62, 1),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Our support team is available 24/7 to assist you with any questions or issues you may have.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Support options
                    _buildSupportOption(
                      icon: Icons.chat_bubble_outline,
                      title: 'Live Chat',
                      description: 'Talk to our support team in real-time',
                      onTap: _openTawkChat, // Use the new function here
                    ),
                    const SizedBox(height: 16),
                    _buildSupportOption(
                      icon: Icons.question_answer_outlined,
                      title: 'FAQ',
                      description: 'Find answers to common questions',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FAQScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSupportOption(
                      icon: Icons.email_outlined,
                      title: 'Email Support',
                      description:
                          'Send us an email at support@micodelivery.com',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Drop a mail for us at support@micodelivery.com'),
                            backgroundColor: Color.fromRGBO(0, 31, 62, 1),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(0, 31, 62, 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color.fromRGBO(0, 31, 62, 1),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(0, 31, 62, 1),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color.fromRGBO(0, 31, 62, 1),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
