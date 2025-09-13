class Message {
  final int messageId;
  final String content;
  final int senderId;
  final String senderName;

  Message({
    required this.messageId,
    required this.content,
    required this.senderId,
    required this.senderName,
  });

  factory Message.fromJson(Map<String, dynamic> data) {
    int messageId = (data["messageId"] as num).toInt();
    String content = data["content"] as String;
    int senderId = (data["senderId"] as num).toInt();
    String senderName = data["senderName"] as String;

    return Message(
      messageId: messageId,
      content: content,
      senderId: senderId,
      senderName: senderName,
    );
  }
}
