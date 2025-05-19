/// name : "string"
/// surname : "string"
/// username : "string"
/// email : "user@example.com"

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
