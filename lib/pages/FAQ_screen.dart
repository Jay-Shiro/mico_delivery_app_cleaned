import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> faqs = [
      {
        "question": "How do I contact support?",
        "answer":
            "You can send us a message through the chat or email us at support@example.com.",
      },
      {
        "question": "What are your support hours?",
        "answer": "We are available 24/7 to assist you with any issues.",
      },
      {
        "question": "How long does it take to get a response?",
        "answer": "Our team usually responds within a few minutes.",
      },
      {
        "question": "Can I send images in the chat?",
        "answer":
            "Yes, you can send images by clicking the image icon in the chat box.",
      },
      {
        "question": "Is my chat history saved?",
        "answer": "Yes, we store chat history securely for reference.",
      },
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 90),
            const Text(
              "FAQS",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            const Divider(thickness: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  return ExpansionTile(
                    iconColor: Colors.redAccent,
                    title: Text(
                      faqs[index]["question"]!,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 5),
                        child: Align(
                          alignment:
                              Alignment.centerLeft, // Aligns text to the left
                          child: Text(
                            faqs[index]["answer"]!,
                            textAlign:
                                TextAlign.left, // Ensures text is left-aligned
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const Divider(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
