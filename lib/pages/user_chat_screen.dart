import 'dart:io';
import 'dart:math';
import 'dart:convert';
import 'dart:async'; // Add this import
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:micollins_delivery_app/services/notification_service.dart';
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

class _UserChatScreenState extends State<UserChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
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

  String? _lastMessageId; // Tracks the last message ID

  // Add this variable to track if the chat is active
  bool _isActiveChat = true;
  DateTime? _lastProcessedMessageTime;
  Set<String> _notifiedMessageIds = {};

  @override
  void initState() {
    super.initState();
    // Register this object as an observer
    WidgetsBinding.instance.addObserver(this);

    _isActiveChat = true;

    // Initialize the set of notified message IDs
    _notifiedMessageIds = <String>{};

    // Set the last processed time to now when the chat is opened
    // This prevents old messages from triggering notifications
    _lastProcessedMessageTime =
        DateTime.now().subtract(const Duration(minutes: 5));
    print(
        'DEBUG: Initialized last processed time to $_lastProcessedMessageTime');

    _fetchChatHistory();

    // Set up periodic refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _fetchChatHistory(silent: true);
      }
    });

    // Start polling for new messages
    _startMessagePolling();
  }

  @override
  void dispose() {
    // Remove this object as an observer
    WidgetsBinding.instance.removeObserver(this);

    _refreshTimer?.cancel();
    _scrollController.dispose();
    _messageController.dispose();
    _isActiveChat = false;
    super.dispose();
  }

  // Now this is a proper override of the WidgetsBindingObserver method
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    print("App lifecycle state changed to: $state");

    if (state == AppLifecycleState.resumed) {
      print("DEBUG: App resumed - setting chat as active");
      setState(() {
        _isActiveChat = true;
      });
      // Refresh messages when app is resumed
      _fetchChatHistory(silent: true);
    } else {
      // For any other state (paused, inactive, detached, hidden)
      print("DEBUG: App not in foreground - setting chat as inactive");
      setState(() {
        _isActiveChat = false;
      });
    }
  }

  void _startMessagePolling() {
    // Create a separate timer for background polling
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        // Always check for new messages, regardless of active state
        _checkForNewMessages();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _checkForNewMessages() async {
    if (widget.deliveryId == null || widget.senderId == null) {
      print('DEBUG: deliveryId or senderId is null, cannot check for messages');
      return;
    }

    try {
      print(
          'DEBUG: Checking for new messages for delivery ${widget.deliveryId}');
      final response = await http.get(
        Uri.parse(
            'https://deliveryapi-ten.vercel.app/chat/${widget.deliveryId}'),
        headers: {
          'Accept': 'application/json',
        },
      );

      print('DEBUG: Chat API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Get messages from the response
        List<dynamic> messages = [];
        if (data is List) {
          messages = data;
        } else if (data['messages'] != null) {
          messages = data['messages'];
        }

        print('DEBUG: Processing ${messages.length} messages');

        // Find the most recent message from the other user
        Map<String, dynamic>? latestMessage;
        DateTime? latestTimestamp;

        for (var msg in messages) {
          // Only consider messages from the other user (not from current user)
          if (msg['sender_id'] != widget.senderId) {
            // Parse the timestamp and convert to local time zone
            final String timestampStr = msg['timestamp'];
            final DateTime serverTime = DateTime.parse(timestampStr);

            // Convert to local time
            final DateTime localTime = serverTime.toLocal();

            print(
                'DEBUG: Message time - Server: $serverTime, Local: $localTime');

            // If we haven't set a latest message yet, or this one is newer
            if (latestMessage == null || localTime.isAfter(latestTimestamp!)) {
              latestMessage = msg;
              latestTimestamp = localTime;
            }
          }
        }

        // If we found a message and it's newer than our last processed message
        if (latestMessage != null && latestTimestamp != null) {
          final String messageId = latestMessage['_id'];
          final String messageText = latestMessage['message'];

          print(
              'DEBUG: Latest message from other user - ID: $messageId, Time: $latestTimestamp, Text: $messageText');

          // Check if this message is new and hasn't been notified yet
          bool isNewMessage = !_notifiedMessageIds.contains(messageId) &&
              (_lastProcessedMessageTime == null ||
                  latestTimestamp.isAfter(_lastProcessedMessageTime!));

          print(
              'DEBUG: Is this a new message? $isNewMessage (Last processed time: $_lastProcessedMessageTime)');

          if (isNewMessage) {
            // Add to notified messages
            _notifiedMessageIds.add(messageId);
            _lastProcessedMessageTime = latestTimestamp;

            print('DEBUG: This is a new message that needs notification');

            // Only show notification if app is not in foreground or chat is not active
            final bool shouldShowNotification = !_isActiveChat;
            print(
                'DEBUG: Should show notification? $shouldShowNotification (isActiveChat: $_isActiveChat)');

            if (shouldShowNotification) {
              print('DEBUG: Showing notification for message: $messageText');

              try {
                await NotificationService().showMessageNotification(
                  title: 'New message from ${widget.userName ?? "Rider"}',
                  body: messageText,
                  payload: {
                    'type': 'message',
                    'deliveryId': widget.deliveryId,
                    'senderId': widget.receiverId,
                    'receiverId': widget.senderId,
                    'userName': widget.userName,
                    'userImage': widget.userImage,
                    'orderId': widget.orderId,
                  },
                );
                print('DEBUG: Notification service called successfully');
              } catch (e) {
                print('DEBUG: Error calling notification service: $e');
              }
            } else {
              print('DEBUG: Not showing notification because chat is active');
            }

            // Refresh the chat history silently
            _fetchChatHistory(silent: true);
          } else {
            print(
                'DEBUG: Message already processed or not new enough for notification');
          }
        } else {
          print('DEBUG: No messages from the other user found');
        }
      } else {
        print(
            'DEBUG: Failed to fetch chat data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('DEBUG: Error checking for new messages: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isActiveChat = true;
  }

  // Modify _fetchChatHistory to handle message IDs better
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
        Set<String> messageIds = {}; // Track message IDs to avoid duplicates

        if (data is List) {
          // Direct array of messages
          for (var msg in data) {
            final String msgId = msg['_id'];

            // Skip if we've already processed this message
            if (messageIds.contains(msgId)) continue;
            messageIds.add(msgId);

            final timestamp = DateTime.parse(msg['timestamp']);

            fetchedMessages.add({
              'text': msg['message'],
              'image': null,
              'isUser': msg['sender_id'] == widget.senderId,
              'timestamp': DateFormat('hh:mm a').format(timestamp),
              'status': msg['read'] ? 'read' : 'delivered',
              'id': msgId,
            });
          }
        } else if (data['messages'] != null) {
          // Response with 'messages' property
          for (var msg in data['messages']) {
            final String msgId = msg['_id'];

            // Skip if we've already processed this message
            if (messageIds.contains(msgId)) continue;
            messageIds.add(msgId);

            final timestamp = DateTime.parse(msg['timestamp']);

            fetchedMessages.add({
              'text': msg['message'],
              'image': null,
              'isUser': msg['sender_id'] == widget.senderId,
              'timestamp': DateFormat('hh:mm a').format(timestamp),
              'status': msg['read'] ? 'read' : 'delivered',
              'id': msgId,
            });
          }
        } else {
          print('No messages found in the API response');
        }

        // Only update state if there are messages
        if (fetchedMessages.isNotEmpty) {
          // Sort messages by timestamp to ensure correct order
          fetchedMessages.sort((a, b) {
            final timeA = DateFormat('hh:mm a').parse(a['timestamp']);
            final timeB = DateFormat('hh:mm a').parse(b['timestamp']);
            return timeA.compareTo(timeB);
          });

          // Update the messages list
          setState(() {
            _messages = fetchedMessages;
            _isLoading = false;
          });

          // Store the ID of the last message
          if (fetchedMessages.isNotEmpty) {
            _lastMessageId = fetchedMessages.last['id'];
          }

          // Mark messages as read
          _markMessagesAsRead();

          // Scroll to bottom on new messages
          if (fetchedMessages.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _scrollToBottom();
            });
          }
        } else if (_messages.isEmpty) {
          // Only set empty state if we haven't loaded any messages yet
          setState(() {
            _isLoading = false;
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
              'https://deliveryapi-ten.vercel.app/chat/${widget.deliveryId}/${widget.senderId}/${widget.receiverId}'),
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
