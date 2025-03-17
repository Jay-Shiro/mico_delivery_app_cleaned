import 'dart:io';
import 'dart:convert';
import 'dart:async'; // Add this import
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class UserChatScreen extends StatefulWidget {
  final String? userName;
  final String? userImage;
  final String? orderId;
  final String? deliveryId;
  final String? senderId; // User ID
  final String? receiverId; // Rider ID
  final bool isDeliveryCompleted; // Add this parameter

  const UserChatScreen({
    super.key,
    this.userName = "User",
    this.userImage,
    this.orderId = "MC12345",
    this.deliveryId,
    this.senderId,
    this.receiverId,
    this.isDeliveryCompleted = false, // Default to false
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  bool _isOnline = true;
  bool _isLoading = true;

  // Define the color scheme
  final Color primaryColor = const Color.fromRGBO(0, 31, 62, 1);
  final Color secondaryColor = const Color.fromRGBO(0, 31, 62, 0.2);
  final Color aliceBlue = const Color(0xFFE6F0FF);

  // Add this variable to the class
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchChatHistory();

    // Set up periodic refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchChatHistory(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchChatHistory({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
      });
    }

    if (widget.deliveryId == null ||
        widget.senderId == null ||
        widget.receiverId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://deliveryapi-plum.vercel.app/chat/${widget.deliveryId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> newMessages = [];

        if (data is List) {
          // Direct array of messages
          for (var msg in data) {
            final timestamp = DateTime.parse(msg['timestamp']);

            newMessages.add({
              'text': msg['message'],
              'image': null,
              'isUser': msg['sender_id'] == widget.senderId,
              'timestamp': DateFormat('hh:mm a').format(timestamp),
              'status': msg['read'] ? 'read' : 'delivered',
              'id': msg['_id'],
            });
          }
        } else if (data['messages'] != null) {
          // Response with 'messages' property
          for (var msg in data['messages']) {
            final timestamp = DateTime.parse(msg['timestamp']);

            newMessages.add({
              'text': msg['message'],
              'image': null,
              'isUser': msg['sender_id'] == widget.senderId,
              'timestamp': DateFormat('hh:mm a').format(timestamp),
              'status': msg['read'] ? 'read' : 'delivered',
              'id': msg['_id'],
            });
          }
        } else {
          print('No messages found in the API response');
        }

        // Only update state if there are new messages or if this is the initial load
        if (newMessages.isNotEmpty || _messages.isEmpty) {
          setState(() {
            _messages.clear();
            _messages.addAll(newMessages);
          });

          // Mark messages as read
          _markMessagesAsRead();

          // Scroll to bottom on new messages
          if (newMessages.isNotEmpty && _messages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        }
      } else {
        print('Failed to fetch chat history: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching chat history: $e');
    } finally {
      if (!silent || _isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (widget.deliveryId == null || widget.receiverId == null) {
      print('Delivery ID or Receiver ID is null');
      return;
    }

    try {
      await http.put(
        Uri.parse(
            'https://deliveryapi-plum.vercel.app/chat/${widget.deliveryId}/${widget.senderId}/mark-read'),
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage({String? text, File? image}) async {
    if ((text == null || text.trim().isEmpty) && image == null) return;

    final String timestamp = DateFormat('hh:mm a').format(DateTime.now());

    // Add message to UI immediately for better UX
    setState(() {
      _messages.add({
        'text': text,
        'image': image,
        'isUser': true,
        'timestamp': timestamp,
        'status': 'sending',
      });
    });

    _messageController.clear();

    // Scroll to bottom after sending message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // Send message to API
    if (widget.deliveryId != null &&
        widget.senderId != null &&
        widget.receiverId != null &&
        text != null) {
      try {
        final response = await http.post(
          Uri.parse(
              'https://deliveryapi-plum.vercel.app/chat/${widget.deliveryId}/${widget.senderId}/${widget.receiverId}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'message': text,
          }),
        );

        if (response.statusCode == 200) {
          setState(() {
            _messages.last['status'] = 'sent';
          });

          // Refresh chat history silently without showing loading indicator
          _fetchChatHistory(silent: true);
        } else {
          print('Failed to send message: ${response.body}');
          setState(() {
            _messages.last['status'] = 'error';
          });
        }
      } catch (e) {
        print('Error sending message: $e');
        setState(() {
          _messages.last['status'] = 'error';
        });
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      _sendMessage(image: File(pickedFile.path));
    }
  }

  Future<void> _takePhoto() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      _sendMessage(image: File(pickedFile.path));
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.only(bottom: 20),
            ),
            Text(
              "Share Content",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: EvaIcons.image,
                  label: "Gallery",
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                _buildAttachmentOption(
                  icon: EvaIcons.camera,
                  label: "Camera",
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
                _buildAttachmentOption(
                  icon: EvaIcons.mapOutline,
                  label: "Location",
                  color: primaryColor,
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Location sharing coming soon')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF2F2F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: Icon(EvaIcons.arrowBack, color: primaryColor),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop();
          },
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: secondaryColor,
              backgroundImage:
                  widget.userImage != null && widget.userImage!.isNotEmpty
                      ? NetworkImage(widget.userImage!) as ImageProvider
                      : null,
              child: (widget.userImage == null || widget.userImage!.isEmpty)
                  ? const Icon(
                      EvaIcons.personOutline,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.userName ?? "User",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Rider",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(EvaIcons.phoneOutline, color: primaryColor),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling feature coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat date indicator
          if (_messages.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                DateFormat('MMMM d, yyyy').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ),

          // Messages list
          Expanded(
            child: _isLoading
                ? _buildLoadingShimmer() // Replace CircularProgressIndicator with shimmer
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          
                          // Check if this is a date header
                          if (message['isDateHeader'] == true) {
                            return _buildDateHeader(message['dateText']);
                          }
                          
                          return _buildMessageItem(message);
                        },
                      ),
          ),

          // Completed delivery notice or message input area
          widget.isDeliveryCompleted
              ? _buildCompletedDeliveryNotice()
              : Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: "Type a message...",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            ),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(EvaIcons.navigation2, size: 18),
                          color: Colors.white,
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            if (_messageController.text.trim().isNotEmpty) {
                              _sendMessage(text: _messageController.text.trim());
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

  // Add this new method to build the completed delivery notice
  Widget _buildCompletedDeliveryNotice() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              EvaIcons.checkmarkCircle2Outline,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "This delivery is marked as complete. Messaging is disabled.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get date key for grouping
  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Helper method to format date for display
  String _getFormattedDate(String dateKey) {
    final DateTime date = DateFormat('yyyy-MM-dd').parse(dateKey);
    final DateTime now = DateTime.now();
    final DateTime yesterday = DateTime(now.year, now.month, now.day - 1);
    
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Yesterday';
    } else if (date.isAfter(DateTime(now.year, now.month, now.day - 7))) {
      // Within the last week
      return DateFormat('EEEE').format(date); // Day name (e.g., "Monday")
    } else if (date.year == now.year) {
      // Same year
      return DateFormat('MMMM d').format(date); // Month and day (e.g., "March 16")
    } else {
      // Different year
      return DateFormat('MMMM d, yyyy').format(date); // Full date with year
    }
  }
  
  Widget _buildDateHeader(String dateText) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            EvaIcons.messageCircleOutline,
            size: 70,
            color: secondaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            "No messages yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start the conversation with your delivery person",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Map<String, dynamic> message) {
    final bool isUser = message['isUser'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: secondaryColor,
              backgroundImage:
                  widget.userImage != null && widget.userImage!.isNotEmpty
                      ? NetworkImage(widget.userImage!) as ImageProvider
                      : null,
              child: (widget.userImage == null || widget.userImage!.isEmpty)
                  ? const Icon(
                      EvaIcons.personOutline,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width *
                    0.65, // Reduced bubble size
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8), // Smaller padding
              decoration: BoxDecoration(
                color: isUser
                    ? primaryColor
                    : Colors.white, // White for received messages
                borderRadius: BorderRadius.circular(18), // All rounded corners
                border: isUser
                    ? null
                    : Border.all(
                        color:
                            Colors.grey.shade200), // Border for white bubbles
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message['text'] != null)
                    Text(
                      message['text'],
                      style: TextStyle(
                        fontSize: 15, // Slightly smaller text
                        color: isUser ? Colors.white : primaryColor,
                      ),
                    ),
                  if (message['image'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 5, bottom: 5),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          message['image'],
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        message['timestamp'],
                        style: TextStyle(
                          fontSize: 10, // Smaller timestamp
                          color: isUser ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        _buildMessageStatus(message['status'] ?? 'sent'),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildMessageStatus(String status) {
    IconData icon;
    Color color = Colors.white70;

    switch (status) {
      case 'sending':
        icon = EvaIcons.clockOutline;
        break;
      case 'sent':
        icon = EvaIcons.checkmark;
        break;
      case 'delivered':
        icon = EvaIcons.checkmark;
        break;
      case 'read':
        icon = EvaIcons.doneAllOutline;
        color = Colors.lightBlueAccent;
        break;
      case 'error':
        icon = EvaIcons.alertCircleOutline;
        color = Colors.redAccent;
        break;
      default:
        icon = EvaIcons.checkmark;
    }

    return Icon(
      icon,
      size: 14,
      color: color,
    );
  }
}

// Add this method to create shimmer loading effect for messages
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: 6, // Show 6 shimmer message bubbles
        itemBuilder: (_, index) {
          final bool isUserMessage = index % 2 == 0; // Alternate between user and other messages
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: isUserMessage 
                  ? MainAxisAlignment.end 
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isUserMessage) ...[
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Container(
                  width: 200 - (index * 20) % 100, // Varying widths for more natural look
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
