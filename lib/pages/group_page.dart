import 'package:chatterbox/pages/group_page_settings.dart';
import 'package:chatterbox/utils.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatterbox/api_request.dart';
import 'dart:async';
import 'package:chatterbox/entities/message.dart';

class GroupPage extends StatefulWidget {
  const GroupPage({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.refreshFunction,
  });

  final int groupId;
  final String groupName;

  final Function refreshFunction;

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  List<Message> _messages = [];
  List<Widget> _messagesWidgets = [];
  bool _loadingMessages = true;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  final ScrollController _scrollController = ScrollController();
  final _messageController = TextEditingController();

  late Timer _timer;
  int _currentOffset = 0;
  final int _limit = 20;
  String groupName = "";

  @override
  void initState() {
    super.initState();
    groupName = widget.groupName;
    _initializeScreen();
    _timer = Timer.periodic(
      const Duration(seconds: 2),
      (Timer t) => _refresh(),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _timer.cancel();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    try {
      setState(() {
        _loadingMessages = true;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt("user_id");
      final token = prefs.getString("user_token");

      if (userId == null || token == null) {
        throw Exception("Identifiants manquants.");
      }

      final initialMessages = await getGroupMessages(
        widget.groupId,
        userId,
        token,
        0,
        _limit,
      );

      _messages = initialMessages;
      _currentOffset = initialMessages.length;

      final widgets = await _buildMessagesWidgetFromMessages(_messages, userId);

      setState(() {
        _messagesWidgets = widgets;
        _loadingMessages = false;
      });
    } catch (e) {
      debugPrint("Erreur lors de l'initialisation : $e");
      setState(() {
        _loadingMessages = false;
      });
    }
    await _loadMoreMessages();
    _scrollToBottom();
  }

  Future<List<Widget>> _buildMessagesWidgetFromMessages(
    List<Message> messages,
    int userId,
  ) async {
    final List<Widget> widgets = [];

    for (final message in messages.reversed) {
      final isMine = message.senderId == userId;

      widgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Align(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isMine ? Colors.blue[700] : Colors.grey[700],
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.blue[600] : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMine ? 18 : 0),
                        bottomRight: Radius.circular(isMine ? 0 : 18),
                      ),
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isMine ? Colors.white : Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent * 1.2,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() async {
    final String messageContent = _messageController.text.trim();
    if (messageContent.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");
    final token = prefs.getString("user_token");

    sendMessage(widget.groupId, userId!, token!, messageContent);

    _messageController.clear();
    _refresh();
  }

  void _refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");
    final token = prefs.getString("user_token");

    final newMessages = await getGroupMessages(
      widget.groupId,
      userId!,
      token!,
      0,
      _limit,
    );

    final newUniqueMessages = newMessages
        .where(
          (msg) =>
              !_messages.any((existing) => existing.messageId == msg.messageId),
        )
        .toList();

    if (newUniqueMessages.isNotEmpty) {
      _messages.addAll(newUniqueMessages);
      final widgets = await _buildMessagesWidgetFromMessages(
        newUniqueMessages,
        userId,
      );

      setState(() {
        _messagesWidgets.addAll(widgets);
      });

      _scrollToBottom();
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || !_hasMoreMessages) return;

    setState(() {
      _isLoadingMore = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");
    final token = prefs.getString("user_token");

    try {
      final oldMessages = await getGroupMessages(
        widget.groupId,
        userId!,
        token!,
        _currentOffset,
        _limit,
      );

      if (oldMessages.isEmpty) {
        setState(() {
          _hasMoreMessages = false;
        });
      } else {
        _messages.insertAll(0, oldMessages);
        _currentOffset += oldMessages.length;

        final widgets = await _buildMessagesWidgetFromMessages(
          oldMessages,
          userId,
        );

        setState(() {
          _messagesWidgets.insertAll(0, widgets);
        });
      }
    } catch (e) {
      debugPrint("Erreur lors du chargement supplémentaire : $e");
    } finally {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _changeGroupName(String newGroupName) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");
    final token = prefs.getString("user_token");

    setState(() {
      groupName = newGroupName;
    });

    if (userId == null || token == null) {
      throw Exception("Identifiants manquants.");
    }

    changeGroupName(userId, token, widget.groupId, newGroupName);
  }

  void _addUser(int addUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("user_id");
    final token = prefs.getString("user_token");

    if (userId == null || token == null) {
      throw Exception("Identifiants manquants.");
    }

    addUserToGroup(userId, token, widget.groupId, addUserId);
    showSnackBar(context, "Utilisateur ajouté", Colors.green);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loadingMessages) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Chargement des données..."),
              const SizedBox(height: 20),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.primary,
                ),
                strokeWidth: 4,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(child: Text(groupName, overflow: TextOverflow.ellipsis)),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GroupPageSettings(
                      groupId: widget.groupId,
                      groupName: widget.groupName,
                      reloadFunction: widget.refreshFunction,
                      addUserFunction: _addUser,
                      changeGroupNameFunction: _changeGroupName,
                    ),
                  ),
                );
              },
              child: Icon(Icons.settings),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                itemCount: _messagesWidgets.length + (_hasMoreMessages ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_hasMoreMessages && index == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: _isLoadingMore ? null : _loadMoreMessages,
                          child: _isLoadingMore
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text("Charger plus de messages"),
                        ),
                      ),
                    );
                  } else {
                    final messageIndex = _hasMoreMessages ? index - 1 : index;
                    return _messagesWidgets[messageIndex];
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: "Écrire un message...",
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade400,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white),
                      onPressed: _sendMessage,
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
