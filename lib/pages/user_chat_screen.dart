import 'dart:io';
import 'dart:convert';
import 'dart:async'; // Add this import
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:micollins_delivery_app/services/notification_service.dart';
import 'package:micollins_delivery_app/services/onesignal_service.dart';
import 'package:micollins_delivery_app/services/global_message_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shimmer/shimmer.dart';

class UserChatScreen extends StatefulWidget {
  final String? userName;
  final String? userImage;
  final String? orderId;
  final String? deliveryId;
  final String? senderId;
  final String? receiverId;
  final String recipientName; // Add this parameter
  final bool isDeliveryCompleted;

  const UserChatScreen({
    super.key,
    this.userName = "User",
    this.userImage,
    this.orderId = "MC12345",
    required this.deliveryId,
    required this.senderId,
    required this.receiverId,
    required this.recipientName, // Add this parameter
    this.isDeliveryCompleted = false,
  });

  @override
  State<UserChatScreen> createState() => _UserChatScreenState();
}

class _UserChatScreenState extends State<UserChatScreen> {
  bool _userHasScrolledUp = false;
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  final ImagePicker _picker = ImagePicker();
  final ScrollController _scrollController = ScrollController();
  // bool _isOnline = true;
  bool _isLoading = true;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final Color primaryColor = const Color.fromRGBO(0, 31, 62, 1);
  final Color secondaryColor = const Color.fromRGBO(0, 31, 62, 0.2);
  final Color aliceBlue = const Color(0xFFE6F0FF);

  Timer? _refreshTimer;

  String? _lastMessageId;

  bool _isActiveChat = true;

  @override
  void initState() {
    super.initState();
    _isActiveChat = true;

    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final threshold = 100.0;
        final distanceFromBottom = _scrollController.position.maxScrollExtent -
            _scrollController.offset;
        if (distanceFromBottom > threshold) {
          _userHasScrolledUp = true;
        } else {
          _userHasScrolledUp = false;
        }
      }
    });

    _fetchChatHistory();

    // Use GlobalMessageService instead of local timer
    if (widget.deliveryId != null &&
        widget.senderId != null &&
        widget.receiverId != null) {
      GlobalMessageService().startPolling(
        deliveryId: widget.deliveryId!,
        senderId: widget.senderId!,
        receiverId: widget.receiverId!,
        userName: widget.userName,
        userImage: widget.userImage,
        orderId: widget.orderId,
      );
    }
  }

  void _startMessagePolling() {
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _isActiveChat) {
        _checkForNewMessages();
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isActiveChat = true;
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _refreshTimer?.cancel();
    _isActiveChat = false;
    // Stop the global polling when leaving the chat
    GlobalMessageService().stopPolling();
    super.dispose();
  }

  Future<void> _checkForNewMessages() async {
    if (widget.deliveryId == null || widget.senderId == null) return;

    try {
      final response = await http.get(
        Uri.parse(
            'https://deliveryapi-ten.vercel.app/chat/${widget.deliveryId}'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> fetchedMessages = [];

        if (data is List) {
          for (var msg in data) {
            final timestamp = DateTime.parse(msg['timestamp']);
            fetchedMessages.add({
              'text': msg['message'],
              'image': null,
              'isUser': msg['sender_id'] == widget.senderId,
              'timestamp': timestamp,
              'displayTime': DateFormat('hh:mm a').format(timestamp),
              'status': msg['read'] ? 'read' : 'delivered',
              'id': msg['_id'],
            });
          }
        } else if (data['messages'] != null) {
          for (var msg in data['messages']) {
            final timestamp = DateTime.parse(msg['timestamp']);
            fetchedMessages.add({
              'text': msg['message'],
              'image': null,
              'isUser': msg['sender_id'] == widget.senderId,
              'timestamp': timestamp,
              'displayTime': DateFormat('hh:mm a').format(timestamp),
              'status': msg['read'] ? 'read' : 'delivered',
              'id': msg['_id'],
            });
          }
        }

        final Map<String, Map<String, dynamic>> uniqueMessages = {};
        for (var msg in fetchedMessages) {
          uniqueMessages[msg['id']] = msg;
        }

        final sortedMessages = uniqueMessages.values.toList()
          ..sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

        // Detect new message
        bool hasNewMessage = false;
        if (_messages.isNotEmpty && sortedMessages.isNotEmpty) {
          if (_messages.last['id'] != sortedMessages.last['id']) {
            hasNewMessage = true;
          }
        } else if (_messages.isEmpty && sortedMessages.isNotEmpty) {
          hasNewMessage = true;
        }

        setState(() {
          _messages = sortedMessages;
        });

        if (sortedMessages.isNotEmpty) {
          _lastMessageId = sortedMessages.last['id'];
        }

        // if (hasNewMessage && !sortedMessages.last['isUser']) {
        //   flutterLocalNotificationsPlugin.show(
        //     0,
        //     'New message from ${widget.userName ?? "Rider"}',
        //     sortedMessages.last['text'],
        //     NotificationDetails(
        //       android: AndroidNotificationDetails(
        //         'chat_channel',
        //         'Chat Messages',
        //         channelDescription: 'Channel for chat message notifications',
        //         importance: Importance.max,
        //         priority: Priority.high,
        //       ),
        //       iOS: DarwinNotificationDetails(),
        //     ),
        //   );
        // }

        _markMessagesAsRead();

        if (!_userHasScrolledUp) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      }
    } catch (e) {
      print('Error checking for new messages: $e');
    }
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
            'https://deliveryapi-ten.vercel.app/chat/${widget.deliveryId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> fetchedMessages = [];

        if (data is List) {
          for (var msg in data) {
            final timestamp = DateTime.parse(msg['timestamp']);
            fetchedMessages.add({
              'text': msg['message'],
              'image': null,
              'isUser': msg['sender_id'] == widget.senderId,
              'timestamp': timestamp,
              'displayTime': DateFormat('hh:mm a').format(timestamp),
              'status': msg['read'] ? 'read' : 'delivered',
              'id': msg['_id'],
            });
          }
        } else if (data['messages'] != null) {
          for (var msg in data['messages']) {
            final timestamp = DateTime.parse(msg['timestamp']);
            fetchedMessages.add({
              'text': msg['message'],
              'image': null,
              'isUser': msg['sender_id'] == widget.senderId,
              'timestamp': timestamp,
              'displayTime': DateFormat('hh:mm a').format(timestamp),
              'status': msg['read'] ? 'read' : 'delivered',
              'id': msg['_id'],
            });
          }
        } else {
          print('No messages found in the API response');
        }

        // Deduplicate by message ID
        final Map<String, Map<String, dynamic>> uniqueMessages = {};
        for (var msg in fetchedMessages) {
          uniqueMessages[msg['id']] = msg;
        }

        // Always sort by timestamp (oldest to newest)
        final sortedMessages = uniqueMessages.values.toList()
          ..sort((a, b) => a['timestamp'].compareTo(b['timestamp']));

        setState(() {
          _messages = sortedMessages;
          _isLoading = false;
        });

        if (sortedMessages.isNotEmpty) {
          _lastMessageId = sortedMessages.last['id'];
        }

        _markMessagesAsRead();

        if (!_userHasScrolledUp) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      } else {
        print('Failed to fetch chat history: ${response.statusCode}');
        if (!silent) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching chat history: $e');
      if (!silent) {
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
            'https://deliveryapi-ten.vercel.app/chat/${widget.deliveryId}/${widget.senderId}/mark-read'),
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage({String? text, File? image}) async {
    if ((text == null || text.trim().isEmpty) && image == null) return;

    final DateTime timestamp = DateTime.now();
    final String messageId = DateTime.now().millisecondsSinceEpoch.toString();

    // Add message to UI immediately for better UX
    setState(() {
      _messages.add({
        'text': text,
        'image': image,
        'isUser': true,
        'timestamp': timestamp,
        'displayTime': DateFormat('hh:mm a').format(timestamp),
        'status': 'sending',
        'id': messageId,
      });
    });

    // Scroll to bottom to show the new message
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    try {
      // Use the correct API endpoint format
      final Uri url = Uri.parse(
          'https://deliveryapi-ten.vercel.app/chat/${widget.deliveryId}/${widget.senderId}/${widget.receiverId}');

      final Map<String, dynamic> messageData = {
        'message': text,
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(messageData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);

        // Update the message status and ID with the one from the server
        setState(() {
          final index = _messages.indexWhere(
              (msg) => msg['timestamp'] == timestamp && msg['isUser'] == true);

          if (index != -1) {
            _messages[index]['status'] = 'delivered';
            _messages[index]['id'] = responseData['_id'] ?? messageId;
          }
        });

        // Immediately fetch messages to ensure both sides are updated
        _fetchChatHistory(silent: true);

        // Clear the message input
        _messageController.clear();
      } else {
        // Handle error
        setState(() {
          final index = _messages.indexWhere(
              (msg) => msg['timestamp'] == timestamp && msg['isUser'] == true);

          if (index != -1) {
            _messages[index]['status'] = 'error';
          }
        });
        print(
            'Failed to send message: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      // Handle exception
      setState(() {
        final index = _messages.indexWhere(
            (msg) => msg['timestamp'] == timestamp && msg['isUser'] == true);

        if (index != -1) {
          _messages[index]['status'] = 'error';
        }
      });
      print('Error sending message: $e');
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

  // Add this method to create shimmer loading effect for messages
  Widget _buildLoadingShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        itemCount: 6, // Show 6 shimmer message bubbles
        itemBuilder: (_, index) {
          final bool isUserMessage =
              index % 2 == 0; // Alternate between user and other messages

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
                  width: 200 -
                      (index * 20) %
                          100, // Varying widths for more natural look
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
                              contentPadding: EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 4),
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
                              _sendMessage(
                                  text: _messageController.text.trim());
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

    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else if (date.isAfter(DateTime(now.year, now.month, now.day - 7))) {
      // Within the last week
      return DateFormat('EEEE').format(date); // Day name (e.g., "Monday")
    } else if (date.year == now.year) {
      // Same year
      return DateFormat('MMMM d')
          .format(date); // Month and day (e.g., "March 16")
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
                maxWidth: MediaQuery.of(context).size.width * 0.65,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isUser ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: isUser ? null : Border.all(color: Colors.grey.shade200),
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
                        fontSize: 15,
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
                        // Always format from DateTime
                        DateFormat('hh:mm a').format(
                          message['timestamp'] is DateTime
                              ? message['timestamp']
                              : DateTime.tryParse(
                                      message['timestamp'].toString()) ??
                                  DateTime.now(),
                        ),
                        style: TextStyle(
                          fontSize: 10,
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
