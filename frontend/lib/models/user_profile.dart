class UserProfile { //this file is for converting json to dart object.Because flutter cant use json directly
//
  final int id;//this says that userprofile must have these fields
  final String name;
  final String role;
  final String email;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });
  factory UserProfile.fromJson(Map<String, dynamic> json) {//this is converter part.it says take backend from 
  //backend and convert into userprfleobject
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}
