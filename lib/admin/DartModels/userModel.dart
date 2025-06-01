/// name : "string"
/// surname : "string"
/// username : "string"
/// email : "user@example.com"
// {
// "access_token": "string",
// "token_type": "string",
// "expires_in": 0,
// "user": {
// "name": "string",
// "surname": "string",
// "username": "string",
// "email": "user@example.com"
// }
// }
class LoginRegisterModel {
  String? accessToken;
  String? tokenType;
  int? expiresIn;
  UserModel? user;

  LoginRegisterModel({
    this.accessToken,
    this.tokenType,
    this.expiresIn,
    this.user,
  });

  LoginRegisterModel.fromJson(Map<String, dynamic> json) {
    accessToken = json['access_token'];
    tokenType = json['token_type'];
    expiresIn = json['expires_in'];
    if (json['user'] != null) {
      user = UserModel.fromJson(json['user']);
    } else {
      user = null;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['access_token'] = accessToken;
    data['token_type'] = tokenType;
    data['expires_in'] = expiresIn;
    if (user != null) {
      data['user'] = user!.toJson();
    }
    return data;
  }
}

class UserModel {
  String? name;
  String? surname;
  String? username;
  String? email;

  UserModel({this.name, this.surname, this.username, this.email});

  UserModel.fromJson(Map<String, dynamic> json) {
    name = json['name'];
    surname = json['surname'];
    username = json['username'];
    email = json['email'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['name'] = name;
    data['surname'] = surname;
    data['username'] = username;
    data['email'] = email;
    return data;
  }
}
