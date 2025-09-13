class Group {
  final int groupId;
  final String name;

  Group({required this.groupId, required this.name});

  factory Group.fromJson(Map<String, dynamic> data) {
    int userId = (data["groupId"] as num).toInt();
    String username = data["name"] as String;

    return Group(groupId: userId, name: username);
  }
}
