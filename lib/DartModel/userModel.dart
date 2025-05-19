/// name : "string"
/// surname : "string"
/// username : "string"
/// email : "user@example.com"

class UserModel {
  UserModel({
      String name, 
      String surname, 
      String username, 
      String email,}){
    _name = name;
    _surname = surname;
    _username = username;
    _email = email;
}

  UserModel.fromJson(dynamic json) {
    _name = json['name'];
    _surname = json['surname'];
    _username = json['username'];
    _email = json['email'];
  }
  String _name;
  String _surname;
  String _username;
  String _email;
UserModel copyWith({  String name,
  String surname,
  String username,
  String email,
}) => UserModel(  name: name ?? _name,
  surname: surname ?? _surname,
  username: username ?? _username,
  email: email ?? _email,
);
  String get name => _name;
  String get surname => _surname;
  String get username => _username;
  String get email => _email;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['name'] = _name;
    map['surname'] = _surname;
    map['username'] = _username;
    map['email'] = _email;
    return map;
  }

}