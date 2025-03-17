import 'package:flutter/material.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';

class FAQScreen extends StatefulWidget {
  const FAQScreen({super.key});

  @override
  State<FAQScreen> createState() => _FAQScreenState();
}

class _FAQScreenState extends State<FAQScreen> {
  final List<Map<String, dynamic>> faqs = [
    {
      "question": "How do I track my delivery?",
      "answer":
          "You can track your delivery in real-time through the 'Deliveries' tab. Each active delivery shows the current location of your rider and estimated arrival time.",
      "isExpanded": false,
      "category": "Delivery"
    },
    {
      "question": "What payment methods are accepted?",
      "answer":
          "We accept credit/debit cards, mobile money, and cash on delivery. You can manage your payment methods in the profile section.",
      "isExpanded": false,
      "category": "Payment"
    },
    {
      "question": "How do I contact my delivery rider?",
      "answer":
          "You can chat or call your rider directly from the delivery tracking screen. Just tap on the chat or call button to connect instantly.",
      "isExpanded": false,
      "category": "Communication"
    },
    {
      "question": "Can I change my delivery address?",
      "answer":
          "Yes, you can change your delivery address before the rider picks up your package. Go to the active delivery and select 'Edit Details'.",
      "isExpanded": false,
      "category": "Delivery"
    },
    {
      "question": "What if my package is damaged?",
      "answer":
          "If your package arrives damaged, please take photos and report it immediately through the 'Support' section. Our team will assist you with the next steps.",
      "isExpanded": false,
      "category": "Issues"
    },
    {
      "question": "How do I cancel a delivery?",
      "answer":
          "You can cancel a delivery before it's picked up by the rider. Go to the active delivery, tap 'More Options' and select 'Cancel Delivery'.",
      "isExpanded": false,
      "category": "Delivery"
    },
    {
      "question": "Is there a loyalty program?",
      "answer":
          "Yes! Our loyalty program rewards frequent users with discounts and special offers. Check your profile to see your current points and available rewards.",
      "isExpanded": false,
      "category": "Account"
    },
  ];

  String selectedCategory = "All";
  final List<String> categories = [
    "All",
    "Delivery",
    "Payment",
    "Communication",
    "Issues",
    "Account"
  ];
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = "";

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredFaqs {
    return faqs.where((faq) {
      final matchesCategory =
          selectedCategory == "All" || faq["category"] == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          faq["question"].toLowerCase().contains(searchQuery.toLowerCase()) ||
          faq["answer"].toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(0, 31, 62, 1),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon:
                            const Icon(EvaIcons.arrowBack, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          "Frequently Asked Questions",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search FAQs...",
                        prefixIcon: const Icon(EvaIcons.searchOutline,
                            color: Color.fromRGBO(0, 31, 62, 0.7)),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(EvaIcons.close,
                                    color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    searchQuery = "";
                                  });
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              height: 60,
              padding: const EdgeInsets.only(left: 20),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == selectedCategory;

                  return Padding(
                    padding:
                        const EdgeInsets.only(right: 10, top: 10, bottom: 10),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedCategory = category;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color.fromRGBO(0, 31, 62, 1)
                              : const Color.fromRGBO(0, 31, 62, 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color.fromRGBO(0, 31, 62, 1),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // FAQ list
            Expanded(
              child: filteredFaqs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            EvaIcons.searchOutline,
                            size: 70,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "No results found",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Try different keywords or categories",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredFaqs.length,
                      itemBuilder: (context, index) {
                        final faq = filteredFaqs[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
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
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: ExpansionTile(
                              initiallyExpanded: faq["isExpanded"],
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  faq["isExpanded"] = expanded;
                                });
                              },
                              backgroundColor: Colors.white,
                              collapsedBackgroundColor: Colors.white,
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 5),
                              title: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getCategoryColor(faq["category"])
                                          .withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(faq["category"]),
                                      color: _getCategoryColor(faq["category"]),
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      faq["question"],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color.fromRGBO(0, 31, 62, 1),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: faq["isExpanded"]
                                      ? const Color.fromRGBO(0, 31, 62, 0.8)
                                      : const Color.fromRGBO(0, 31, 62, 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  faq["isExpanded"]
                                      ? EvaIcons.minus
                                      : EvaIcons.plus,
                                  color: faq["isExpanded"]
                                      ? Colors.white
                                      : const Color.fromRGBO(0, 31, 62, 1),
                                  size: 18,
                                ),
                              ),
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  child: Text(
                                    faq["answer"],
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[700],
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Contact support button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Navigate back to support page
                },
                icon: const Icon(EvaIcons.messageCircleOutline),
                label: const Text("Still have questions? Contact us"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(
                      0, 31, 62, 1), // Changed from green to primary blue
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case "Delivery":
        return EvaIcons.carOutline;
      case "Payment":
        return EvaIcons.creditCardOutline;
      case "Communication":
        return EvaIcons.messageCircleOutline;
      case "Issues":
        return EvaIcons.alertTriangleOutline;
      case "Account":
        return EvaIcons.personOutline;
      default:
        return EvaIcons.questionMarkCircleOutline;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case "Delivery":
        return const Color.fromRGBO(0, 31, 62, 1);
      case "Payment":
        return Colors.purple;
      case "Communication":
        return const Color.fromRGBO(0, 31, 62, 0.7);
      case "Issues":
        return Colors.orange;
      case "Account":
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
