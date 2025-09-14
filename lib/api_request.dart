import 'package:chatterbox/entities/message.dart';
import 'package:chatterbox/entities/user.dart';
import 'package:chatterbox/entities/group.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

String originUrl = "https://app.bustedindustries.com";
String baseUrl = originUrl;

Future<void> initBaseUrl() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey("current_server")) {
    final a = prefs.getString("current_server");

    if (a == null) return;

    baseUrl = a;
  } else {
    prefs.setString("current_server", originUrl);
    prefs.setStringList("servers_address", [originUrl]);
  }
}

Future<bool> isValidServer(String serverAddress) async {
  String url = "$serverAddress/api/test.php";

  if (url.substring(0, 5) != "https") {
    return false;
  }

  try {
    final uri = Uri.parse(url);
    final response = await http.get(uri);
    if (response.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  } catch (e) {
    return false;
  }
}

Future<String> register(String username, String password) async {
  String url = "$baseUrl/api/auth/register.php";

  final uri = Uri.parse(url);

  final body = json.encode({"username": username, "password": password});

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 201) {
    return "Inscription réussie";
  } else {
    return json.decode(response.body)["erreur"];
  }
}

Future<String> login(String username, String password) async {
  String url = "$baseUrl/api/auth/login.php";
  final uri = Uri.parse(url);

  final body = json.encode({"username": username, "password": password});

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    await User.persist(data);

    return "Connexion réussie";
  } else {
    return json.decode(response.body)["erreur"];
  }
}

Future<User> getUserInfo(int id, String token) async {
  String url = "$baseUrl/api/users/getUserInfo.php";
  final uri = Uri.parse(url);

  final body = json.encode({"userId": id, "token": token});

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    return User.fromJson(data);
  } else {
    return User(userId: -1, username: "Inexistant", token: "none");
  }
}

Future<List<Group>> getUserGroups(int? id, String? token) async {
  String url = "$baseUrl/api/users/getUserGroups.php";
  final uri = Uri.parse(url);

  final body = json.encode({"userId": id, "token": token});

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    List<Group> res = [];
    for (var element in data["success"]) {
      res.add(Group.fromJson(element));
    }
    return res;
  } else {
    return [];
  }
}

Future<List<Message>> getGroupMessages(
  int groupId,
  int userId,
  String token,
  int offset,
  int limit,
) async {
  final uri = Uri.parse("$baseUrl/api/messages/getMessages.php");

  final body = json.encode({
    "userId": userId,
    "token": token,
    "groupId": groupId,
    "offset": offset,
    "limit": limit,
  });

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    List<Message> res = [];
    for (var element in data["success"]) {
      res.add(Message.fromJson(element));
    }
    return res;
  } else {
    return [];
  }
}

void sendMessage(int groupId, int userId, String token, String content) async {
  String url = "$baseUrl/api/messages/sendMessage.php";
  final uri = Uri.parse(url);

  final body = json.encode({
    "userId": userId,
    "token": token,
    "groupId": groupId,
    "content": content,
  });

  await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
}

void createBasicGroupChat(int userId, String token) async {
  String url = "$baseUrl/api/groups/createGroup.php";
  final uri = Uri.parse(url);

  final body = json.encode({"userId": userId, "token": token});

  await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
}

void leaveGroupChat(int userId, String token, int groupId) async {
  String url = "$baseUrl/api/groups/leaveGroup.php";
  final uri = Uri.parse(url);

  final body = json.encode({
    "userId": userId,
    "token": token,
    "groupId": groupId,
  });

  await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
}

void changeGroupName(
  int userId,
  String token,
  int groupId,
  String newGroupName,
) async {
  String url = "$baseUrl/api/groups/changeGroupName.php";
  final uri = Uri.parse(url);

  final body = json.encode({
    "userId": userId,
    "token": token,
    "groupId": groupId,
    "newGroupName": newGroupName,
  });

  await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
}

void addUserToGroup(
  int userId,
  String token,
  int groupId,
  int addUserId,
) async {
  String url = "$baseUrl/api/groups/addUser.php";
  final uri = Uri.parse(url);

  final body = json.encode({
    "userId": userId,
    "token": token,
    "groupId": groupId,
    "addUserId": addUserId,
  });

  await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
}

Future<List<User>> getGroupMembers(int groupId) async {
  String url = "$baseUrl/api/groups/getGroupMembers.php";
  final uri = Uri.parse(url);

  final body = json.encode({"groupId": groupId});

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    List<User> res = [];
    for (var element in data["success"]) {
      res.add(User.fromJson(element));
    }
    return res;
  } else {
    return [];
  }
}

Future<List<User>> getUserByStartingName(String username) async {
  final uri = Uri.parse(
    "$baseUrl/api/users/getUserByStartingName.php",
  ).replace(queryParameters: {"username": username});

  final response = await http.get(
    uri,
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    List<User> res = [];
    for (var element in data["success"]) {
      res.add(User.fromJson(element));
    }
    return res;
  } else {
    return [];
  }
}

Future<String> resetToken(int userId, String token) async {
  String url = "$baseUrl/api/users/resetToken.php";
  final uri = Uri.parse(url);

  final body = json.encode({"userId": userId, "token": token});

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  final data = json.decode(response.body);

  if (response.statusCode == 200) {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("user_token", data["token"]);
    return data["success"];
  } else {
    return data["erreur"];
  }
}

Future<String> changePassword(
  int userId,
  String token,
  String newPassword,
) async {
  String url = "$baseUrl/api/users/changePassword.php";
  final uri = Uri.parse(url);

  final body = json.encode({
    "userId": userId,
    "token": token,
    "newPassword": newPassword,
  });

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  final data = json.decode(response.body);

  if (response.statusCode == 200) {
    return data["success"];
  } else {
    return data["erreur"];
  }
}

Future<int> deleteAccount(int userId, String token) async {
  String url = "$baseUrl/api/users/deleteAccount.php";
  final uri = Uri.parse(url);

  final body = json.encode({"userId": userId, "token": token});

  final response = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  return response.statusCode;
}
